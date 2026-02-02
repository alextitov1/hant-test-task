#!/bin/bash

###############################################################################
# EC2 Instance Info - Deployment Script
# 
# This script automates the deployment of the FastAPI application on an
# AWS EC2 instance running Ubuntu.
#
# Usage: sudo bash deploy.sh
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="ec2-instance-info"
APP_DIR="/opt/${APP_NAME}"
APP_USER="ubuntu"
VENV_DIR="${APP_DIR}/venv"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

install_system_dependencies() {
    print_info "Installing system dependencies..."
    apt-get update
    apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        nginx \
        git \
        curl
    print_info "System dependencies installed successfully"
}

create_app_directory() {
    print_info "Creating application directory..."
    mkdir -p "${APP_DIR}"
    mkdir -p "${APP_DIR}/app/templates"
    mkdir -p /var/log/gunicorn
    mkdir -p /var/run/gunicorn
}

setup_python_environment() {
    print_info "Setting up Python virtual environment..."
    python3 -m venv "${VENV_DIR}"
    source "${VENV_DIR}/bin/activate"
    pip install --upgrade pip
    print_info "Python virtual environment created"
}

install_python_dependencies() {
    print_info "Installing Python dependencies..."
    source "${VENV_DIR}/bin/activate"
    
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        print_info "Python dependencies installed successfully"
    else
        print_error "requirements.txt not found!"
        exit 1
    fi
}

copy_application_files() {
    print_info "Copying application files..."
    
    # Copy application code
    cp -r app/* "${APP_DIR}/app/"
    cp gunicorn.conf.py "${APP_DIR}/"
    
    # Set proper permissions
    chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"
    chown -R "${APP_USER}:${APP_USER}" /var/log/gunicorn
    chown -R "${APP_USER}:${APP_USER}" /var/run/gunicorn
    
    print_info "Application files copied successfully"
}

create_systemd_service() {
    print_info "Creating systemd service..."
    
    cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=EC2 Instance Info FastAPI Application
After=network.target

[Service]
Type=notify
User=${APP_USER}
Group=${APP_USER}
RuntimeDirectory=gunicorn
WorkingDirectory=${APP_DIR}
Environment="PATH=${VENV_DIR}/bin"
ExecStart=${VENV_DIR}/bin/gunicorn -c ${APP_DIR}/gunicorn.conf.py app.main:app
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_info "Systemd service created successfully"
}

configure_nginx() {
    print_info "Configuring Nginx..."
    
    # Backup default config if it exists
    if [ -f /etc/nginx/sites-enabled/default ]; then
        mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.backup
    fi
    
    # Copy Nginx configuration
    cp nginx.conf "/etc/nginx/sites-available/${APP_NAME}"
    ln -sf "/etc/nginx/sites-available/${APP_NAME}" "/etc/nginx/sites-enabled/${APP_NAME}"
    
    # Test Nginx configuration
    nginx -t
    
    print_info "Nginx configured successfully"
}

start_services() {
    print_info "Starting services..."
    
    # Start and enable application service
    systemctl enable "${APP_NAME}"
    systemctl start "${APP_NAME}"
    
    # Restart Nginx
    systemctl restart nginx
    
    print_info "Services started successfully"
}

check_service_status() {
    print_info "Checking service status..."
    
    if systemctl is-active --quiet "${APP_NAME}"; then
        print_info "✓ ${APP_NAME} service is running"
    else
        print_error "✗ ${APP_NAME} service is not running"
        systemctl status "${APP_NAME}"
    fi
    
    if systemctl is-active --quiet nginx; then
        print_info "✓ Nginx service is running"
    else
        print_error "✗ Nginx service is not running"
        systemctl status nginx
    fi
}

display_completion_message() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    print_info "Deployment completed successfully!"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Application is now running at:"
    echo "  • http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
    echo "  • http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
    echo ""
    echo "Useful commands:"
    echo "  • Check status:  sudo systemctl status ${APP_NAME}"
    echo "  • View logs:     sudo journalctl -u ${APP_NAME} -f"
    echo "  • Restart app:   sudo systemctl restart ${APP_NAME}"
    echo "  • Restart nginx: sudo systemctl restart nginx"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# Main execution
main() {
    print_info "Starting deployment of ${APP_NAME}..."
    
    check_root
    install_system_dependencies
    create_app_directory
    setup_python_environment
    install_python_dependencies
    copy_application_files
    create_systemd_service
    configure_nginx
    start_services
    check_service_status
    display_completion_message
}

# Run main function
main
