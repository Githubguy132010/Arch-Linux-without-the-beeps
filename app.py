import os
import subprocess
import threading
from queue import Queue, Empty
from flask import Flask, render_template, Response, send_from_directory
from werkzeug.utils import secure_filename

app = Flask(__name__)
ISO_DIR = "/workdir/out"
ISO_NAME = "Arch.iso"
ISO_PATH = os.path.join(ISO_DIR, ISO_NAME)

# --- Build Process Management ---
build_process = None
build_lock = threading.Lock()

def run_build_in_thread(queue):
    """
    Runs the build script in a separate thread and puts its output into a queue.
    This prevents the Flask endpoint from blocking.
    """
    global build_process
    try:
        command = ["/entrypoint.sh", "build", "out", "work"]
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True,
            errors='replace' # Avoids crashing on weird characters
        )
        # Set the global process object so we can check its status
        with build_lock:
            build_process = process

        # Stream output to the queue
        for line in iter(process.stdout.readline, ''):
            queue.put(line)

        process.stdout.close()
        process.wait()

        # Signal completion status via the queue
        if process.returncode == 0:
            queue.put("BUILD_SUCCESS")
        else:
            queue.put("BUILD_FAILED")

    except Exception as e:
        queue.put(f"BUILD_ERROR: {str(e)}")
    finally:
        # Clear the global process variable once done
        with build_lock:
            build_process = None

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/build')
def build():
    """
    Starts a new build if one is not already running.
    Streams build logs back to the client using Server-Sent Events.
    """
    with build_lock:
        if build_process and build_process.poll() is None:
            return Response("data: BUILD_IN_PROGRESS\n\n", mimetype='text/event-stream')

    log_queue = Queue()
    thread = threading.Thread(target=run_build_in_thread, args=(log_queue,))
    thread.daemon = True
    thread.start()

    def generate():
        while thread.is_alive() or not log_queue.empty():
            try:
                line = log_queue.get(timeout=1)
                yield f"data: {line}\n\n"
            except Empty:
                # If the queue is empty, the build may still be running.
                # The loop will continue until the thread is finished.
                pass

    return Response(generate(), mimetype='text/event-stream')

@app.route('/download')
def download():
    """
    Provides the built ISO for download.
    Includes filename sanitization as a security best practice.
    """
    safe_filename = secure_filename(ISO_NAME)
    if safe_filename != ISO_NAME:
        # This case should not be reachable with a hardcoded ISO_NAME,
        # but serves as a defense-in-depth security measure.
        return "Invalid filename provided.", 400

    if os.path.exists(os.path.join(ISO_DIR, safe_filename)):
        return send_from_directory(directory=ISO_DIR, path=safe_filename, as_attachment=True)
    else:
        return "ISO not found.", 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)