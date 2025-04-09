import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useWebSocket } from '../contexts/WebSocketContext';

/**
 * BuildISO component allows users to configure and trigger ISO builds
 * Displays real-time build status and queue information
 */
const BuildISO = () => {
  const navigate = useNavigate();
  const { isConnected, queue, activeJob } = useWebSocket();
  
  const [buildConfig, setBuildConfig] = useState({
    customPackages: '',
    compressionLevel: '9',
    buildMode: 'standard',
    includeExtraModules: false
  });
  
  const [buildStatus, setBuildStatus] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setBuildConfig({
      ...buildConfig,
      [name]: type === 'checkbox' ? checked : value
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setBuildStatus({ status: 'pending', message: 'Submitting build request...' });
    
    // Extract custom packages if provided
    const configToSubmit = { ...buildConfig };
    if (buildConfig.buildMode === 'custom' && buildConfig.customPackages) {
      configToSubmit.packageList = buildConfig.customPackages
        .split('\n')
        .map(p => p.trim())
        .filter(p => p.length > 0);
    }
    
    // Send build configuration to the server
    fetch('/api/build', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(configToSubmit)
    })
      .then(res => {
        if (!res.ok) throw new Error('Failed to start build');
        return res.json();
      })
      .then(data => {
        setBuildStatus({
          status: 'accepted',
          message: 'Build job started successfully!',
          jobId: data.job_id
        });
        
        // Navigate to the build details page if a job ID was returned
        if (data.job_id) {
          navigate(`/builds/${data.job_id}`);
        }
      })
      .catch(err => {
        setBuildStatus({
          status: 'error',
          message: `Build failed to start: ${err.message}`
        });
      })
      .finally(() => {
        setIsSubmitting(false);
      });
  };

  // Calculate estimated wait time based on queue length
  const estimateWaitTime = () => {
    // Assuming each build takes approximately 15 minutes
    const averageBuildTime = 15; // minutes
    const queuePosition = queue.length;
    
    if (queuePosition === 0) {
      return activeJob ? "After current build (~15 minutes)" : "No wait, build will start immediately";
    } else {
      const waitTime = queuePosition * averageBuildTime;
      return `Approximately ${waitTime} minutes (position ${queuePosition + 1} in queue)`;
    }
  };

  return (
    <div className="build-iso">
      <h2>Build ISO</h2>
      
      {/* Build Queue Status */}
      <div className="queue-status">
        <h3>Current Build Status</h3>
        <div className="queue-info">
          <div className="queue-item">
            <span className="queue-label">WebSocket Status:</span>
            <span className={`queue-value ${isConnected ? 'connected' : 'disconnected'}`}>
              {isConnected ? 'Connected' : 'Disconnected'}
            </span>
          </div>
          <div className="queue-item">
            <span className="queue-label">Active Build:</span>
            <span className="queue-value">
              {activeJob ? `Yes (ID: ${activeJob.id.substring(0, 8)}...)` : 'None'}
            </span>
          </div>
          <div className="queue-item">
            <span className="queue-label">Queue Length:</span>
            <span className="queue-value">{queue.length} job(s)</span>
          </div>
          <div className="queue-item">
            <span className="queue-label">Estimated Wait:</span>
            <span className="queue-value">{estimateWaitTime()}</span>
          </div>
        </div>
      </div>
      
      <form onSubmit={handleSubmit} className="build-form">
        <div className="form-group">
          <label htmlFor="buildMode">Build Mode:</label>
          <select
            id="buildMode"
            name="buildMode"
            value={buildConfig.buildMode}
            onChange={handleInputChange}
            disabled={isSubmitting}
          >
            <option value="standard">Standard (Recommended)</option>
            <option value="minimal">Minimal (Smaller size)</option>
            <option value="full">Full (All packages)</option>
            <option value="custom">Custom</option>
          </select>
          <small className="form-text">
            Choose the type of ISO to build. Standard includes common packages, minimal is bare-bones, and full includes all packages.
          </small>
        </div>
        
        {buildConfig.buildMode === 'custom' && (
          <div className="form-group">
            <label htmlFor="customPackages">Additional Packages:</label>
            <textarea
              id="customPackages"
              name="customPackages"
              value={buildConfig.customPackages}
              onChange={handleInputChange}
              placeholder="Enter package names, one per line"
              disabled={isSubmitting}
              rows={6}
            />
            <small className="form-text">
              Add packages to include, one per line. These will be added to the base packages.
            </small>
          </div>
        )}
        
        <div className="form-group">
          <label htmlFor="compressionLevel">Compression Level (1-9):</label>
          <input
            type="number"
            id="compressionLevel"
            name="compressionLevel"
            min="1"
            max="9"
            value={buildConfig.compressionLevel}
            onChange={handleInputChange}
            disabled={isSubmitting}
          />
          <small className="form-text">
            Higher values result in smaller ISOs but longer build times.
          </small>
        </div>
        
        <div className="form-group checkbox">
          <input
            type="checkbox"
            id="includeExtraModules"
            name="includeExtraModules"
            checked={buildConfig.includeExtraModules}
            onChange={handleInputChange}
            disabled={isSubmitting}
          />
          <label htmlFor="includeExtraModules">Include extra kernel modules</label>
          <small className="form-text">
            Includes additional kernel modules for wider hardware compatibility.
          </small>
        </div>
        
        <div className="form-actions">
          <button 
            type="submit" 
            className="primary-button"
            disabled={isSubmitting}
          >
            {isSubmitting ? 'Submitting...' : 'Build ISO'}
          </button>
        </div>
      </form>
      
      {buildStatus && (
        <div className={`build-status ${buildStatus.status}`}>
          <h3>Submission Status</h3>
          <p>{buildStatus.message}</p>
          {buildStatus.jobId && (
            <p>Job ID: <strong>{buildStatus.jobId}</strong></p>
          )}
        </div>
      )}
    </div>
  );
};

export default BuildISO;