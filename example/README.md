# flutter_voip example

This is a minimal demo application showing how to register to a SIP/WebSocket server and place a call using `flutter_voip`.

## Run

1. Ensure you have Flutter set up.
2. From the repo root, run:
   - `cd example`
   - `flutter pub get`
   - If the Android/iOS folders are missing/incomplete, you can scaffold them with `flutter create .`
3. Launch on a device/emulator: `flutter run`

## Usage

- Enter your WSS URL, SIP domain, port, username and password.
- Tap "Register" to connect and register.
- Enter a destination (extension/number) and tap "Call".
- Use "Hangup" to terminate the current call.

Notes:
- This demo uses basic audio call settings and accepts self-signed TLS certificates for convenience.
- For production, secure your WSS and adjust permissions/entitlements as needed.

