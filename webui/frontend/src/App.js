import React, { useState, useEffect, Suspense } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import './App.css';

// Import WebSocket Provider
import { WebSocketProvider } from './contexts/WebSocketContext';

// Lazy load page components for better performance
const Dashboard = React.lazy(() => import('./pages/Dashboard'));
const BuildISO = React.lazy(() => import('./pages/BuildISO'));
const BuildHistory = React.lazy(() => import('./pages/BuildHistory'));
const BuildDetails = React.lazy(() => import('./pages/BuildDetails'));

// Loading fallback component
const LoadingFallback = () => (
  <div className="loading-fallback">
    <p>Loading component...</p>
  </div>
);

/**
 * Main application component responsible for routing and layout
 * @returns {React.ReactElement} The rendered App component
 */
function App() {
  const [status, setStatus] = useState({ status: 'loading' });
  const [apiError, setApiError] = useState(null);
  const [apiTimeout, setApiTimeout] = useState(false);
  
  useEffect(() => {
    // Set a short timeout to show error if API is unreachable
    const timeoutId = setTimeout(() => {
      if (status.status === 'loading') {
        console.error('API request timed out');
        setApiTimeout(true);
        setApiError('API request timed out. Server may be down or not properly configured.');
      }
    }, 8000); // 8 seconds timeout

    // Attempt to fetch API status
    fetch('/api/status')
      .then(res => {
        if (!res.ok) {
          throw new Error(`API returned ${res.status}: ${res.statusText}`);
        }
        return res.json();
      })
      .then(data => {
        console.log('API status:', data);
        setStatus(data);
        clearTimeout(timeoutId);
      })
      .catch(err => {
        console.error('API Status Error:', err);
        setStatus({ status: 'offline' });
        setApiError(err.message);
        clearTimeout(timeoutId);
      });

    return () => clearTimeout(timeoutId);
  }, []);

  // Mark app as loaded to notify error handlers
  useEffect(() => {
    window.appLoaded = true;
  }, []);

  // If we've waited too long or there's an API error, show diagnostic information
  if (apiTimeout || apiError) {
    return (
      <div className="api-error-container">
        <h1>Connection Error</h1>
        <p>Unable to connect to the server API. Please check that:</p>
        <ul>
          <li>The backend server is running properly</li>
          <li>You're accessing the correct URL</li>
          <li>Required Python dependencies are installed (Flask, Eventlet, Flask-SocketIO)</li>
          <li>No network or proxy issues are blocking the connection</li>
        </ul>
        <div className="error-details">
          <h3>Error Details:</h3>
          <pre>{apiError || 'Connection timeout - server did not respond'}</pre>
        </div>
        <div className="troubleshooting-steps">
          <h3>Troubleshooting Steps:</h3>
          <ol>
            <li>Check the Docker container logs for Python errors</li>
            <li>Ensure all dependencies are installed in the container</li>
            <li>Verify the backend is listening on the correct port</li>
            <li>Check that the static files are being served correctly</li>
          </ol>
        </div>
        <button 
          className="retry-button" 
          onClick={() => window.location.reload()}
        >
          Retry Connection
        </button>
      </div>
    );
  }

  return (
    <WebSocketProvider>
      <Router>
        <div className="app">
          <header className="app-header">
            <h1>Arch Linux No-Beep ISO Builder</h1>
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
            <Suspense fallback={<LoadingFallback />}>
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/build" element={<BuildISO />} />
                <Route path="/history" element={<BuildHistory />} />
                <Route path="/builds/:buildId" element={<BuildDetails />} />
                <Route path="*" element={<div>Page Not Found</div>} />
              </Routes>
            </Suspense>
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