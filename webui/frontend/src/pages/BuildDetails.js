import React, { useState, useEffect, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useWebSocket } from '../contexts/WebSocketContext';

/**
 * BuildDetails component displays real-time information about a specific build job
 * Shows build status, progress, logs, and configuration details
 */
const BuildDetails = () => {
  const { buildId } = useParams();
  const { activeJob, queue, history } = useWebSocket();
  const [buildData, setBuildData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const logEndRef = useRef(null);

  // Find build data from WebSocket context
  useEffect(() => {
    // Check if the job is the active one
    if (activeJob && activeJob.id === buildId) {
      setBuildData(activeJob);
      setLoading(false);
      return;
    }

    // Check the queue
    const queuedJob = queue.find(job => job.id === buildId);
    if (queuedJob) {
      setBuildData(queuedJob);
      setLoading(false);
      return;
    }

    // Check history
    const historyJob = history.find(job => job.id === buildId);
    if (historyJob) {
      setBuildData(historyJob);
      setLoading(false);
      return;
    }

    // If not found in WebSocket data, fetch it from API
    if (!buildData && loading) {
      fetch(`/api/builds/${buildId}`)
        .then(res => {
          if (!res.ok) throw new Error(`Failed to fetch build details (${res.status})`);
          return res.json();
        })
        .then(data => {
          setBuildData(data);
          setLoading(false);
        })
        .catch(err => {
          console.error('Error fetching build details:', err);
          setError(err.message);
          setLoading(false);
        });
    }
  }, [buildId, activeJob, queue, history, buildData, loading]);

  // Auto-scroll to bottom of logs when they update
  useEffect(() => {
    if (logEndRef.current) {
      logEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [buildData?.build_log]);

  // Helper function to get status class for styling
  const getStatusClass = (status) => {
    switch (status) {
      case 'completed': return 'status-success';
      case 'failed': return 'status-error';
      case 'in_progress': return 'status-progress';
      case 'queued': return 'status-queued';
      default: return '';
    }
  };

  // Format date for display
  const formatDate = (isoString) => {
    if (!isoString) return 'N/A';
    return new Date(isoString).toLocaleString();
  };

  if (loading) return <div className="loading-container">Loading build details...</div>;
  if (error) return <div className="error-container">Error: {error}</div>;
  if (!buildData) return <div className="error-container">Build not found</div>;

  return (
    <div className="build-details">
      <div className="build-header">
        <h2>Build Details</h2>
        <div className="build-id">ID: {buildData.id}</div>
        <div className={`build-status ${getStatusClass(buildData.status)}`}>
          Status: {buildData.status}
        </div>
      </div>

      {/* Progress bar for in-progress builds */}
      {buildData.status === 'in_progress' && (
        <div className="progress-container">
          <div className="progress-label">
            Progress: {buildData.progress}%
          </div>
          <div className="progress-bar">
            <div 
              className="progress-bar-fill" 
              style={{ width: `${buildData.progress}%` }}
            />
          </div>
        </div>
      )}

      <div className="build-info-grid">
        <div className="build-info-item">
          <strong>Created:</strong> {formatDate(buildData.created_at)}
        </div>
        <div className="build-info-item">
          <strong>Started:</strong> {formatDate(buildData.started_at)}
        </div>
        <div className="build-info-item">
          <strong>Completed:</strong> {formatDate(buildData.completed_at)}
        </div>
      </div>

      {buildData.status === 'completed' && buildData.output_path && (
        <div className="build-download">
          <h3>Download</h3>
          <a 
            href={`/api/downloads/${buildData.id}`}
            className="download-button"
            download
          >
            Download ISO
          </a>
        </div>
      )}

      <div className="build-config">
        <h3>Build Configuration</h3>
        <pre>{JSON.stringify(buildData.config, null, 2)}</pre>
      </div>

      <div className="build-logs">
        <h3>Build Logs</h3>
        <div className="log-container">
          {buildData.build_log && buildData.build_log.length > 0 ? (
            <div className="log-entries">
              {buildData.build_log.map((entry, index) => (
                <div key={index} className="log-entry">
                  {entry}
                </div>
              ))}
              <div ref={logEndRef} />
            </div>
          ) : (
            <div className="no-logs">No logs available</div>
          )}
        </div>
      </div>

      {buildData.error && (
        <div className="build-error">
          <h3>Error</h3>
          <div className="error-message">{buildData.error}</div>
        </div>
      )}

      <div className="build-actions">
        <Link to="/history" className="button secondary-button">
          Back to Build History
        </Link>
      </div>
    </div>
  );
};

export default BuildDetails;