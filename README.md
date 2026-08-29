<p align="center">
  <img src="https://github.com/antony-jude/mesh/raw/main/docs/architecture-diagram.png" alt="ResQ-Mesh architecture diagram" width="100%" />
</p>

# ResQ-Mesh (MeshLink)
## Zero-Infrastructure Off-Grid Emergency Communication & Multimodal Disaster Triage

## Problem Statement

Natural disasters regularly destroy cellular infrastructure, leaving victims isolated and rescue teams blind to critical local ground truth. In the first minutes after a collapse, flood, fire, or blackout, communication networks fail just when they are needed most.

## Solution

ResQ-Mesh creates an ad-hoc, off-grid peer-to-peer mesh network across standard smartphones and low-power edge nodes to relay life-critical SOS payloads and automate multimodal rescue triage. It turns nearby devices into a resilient communication layer when infrastructure is unavailable.

---

## Why it matters

- Victims lose mobile connectivity exactly when emergency signals matter most
- Rescue teams lack real-time, local incident awareness
- Conventional systems depend on the infrastructure that has already failed
- A decentralized mesh can preserve life-critical information and local situational intelligence

---

## System Architecture

<p align="center">
  <img src="https://github.com/antony-jude/mesh/raw/main/docs/architecture-diagram.png" alt="ResQ-Mesh system architecture" width="100%" />
</p>

<table>
  <tr>
    <td width="30%" valign="top" style="background:#dfeef0; border:2px solid #5bb5a6; border-radius:12px; padding:18px;">
      <strong>1. EDGE SENSING &amp; TRIAGE</strong><br><br>
      Passive Audio<br>
      YAMNet filter<br>
      Silent SOS detector<br>
      Gemini Nano / TF Lite<br>
      Priority score + context
    </td>
    <td width="40%" valign="top" style="background:#dfeaf8; border:2px solid #4a9ad0; border-radius:12px; padding:18px;">
      <strong>2. DECENTRALIZED MESH NETWORK</strong><br><br>
      <table width="100%" style="border-spacing:12px 8px;">
        <tr>
          <td align="center" style="border:2px solid #5a8fb5; background:#f7fbff; padding:12px 10px; border-radius:8px; width:25%;"><strong>Node A</strong><br>Victim</td>
          <td align="center" style="border:2px solid #5a8fb5; background:#f7fbff; padding:12px 10px; border-radius:8px; width:25%;"><strong>Node B</strong><br>Relay</td>
          <td align="center" style="border:2px solid #5a8fb5; background:#f7fbff; padding:12px 10px; border-radius:8px; width:25%;"><strong>Node C</strong><br>Relay</td>
          <td align="center" style="border:2px solid #5a8fb5; background:#f7fbff; padding:12px 10px; border-radius:8px; width:25%;"><strong>Node D</strong><br>Gateway</td>
        </tr>
      </table>
      <br>
      BLE + Wi‑Fi Direct &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Store-and-forward relay
    </td>
    <td width="30%" valign="top" style="background:#f6ead6; border:2px solid #d79b4b; border-radius:12px; padding:18px;">
      <strong>3. CLOUD GATEWAY SYNC</strong><br><br>
      Gateway role detection<br>
      Offline packet buffer<br>
      Sync service<br>
      Firebase / Firestore<br>
      Secure push / alerting
    </td>
  </tr>
</table>

<br>

<table>
  <tr>
    <td width="25%" valign="top" style="background:#eef3ff; border:2px solid #4e52db; border-radius:12px; padding:18px;">
      <strong>A. DATA &amp; SECURITY LAYER</strong><br><br>
      AES-256 encrypted packets<br>
      SHA-256 HMAC integrity<br>
      Message TTL / hop count<br>
      On-device identity + auth<br>
      Deduplication and retry
    </td>
    <td width="25%" valign="top" style="background:#edf9ef; border:2px solid #3aa45e; border-radius:12px; padding:18px;">
      <strong>B. ROUTING &amp; MESH LAYER</strong><br><br>
      Store-and-forward queue<br>
      TTL management<br>
      Message deduplication<br>
      Link quality monitoring<br>
      Fault tolerance / retries
    </td>
    <td width="25%" valign="top" style="background:#fff7ea; border:2px solid #d49b2d; border-radius:12px; padding:18px;">
      <strong>C. COMMAND CENTER</strong><br><br>
      Live incident map<br>
      Mesh topology graph<br>
      Gemini rationale view<br>
      Hazard-aware routing<br>
      Rescue dispatch monitor
    </td>
    <td width="25%" valign="top" style="background:#f7f0ff; border:2px solid #855bdb; border-radius:12px; padding:18px;">
      <strong>D. DISPATCH ENGINE</strong><br><br>
      Shortest safe path<br>
      Hazard penalty model<br>
      Risk-aware route<br>
      Resource allocation<br>
      Responder guidance
    </td>
  </tr>
</table>

---

## Product Workflow

<table>
  <tr>
    <td width="25%" valign="top" style="background:#eef7f3; border:2px solid #48b89b; border-radius:12px; padding:16px;">
      <strong>1. SENSING</strong><br><br>
      Victim device captures audio, vibration, or emergency input.
    </td>
    <td width="25%" valign="top" style="background:#eef7f3; border:2px solid #48b89b; border-radius:12px; padding:16px;">
      <strong>2. TRIAGE</strong><br><br>
      Edge ML / on-device inference computes priority and context.
    </td>
    <td width="25%" valign="top" style="background:#eef7f3; border:2px solid #48b89b; border-radius:12px; padding:16px;">
      <strong>3. RELAY</strong><br><br>
      Encrypted packet hops through nearby devices using BLE + Wi‑Fi Direct.
    </td>
    <td width="25%" valign="top" style="background:#eef7f3; border:2px solid #48b89b; border-radius:12px; padding:16px;">
      <strong>4. DISPATCH</strong><br><br>
      Gateway syncs to the command center and the safe route is computed.
    </td>
  </tr>
</table>

### Workflow flow

1. Victim device captures emergency signal input
2. Edge triage runs local analysis and computes priority score
3. Encrypted SOS packet is generated with metadata and location context
4. Packet is relayed across nearby phones via P2P mesh routing
5. Gateway node syncs valid incidents to the backend when connectivity returns
6. Rescue command center visualizes topology, risk, and safe dispatch route

---

## Hackathon Demo Flow

### Demo narrative

> “Natural disasters destroy cellular infrastructure. Victims are isolated, and rescue teams are blind to local ground truth. ResQ-Mesh restores local communication through an ad-hoc mesh network built across nearby smartphones and edge devices.”

> “A victim emits a distress signal, the device performs on-device triage, and the message is relayed automatically through nearby nodes until it reaches a gateway, which then syncs to the command center.”

---

## App Screenshots

### Home dashboard

<p align="center">
  <img src="https://github.com/antony-jude/mesh/raw/main/docs/screenshots/home-dashboard.svg" alt="MeshLink home dashboard" width="420" />
</p>

### Emergency broadcast screen

<p align="center">
  <img src="https://github.com/antony-jude/mesh/raw/main/docs/screenshots/emergency-broadcast.svg" alt="Emergency broadcast screen" width="420" />
</p>

### Nearby mesh nodes

<p align="center">
  <img src="https://github.com/antony-jude/mesh/raw/main/docs/screenshots/nearby-mesh.svg" alt="Nearby mesh nodes screen" width="420" />
</p>

---

## Implementation Highlights

- Offline-first mobile mesh application
- Multi-node relay concept for emergency coordination
- Secure stored-and-forward SOS transmission
- Local triage logic and emergency classification
- Real-time command visualization for concept validation
- Designed for hackathon and prototype presentation

---

## Repository Structure

```text
mesh/
├── mobile_app/                  # Flutter app for Android prototype
├── web_dashboard/               # React command dashboard
├── docs/screenshots/             # Demo screenshots and architecture visuals
├── README.md                    # Project overview and hackathon deck
├── DEMO_GUIDE.md                # Live demo presentation flow
├── PITCH_DECK.md                # Investor / judge pitch narrative
├── mobile_app/README.md         # Mobile app setup guide
└── .gitignore
```

---

## Quick Start

### Install dependencies

```bash
cd mobile_app
flutter pub get
```

### Run locally

```bash
flutter run
```

### Build APK for device testing

```bash
flutter build apk --debug
```

### Install on a connected Android device

```bash
adb devices
adb -s <device_serial> install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Launch the dashboard

```bash
cd ../web_dashboard
npm install
npm run dev
```

---

## Live Demo Setup

For a 3-phone showcase:

- Phone A: Victim / sender node
- Phone B: Relay node
- Phone C: Gateway / receiver node

Recommended flow:

1. Install app on all three phones
2. Turn on Airplane Mode on each device
3. Keep Bluetooth enabled
4. Place phones close together
5. Trigger emergency broadcast or SOS from Phone A
6. Show relay behavior on Phone B
7. Show gateway sync or dashboard update on Phone C

---

## Future Roadmap

- Real Bluetooth Nearby Connections integration
- Edge AI classification refinement
- More robust security and encrypted packet routing
- Improved topology analytics and rescue pathing
- Production APK signing and deployment workflow

---

## Final Statement

ResQ-Mesh is a practical, demonstrable emergency resilience platform that turns everyday smartphones into a local, autonomous rescue network. It combines decentralized communication, on-device triage, and topology-aware dispatch to help bridge the critical window between disaster and rescue.

<p align="center">
  <b>Built for hackathon demos, startup showcases, and real-world resilience experiments.</b>
</p>
