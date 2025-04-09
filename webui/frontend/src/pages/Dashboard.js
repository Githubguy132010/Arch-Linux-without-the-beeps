import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useWebSocket } from '../contexts/WebSocketContext';

/**
 * Dashboard component that displays system overview, active builds, and current ISO configuration
 */
const Dashboard = () => {
  const { isConnected, activeJob, queue, error: wsError } = useWebSocket();
  const [config, setConfig] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Fetch config data when component mounts
    fetch('/api/config')
      .then(res => {
        if (!res.ok) throw new Error('Failed to fetch configuration');
        return res.json();
      })
      .then(data => {
        setConfig(data);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  // Format date for display
  const formatDate = (isoString) => {
    if (!isoString) return 'N/A';
    return new Date(isoString).toLocaleString();
  };

  if (loading) return <div className="loading">Loading configuration...</div>;
  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div className="dashboard">
      <h2>Dashboard</h2>
      
      {/* Real-time WebSocket status */}
      <section className="dashboard-section websocket-status">
        <div className={`ws-indicator ${isConnected ? 'connected' : 'disconnected'}`}>
          Real-time updates: {isConnected ? 'Connected' : 'Disconnected'}
        </div>
        {wsError && <div className="ws-error">WebSocket error: {wsError}</div>}
      </section>
      
      {/* Active Build Status */}
      <section className="dashboard-section">
        <h3>Active Build</h3>
        {activeJob ? (
          <div className="active-build">
            <div className="build-header">
              <span className="build-id">ID: {activeJob.id}</span>
              <span className="build-status status-progress">In Progress</span>
            </div>
            
            <div className="progress-container">
              <div className="progress-label">Progress: {activeJob.progress}%</div>
              <div className="progress-bar">
                <div 
                  className="progress-bar-fill" 
                  style={{ width: `${activeJob.progress}%` }}
                />
              </div>
            </div>
            
            <div className="build-times">
              <div>Started: {formatDate(activeJob.started_at)}</div>
              <div>Created: {formatDate(activeJob.created_at)}</div>
            </div>
            
            <div className="build-actions">
              <Link to={`/builds/${activeJob.id}`} className="button view-button">
                View Details
              </Link>
            </div>
          </div>
        ) : (
          <div className="no-active-build">
            No active builds at the moment
          </div>
        )}
      </section>
      
      {/* Build Queue */}
      <section className="dashboard-section">
        <h3>Build Queue</h3>
        {queue && queue.length > 0 ? (
          <div className="queue-list">
            <div className="queue-header">
              <span>ID</span>
              <span>Status</span>
              <span>Created</span>
              <span>Actions</span>
            </div>
            {queue.map(job => (
              <div key={job.id} className="queue-item">
                <span className="queue-id">{job.id.substring(0, 8)}...</span>
                <span className="queue-status">{job.status}</span>
                <span className="queue-created">{formatDate(job.created_at)}</span>
                <span className="queue-actions">
                  <Link to={`/builds/${job.id}`} className="button small-button">
                    View
                  </Link>
                </span>
              </div>
            ))}
          </div>
        ) : (
          <div className="empty-queue">No builds in queue</div>
        )}
      </section>
      
      {/* ISO Configuration */}
      <section className="dashboard-section">
        <h3>ISO Configuration</h3>
        <div className="config-info">
          {config && config.profile_settings && (
            <div className="profile-settings">
              <h4>Profile Settings</h4>
              <table>
                <tbody>
                  {Object.entries(config.profile_settings).map(([key, value]) => (
                    <tr key={key}>
                      <td>{key}</td>
                      <td>{value}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </section>
      
      {/* Included Packages */}
      <section className="dashboard-section">
        <h3>Included Packages</h3>
        {config && config.packages && (
          <div className="packages-list">
            <p>Total packages: {config.packages.length}</p>
            <div className="package-tags">
              {config.packages.slice(0, 20).map((pkg, index) => (
                <span key={index} className="package-tag">{pkg}</span>
              ))}
              {config.packages.length > 20 && <span>...and {config.packages.length - 20} more</span>}
            </div>
          </div>
        )}
      </section>
      
      {/* Quick Actions */}
      <section className="dashboard-section">
        <h3>Quick Actions</h3>
        <div className="quick-actions">
          <Link to="/build" className="action-button primary">
            Start New Build
          </Link>
          <Link to="/history" className="action-button">
            View Build History
          </Link>
        </div>
      </section>
    </div>
  );
};

export default Dashboard;