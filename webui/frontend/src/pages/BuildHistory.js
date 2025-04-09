import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useWebSocket } from '../contexts/WebSocketContext';

/**
 * BuildHistory component shows the history of ISO builds and their status
 * Uses WebSockets to display real-time updates
 */
const BuildHistory = () => {
  const { isConnected, activeJob, queue, history } = useWebSocket();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Once WebSocket data is available, we can stop loading
  useEffect(() => {
    if (isConnected) {
      setLoading(false);
    }
  }, [isConnected]);

  // Format date for display
  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  // Get appropriate CSS class for status styling
  const getStatusClass = (status) => {
    switch(status) {
      case 'completed': return 'status-success';
      case 'failed': return 'status-error';
      case 'in_progress': return 'status-progress';
      case 'queued': return 'status-queued';
      default: return 'status-info';
    }
  };

  // Calculate build duration
  const calculateDuration = (startTime, endTime) => {
    if (!startTime || !endTime) return 'N/A';
    
    const start = new Date(startTime);
    const end = new Date(endTime);
    const durationMs = end - start;
    
    // Format duration as minutes and seconds
    const minutes = Math.floor(durationMs / 60000);
    const seconds = Math.floor((durationMs % 60000) / 1000);
    
    return `${minutes}m ${seconds}s`;
  };

  if (loading && !isConnected) return <div className="loading-container">Connecting to server...</div>;
  if (error) return <div className="error-container">Error: {error}</div>;

  // Combine active, queued, and history for display
  const allBuilds = [
    ...(activeJob ? [activeJob] : []),
    ...queue,
    ...history
  ];

  return (
    <div className="build-history">
      <h2>Build History</h2>
      
      <div className="connection-status">
        <span className={`connection-indicator ${isConnected ? 'connected' : 'disconnected'}`}>
          {isConnected ? 'Real-time updates enabled' : 'Connecting to server...'}
        </span>
      </div>
      
      {allBuilds.length === 0 ? (
        <div className="no-builds">
          <p>No build history found. Start a new build to see it here.</p>
          <Link to="/build" className="button primary-button">Start a New Build</Link>
        </div>
      ) : (
        <>
          <div className="build-filters">
            <input 
              type="text" 
              placeholder="Filter builds..." 
              className="build-filter-input"
            />
            <select className="build-filter-select">
              <option value="all">All Statuses</option>
              <option value="completed">Completed</option>
              <option value="failed">Failed</option>
              <option value="in_progress">In Progress</option>
              <option value="queued">Queued</option>
            </select>
          </div>
          
          <table className="builds-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Status</th>
                <th>Created</th>
                <th>Started</th>
                <th>Completed</th>
                <th>Duration</th>
                <th>Progress</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {allBuilds.map(build => (
                <tr key={build.id} className={build.status === 'in_progress' ? 'active-row' : ''}>
                  <td className="build-id">{build.id.substring(0, 8)}...</td>
                  <td>
                    <span className={`status-badge ${getStatusClass(build.status)}`}>
                      {build.status}
                    </span>
                  </td>
                  <td>{formatDate(build.created_at)}</td>
                  <td>{formatDate(build.started_at)}</td>
                  <td>{formatDate(build.completed_at)}</td>
                  <td>{calculateDuration(build.started_at, build.completed_at)}</td>
                  <td>
                    {build.status === 'in_progress' && (
                      <div className="progress-mini">
                        <div 
                          className="progress-mini-fill" 
                          style={{ width: `${build.progress}%` }}
                        />
                        <span className="progress-text">{build.progress}%</span>
                      </div>
                    )}
                  </td>
                  <td>
                    <div className="action-buttons">
                      <Link 
                        to={`/builds/${build.id}`} 
                        className="button info-button"
                      >
                        Details
                      </Link>
                      {build.status === 'completed' && (
                        <a 
                          href={`/api/downloads/${build.id}`} 
                          className="button download-button"
                          download
                        >
                          Download
                        </a>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      )}
      
      <div className="history-actions">
        <Link to="/build" className="button primary-button">
          Start New Build
        </Link>
      </div>
    </div>
  );
};

export default BuildHistory;