# PulseChat

A real-time messaging app built with **Flutter** and a **Node.js WebSocket server**. Features one-on-one chat, group messaging, typing indicators, message delivery states, offline storage, and animated UI — all wired together with clean architecture and Riverpod.

---

## Features

### Messaging
- One-on-one real-time chat via WebSocket
- Group messaging with member broadcast
- Message states: **sending → sent → delivered → seen**
- Typing indicators (per-user and per-group)
- Presence updates (online/offline status)

### UI & Animations
- Reverse `ListView` (latest messages at bottom)
- Message bubble slide-in animations (left for received, right for sent)
- Animated send button (scales in/out based on text input)
- Animated status icon transitions on message bubbles
- Typing indicator in the app bar
- Emoji button and image picker placeholders

### Offline & Storage
- SQLite local database via `sqflite`
- Messages saved locally for instant chat history loading
- Session persistence (auto-login on app restart)
- Contact and group management stored locally
- Server sync on reconnect

### Architecture
- **Clean Architecture** — data / domain / presentation layers per feature
- **Riverpod** state management with `StateNotifier` + providers
- **Repository pattern** for data abstraction
- **Use cases** for single-responsibility business logic
- **GoRouter** for declarative navigation

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x, Dart |
| State Management | Riverpod (`flutter_riverpod`) |
| Routing | GoRouter (`go_router`) |
| WebSocket Client | `web_socket_channel` |
| Local Database | SQLite (`sqflite`) |
| Connectivity | `connectivity_plus` |
| Backend | Node.js + `ws` |

---

## Project Structure

```
pulse_chat/
├── lib/
│   ├── main.dart                    # App entry point, DB init, ProviderScope
│   ├── app_router.dart              # GoRouter route definitions
│   ├── core/
│   │   ├── constant/
│   │   │   ├── app_color.dart       # Color palette & gradients
│   │   │   ├── app_icons.dart       # Centralized icon constants
│   │   │   ├── app_style.dart       # Text styles & button styles
│   │   │   └── string_constants.dart# All UI strings
│   │   ├── database/
│   │   │   ├── database_helper.dart # SQLite schema & migrations
│   │   │   └── database_provider.dart# Riverpod DB provider
│   │   ├── network/
│   │   │   └── connectivity_service.dart # Network state monitoring
│   │   └── websocket/
│   │       ├── websocket_service.dart   # WebSocket client with auto-reconnect
│   │       └── websocket_provider.dart  # Riverpod WS provider
│   └── features/
│       ├── auth/                    # Login, register, contacts, sessions
│       ├── chat/                    # 1-on-1 messaging
│       ├── group/                   # Group chat & member management
│       ├── home/                    # Main hub with tabs & search
│       └── splash/                  # App initialization & session restore
├── server/
│   ├── server.js                    # Node.js WebSocket server
│   └── package.json
├── android/
├── ios/
├── web/
└── pubspec.yaml
```

Each feature follows clean architecture:
```
feature/
├── data/
│   ├── datasources/     # Local DB operations
│   ├── models/           # Data models (fromJson/toJson)
│   └── repositories/     # Repository implementations
├── domain/
│   ├── entities/         # Business entities
│   ├── repositories/     # Abstract repository contracts
│   └── usecases/         # Single-purpose use cases
└── presentation/
    ├── controllers/      # StateNotifier + State classes
    ├── providers/        # Riverpod provider definitions
    ├── screens/          # Page-level widgets
    └── widgets/          # Reusable UI components
```

---

## Database Schema

| Table | Purpose |
|-------|---------|
| `users` | User profiles with password hashes |
| `messages` | All chat messages (1-on-1 & group) |
| `contacts` | User contact relationships |
| `groups` | Group metadata |
| `group_members` | Group membership with roles |
| `sessions` | Login session tracking |
| `chats` | Chat list with last message & unread count |

---

## WebSocket Events

### Client → Server

| Event | Payload | Description |
|-------|---------|-------------|
| `connect` | `{ userId }` | Register user connection |
| `message` | `{ receiverId, text, messageId }` | Send direct message |
| `group_message` | `{ groupId, text, messageId, memberIds }` | Send group message |
| `typing` | `{ receiverId?, groupId?, memberIds? }` | Typing indicator |
| `message_seen` | `{ messageId, senderId }` | Mark message as seen |

### Server → Client

| Event | Payload | Description |
|-------|---------|-------------|
| `message` | `{ messageId, senderId, receiverId, text, timestamp }` | Incoming direct message |
| `group_message` | `{ messageId, senderId, groupId, text, timestamp }` | Incoming group message |
| `message_ack` | `{ messageId, status, timestamp }` | Send acknowledgment |
| `message_status` | `{ messageId, status, timestamp }` | Delivery/seen update |
| `typing` | `{ senderId, receiverId?, groupId? }` | Someone is typing |
| `presence` | `{ userId, status, timestamp }` | User online/offline |
| `online_users` | `{ users[] }` | Initial online users list |

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.11.1`
- Node.js `>=18`
- Android Studio / Xcode (for mobile)

### 1. Clone & Install

```bash
git clone <repo-url>
cd pulse_chat

# Flutter dependencies
flutter pub get

# Server dependencies
cd server
npm install
```

### 2. Start the WebSocket Server

```bash
cd server
npm start
# Server runs on ws://localhost:8080
```

### 3. Configure Server URL

Update the default URL in `lib/core/websocket/websocket_service.dart`:

```dart
// For Android emulator (default):
WebSocketService({String url = 'ws://10.0.2.2:8080'}) : _url = url;

// For iOS simulator:
WebSocketService({String url = 'ws://localhost:8080'}) : _url = url;

// For physical device (use your machine's local IP):
WebSocketService({String url = 'ws://192.168.x.x:8080'}) : _url = url;
```

### 4. Run the App

```bash
flutter run
```

---

## Key Implementation Details

### WebSocket Auto-Reconnect
The `WebSocketService` reconnects automatically with incremental backoff (1s → 30s max). The connection lifecycle is:
1. `connect(userId)` → establishes connection and registers with server
2. On disconnect → schedules reconnect timer
3. On reconnect → re-registers userId, resumes message streams

### Message Flow
```
User types message
  → ChatController.sendMessage()
    → ChatRepository.sendMessage()
      → Save to SQLite (status: sending)
      → Send via WebSocket
      → Server routes to receiver
      → Server sends ACK (status: sent)
      → Receiver confirms delivery (status: delivered)
      → Receiver opens chat (status: seen)
```

### State Management
All state flows through Riverpod providers:
```
WebSocketService → ChatRepository → UseCases → ChatController → UI
                 ↕
            SQLite (ChatLocalDataSource)
```

---

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Splash | `/` | DB init, session restore, auto-navigate |
| Login | `/login` | Email/password authentication |
| Register | `/register` | New user registration |
| Home | `/home` | Tabs: All, Contacts, Groups + search + FAB |
| Chat | `/chat` | 1-on-1 messaging with typing indicator |
| Group List | `/groups` | All groups with create group |
| Group Chat | `/group/:id` | Group messaging with add members |

---

## License

This project is for portfolio/demonstration purposes.
