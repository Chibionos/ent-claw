#!/bin/bash
# EnterpriseClaw Quick Install
# Installs OpenClaw gateway with EnterpriseClaw branding

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji/symbols
CHECK="✅"
CROSS="❌"
ARROW="➜"
PHONE="📱"
GEAR="⚙️"
ROCKET="🚀"

# Helper functions
log_info() {
    echo -e "${BLUE}${ARROW}${NC} $1"
}

log_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

log_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}${GEAR}${NC} $1"
}

# Check for required commands
check_dependencies() {
    local missing=()

    if ! command -v node &> /dev/null; then
        missing+=("node")
    fi

    if ! command -v npm &> /dev/null; then
        missing+=("npm")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install Node.js (v22+) first:"
        echo "  macOS:   brew install node"
        echo "  Linux:   https://nodejs.org/en/download/"
        exit 1
    fi

    # Check Node version
    local node_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 22 ]; then
        log_warn "Node.js version 22+ recommended (current: $(node -v))"
    fi
}

# Get local IP address
get_local_ip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1
    else
        # Linux
        hostname -I | awk '{print $1}'
    fi
}

# Generate random token
generate_token() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    else
        # Fallback to /dev/urandom
        cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
    fi
}

# Install OpenClaw
install_openclaw() {
    log_info "Installing OpenClaw globally..."

    # Check if already installed
    if command -v openclaw &> /dev/null; then
        local current_version=$(openclaw --version 2>/dev/null || echo "unknown")
        log_warn "OpenClaw already installed (version: $current_version)"
        echo ""
        read -p "Upgrade to latest? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping installation"
            return 0
        fi
    fi

    # Install globally
    if npm install -g openclaw@latest; then
        log_success "OpenClaw installed"
    else
        log_error "Failed to install OpenClaw"
        exit 1
    fi
}

# Initialize OpenClaw config
init_config() {
    log_info "Initializing OpenClaw configuration..."

    # Set gateway mode to local
    if openclaw config set gateway.mode=local 2>/dev/null; then
        log_success "Config initialized (gateway.mode=local)"
    else
        log_warn "Config may already exist"
    fi

    # Restrict channels to mobile app + Slack only
    log_info "Configuring channel restrictions..."
    if openclaw config set 'plugins.allow=["slack"]' 2>/dev/null; then
        log_success "Channels restricted (mobile + Slack only)"
    else
        log_warn "Failed to configure channel restrictions"
    fi
}

# Generate and store gateway token
setup_token() {
    log_info "Generating gateway token..."

    # Check if token already exists
    local existing_token=$(openclaw config get gateway.token 2>/dev/null || echo "")

    if [ -n "$existing_token" ]; then
        log_warn "Gateway token already exists"
        echo ""
        read -p "Generate new token? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "$existing_token"
            return 0
        fi
    fi

    local token=$(generate_token)

    if openclaw config set gateway.token="$token" 2>/dev/null; then
        log_success "Token generated and stored"
        echo "$token"
    else
        log_error "Failed to store token"
        exit 1
    fi
}

# Generate QR code
generate_qr_code() {
    local url="$1"
    local token="$2"
    local display_name="$3"

    # Create JSON payload
    local qr_json=$(cat <<EOF
{"url":"$url","token":"$token","displayName":"$display_name"}
EOF
)

    log_info "Generating QR code..."

    # Check for qrencode
    if command -v qrencode &> /dev/null; then
        echo "$qr_json" | qrencode -t ANSIUTF8
        log_success "QR code generated"
        return 0
    fi

    # Fallback: show JSON for manual QR generation
    log_warn "qrencode not found"
    echo ""
    echo "Install qrencode for ASCII QR codes:"
    echo "  macOS:   brew install qrencode"
    echo "  Linux:   apt install qrencode / yum install qrencode"
    echo ""
    echo "Or generate QR code manually with this JSON:"
    echo ""
    echo "$qr_json"
    echo ""
}

# Display connection info
show_connection_info() {
    local url="$1"
    local token="$2"
    local local_ip="$3"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}${ROCKET} EnterpriseClaw Gateway Installed!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${PHONE} ${CYAN}Scan this QR code with your iOS app:${NC}"
    echo ""

    generate_qr_code "$url" "$token" "EnterpriseClaw Gateway"

    echo ""
    echo -e "${CYAN}Or connect manually:${NC}"
    echo "  URL:   $url"
    echo "  Token: $token"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Start gateway in background
start_gateway() {
    local port="${1:-18789}"

    log_info "Starting EnterpriseClaw gateway on port $port..."

    # Check if already running
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warn "Gateway already running on port $port"
        echo ""
        read -p "Restart gateway? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing gateway"
            return 0
        fi

        # Kill existing process
        log_info "Stopping existing gateway..."
        pkill -f "openclaw gateway run" || true
        sleep 2
    fi

    # Start gateway in background
    nohup openclaw gateway run --bind 0.0.0.0 --port "$port" > /tmp/openclaw-gateway.log 2>&1 &
    local pid=$!

    # Wait a moment and verify it started
    sleep 2

    if ps -p $pid > /dev/null 2>&1; then
        log_success "Gateway started (PID: $pid)"
        echo ""
        echo "Logs: tail -f /tmp/openclaw-gateway.log"
        echo "Stop: pkill -f 'openclaw gateway run'"
        return 0
    else
        log_error "Gateway failed to start"
        echo ""
        echo "Check logs: tail -f /tmp/openclaw-gateway.log"
        exit 1
    fi
}

# Main installation flow
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}${ROCKET} EnterpriseClaw Gateway Installer${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Step 1: Check dependencies
    log_info "Checking dependencies..."
    check_dependencies
    log_success "Dependencies OK"
    echo ""

    # Step 2: Install OpenClaw
    install_openclaw
    echo ""

    # Step 3: Initialize config
    init_config
    echo ""

    # Step 4: Setup token
    local token=$(setup_token)
    echo ""

    # Step 5: Get connection details
    local port="${GATEWAY_PORT:-18789}"
    local local_ip=$(get_local_ip)
    local url="ws://${local_ip}:${port}"

    # Step 6: Show connection info
    show_connection_info "$url" "$token" "$local_ip"

    # Step 7: Ask to start gateway
    echo ""
    read -p "Start gateway now? [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        start_gateway "$port"
    else
        log_info "Skipped gateway start"
        echo ""
        echo "Start manually:"
        echo "  openclaw gateway run --bind 0.0.0.0 --port $port"
    fi

    echo ""
    echo -e "${GREEN}${CHECK} Installation complete!${NC}"
    echo ""
}

# Run main
main "$@"
