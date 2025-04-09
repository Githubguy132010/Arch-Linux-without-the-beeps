/**
 * ErrorBoundary component for catching and displaying React rendering errors
 * This helps prevent white screens by showing useful error messages
 */
import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    // Update state so the next render will show the fallback UI
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    // Log the error to the console
    console.error('React Error Boundary caught an error:', error, errorInfo);
    this.setState({ errorInfo });
  }

  render() {
    if (this.state.hasError) {
      // Render fallback UI
      return (
        <div style={{
          padding: '20px',
          background: '#fff8f8',
          border: '1px solid #ffb6b6',
          borderRadius: '5px',
          margin: '20px',
          color: '#333'
        }}>
          <h2 style={{ color: '#d32f2f' }}>Something went wrong</h2>
          <details style={{ whiteSpace: 'pre-wrap', marginTop: '10px' }}>
            <summary>Show technical details</summary>
            <p>{this.state.error?.toString()}</p>
            <p>Component Stack:</p>
            <pre style={{
              padding: '10px',
              background: '#f5f5f5',
              borderRadius: '3px',
              overflowX: 'auto'
            }}>
              {this.state.errorInfo?.componentStack || 'No stack trace available'}
            </pre>
          </details>
          <button 
            style={{
              marginTop: '15px',
              padding: '8px 15px',
              background: '#d32f2f',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer'
            }}
            onClick={() => window.location.reload()}
          >
            Reload Page
          </button>
        </div>
      );
    }

    // If no error occurred, render children normally
    return this.props.children;
  }
}

export default ErrorBoundary;