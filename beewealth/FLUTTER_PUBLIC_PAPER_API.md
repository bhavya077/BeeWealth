# Flutter integration — public paper trading APIs

These endpoints require **no authentication** (no Bearer token, no API key). They expose the same in-memory / DB-backed paper portfolio the backend already uses.

**Production API host:** `api.kalique.xyz` (HTTPS / WSS). The web app is served at `trade.kalique.xyz`; Flutter and other clients should call the **API** host below, not the trade UI origin.

**Local development:** `http://localhost:8000` (REST) and `ws://localhost:8000` (WebSocket), if you run the backend on port 8000.

---

## 1. WebSocket — live open positions

**Purpose:** Stream open paper positions with **symbol** (instrument / trade name), **last traded price (LTP)**, and **unrealized P/L percentage**.

### URL

- **Path:** `/api/public/paper/ws/positions`
- **Full URLs:**
  - **Production:** `wss://api.kalique.xyz/api/public/paper/ws/positions`
  - **Local:** `ws://localhost:8000/api/public/paper/ws/positions`

### Behaviour

- Connect with a normal WebSocket client; no headers required for auth.
- The server sends **one JSON object per second** while the connection stays open.
- If there are no open positions, `positions` is an empty array.

### Message shape (server → client)

```json
{
  "positions": [
    {
      "symbol": "RELIANCE",
      "ltp": 2450.5,
      "pnl_percentage": 1.25
    }
  ],
  "server_ts_ist": "2026-04-22T15:30:00.123456+05:30"
}
```

| Field | Type | Meaning |
|--------|------|--------|
| `positions` | `List` | Open paper trades only. |
| `positions[].symbol` | `String?` | Stock / instrument name. |
| `positions[].ltp` | `double` | Current price used for the position (falls back to entry if no live tick yet). |
| `positions[].pnl_percentage` | `double` | Unrealized P/L % for that open leg. |
| `server_ts_ist` | `String` | Server clock in **Asia/Kolkata** when the snapshot was built. |

### Flutter example (`web_socket_channel`)

Add to `pubspec.yaml`:

```yaml
dependencies:
  web_socket_channel: ^3.0.0
```

Example:

```dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

final uri = Uri.parse('wss://api.kalique.xyz/api/public/paper/ws/positions');
final channel = WebSocketChannel.connect(uri);

channel.stream.listen(
  (message) {
    final map = jsonDecode(message as String) as Map<String, dynamic>;
    final positions = (map['positions'] as List?) ?? [];
    for (final p in positions) {
      final m = p as Map<String, dynamic>;
      final symbol = m['symbol'];
      final ltp = (m['ltp'] as num?)?.toDouble();
      final pnlPct = (m['pnl_percentage'] as num?)?.toDouble();
      // update UI
    }
  },
  onError: (e, st) {},
  onDone: () {},
);
```

**Reconnection:** On `onDone` / `onError`, wait a short backoff (for example 1–5 seconds) and open a new `WebSocketChannel.connect` so the UI recovers after network drops.

---

## 2. REST — today’s closed order history (IST)

**Purpose:** List **closed** paper trades whose **exit time** falls on **today’s calendar date in Asia/Kolkata (IST)**. Fields: **symbol**, **realized P/L %**, **entry time**, **exit time**.

### Request

- **Method:** `GET`
- **Path:** `/api/public/paper/today-orders`
- **Full URLs:**
  - **Production:** `https://api.kalique.xyz/api/public/paper/today-orders`
  - **Local:** `http://localhost:8000/api/public/paper/today-orders`
- **Headers:** none required.

### Response shape

```json
{
  "date_ist": "2026-04-22",
  "orders": [
    {
      "symbol": "INFY",
      "pnl_percentage": -0.42,
      "entry_time": "2026-04-22T09:20:00+05:30",
      "exit_time": "2026-04-22T11:05:00+05:30"
    }
  ]
}
```

| Field | Type | Meaning |
|--------|------|--------|
| `date_ist` | `String` | `YYYY-MM-DD` for the IST “today” filter used on the server. |
| `orders` | `List` | Closed trades exited on that IST day. |
| `orders[].symbol` | `String?` | Stock / instrument name. |
| `orders[].pnl_percentage` | `double` | Realized P/L % (same basis as the backend trade history). |
| `orders[].entry_time` | `String?` | ISO 8601 entry timestamp (nullable if missing in DB). |
| `orders[].exit_time` | `String?` | ISO 8601 exit timestamp. |

### Flutter example (`http`)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> loadTodayOrders() async {
  final url = Uri.parse('https://api.kalique.xyz/api/public/paper/today-orders');
  final res = await http.get(url);
  if (res.statusCode != 200) return;
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final orders = (body['orders'] as List?) ?? [];
  for (final o in orders) {
    final m = o as Map<String, dynamic>;
    // m['symbol'], m['pnl_percentage'], m['entry_time'], m['exit_time']
  }
}
```

**Polling:** This is a snapshot API. Typical refresh interval for a “today’s history” screen is 15–60 seconds, or refresh on pull-to-refresh; use the WebSocket above for live open positions.

---

## CORS and TLS

- If the Flutter app is **web** and calls a **different origin**, ensure the FastAPI app’s **CORS** settings allow your web origin.
- Use **`wss` / `https`** in production so traffic is encrypted.

---

## Quick reference

| What | Method | Production URL |
|------|--------|----------------|
| Live open positions | WebSocket | `wss://api.kalique.xyz/api/public/paper/ws/positions` |
| Today’s closed orders (IST) | GET | `https://api.kalique.xyz/api/public/paper/today-orders` |
