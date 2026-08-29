import React, { useState, useEffect } from 'react';
import { Radio, Wifi, WifiOff, Activity, Layers, AlertTriangle, Cpu } from 'lucide-react';

export default function Navbar({ 
  isGatewayOnline, 
  setIsGatewayOnline, 
  activePacketCount, 
  onOpenSimulator, 
  activeView, 
  setActiveView 
}) {
  const [currentTime, setCurrentTime] = useState(new Date().toISOString().substring(11, 19));

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toISOString().substring(11, 19));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header className="navbar">
      {/* Left Brand */}
      <div className="nav-brand-section">
        <div className="brand-icon-box">
          <Radio size={22} color="#ef4444" />
        </div>
        <div>
          <div className="brand-title">
            <span>ResQ<span style={{ color: '#38bdf8' }}>-</span>Mesh</span>
            <span className="brand-badge">TACTICAL EOC</span>
          </div>
          <div className="brand-subtitle">
            Multimodal Acoustic & Tap Triage • P2P Store-and-Forward Mesh • Hazard Dispatch
          </div>
        </div>
      </div>

      {/* Center View Selector Tabs */}
      <div className="nav-center-tabs">
        <button
          onClick={() => setActiveView('map')}
          className={`nav-tab-btn ${activeView === 'map' ? 'active' : ''}`}
        >
          <Activity size={15} />
          <span>Tactical Map & Routing</span>
        </button>
        
        <button
          onClick={() => setActiveView('topology')}
          className={`nav-tab-btn ${activeView === 'topology' ? 'active' : ''}`}
        >
          <Layers size={15} />
          <span>Mesh Topology Graph</span>
        </button>
      </div>

      {/* Right Controls & Status */}
      <div className="nav-actions">
        {/* Active Incidents */}
        <div className="nav-metric-pill">
          <AlertTriangle size={15} color="#f97316" />
          <span>Active SOS: <strong style={{ color: '#fff' }}>{activePacketCount}</strong></span>
        </div>

        {/* Gateway Online/Offline Toggle */}
        <button
          onClick={() => setIsGatewayOnline(!isGatewayOnline)}
          className={`nav-status-btn ${isGatewayOnline ? 'online' : 'offline'}`}
          title="Toggle simulated Internet connectivity on Gateway node"
        >
          {isGatewayOnline ? (
            <>
              <Wifi size={15} color="#22c55e" />
              <span>GATEWAY ONLINE (SYNC ON)</span>
            </>
          ) : (
            <>
              <WifiOff size={15} color="#ef4444" />
              <span>AIRPLANE MODE (MESH ONLY)</span>
            </>
          )}
        </button>

        {/* 3-Phone Live Testbed Button */}
        <button onClick={onOpenSimulator} className="nav-testbed-btn">
          <Cpu size={15} />
          <span>3-Phone Live Testbed</span>
        </button>

        {/* Clock */}
        <div className="nav-clock">
          {currentTime} UTC
        </div>
      </div>
    </header>
  );
}
