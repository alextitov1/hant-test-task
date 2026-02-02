"""
Gunicorn configuration file for production deployment.

This configuration sets up Gunicorn to run the FastAPI application
with proper worker management, logging, and performance settings.
"""

import multiprocessing
import os

# Server socket
bind = "0.0.0.0:8000"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "uvicorn.workers.UvicornWorker"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 50
timeout = 30
keepalive = 5

# Logging
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "ec2-instance-info"

# Server mechanics
daemon = False
pidfile = "/var/run/gunicorn/gunicorn.pid"
user = None
group = None
tmp_upload_dir = None

# SSL (if needed)
# keyfile = "/path/to/keyfile"
# certfile = "/path/to/certfile"

# Environment
raw_env = [
    "PYTHONUNBUFFERED=1",
]

# Preload app for better performance
preload_app = True

# Graceful timeout
graceful_timeout = 30

# Enable zero downtime deployment
# When a new version is deployed, old workers will finish their requests
# before shutting down
reload = False

# Custom hooks (optional)
def on_starting(server):
    """Called just before the master process is initialized."""
    print("Gunicorn master process starting...")

def on_reload(server):
    """Called when a worker is reloaded."""
    print("Gunicorn worker reloading...")

def when_ready(server):
    """Called just after the server is started."""
    print("Gunicorn server is ready. Spawning workers...")

def pre_fork(server, worker):
    """Called just before a worker is forked."""
    pass

def post_fork(server, worker):
    """Called just after a worker has been forked."""
    print(f"Worker spawned (pid: {worker.pid})")

def pre_exec(server):
    """Called just before a new master process is forked."""
    print("Forking new master process...")

def worker_int(worker):
    """Called when a worker receives the SIGINT or SIGQUIT signal."""
    print(f"Worker received INT or QUIT signal (pid: {worker.pid})")

def worker_abort(worker):
    """Called when a worker receives the SIGABRT signal."""
    print(f"Worker received ABORT signal (pid: {worker.pid})")
