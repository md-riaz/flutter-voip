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

## Full VoIP App (Push + Background)

- Navigate to "Full VoIP App" from the menu.
- Tabs:
  - Dialer: Place calls and observe live call state.
  - Settings: Configure SIP and basic push params (bundle ID/team ID).
  - Push: Work without real Firebase by using an example FCM token.

### Push tab

- Manual FCM token: Uses an example token by default. You can paste your own.
- Register (Manual Token): Registers your SIP account with push parameters using the token provided above. No Firebase initialization is called.
- Init Firebase (optional): For developers who have `google-services.json`/`GoogleService-Info.plist` configured, you can initialize Firebase to get a real FCM token. Not required for the example.
- Show CallKit Incoming: Simulates an incoming call (useful for testing background/locked screen behavior).

Note: For actual push delivery from your backend, send a push payload matching the plugin format documented in `PUSH_NOTIF.md`. This example focuses on UX, background call UI, and a manual-token workflow to avoid Firebase init.