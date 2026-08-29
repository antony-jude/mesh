import React, { useState, useMemo } from 'react';
import Navbar from './components/Navbar';
import MapDashboard from './components/MapDashboard';
import TopologyVisualizer from './components/TopologyVisualizer';
import TriageInspector from './components/TriageInspector';
import HazardControlPanel from './components/HazardControlPanel';
import AudioSoundboard from './components/AudioSoundboard';
import SilentSOSPad from './components/SilentSOSPad';
import MeshSimulatorModal from './components/MeshSimulatorModal';
import { 
  DEFAULT_WAYPOINTS, 
  DEFAULT_EDGES, 
  INITIAL_HAZARD_ZONES, 
  solveDijkstraRoute 
} from './utils/dijkstraRouter';

export default function App() {
  const [activeView, setActiveView] = useState('map');
  const [isSimulatorOpen, setIsSimulatorOpen] = useState(false);
  const [isGatewayOnline, setIsGatewayOnline] = useState(true);

  const [sosPackets, setSosPackets] = useState([
    {
      packet_id: 'pkt_sf_001_rubble',
      origin_device_id: 'VICTIM_NODE_ALPHA',
      timestamp: new Date().toISOString(),
      hop_count: 2,
      hop_path: ['VICTIM_NODE_ALPHA', 'RELAY_NODE_01', 'GATEWAY_NODE_01'],
      priority_score: 0.94,
      priority_label: 'CRITICAL',
      signal_type: 'ACOUSTIC',
      classification_reasoning: 'Gemini Nano (Offline): High-confidence acoustic pattern (Rubble Tapping / Knock, 94%) indicates conscious survivor trapped under structural rubble actively signaling rescuers.',
      last_known_location: { lat: 37.7825, lng: -122.4075, accuracy_m: 3.2 },
      payload_encrypted: true
    },
    {
      packet_id: 'pkt_sf_002_silent',
      origin_device_id: 'VICTIM_NODE_BETA',
      timestamp: new Date(Date.now() - 1000 * 60 * 3).toISOString(),
      hop_count: 3,
      hop_path: ['VICTIM_NODE_BETA', 'RELAY_01', 'RELAY_02', 'GATEWAY_01'],
      priority_score: 1.0,
      priority_label: 'CRITICAL',
      signal_type: 'TAP_PATTERN',
      classification_reasoning: 'Silent SOS Triggered: Accelerometer rhythmic pattern (3-Short + 1-Long Morse distress) verified. Victim incapacitated/unable to speak. Immediate critical dispatch.',
      last_known_location: { lat: 37.7790, lng: -122.4100, accuracy_m: 4.0 },
      payload_encrypted: true
    },
    {
      packet_id: 'pkt_sf_003_vocal',
      origin_device_id: 'VICTIM_NODE_GAMMA',
      timestamp: new Date(Date.now() - 1000 * 60 * 8).toISOString(),
      hop_count: 1,
      hop_path: ['VICTIM_NODE_GAMMA', 'GATEWAY_01'],
      priority_score: 0.88,
      priority_label: 'HIGH',
      signal_type: 'ACOUSTIC',
      classification_reasoning: 'Gemini Nano (Offline): Human vocal distress pattern (Crying, sobbing, 89%) indicates injured survivor requiring urgent medical extraction.',
      last_known_location: { lat: 37.7720, lng: -122.4140, accuracy_m: 5.5 },
      payload_encrypted: true
    }
  ]);

  const [selectedPacket, setSelectedPacket] = useState(sosPackets[0]);
  const [hazardZones, setHazardZones] = useState(INITIAL_HAZARD_ZONES);

  const dijkstraSafeRoute = useMemo(() => {
    return solveDijkstraRoute({
      waypoints: DEFAULT_WAYPOINTS,
      edges: DEFAULT_EDGES,
      hazards: hazardZones,
      applyHazardPenalties: true
    });
  }, [hazardZones]);

  const naiveRoute = useMemo(() => {
    return solveDijkstraRoute({
      waypoints: DEFAULT_WAYPOINTS,
      edges: DEFAULT_EDGES,
      hazards: hazardZones,
      applyHazardPenalties: false
    });
  }, [hazardZones]);

  const handleAddHazard = (newHazard) => {
    setHazardZones(prev => [...prev, newHazard]);
  };

  const handleRemoveHazard = (hazardId) => {
    setHazardZones(prev => prev.filter(h => h.id !== hazardId));
  };

  const handleUpdatePenalty = (hazardId, penaltyMultiplier) => {
    setHazardZones(prev => prev.map(h => h.id === hazardId ? { ...h, penaltyMultiplier } : h));
  };

  const handleNewSosPacket = (pkt) => {
    setSosPackets(prev => [pkt, ...prev]);
    setSelectedPacket(pkt);
  };

  return (
    <div className="app-container">
      {/* Top Navbar */}
      <Navbar
        isGatewayOnline={isGatewayOnline}
        setIsGatewayOnline={setIsGatewayOnline}
        activePacketCount={sosPackets.length}
        onOpenSimulator={() => setIsSimulatorOpen(true)}
        activeView={activeView}
        setActiveView={setActiveView}
      />

      {/* Main Grid Content */}
      <main className="main-content">
        {/* Left Column (Map / Topology + Hazard Router) */}
        <div className="left-column">
          {activeView === 'map' ? (
            <MapDashboard
              sosPackets={sosPackets}
              selectedPacket={selectedPacket}
              onSelectPacket={setSelectedPacket}
              hazardZones={hazardZones}
              dijkstraSafeRoute={dijkstraSafeRoute}
              naiveRoute={naiveRoute}
              waypoints={DEFAULT_WAYPOINTS}
            />
          ) : (
            <TopologyVisualizer
              activePacket={selectedPacket}
              allPackets={sosPackets}
            />
          )}

          <HazardControlPanel
            hazardZones={hazardZones}
            onAddHazard={handleAddHazard}
            onRemoveHazard={handleRemoveHazard}
            onUpdatePenalty={handleUpdatePenalty}
            dijkstraSafeRoute={dijkstraSafeRoute}
            naiveRoute={naiveRoute}
          />
        </div>

        {/* Right Column (Triage Inspector + Soundboard + Silent SOS) */}
        <div className="right-column">
          <TriageInspector
            packet={selectedPacket}
            onDeselect={() => setSelectedPacket(null)}
          />

          <AudioSoundboard
            onTriggerAcousticSos={handleNewSosPacket}
          />

          <SilentSOSPad
            onTriggerSilentSos={handleNewSosPacket}
          />
        </div>
      </main>

      {/* 3-Node Testbed Modal */}
      <MeshSimulatorModal
        isOpen={isSimulatorOpen}
        onClose={() => setIsSimulatorOpen(false)}
        onSyncPacketToDashboard={handleNewSosPacket}
      />
    </div>
  );
}
