const http = require('http');
const fs = require('fs');
const path = require('path');
const { WebSocketServer } = require('ws');

const PORT = process.env.PORT || 8080;
const USERS_FILE = path.join(__dirname, 'users.json');

// Load persisted users from disk
function loadUsers() {
    try {
        if (fs.existsSync(USERS_FILE)) {
            const data = fs.readFileSync(USERS_FILE, 'utf8');
            const arr = JSON.parse(data);
            const map = new Map();
            for (const user of arr) {
                map.set(user.id, user);
            }
            console.log(`[Persistence] Loaded ${map.size} users from disk`);
            return map;
        }
    } catch (err) {
        console.error('[Persistence] Failed to load users:', err.message);
    }
    return new Map();
}

// Save users to disk
function saveUsers() {
    try {
        const arr = Array.from(registeredUsers.values());
        fs.writeFileSync(USERS_FILE, JSON.stringify(arr, null, 2), 'utf8');
    } catch (err) {
        console.error('[Persistence] Failed to save users:', err.message);
    }
}

// Create HTTP server to handle both HTTP API and WebSocket
const server = http.createServer((req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    // POST /register - Register a user
    if (req.method === 'POST' && req.url === '/register') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const { id, name, email, avatarUrl, passwordHash } = JSON.parse(body);
                if (!id || !name || !email) {
                    res.writeHead(400, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'id, name, email required' }));
                    return;
                }
                registeredUsers.set(id, { id, name, email, avatarUrl: avatarUrl || null, passwordHash: passwordHash || null });
                saveUsers();
                console.log(`[HTTP] User registered: ${name} (${id})`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ok' }));
            } catch {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Invalid JSON' }));
            }
        });
        return;
    }

    // POST /login - Authenticate a user
    if (req.method === 'POST' && req.url === '/login') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const { email, passwordHash } = JSON.parse(body);
                if (!email || !passwordHash) {
                    res.writeHead(400, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'email and passwordHash required' }));
                    return;
                }
                // Find user by email
                let foundUser = null;
                for (const user of registeredUsers.values()) {
                    if (user.email === email) {
                        foundUser = user;
                        break;
                    }
                }
                if (!foundUser || foundUser.passwordHash !== passwordHash) {
                    console.log(`[HTTP] Login failed for ${email}`);
                    res.writeHead(401, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Invalid credentials' }));
                    return;
                }
                console.log(`[HTTP] Login success: ${foundUser.name} (${foundUser.id})`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ id: foundUser.id, name: foundUser.name, email: foundUser.email, avatarUrl: foundUser.avatarUrl }));
            } catch {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Invalid JSON' }));
            }
        });
        return;
    }

    // GET /users - Get all registered users
    if (req.method === 'GET' && req.url === '/users') {
        const users = Array.from(registeredUsers.values()).map(({ passwordHash, ...rest }) => rest);
        console.log(`[HTTP] Users list requested, returning ${users.length} users`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(users));
        return;
    }

    // Health check
    if (req.method === 'GET' && req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'running', users: registeredUsers.size }));
        return;
    }

    res.writeHead(404);
    res.end();
});

const wss = new WebSocketServer({ server });

// userId -> WebSocket connection
const connections = new Map();

// Persistent user registry: userId -> { id, name, email, avatarUrl, passwordHash }
const registeredUsers = loadUsers();

// In-memory message storage
const messageStore = [];
const groupMessages = new Map(); // groupId -> messages[]

wss.on('connection', (ws) => {
    let userId = null;

    ws.on('message', (raw) => {
        let data;
        try {
            data = JSON.parse(raw.toString());
        } catch {
            return;
        }

        const { event } = data;

        switch (event) {
            case 'connect': {
                userId = data.userId;
                if (!userId) return;
                connections.set(userId, ws);
                console.log(`User connected: ${userId}`);

                // Broadcast presence to all other users
                broadcast({
                    event: 'presence',
                    userId,
                    status: 'online',
                    timestamp: new Date().toISOString(),
                }, userId);

                // Send current online users list to the newly connected user
                const onlineUsers = [];
                for (const [id] of connections) {
                    if (id !== userId) onlineUsers.push(id);
                }
                ws.send(JSON.stringify({
                    event: 'online_users',
                    users: onlineUsers,
                    timestamp: new Date().toISOString(),
                }));
                break;
            }

            case 'message': {
                const { receiverId, text, messageId } = data;
                if (!userId || !receiverId || !text) return;

                const message = {
                    event: 'message',
                    messageId: messageId || generateId(),
                    senderId: userId,
                    receiverId,
                    text,
                    timestamp: new Date().toISOString(),
                };

                // Store message
                messageStore.push(message);

                // Send ACK to sender
                ws.send(JSON.stringify({
                    event: 'message_ack',
                    messageId: message.messageId,
                    status: 'sent',
                    timestamp: message.timestamp,
                }));

                // Route to receiver
                const receiverSocket = connections.get(receiverId);
                if (receiverSocket && receiverSocket.readyState === 1) {
                    receiverSocket.send(JSON.stringify(message));

                    // Send delivered status back to sender
                    ws.send(JSON.stringify({
                        event: 'message_status',
                        messageId: message.messageId,
                        status: 'delivered',
                        timestamp: new Date().toISOString(),
                    }));
                }
                break;
            }

            case 'group_message': {
                const { groupId, text, messageId, memberIds } = data;
                if (!userId || !groupId || !text) return;

                const message = {
                    event: 'group_message',
                    messageId: messageId || generateId(),
                    senderId: userId,
                    groupId,
                    text,
                    timestamp: new Date().toISOString(),
                };

                // Store group message
                if (!groupMessages.has(groupId)) {
                    groupMessages.set(groupId, []);
                }
                groupMessages.get(groupId).push(message);

                // Send ACK to sender
                ws.send(JSON.stringify({
                    event: 'message_ack',
                    messageId: message.messageId,
                    status: 'sent',
                    timestamp: message.timestamp,
                }));

                // Broadcast to all group members except sender
                const members = memberIds || [];
                for (const memberId of members) {
                    if (memberId === userId) continue;
                    const memberSocket = connections.get(memberId);
                    if (memberSocket && memberSocket.readyState === 1) {
                        memberSocket.send(JSON.stringify(message));
                    }
                }
                break;
            }

            case 'typing': {
                const { receiverId: typingReceiverId, groupId: typingGroupId } = data;
                if (!userId) return;

                const typingEvent = {
                    event: 'typing',
                    senderId: userId,
                    timestamp: new Date().toISOString(),
                };

                if (typingGroupId) {
                    // Broadcast typing to group members
                    typingEvent.groupId = typingGroupId;
                    const members = data.memberIds || [];
                    for (const memberId of members) {
                        if (memberId === userId) continue;
                        const memberSocket = connections.get(memberId);
                        if (memberSocket && memberSocket.readyState === 1) {
                            memberSocket.send(JSON.stringify(typingEvent));
                        }
                    }
                } else if (typingReceiverId) {
                    // Send typing to specific user
                    typingEvent.receiverId = typingReceiverId;
                    const receiverSocket = connections.get(typingReceiverId);
                    if (receiverSocket && receiverSocket.readyState === 1) {
                        receiverSocket.send(JSON.stringify(typingEvent));
                    }
                }
                break;
            }

            case 'message_seen': {
                const { messageId: seenMsgId, senderId: originalSenderId } = data;
                if (!userId || !seenMsgId || !originalSenderId) return;

                const senderSocket = connections.get(originalSenderId);
                if (senderSocket && senderSocket.readyState === 1) {
                    senderSocket.send(JSON.stringify({
                        event: 'message_status',
                        messageId: seenMsgId,
                        status: 'seen',
                        timestamp: new Date().toISOString(),
                    }));
                }
                break;
            }

            case 'register_user': {
                const { id, name, email, avatarUrl, passwordHash } = data;
                if (!id || !name || !email) return;

                registeredUsers.set(id, { id, name, email, avatarUrl: avatarUrl || null, passwordHash: passwordHash || null });
                saveUsers();
                console.log(`User registered: ${name} (${id})`);

                // ACK back to sender
                ws.send(JSON.stringify({
                    event: 'register_user_ack',
                    status: 'ok',
                    timestamp: new Date().toISOString(),
                }));
                break;
            }

            case 'get_users': {
                // Return all registered users to the requesting client
                const users = Array.from(registeredUsers.values());
                ws.send(JSON.stringify({
                    event: 'users_list',
                    users,
                    timestamp: new Date().toISOString(),
                }));
                break;
            }

            default:
                break;
        }
    });

    ws.on('close', () => {
        if (userId) {
            connections.delete(userId);
            console.log(`User disconnected: ${userId}`);

            // Broadcast offline presence
            broadcast({
                event: 'presence',
                userId,
                status: 'offline',
                timestamp: new Date().toISOString(),
            }, userId);
        }
    });

    ws.on('error', (err) => {
        console.error(`WebSocket error for user ${userId}:`, err.message);
    });
});

function broadcast(data, excludeUserId) {
    const payload = JSON.stringify(data);
    for (const [id, socket] of connections) {
        if (id !== excludeUserId && socket.readyState === 1) {
            socket.send(payload);
        }
    }
}

function generateId() {
    return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
}

server.listen(PORT, '0.0.0.0', () => {
    const os = require('os');
    const nets = os.networkInterfaces();
    const localIps = [];
    for (const iface of Object.values(nets)) {
        for (const cfg of iface) {
            if (cfg.family === 'IPv4' && !cfg.internal) {
                localIps.push(cfg.address);
            }
        }
    }
    const ip = localIps[0] || 'localhost';
    console.log(`PulseChat server running on port ${PORT}`);
    console.log(`  Local:   http://localhost:${PORT}`);
    console.log(`  Network: http://${ip}:${PORT}`);
    console.log(`  WebSocket: ws://${ip}:${PORT}`);
    console.log(`\nRun Flutter with: flutter run --dart-define=SERVER_IP=${ip}`);
});
