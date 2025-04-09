"""
Queue Manager Module for ISO Build Jobs
This module handles the queuing, processing, and status tracking of ISO build jobs.
"""
import os
import json
import time
import uuid
import threading
import logging
import subprocess
from datetime import datetime
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass, field, asdict

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('queue_manager')

# Constants
# Use tmp directory which is writable by any user
DATA_DIR = os.path.join('/tmp', 'webui_data')
QUEUE_FILE = os.path.join(DATA_DIR, 'build_queue.json')
HISTORY_FILE = os.path.join(DATA_DIR, 'build_history.json')
MAX_CONCURRENT_BUILDS = 1  # Limit to 1 concurrent build due to resource constraints

@dataclass
class BuildJob:
    """Data class representing a build job in the queue"""
    id: str
    status: str  # 'queued', 'in_progress', 'completed', 'failed'
    config: Dict
    created_at: str
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    build_log: List[str] = field(default_factory=list)
    error: Optional[str] = None
    output_path: Optional[str] = None
    progress: int = 0
    
    def to_dict(self) -> Dict:
        """Convert job to dictionary for serialization"""
        return asdict(self)
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'BuildJob':
        """Create a job instance from dictionary data"""
        return cls(
            id=data['id'],
            status=data['status'],
            config=data['config'],
            created_at=data['created_at'],
            started_at=data.get('started_at'),
            completed_at=data.get('completed_at'),
            build_log=data.get('build_log', []),
            error=data.get('error'),
            output_path=data.get('output_path'),
            progress=data.get('progress', 0)
        )

class BuildQueueManager:
    """Manages the build queue and job execution"""
    
    def __init__(self):
        """Initialize the queue manager"""
        self._queue: List[BuildJob] = []
        self._history: List[BuildJob] = []
        self._current_job: Optional[BuildJob] = None
        self._lock = threading.RLock()
        self._worker_thread: Optional[threading.Thread] = None
        self._running = False
        self._status_callbacks: List[Callable] = []
        
        # Create data directory if it doesn't exist
        os.makedirs(os.path.dirname(QUEUE_FILE), exist_ok=True)
        
        # Load existing queue and history
        self._load_queue()
        self._load_history()
    
    def register_status_callback(self, callback: Callable) -> None:
        """Register a callback function to be called when job status changes"""
        with self._lock:
            self._status_callbacks.append(callback)
    
    def _notify_status_update(self, job: BuildJob) -> None:
        """Notify all registered callbacks of a job status update"""
        for callback in self._status_callbacks:
            try:
                callback(job)
            except Exception as e:
                logger.error(f"Error in status callback: {str(e)}")
    
    def _load_queue(self) -> None:
        """Load the queue from file if available"""
        try:
            if os.path.exists(QUEUE_FILE):
                with open(QUEUE_FILE, 'r') as f:
                    data = json.load(f)
                    self._queue = [BuildJob.from_dict(job) for job in data]
                    logger.info(f"Loaded {len(self._queue)} jobs from queue file")
        except Exception as e:
            logger.error(f"Error loading queue: {str(e)}")
            self._queue = []
    
    def _load_history(self) -> None:
        """Load the build history from file if available"""
        try:
            if os.path.exists(HISTORY_FILE):
                with open(HISTORY_FILE, 'r') as f:
                    data = json.load(f)
                    self._history = [BuildJob.from_dict(job) for job in data]
                    logger.info(f"Loaded {len(self._history)} jobs from history file")
        except Exception as e:
            logger.error(f"Error loading history: {str(e)}")
            self._history = []
    
    def _save_queue(self) -> None:
        """Save the current queue to file"""
        try:
            with open(QUEUE_FILE, 'w') as f:
                json.dump([job.to_dict() for job in self._queue], f, indent=2)
        except Exception as e:
            logger.error(f"Error saving queue: {str(e)}")
    
    def _save_history(self) -> None:
        """Save the build history to file"""
        try:
            with open(HISTORY_FILE, 'w') as f:
                json.dump([job.to_dict() for job in self._history], f, indent=2)
        except Exception as e:
            logger.error(f"Error saving history: {str(e)}")
    
    def add_job(self, config: Dict) -> BuildJob:
        """Add a new job to the queue"""
        with self._lock:
            job_id = str(uuid.uuid4())
            job = BuildJob(
                id=job_id,
                status='queued',
                config=config,
                created_at=datetime.now().isoformat()
            )
            self._queue.append(job)
            self._save_queue()
            logger.info(f"Added new job {job_id} to queue")
            
            # Start the worker if not already running
            self._ensure_worker_running()
            
            # Notify listeners
            self._notify_status_update(job)
            
            return job
    
    def get_job(self, job_id: str) -> Optional[BuildJob]:
        """Get a job by ID from queue or history"""
        with self._lock:
            # First check the current job
            if self._current_job and self._current_job.id == job_id:
                return self._current_job
            
            # Then check the queue
            for job in self._queue:
                if job.id == job_id:
                    return job
            
            # Finally check the history
            for job in self._history:
                if job.id == job_id:
                    return job
            
            return None
    
    def get_queue(self) -> List[Dict]:
        """Get the current queue as a list of dictionaries"""
        with self._lock:
            return [job.to_dict() for job in self._queue]
    
    def get_history(self) -> List[Dict]:
        """Get the build history as a list of dictionaries"""
        with self._lock:
            return [job.to_dict() for job in self._history]
    
    def _ensure_worker_running(self) -> None:
        """Ensure the worker thread is running"""
        if not self._running:
            self._running = True
            self._worker_thread = threading.Thread(target=self._worker_loop, daemon=True)
            self._worker_thread.start()
            logger.info("Started worker thread")
    
    def _worker_loop(self) -> None:
        """Main worker loop that processes jobs in the queue"""
        logger.info("Worker thread started")
        
        while self._running:
            job_to_process = None
            
            # Get the next job from the queue if we're not already processing one
            with self._lock:
                if not self._current_job and self._queue:
                    job_to_process = self._queue[0]
                    self._queue.pop(0)
                    self._current_job = job_to_process
                    self._save_queue()
            
            # Process the job if we have one
            if job_to_process:
                self._process_job(job_to_process)
                
                # Job finished, add it to history and clear current_job
                with self._lock:
                    self._history.append(self._current_job)
                    self._current_job = None
                    self._save_history()
            else:
                # No jobs to process, sleep for a bit
                time.sleep(1)
    
    def _process_job(self, job: BuildJob) -> None:
        """Process a single build job"""
        logger.info(f"Processing job {job.id}")
        
        try:
            # Update job status
            job.status = 'in_progress'
            job.started_at = datetime.now().isoformat()
            job.progress = 5
            self._notify_status_update(job)
            
            # Simulate ISO build process
            self._simulate_build_process(job)
            
            # Set job as completed
            job.status = 'completed'
            job.completed_at = datetime.now().isoformat()
            job.progress = 100
            job.output_path = f"/workdir/out/archlinux-{datetime.now().strftime('%Y.%m.%d')}-x86_64.iso"
            logger.info(f"Job {job.id} completed successfully")
        except Exception as e:
            # Handle job failure
            error_message = f"Build failed: {str(e)}"
            job.status = 'failed'
            job.error = error_message
            job.completed_at = datetime.now().isoformat()
            logger.error(f"Job {job.id} failed: {error_message}")
        finally:
            # Always notify status update
            self._notify_status_update(job)
    
    def _simulate_build_process(self, job: BuildJob) -> None:
        """Simulate the ISO build process with progress updates
        
        In a real implementation, this would call the actual build script
        and capture its output in real-time.
        """
        # Add build log entry to indicate start
        job.build_log.append(f"[{datetime.now().isoformat()}] Starting ISO build process")
        self._notify_status_update(job)
        
        # Log the configuration
        job.build_log.append(f"[{datetime.now().isoformat()}] Build configuration: {json.dumps(job.config)}")
        job.progress = 10
        self._notify_status_update(job)
        
        # In a real implementation, we would run the build script and capture output
        # For simulation, we'll just add some progress updates
        build_steps = [
            ("Initializing build environment", 15),
            ("Preparing file system", 20),
            ("Installing base packages", 30),
            ("Installing custom packages", 50),
            ("Configuring system", 60),
            ("Blacklisting PC speaker modules", 70),
            ("Creating hooks", 80),
            ("Building ISO image", 90),
            ("Finalizing ISO", 95)
        ]
        
        for step_msg, progress in build_steps:
            # Add log entry
            job.build_log.append(f"[{datetime.now().isoformat()}] {step_msg}")
            job.progress = progress
            self._notify_status_update(job)
            # Simulate work being done
            time.sleep(2)
        
        # Add completion log entry
        job.build_log.append(f"[{datetime.now().isoformat()}] ISO build completed successfully")
        self._notify_status_update(job)

# Create a singleton instance for the application to use
queue_manager = BuildQueueManager()