import os
import subprocess
from flask import Flask, render_template, Response, send_from_directory

app = Flask(__name__)
ISO_DIR = "/workdir/out"
ISO_NAME = "Arch.iso"
ISO_PATH = os.path.join(ISO_DIR, ISO_NAME)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/build')
def build():
    def generate():
        # Ensure the output directory exists
        os.makedirs(ISO_DIR, exist_ok=True)

        # Command to execute the build script
        command = ["/entrypoint.sh", "build", "out", "work"]

        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1, universal_newlines=True)

        for line in process.stdout:
            yield f"data: {line}\n\n"

        process.wait()

        if process.returncode == 0:
            yield "data: BUILD_SUCCESS\n\n"
        else:
            yield "data: BUILD_FAILED\n\n"

    return Response(generate(), mimetype='text/event-stream')

@app.route('/download')
def download():
    if os.path.exists(ISO_PATH):
        return send_from_directory(directory=ISO_DIR, path=ISO_NAME, as_attachment=True)
    else:
        return "ISO not found.", 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
