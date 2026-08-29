# ResQ-Mesh — Pitch Deck & Competitive Positioning

---

## 🏆 Slide 1: The Problem — Blind Spots in Disaster Response
- **Cellular & Power Collapse**: Earthquakes, floods, and hurricanes sever cellular towers and Wi-Fi within minutes.
- **Victim Incapacitation**: Buried or injured victims cannot unlock phones, type text messages, or call out.
- **Rescuer Danger**: Responders lack ground-truth information and navigate blindly into collapsed bridges and gas leaks.

---

## ⚔️ Slide 2: Competitive Landscape Matrix

| Capability | Meshtastic / LoRa Beacons | GOTOKY / MeshCore | SafeGrid | **ResQ-Mesh (Our Solution)** |
| :--- | :---: | :---: | :---: | :---: |
| **Hardware Required** | Proprietary Radios ($60–$120) | Custom Hardware | Custom Beacons | **Zero Extra Hardware (Stock Android)** |
| **Triage Mode** | Manual Text Only | Manual SOS Button | Text / GPS Ping | **Multimodal Acoustic ML + Accelerometer Tap** |
| **Victim Action Needed** | High (Typing/Interacting) | Moderate (Pressing) | Moderate | **Zero Action Needed (Passive Mic Sensing)** |
| **Incapacitated SOS** | ❌ No | ❌ No | ❌ No | **✅ Silent SOS Tap-Pattern Detection** |
| **On-Device AI Reasoning** | ❌ No | ❌ No | Basic Text Filter | **✅ Gemini Nano (AICore) Offline Triage** |
| **Rescue Dispatch** | Heatmap / Static List | Message Log | Pin on Map | **✅ Closed-Loop Hazard-Aware Dijkstra Routing** |

### 🎯 Positioning Statement
> *"Phone-to-phone disaster mesh already exists (Meshtastic, GOTOKY, MeshCore, SafeGrid). On-device ML message-priority triage over BLE mesh already exists. What doesn't exist: acoustic/multimodal triage that needs zero victim action, silent tap-based SOS for incapacitated victims, and closed-loop hazard-aware rescue routing. Detection is solved. Dispatch is not. ResQ-Mesh closes that loop."*

---

## 🌐 Slide 3: Google Technologies Scorecard

| Google Technology | Role in ResQ-Mesh |
| :--- | :--- |
| **Google Nearby Connections API** | Decentralized multi-hop store-and-forward mesh relay (`Strategy.P2P_CLUSTER`) across BLE and Wi-Fi Direct. |
| **Gemini Nano (via AICore / ML Kit GenAI)** | Fully on-device, offline reasoning layer generating structured priority scores and natural-language coordinator rationale. |
| **MediaPipe Audio Classifier (YAMNet)** | Ultra-fast on-device acoustic categorization filtering 521 audio classes into distress-relevant events. |
| **Firebase Firestore** | Real-time cloud sync & snapshot listener linking off-grid gateways with Emergency Operations Centers. |
| **Firebase Hosting** | Global low-latency CDN hosting for the tactical command center web app. |
| **Google Maps Platform (Maps JS & Routes API)** | High-precision GIS mapping, tactical incident visualization, and road geometry graph generation. |

---

## 🏗️ Slide 4: System Architecture

```
[ INCAPACITATED VICTIM ]
         │ (Passive Mic / Accelerometer Tap)
         ▼
[ STAGE A: MediaPipe Audio YAMNet ]
         │ (High-Confidence Distress Filter)
         ▼
[ STAGE B: Gemini Nano Offline AICore ]
         │ (Priority Score + Coordinator Reasoning)
         ▼
[ AES-256 ENCRYPTED SOS PACKET ]
         │
         ▼ (Google Nearby Connections P2P_CLUSTER)
[ INTERMEDIATE RELAY NODES (Dedupe & Rebroadcast) ]
         │
         ▼ (Store-and-Forward Mesh)
[ CLOUD GATEWAY NODE (Offline Queue Buffer) ]
         │ (Internet Reconnection Detected)
         ▼
[ FIREBASE FIRESTORE REAL-TIME SYNC ]
         │
         ▼
[ RESQ-MESH COMMAND DASHBOARD ]
         ├── Dynamic Mesh Topology Visualizer
         ├── Gemini Nano Rationale Inspector
         └── Hazard-Aware Dijkstra Rescue Router
```
