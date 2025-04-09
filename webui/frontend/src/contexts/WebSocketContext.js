import React, { createContext, useContext, useEffect, useState } from 'react';
import { io } from 'socket.io-client';

/**
 * WebSocket Context for managing real-time communication with the backend
 * Provides WebSocket state and event handlers throughout the application
 */
const WebSocketContext = createContext(null);

/**
 * WebSocketProvider component manages WebSocket connection and state
 * Contains improved error handling and connection retry logic
 */
export const WebSocketProvider = ({ children }) => {
  const [socket, setSocket] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [queue, setQueue] = useState([]);
  const [history, setHistory] = useState([]);
  const [activeJob, setActiveJob] = useState(null);
  const [error, setError] = useState(null);
  const [retryCount, setRetryCount] = useState(0);

  // Initialize socket connection on component mount
  useEffect(() => {
    console.log('Initializing WebSocket connection');
    
    // Determine WebSocket URL based on environment
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = process.env.REACT_APP_API_HOST || window.location.host;
    const wsUrl = process.env.NODE_ENV === 'development' 
      ? 'http://localhost:8080' 
      : `${window.location.protocol}//${host}`;
      
    console.log('WebSocket URL:', wsUrl);

    // Create socket instance with more robust configuration
    const socketOptions = {
      reconnectionAttempts: 10,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
      timeout: 20000,
      autoConnect: true,
      transports: ['websocket', 'polling'] // Try WebSocket first, fallback to polling
    };

    try {
      const socketInstance = io(wsUrl, socketOptions);
      console.log('Socket instance created');

      // Set up event handlers
      socketInstance.on('connect', () => {
        console.log('WebSocket connected successfully');
        setIsConnected(true);
        setError(null);
        setRetryCount(0);
      });

      socketInstance.on('disconnect', (reason) => {
        console.log(`WebSocket disconnected: ${reason}`);
        setIsConnected(false);
        
        // Handle different disconnect reasons
        if (reason === 'io server disconnect') {
          // Server initiated disconnect, need to manually reconnect
          console.log('Server disconnected the socket, attempting to reconnect...');
          socketInstance.connect();
        }
        // Other disconnects are automatically handled by socket.io
      });

      socketInstance.on('connect_error', (err) => {
        console.error('WebSocket connection error:', err);
        setError(`Connection error: ${err.message}`);
        
        // Increment retry count
        setRetryCount(prev => {
          const newCount = prev + 1;
          console.log(`Connection retry attempt: ${newCount}`);
          return newCount;
        });
        
        // After multiple failures, try to use polling if initially using websocket
        if (retryCount > 3 && socketInstance.io.opts.transports[0] === 'websocket') {
          console.log('Multiple connection failures, forcing polling transport');
          socketInstance.io.opts.transports = ['polling'];
        }
      });

      // Handle queue updates
      socketInstance.on('queue_update', (data) => {
        console.log('Received queue update:', data);
        if (Array.isArray(data)) {
          setQueue(data);
        } else {
          console.error('Invalid queue data format received:', data);
          setQueue([]);
        }
      });

      // Handle history updates
      socketInstance.on('history_update', (data) => {
        console.log('Received history update:', data);
        if (Array.isArray(data)) {
          setHistory(data);
        } else {
          console.error('Invalid history data format received:', data);
          setHistory([]);
        }
      });

      // Handle individual job updates
      socketInstance.on('job_update', (job) => {
        console.log('Received job update:', job);
        if (!job || typeof job !== 'object' || !job.id) {
          console.error('Invalid job update received:', job);
          return;
        }
        
        // If this is an active job, update activeJob state
        if (job.status === 'in_progress') {
          setActiveJob(job);
        } else if (activeJob && activeJob.id === job.id) {
          // Job was active but now completed or failed
          setActiveJob(null);
        }

        // Update job in queue if it's there
        setQueue(prevQueue => {
          if (!Array.isArray(prevQueue)) return [];
          
          const index = prevQueue.findIndex(item => item?.id === job.id);
          if (index !== -1) {
            const updatedQueue = [...prevQueue];
            updatedQueue[index] = job;
            return updatedQueue;
          }
          return prevQueue;
        });

        // Update job in history if it's there
        setHistory(prevHistory => {
          if (!Array.isArray(prevHistory)) return [];
          
          const index = prevHistory.findIndex(item => item?.id === job.id);
          if (index !== -1) {
            const updatedHistory = [...prevHistory];
            updatedHistory[index] = job;
            return updatedHistory;
          }
          // Add to history if completed or failed and not already there
          if ((job.status === 'completed' || job.status === 'failed') && 
              !prevHistory.some(item => item?.id === job.id)) {
            return [job, ...prevHistory];
          }
          return prevHistory;
        });
      });

      // Fetch initial data on connection
      socketInstance.on('connect', () => {
        console.log('Requesting initial data');
        socketInstance.emit('get_queue');
        socketInstance.emit('get_history');
        socketInstance.emit('get_active_job');
      });

      // Store socket instance and clean up on unmount
      setSocket(socketInstance);
      return () => {
        console.log('Cleaning up WebSocket connection');
        socketInstance.disconnect();
      };
    } catch (err) {
      console.error('Error initializing WebSocket:', err);
      setError(`Failed to initialize WebSocket: ${err.message}`);
      return () => {}; // No cleanup needed if initialization failed
    }
  }, [retryCount]);

  // Create context value object with additional helper functions
  const value = {
    socket,
    isConnected,
    queue: Array.isArray(queue) ? queue : [],
    history: Array.isArray(history) ? history : [],
    activeJob,
    error,
    reconnect: () => {
      if (socket) {
        console.log('Manually reconnecting WebSocket');
        socket.disconnect();
        socket.connect();
      }
    }
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
    console.error('useWebSocket must be used within a WebSocketProvider');
    // Return safe fallback values instead of throwing
    return {
      socket: null,
      isConnected: false,
      queue: [],
      history: [],
      activeJob: null,
      error: 'WebSocket context not available',
      reconnect: () => {}
    };
  }
  return context;
};

export default WebSocketContext;