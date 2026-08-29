# MeshLink Mobile App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-Test%20Build-34A853?logo=android)](https://developer.android.com)
[![Prototype](https://img.shields.io/badge/Prototype-Multi%20Phone%20Demo-8B5CF6)](https://)

</div>

MeshLink is the Android mobile prototype for a resilient offline communication system. It is built to show how nearby phones can pass information without cellular data or Wi‑Fi.

---

## What this app demonstrates

- Device-to-device local communication concept
- Store-and-forward design for offline relay
- Emergency broadcast simulation and mesh interaction
- Real-time status indicators for connected/local nodes
- Demo-ready flow for A / B / C phone testing

---

## Requirements

- Flutter SDK 3.x
- Android Studio or VS Code with Flutter plugin
- 3 Android phones for live multi-device demo
- USB debugging enabled on each device

---

## Install and run

```bash
cd mobile_app
flutter pub get
flutter devices
flutter run
```

To install directly on a device:

```bash
flutter install
```

To generate an APK for demo distribution:

```bash
flutter build apk --debug
```

Then install to each phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## Multi-phone demo guide

### Setup

- Phone A: sender node
- Phone B: relay node
- Phone C: receiver node

### Demo flow

1. Install the app on all three devices
2. Enable airplane mode on all devices
3. Keep Bluetooth enabled
4. Open the app on each device
5. Trigger a message or emergency broadcast on Phone A
6. Show that Phone B relays the communication
7. Show Phone C receiving the information

### Best practice

Keep the phones close together during the demo so the network can be observed clearly. If needed, use the simulation tools built into the app to create a repeatable and clean presentation flow.

---

## Useful commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

---

## Troubleshooting

### Device not detected

```bash
adb devices
flutter doctor
```

### Build errors

```bash
flutter clean
flutter pub get
flutter run
```

---

## Demo script

> “This is a local-first mobile mesh prototype. When the internet is unavailable, devices can still connect within a short range and forward critical communication between nearby phones.”

> “The app is designed to show proof of concept for resilient communication in offline or disrupted conditions.”

---

## Next stage

- Production-grade Bluetooth discovery
- Real Nearby Connections / P2P integration
- Release signing and APK distribution
- Stronger security and message validation
- Dashboard enhancements for live presentation

<p align="center">
  <b>Ready for prototype live demos on multiple Android devices.</b>
</p>
