# flutter_voip example

This example app now contains multiple demos that showcase the main features of `flutter_voip`.

## Run

1. Ensure you have Flutter set up.
2. From the repo root, run:
   - `cd example`
   - `flutter pub get`
   - If the Android/iOS folders are missing/incomplete, you can scaffold them with `flutter create .`
3. Launch on a device/emulator: `flutter run`

## Demos

- Basic SIP (register/call): Connect, register, place/answer audio calls.
- Call Controls: Mute/unmute, hold/unhold, speaker toggle, DTMF, SIP INFO, REFER (transfer).
- Messaging: Send/receive SIP MESSAGE.
- Video Call: Show local/remote video using WebRTC renderers.
- Prebuilt Screens: Use `CallScreen` (and pointers to `VoipApp`/`VoipCallWidget`) for a ready-made call UI.

All demos accept self-signed TLS certificates for convenience. For production, secure your WSS and adjust permissions/entitlements as needed.
