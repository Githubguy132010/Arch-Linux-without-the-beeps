"""
WebSocket Manager for Real-time Build Updates
This module handles WebSocket connections and broadcasting build status updates.
"""
import logging
from typing import Dict, Any, Set
import json
from flask_socketio import SocketIO
from queue_manager import queue_manager, BuildJob

# Configure logging
logger = logging.getLogger('websocket_manager')

class WebSocketManager:
    """Manages WebSocket connections and broadcasts build updates"""
    
    def __init__(self, socketio: SocketIO):
        """Initialize the WebSocket manager with a SocketIO instance"""
        self.socketio = socketio
        self.connected_clients: Set[str] = set()
        
        # Register event handlers
        @socketio.on('connect')
        def handle_connect():
            client_id = self.socketio.request.sid
            logger.info(f"Client connected: {client_id}")
            self.connected_clients.add(client_id)
            # Send initial queue and history data
            self.send_queue_update(client_id)
            self.send_history_update(client_id)
        
        @socketio.on('disconnect')
        def handle_disconnect():
            client_id = self.socketio.request.sid
            logger.info(f"Client disconnected: {client_id}")
            self.connected_clients.remove(client_id)
        
        # Register for build status updates
        queue_manager.register_status_callback(self.handle_build_status_update)
        
        logger.info("WebSocket manager initialized")
    
    def handle_build_status_update(self, job: BuildJob) -> None:
        """Handle a build status update from the queue manager"""
        try:
            # Broadcast job update to all clients
            job_data = job.to_dict()
            self.socketio.emit('job_update', job_data)
            logger.debug(f"Broadcast job update for job {job.id}")
            
            # If job status changed, also broadcast queue and history updates
            if job.status in ('completed', 'failed'):
                self.broadcast_queue_update()
                self.broadcast_history_update()
        except Exception as e:
            logger.error(f"Error broadcasting job update: {str(e)}")
    
    def send_queue_update(self, client_id: str = None) -> None:
        """Send queue update to a specific client or all clients if client_id is None"""
        try:
            queue_data = queue_manager.get_queue()
            if client_id:
                self.socketio.emit('queue_update', queue_data, room=client_id)
            else:
                self.socketio.emit('queue_update', queue_data)
        except Exception as e:
            logger.error(f"Error sending queue update: {str(e)}")
    
    def send_history_update(self, client_id: str = None) -> None:
        """Send history update to a specific client or all clients if client_id is None"""
        try:
            history_data = queue_manager.get_history()
            if client_id:
                self.socketio.emit('history_update', history_data, room=client_id)
            else:
                self.socketio.emit('history_update', history_data)
        except Exception as e:
            logger.error(f"Error sending history update: {str(e)}")
    
    def broadcast_queue_update(self) -> None:
        """Broadcast queue update to all connected clients"""
        self.send_queue_update()
    
    def broadcast_history_update(self) -> None:
        """Broadcast history update to all connected clients"""
        self.send_history_update()

# The actual instance will be created when the main app initializes the SocketIO instance