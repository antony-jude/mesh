# ResQ-Mesh — 3-Minute Live Hackathon Demo Guide

This script is structured for live GDG hackathon judging in under 3 minutes with 3 Android phones in airplane mode or using the interactive multi-node live testbed.

---

## ⏱️ Pre-Demo Setup Checklist (2 Minutes Before Stage)

1. **Physical Devices Setup (If using 3 physical phones)**:
   - **Phone 1 (VICTIM)**: Open ResQ-Mesh app $\to$ Switch Role to `VICTIM` $\to$ Toggle Airplane Mode ON $\to$ Enable Passive Mic Sampling.
   - **Phone 2 (RELAY)**: Open ResQ-Mesh app $\to$ Switch Role to `RELAY` $\to$ Toggle Airplane Mode ON $\to$ Open Mesh Debug Screen.
   - **Phone 3 (GATEWAY)**: Open ResQ-Mesh app $\to$ Switch Role to `GATEWAY` $\to$ Toggle Airplane Mode ON $\to$ Open Stored Queue.
2. **Command Center Dashboard**:
   - Open Web Command Center (`http://localhost:5173`) on laptop connected to projector.
   - Click "Simulate Internet Reconnection" or ensure Firestore live listener is active.

---

## 🎤 3-Minute Live Judge Presentation Script

### [0:00 - 0:45] The Problem & Our Differentiation
> "Judges, when an earthquake or hurricane strikes, cellular towers and Wi-Fi fail within seconds. Victims are trapped under rubble, incapacitated, and rescue teams are forced to search blindly.
> 
> Existing disaster apps like Meshtastic only solve text relay over hardware radios. ResQ-Mesh is fundamentally different:
> 1. **Multimodal Acoustic ML Triage**: Passively analyzes mic acoustics (rubble tapping, structural creaks, screams) with zero victim action required.
> 2. **Silent SOS**: Decodes accelerometer tap rhythms for incapacitated victims who cannot speak or type.
> 3. **Closed-Loop Hazard-Aware Rescue Routing**: Calculates safe extraction corridors around collapsed bridges using Dijkstra's algorithm.
> 4. **Zero Extra Hardware**: Runs directly on stock Android phones using Google Nearby Connections."

### [0:45 - 1:30] Live Acoustic Triage & Gemini Nano Offline Proof
> *"Watch as we put all 3 phones into Airplane Mode on stage—no Wi-Fi, no cellular data."*
> 
> 1. Play distress audio / click **Rubble Tapping / Knock (94% confidence)** on the Victim device.
> 2. Show Stage A MediaPipe YAMNet classifier detect the distress signal.
> 3. Show Stage B **Gemini Nano on-device AI reasoning** run fully offline:
>    > *"Gemini Nano (Offline): Rhythmic mechanical acoustic pattern indicates conscious survivor trapped under structural rubble actively signaling rescuers."*
> 4. Show the AES-256 encrypted SOS packet generated with `CRITICAL` priority.

### [1:30 - 2:15] Multi-Hop Mesh Relay & Cloud Gateway Sync
> 1. Show Phone 2 (RELAY) receive the packet over Google Nearby Connections BLE mesh, deduplicate the UUID, increment hop count to `1`, append `PHONE_2_RELAY` to `hop_path`, and rebroadcast.
> 2. Show Phone 3 (GATEWAY) receive the packet (Hop 2) and buffer it in its local offline queue.
> 3. Toggle Wi-Fi back on at the GATEWAY device.
> 4. **Boom**: The Gateway instantly executes a batch push to Firestore cloud backend!

### [2:15 - 2:45] Tactical Command Center & Hazard-Aware Dijkstra Routing
> 1. Switch screen to the **ResQ-Mesh Command Center**.
> 2. Show the victim's location pin pulsing red on the tactical map with Gemini Nano's reasoning card displayed.
> 3. Show the **Dynamic Topology Graph** illustrating the multi-hop transmission path.
> 4. Click the incident $\to$ Show the comparison:
>    - **Naive Route (Red)**: Naively goes through the collapsed bridge zone (High danger).
>    - **ResQ-Mesh Safe Route (Green)**: Dijkstra algorithm with $50\times$ hazard penalty safely circumvents the danger zone!

### [2:45 - 3:00] Silent SOS Closing & Impact Statement
> *"And finally, what if a victim is completely incapacitated and cannot speak?"*
> 1. Knock or tap the screen rhythmically: **3 Short Taps + 1 Long Tap**.
> 2. Show the accelerometer peak detector instantly trigger an unalterable `CRITICAL` Silent SOS into the mesh.
> 
> *"Detection is solved. Dispatch is not. ResQ-Mesh closes that loop. Thank you!"*
