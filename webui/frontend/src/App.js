import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import './App.css';

// Import WebSocket Provider
import { WebSocketProvider } from './contexts/WebSocketContext';

// Page components
import Dashboard from './pages/Dashboard';
import BuildISO from './pages/BuildISO';
import BuildHistory from './pages/BuildHistory';
import BuildDetails from './pages/BuildDetails';

function App() {
  const [status, setStatus] = useState({ status: 'loading' });
  
  useEffect(() => {
    // Check API status on load
    fetch('/api/status')
      .then(res => res.json())
      .then(data => setStatus(data))
      .catch(err => setStatus({ status: 'offline', error: err.message }));
  }, []);

  return (
    <WebSocketProvider>
      <Router>
        <div className="app">
          <header className="app-header">
            <h1>Arch Linux without the beeps ISO Builder</h1>
            <nav>
              <ul>
                <li><Link to="/">Dashboard</Link></li>
                <li><Link to="/build">Build ISO</Link></li>
                <li><Link to="/history">Build History</Link></li>
              </ul>
            </nav>
            <div className="status-indicator">
              Status: {status.status === 'online' ? 
                <span className="status online">Online</span> : 
                <span className="status offline">Offline</span>
              }
            </div>
          </header>
          
          <main className="app-content">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/build" element={<BuildISO />} />
              <Route path="/history" element={<BuildHistory />} />
              <Route path="/builds/:buildId" element={<BuildDetails />} />
            </Routes>
          </main>
          
          <footer className="app-footer">
            <p>Arch Linux without the beeps &copy; {new Date().getFullYear()}</p>
          </footer>
        </div>
      </Router>
    </WebSocketProvider>
  );
}

export default App;