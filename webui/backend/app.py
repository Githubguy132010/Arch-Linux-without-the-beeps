"""
Backend server for Arch Linux ISO Builder WebUI
This Flask application serves as the backend for the ISO builder web interface.
"""
from flask import Flask, jsonify, request, send_from_directory
import os
import json
import uuid
from datetime import datetime
import eventlet

# Initialize eventlet for async I/O - this must be done first
eventlet.monkey_patch()

from flask_socketio import SocketIO, emit

# Import queue manager
from queue_manager import queue_manager, BuildJob

# Create data directory if it doesn't exist
os.makedirs(os.path.join('/tmp', 'webui_data'), exist_ok=True)

# Initialize Flask app
app = Flask(__name__, static_folder='static')
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev_key_' + uuid.uuid4().hex)

# Initialize SocketIO with the app - use engineio_logger and logger for debugging
socketio = SocketIO(app, 
                   cors_allowed_origins="*", 
                   async_mode='eventlet',
                   logger=True,
                   engineio_logger=True)

# Import and initialize WebSocket manager after socketio is created
from websocket_manager import WebSocketManager
websocket_manager = WebSocketManager(socketio)

@app.route('/')
def index():
    """Serve the frontend application"""
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/api/status')
def status():
    """Return the status of the application"""
    return jsonify({
        'status': 'online',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat(),
        'queue_size': len(queue_manager.get_queue()),
        'has_active_build': queue_manager._current_job is not None
    })

@app.route('/api/config', methods=['GET'])
def get_config():
    """Return the current ISO configuration"""
    try:
        # Read packages list
        packages = []
        try:
            with open('/workdir/packages.x86_64', 'r') as f:
                packages = [pkg.strip() for pkg in f.readlines() if pkg.strip() and not pkg.startswith('#')]
        except Exception as e:
            app.logger.error(f"Error reading packages: {str(e)}")
        
        # Read profiledef.sh for iso settings
        profile_settings = {}
        try:
            with open('/workdir/profiledef.sh', 'r') as f:
                for line in f:
                    if line.strip() and '=' in line and not line.strip().startswith('#'):
                        key, value = line.split('=', 1)
                        profile_settings[key.strip()] = value.strip().strip('"\'')
        except Exception as e:
            app.logger.error(f"Error reading profiledef: {str(e)}")
            profile_settings = {'error': str(e)}
        
        return jsonify({
            'packages': packages,
            'profile_settings': profile_settings
        })
    except Exception as e:
        app.logger.error(f"Error in get_config: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/build', methods=['POST'])
def build_iso():
    """Trigger an ISO build with specified configuration"""
    try:
        # Get build configuration from request
        config = request.json
        
        if not config:
            return jsonify({'error': 'No configuration provided'}), 400
        
        # Add job to build queue
        job = queue_manager.add_job(config)
        
        return jsonify({
            'status': 'accepted',
            'message': 'Build job queued',
            'job_id': job.id,
            'timestamp': datetime.now().isoformat(),
            'queue_position': len(queue_manager.get_queue())
        })
    except Exception as e:
        app.logger.error(f"Error in build_iso: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/builds')
def list_builds():
    """List the builds in the queue and history"""
    try:
        active_job = None
        if queue_manager._current_job:
            active_job = queue_manager._current_job.to_dict()
        
        return jsonify({
            'active': active_job,
            'queue': queue_manager.get_queue(),
            'history': queue_manager.get_history()
        })
    except Exception as e:
        app.logger.error(f"Error in list_builds: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/builds/<job_id>')
def get_build_details(job_id):
    """Get details of a specific build"""
    try:
        job = queue_manager.get_job(job_id)
        if job:
            return jsonify(job.to_dict())
        else:
            return jsonify({'error': 'Build not found'}), 404
    except Exception as e:
        app.logger.error(f"Error in get_build_details: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/builds/<job_id>/log')
def get_build_log(job_id):
    """Get the build log for a specific job"""
    try:
        job = queue_manager.get_job(job_id)
        if job:
            return jsonify({
                'id': job.id,
                'status': job.status,
                'log': job.build_log,
                'progress': job.progress
            })
        else:
            return jsonify({'error': 'Build not found'}), 404
    except Exception as e:
        app.logger.error(f"Error in get_build_log: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/downloads/<job_id>')
def download_iso(job_id):
    """Generate a download link for a completed ISO build"""
    try:
        job = queue_manager.get_job(job_id)
        if not job:
            return jsonify({'error': 'Build not found'}), 404
            
        if job.status != 'completed' or not job.output_path:
            return jsonify({'error': 'ISO not available for download'}), 400
            
        # Extract filename from path
        filename = os.path.basename(job.output_path)
        directory = os.path.dirname(job.output_path)
        
        # In a real implementation, you might want to check if the file exists
        # and handle appropriate permissions
        
        return send_from_directory(directory, filename, as_attachment=True)
    except Exception as e:
        app.logger.error(f"Error in download_iso: {str(e)}")
        return jsonify({'error': str(e)}), 500

# Catch-all route to serve the frontend for client-side routing
@app.route('/<path:path>')
def serve_static(path):
    """Serve static files or return the index for client-side routes"""
    if os.path.exists(os.path.join(app.static_folder, path)):
        return send_from_directory(app.static_folder, path)
    return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    # In development, use the SocketIO development server
    debug = os.environ.get('FLASK_ENV') == 'development'
    port = int(os.environ.get('PORT', 8080))
    
    print(f"Starting Arch Linux WebUI server on port {port}")
    socketio.run(app, host='0.0.0.0', port=port, debug=debug)