# Android foreground service strategy (Pomopet)

Goal: keep a reliable timer running with a persistent notification.

## Recommended approach (plugin-first)
Use a maintained Flutter plugin to run a Foreground Service and update its notification:
- `flutter_foreground_task` (common choice)

Why:
- Faster to ship than a custom platform channel
- Handles Android service lifecycle + notification boilerplate

High-level wiring:
1. On timer start:
   - start foreground service
   - show/update ongoing notification with actions (pause/resume/stop)
2. On timer pause/resume:
   - update notification content
3. On timer stop/finish:
   - stop foreground service

## Alternative (native bridge)
Implement your own Android Service and expose minimal platform channel methods:
- startService(sessionId, endAt)
- updateNotification(sessionId, title, body, paused)
- stopService()

When to choose:
- You need full control
- You want to minimize dependencies

## MVP scope recommendation
Plugin-first for v0.1.0, native bridge only if plugin limitations block:
- action callbacks not delivered reliably
- notification updating too limited

## Notes
- Always compute remaining from `endAt` (absolute time) to survive restarts.
- Use `exactAllowWhileIdle` for finish notification (already in blueprint).
