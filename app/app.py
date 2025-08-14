from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.get("/")
def index():
    sha = os.getenv("GIT_SHA", "dev")
    return f"Hello from CI/CD! Build: {sha}\n"

@app.get("/healthz")
def healthz():
    return jsonify(status="ok"), 200

if __name__ == "__main__":
    # For local runs only. In production we use gunicorn (see Dockerfile)
    app.run(host="0.0.0.0", port=8000)
