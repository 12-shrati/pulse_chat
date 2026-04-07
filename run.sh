#!/bin/bash
# Auto-detect local IP and run Flutter with the correct SERVER_IP
IP=$(hostname -I | awk '{print $1}')
if [ -z "$IP" ]; then
  IP="10.0.2.2"
fi
echo "Detected IP: $IP"
echo "Starting Flutter with SERVER_IP=$IP ..."
flutter run --dart-define=SERVER_IP=$IP "$@"
