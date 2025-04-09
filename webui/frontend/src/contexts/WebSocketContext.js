import React, { createContext, useContext, useEffect, useState } from 'react';
import { io } from 'socket.io-client';

/**
 * WebSocket Context for managing real-time communication with the backend
 * Provides WebSocket state and event handlers throughout the application
 */
const WebSocketContext = createContext(null);

/**
 * WebSocketProvider component manages WebSocket connection and state
 * Connects to the backend WebSocket server and handles events
 */
export const WebSocketProvider = ({ children }) => {
  const [socket, setSocket] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [queue, setQueue] = useState([]);
  const [history, setHistory] = useState([]);
  const [activeJob, setActiveJob] = useState(null);
  const [error, setError] = useState(null);

  // Initialize socket connection on component mount
  useEffect(() => {
    // Determine WebSocket URL based on environment
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = process.env.REACT_APP_API_HOST || window.location.host;
    const wsUrl = process.env.NODE_ENV === 'development' 
      ? 'http://localhost:8080' 
      : `${window.location.protocol}//${host}`;

    // Create socket instance
    const socketInstance = io(wsUrl, {
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
      autoConnect: true,
    });

    // Set up event handlers
    socketInstance.on('connect', () => {
      console.log('WebSocket connected');
      setIsConnected(true);
      setError(null);
    });

    socketInstance.on('disconnect', () => {
      console.log('WebSocket disconnected');
      setIsConnected(false);
    });

    socketInstance.on('connect_error', (err) => {
      console.error('WebSocket connection error:', err);
      setError(`Connection error: ${err.message}`);
    });

    // Handle queue updates
    socketInstance.on('queue_update', (data) => {
      console.log('Received queue update:', data);
      setQueue(data || []);
    });

    // Handle history updates
    socketInstance.on('history_update', (data) => {
      console.log('Received history update:', data);
      setHistory(data || []);
    });

    // Handle individual job updates
    socketInstance.on('job_update', (job) => {
      console.log('Received job update:', job);
      
      // If this is an active job, update activeJob state
      if (job.status === 'in_progress') {
        setActiveJob(job);
      } else if (activeJob && activeJob.id === job.id) {
        // Job was active but now completed or failed
        setActiveJob(null);
      }

      // Update job in queue if it's there
      setQueue(prevQueue => {
        const index = prevQueue.findIndex(item => item.id === job.id);
        if (index !== -1) {
          const updatedQueue = [...prevQueue];
          updatedQueue[index] = job;
          return updatedQueue;
        }
        return prevQueue;
      });

      // Update job in history if it's there
      setHistory(prevHistory => {
        const index = prevHistory.findIndex(item => item.id === job.id);
        if (index !== -1) {
          const updatedHistory = [...prevHistory];
          updatedHistory[index] = job;
          return updatedHistory;
        }
        // Add to history if completed or failed and not already there
        if ((job.status === 'completed' || job.status === 'failed') && 
            !prevHistory.some(item => item.id === job.id)) {
          return [job, ...prevHistory];
        }
        return prevHistory;
      });
    });

    // Store socket instance and clean up on unmount
    setSocket(socketInstance);
    return () => {
      socketInstance.disconnect();
    };
  }, []);

  // Create context value object
  const value = {
    socket,
    isConnected,
    queue,
    history,
    activeJob,
    error,
  };

  return (
    <WebSocketContext.Provider value={value}>
      {children}
    </WebSocketContext.Provider>
  );
};

/**
 * Custom hook for consuming the WebSocket context
 * @returns {object} WebSocket context value
 */
export const useWebSocket = () => {
  const context = useContext(WebSocketContext);
  if (context === null) {
    throw new Error('useWebSocket must be used within a WebSocketProvider');
  }
  return context;
};

export default WebSocketContext;