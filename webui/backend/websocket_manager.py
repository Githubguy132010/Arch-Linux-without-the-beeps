"""
WebSocket Manager for real-time communication with clients
This module handles WebSocket connections and event broadcasting
"""
import logging
import json
from typing import Dict, Any, List, Optional, Callable
from queue_manager import queue_manager, BuildJob

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('websocket_manager')

class WebSocketManager:
    """Manages WebSocket connections and event broadcasting"""
    
    def __init__(self, socketio):
        """Initialize the WebSocket manager
        
        Args:
            socketio: The Flask-SocketIO instance
        """
        self.socketio = socketio
        self.connected_clients = set()
        
        # Register event handlers
        self._register_socket_events()
        
        # Register queue status callbacks
        queue_manager.register_status_callback(self._on_job_status_update)
        
        logger.info("WebSocket manager initialized")
    
    def _register_socket_events(self):
        """Register SocketIO event handlers"""
        
        @self.socketio.on('connect')
        def handle_connect():
            """Handle new client connection"""
            client_id = getattr(self.socketio.request, 'sid', None)
            if not client_id:
                logger.error("Failed to get client ID for new connection")
                return
                
            logger.info(f"New client connected: {client_id}")
            self.connected_clients.add(client_id)
            
            # Send initial data
            self._send_initial_data(client_id)
        
        @self.socketio.on('disconnect')
        def handle_disconnect():
            """Handle client disconnection"""
            client_id = getattr(self.socketio.request, 'sid', None)
            if not client_id:
                logger.error("Failed to get client ID for disconnection")
                return
                
            logger.info(f"Client disconnected: {client_id}")
            if client_id in self.connected_clients:
                self.connected_clients.remove(client_id)
        
        @self.socketio.on('get_queue')
        def handle_get_queue():
            """Handle request for current queue"""
            try:
                client_id = getattr(self.socketio.request, 'sid', None)
                queue_data = queue_manager.get_queue()
                logger.info(f"Sending queue data to client {client_id}")
                self.socketio.emit('queue_update', queue_data, room=client_id)
            except Exception as e:
                logger.error(f"Error sending queue data: {str(e)}")
                self._send_error(client_id, "Failed to retrieve queue data")
        
        @self.socketio.on('get_history')
        def handle_get_history():
            """Handle request for build history"""
            try:
                client_id = getattr(self.socketio.request, 'sid', None)
                history_data = queue_manager.get_history()
                logger.info(f"Sending history data to client {client_id}")
                self.socketio.emit('history_update', history_data, room=client_id)
            except Exception as e:
                logger.error(f"Error sending history data: {str(e)}")
                self._send_error(client_id, "Failed to retrieve history data")
        
        @self.socketio.on('get_active_job')
        def handle_get_active_job():
            """Handle request for active job"""
            try:
                client_id = getattr(self.socketio.request, 'sid', None)
                active_job = queue_manager._current_job
                
                if active_job:
                    logger.info(f"Sending active job data to client {client_id}")
                    self.socketio.emit('job_update', active_job.to_dict(), room=client_id)
                else:
                    logger.info(f"No active job to send to client {client_id}")
            except Exception as e:
                logger.error(f"Error sending active job data: {str(e)}")
                self._send_error(client_id, "Failed to retrieve active job data")
        
        @self.socketio.on('get_job')
        def handle_get_job(job_id):
            """Handle request for a specific job
            
            Args:
                job_id: The ID of the job to retrieve
            """
            try:
                if not job_id or not isinstance(job_id, str):
                    raise ValueError(f"Invalid job_id: {job_id}")
                    
                client_id = getattr(self.socketio.request, 'sid', None)
                job = queue_manager.get_job(job_id)
                
                if job:
                    logger.info(f"Sending job {job_id} data to client {client_id}")
                    self.socketio.emit('job_update', job.to_dict(), room=client_id)
                else:
                    logger.warning(f"Job {job_id} not found for client {client_id}")
                    self._send_error(client_id, f"Job with ID {job_id} not found")
            except Exception as e:
                logger.error(f"Error sending job data: {str(e)}")
                self._send_error(client_id, f"Failed to retrieve job data: {str(e)}")
        
        @self.socketio.on_error()
        def handle_error(e):
            """Handle WebSocket errors
            
            Args:
                e: The error that occurred
            """
            logger.error(f"WebSocket error: {str(e)}")
            client_id = getattr(self.socketio.request, 'sid', None)
            if client_id:
                self._send_error(client_id, f"Server error: {str(e)}")
    
    def _send_initial_data(self, client_id):
        """Send initial data to a newly connected client
        
        Args:
            client_id: The client ID to send the data to
        """
        try:
            # Send queue data
            queue_data = queue_manager.get_queue()
            self.socketio.emit('queue_update', queue_data, room=client_id)
            
            # Send history data
            history_data = queue_manager.get_history()
            self.socketio.emit('history_update', history_data, room=client_id)
            
            # Send active job if any
            active_job = queue_manager._current_job
            if active_job:
                self.socketio.emit('job_update', active_job.to_dict(), room=client_id)
            
            logger.info(f"Sent initial data to client {client_id}")
        except Exception as e:
            logger.error(f"Error sending initial data: {str(e)}")
            self._send_error(client_id, "Failed to load initial data")
    
    def _send_error(self, client_id, message):
        """Send error message to a client
        
        Args:
            client_id: The client ID to send the error to
            message: The error message
        """
        if not client_id:
            logger.error(f"Cannot send error without client_id: {message}")
            return
            
        try:
            self.socketio.emit('error', {'message': message}, room=client_id)
            logger.info(f"Sent error to client {client_id}: {message}")
        except Exception as e:
            logger.error(f"Error sending error message: {str(e)}")
    
    def _on_job_status_update(self, job):
        """Handle job status updates from the queue manager
        
        Args:
            job: The BuildJob that was updated
        """
        try:
            # Check if job is valid
            if not job or not isinstance(job, BuildJob):
                logger.error(f"Invalid job object received: {job}")
                return
                
            # Broadcast job update to all clients
            job_data = job.to_dict()
            logger.info(f"Broadcasting job update for job {job.id}, status: {job.status}")
            self.socketio.emit('job_update', job_data)
            
            # If job status changed to completed or failed, update history
            if job.status in ('completed', 'failed'):
                history_data = queue_manager.get_history()
                self.socketio.emit('history_update', history_data)
            
            # If job was moved to or from queue, update queue
            queue_data = queue_manager.get_queue()
            self.socketio.emit('queue_update', queue_data)
        except Exception as e:
            logger.error(f"Error broadcasting job update: {str(e)}")
            
    def broadcast_message(self, event, data, room=None):
        """Broadcast a message to all clients or a specific room
        
        Args:
            event: The event name
            data: The data to send
            room: Optional room to broadcast to
        """
        try:
            self.socketio.emit(event, data, room=room)
            logger.info(f"Broadcast {event} to {room or 'all clients'}")
        except Exception as e:
            logger.error(f"Error broadcasting message: {str(e)}")