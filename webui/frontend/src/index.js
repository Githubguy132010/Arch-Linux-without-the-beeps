import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import ErrorBoundary from './ErrorBoundary';

// Enable more detailed console logging for development
console.log('Application starting - ' + new Date().toISOString());
console.log('Environment:', process.env.NODE_ENV);

// Add global error handling for uncaught errors
window.addEventListener('error', (event) => {
  console.error('Global error caught:', event.error);
});

// Add global promise rejection handling
window.addEventListener('unhandledrejection', (event) => {
  console.error('Unhandled Promise rejection:', event.reason);
});

// Create root with error boundary to prevent white screen on errors
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </React.StrictMode>
);

// Log successful render
console.log('Root render called - check for errors above');