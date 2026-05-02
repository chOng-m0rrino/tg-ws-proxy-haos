#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "🚀 TG WS Proxy — starting..."

CACHE_DIR="/data/tg-ws-proxy"
VERSION_FILE="$CACHE_DIR/.version"
ARCH_FILE="$CACHE_DIR/.arch"
METHOD_FILE="$CACHE_DIR/.method"
LAST_CHECK_FILE="$CACHE_DIR/.last_check"
UPDATE_LOCK_FILE="$CACHE_DIR/.update_lock"
SRC_DIR="$CACHE_DIR/src"
VENV_DIR="$CACHE_DIR/venv"
INSTALLED_FLAG="$CACHE_DIR/.installed"

GITHUB_REPO="Flowseal/tg-ws-proxy"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO/releases/latest"

HOST=$(bashio::config 'host')
PORT=$(bashio::config 'port')
CONFIG_SECRET=$(bashio::config 'secret')
AUTO_UPDATE=$(bashio::config 'auto_update' 2>/dev/null || true)
DEBUG=$(bashio::config 'debug' 2>/dev/null || false)
NO_CFPROXY=$(bashio::config 'no_cfproxy' 2>/dev/null || false)
CFPROXY_DOMAIN=$(bashio::config 'cfproxy_domain' 2>/dev/null || "")
CFPROXY_PRIORITY=$(bashio::config 'cfproxy_priority' 2>/dev/null || true)
FAKE_TLS_DOMAIN=$(bashio::config 'fake_tls_domain' 2>/dev/null || "")
PROXY_PROTOCOL=$(bashio::config 'proxy_protocol' 2>/dev/null || false)
BUF_KB=$(bashio::config 'buf_kb' 2>/dev/null || 256)
POOL_SIZE=$(bashio::config 'pool_size' 2>/dev/null || 4)

RAW_ARCH=$(uname -m)
case "$RAW_ARCH" in
    aarch64|arm64)  ARCH="aarch64" ;;
    x86_64|amd64)   ARCH="amd64" ;;
    *)
        bashio::log.error "Unsupported architecture: $RAW_ARCH"
        exit 1
        ;;
esac

debug_log() { [[ "$DEBUG" == "true" ]] && bashio::log.info "[DEBUG] $*" || true; }

ensure_utils() {
    command -v curl &>/dev/null || apk add --no-cache -q curl 2>/dev/null || true
    command -v jq &>/dev/null || apk add --no-cache -q jq 2>/dev/null || true
    command -v xxd &>/dev/null || apk add --no-cache -q xxd 2>/dev/null || true
}

get_latest_version() {
    ensure_utils
    local tag=$(curl -fsSL "$GITHUB_API" 2>/dev/null | jq -r '.tag_name // empty' 2>/dev/null)
    [[ -n "$tag" && "$tag" != "null" ]] && echo "$tag" | sed 's/^v//' || echo "unknown"
}

download_binary() {
    local version=$1
    local url="https://github.com/$GITHUB_REPO/releases/download/v${version}/TgWsProxy_linux_amd64"
    bashio::log.info "⬇️ Downloading TgWsProxy v${version} (binary)..."
    if curl -fsSL -o "$CACHE_DIR/tg-ws-proxy.tmp" "$url" 2>/dev/null; then
        chmod +x "$CACHE_DIR/tg-ws-proxy.tmp"
        mv "$CACHE_DIR/tg-ws-proxy.tmp" "$CACHE_DIR/tg-ws-proxy"
        echo "$version" > "$VERSION_FILE"
        echo "amd64" > "$ARCH_FILE"
        echo "binary" > "$METHOD_FILE"
        return 0
    else
        rm -f "$CACHE_DIR/tg-ws-proxy.tmp"
        return 1
    fi
}

install_via_pip() {
    bashio::log.info "Installing TG WS Proxy..."
    ensure_utils
	
    export CRYPTOGRAPHY_DONT_BUILD_RUST=1
    export PIP_CACHE_DIR="$CACHE_DIR/pip_cache"
    mkdir -p "$PIP_CACHE_DIR"
    
    [[ "$ARCH" == "aarch64" ]] && export CFLAGS="-O2 -pipe -march=armv8-a"
    [[ "$ARCH" == "amd64" ]] && export CFLAGS="-O2 -pipe -march=x86-64-v2"
    
    local tarball_url=$(curl -fsSL "$GITHUB_API" 2>/dev/null | jq -r '.tarball_url // empty' 2>/dev/null)
    local latest_ver=$(get_latest_version)
    if [[ -z "$tarball_url" || "$tarball_url" == "null" || "$latest_ver" == "unknown" ]]; then
        bashio::log.error "Failed to fetch release info"
        return 1
    fi
	debug_log "Release info: v${latest_ver}"
    
    rm -rf "$SRC_DIR" && mkdir -p "$SRC_DIR"
    curl -fsSL "$tarball_url" | tar -xz -C "$SRC_DIR" --strip-components=1 2>/dev/null || {
        bashio::log.error "Failed to download source"; return 1
    }
    debug_log "Source extracted to $SRC_DIR"
	
	[[ ! -f "$SRC_DIR/pyproject.toml" ]] && { bashio::log.error "pyproject.toml not found"; return 1; }
    
    cd "$SRC_DIR" || return 1
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR" || { bashio::log.error "Failed to create venv"; return 1; }
    source "$VENV_DIR/bin/activate" || { bashio::log.error "Failed to activate venv"; return 1; }
    pip install --upgrade pip -q
    
    if ! pip install --prefer-binary --use-feature=fast-deps -q -e . 2>/dev/null; then
        debug_log "First attempt failed, retrying with --no-build-isolation"
        pip install --prefer-binary --no-build-isolation -q -e . || {
            bashio::log.error "Pip installation failed"
            return 1
        }
    fi
    
    local installed_ver=$(pip show tg-ws-proxy 2>/dev/null | grep "^Version:" | awk '{print $2}')
    bashio::log.info "Installation successful (v${installed_ver:-$latest_ver})"
	
    mkdir -p "$CACHE_DIR"
    touch "$INSTALLED_FLAG"
    echo "$latest_ver" > "$VERSION_FILE"
    echo "$ARCH" > "$ARCH_FILE"
    echo "pip" > "$METHOD_FILE"
    date +%s > "$LAST_CHECK_FILE"
    ln -sf "$VENV_DIR/bin/tg-ws-proxy" /usr/local/bin/tg-ws-proxy 2>/dev/null || true
    return 0
}

ensure_installed() {
    mkdir -p "$CACHE_DIR"
    local remote_ver=$(get_latest_version)
    local local_ver=$(cat "$VERSION_FILE" 2>/dev/null || echo "none")
    local local_arch=$(cat "$ARCH_FILE" 2>/dev/null || echo "none")
    local local_method=$(cat "$METHOD_FILE" 2>/dev/null || echo "none")
    
    if [[ "$local_arch" != "none" && "$local_arch" != "$ARCH" ]]; then
        rm -f "$CACHE_DIR/tg-ws-proxy" "$INSTALLED_FLAG" "$VERSION_FILE" "$ARCH_FILE" "$METHOD_FILE"
        rm -rf "$VENV_DIR"
        local_ver="none"
    fi
    
    if [[ "$ARCH" == "amd64" ]]; then
        if [[ ! -x "$CACHE_DIR/tg-ws-proxy" || "$local_ver" != "$remote_ver" || "$local_method" != "binary" ]]; then
            if ! download_binary "$remote_ver"; then
                bashio::log.warning "Binary download failed, falling back to pip..."
                install_via_pip || exit 1
            fi
        else
            bashio::log.info "TG WS Proxy v${local_ver} (amd64/binary) ready"
        fi
        return 0
    fi
    
    if [[ -f "$INSTALLED_FLAG" && -d "$VENV_DIR" && "$local_ver" == "$remote_ver" ]]; then
        bashio::log.info "✅ TG WS Proxy v${local_ver}"
        source "$VENV_DIR/bin/activate"
        return 0
    fi
    install_via_pip || exit 1
    source "$VENV_DIR/bin/activate"
}

hex_encode() {
    ensure_utils
    echo -n "$1" | xxd -p -c 256 | tr -d '\n'
}

generate_ee_secret() {
    local domain="$1" base_secret="$2"
    echo "ee${base_secret}$(hex_encode "$domain")"
}

generate_temporary_secret() {
    local secret=$(openssl rand -hex 16)
    bashio::log.info "🔑 Generated temporary key (not persisted)"
    debug_log "New secret: $secret"
    echo "$secret"
}

cleanup() {
    rm -f "$UPDATE_LOCK_FILE"
    kill %1 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT SIGHUP

mkdir -p "$CACHE_DIR"
rm -f "$UPDATE_LOCK_FILE"

ensure_installed

SECRET=""
SECRET_IS_TEMPORARY=false
if ! bashio::var.is_empty "$CONFIG_SECRET"; then
    SECRET="$CONFIG_SECRET"
    bashio::log.info "🔑 Using key from configuration"
else
    SECRET=$(generate_temporary_secret)
    SECRET_IS_TEMPORARY=true
fi

if [[ -n "$FAKE_TLS_DOMAIN" ]]; then
    if [[ ! "$FAKE_TLS_DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
        bashio::log.error "Invalid domain: $FAKE_TLS_DOMAIN"
        exit 1
    fi
    bashio::log.info "Domain validated: $FAKE_TLS_DOMAIN"
fi

DC_ARGS=""
if [[ -f /data/options.json ]]; then
    while IFS= read -r dc; do
        [[ -n "$dc" && "$dc" != "null" ]] && DC_ARGS="$DC_ARGS --dc-ip $dc"
    done < <(jq -r '.dc_ip[]' /data/options.json 2>/dev/null || true)
fi

EXTRA_ARGS=""
[[ "$DEBUG" == "true" ]] && EXTRA_ARGS="$EXTRA_ARGS -v"
[[ "$NO_CFPROXY" == "true" ]] && EXTRA_ARGS="$EXTRA_ARGS --no-cfproxy"
[[ -n "$CFPROXY_DOMAIN" ]] && EXTRA_ARGS="$EXTRA_ARGS --cfproxy-domain $CFPROXY_DOMAIN"
bashio::var.false "$CFPROXY_PRIORITY" && EXTRA_ARGS="$EXTRA_ARGS --cfproxy-priority false"
[[ -n "$FAKE_TLS_DOMAIN" ]] && EXTRA_ARGS="$EXTRA_ARGS --fake-tls-domain $FAKE_TLS_DOMAIN"
[[ "$PROXY_PROTOCOL" == "true" ]] && EXTRA_ARGS="$EXTRA_ARGS --proxy-protocol"
EXTRA_ARGS="$EXTRA_ARGS --buf-kb $BUF_KB --pool-size $POOL_SIZE"

if [[ "$HOST" == "0.0.0.0" ]]; then
    LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $NF; exit}')
    [[ -z "$LOCAL_IP" ]] && LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    LOCAL_IP=${LOCAL_IP:-unknown}
else
    LOCAL_IP="$HOST"
fi
debug_log "Local IP: $LOCAL_IP (Config: $HOST)"

if [[ -n "$FAKE_TLS_DOMAIN" ]]; then
    EE_SECRET=$(generate_ee_secret "$FAKE_TLS_DOMAIN" "$SECRET")
    bashio::log.info "🔗 Fake TLS: tg://proxy?server=$FAKE_TLS_DOMAIN&port=443&secret=$EE_SECRET"
    bashio::log.info "📌 Direct: tg://proxy?server=$LOCAL_IP&port=$PORT&secret=$SECRET"
else
    bashio::log.info "🔗 Link: tg://proxy?server=$LOCAL_IP&port=$PORT&secret=$SECRET"
fi

if [[ -n "$FAKE_TLS_DOMAIN" ]]; then
    bashio::log.info ""
    bashio::log.info "   Fake TLS requirements:"
    bashio::log.info "   1. $FAKE_TLS_DOMAIN → your server IP"
    bashio::log.info "   2. Port 443 accessible"
    bashio::log.info "   3. nginx: stream { listen 443; proxy_pass 127.0.0.1:$PORT; ssl_preread on; proxy_protocol on; }"
    [[ "$PROXY_PROTOCOL" != "true" ]] && bashio::log.warning "    Enable proxy_protocol for nginx"
    bashio::log.info ""
fi

[[ "$SECRET_IS_TEMPORARY" == "true" ]] && bashio::log.info "ℹ️ Temporary secret: $SECRET (set 'secret' in config to persist)"

background_update_check() {
    while true; do
        sleep 86400
		#sleep 20 #test
        ensure_utils
        if [[ -f "$UPDATE_LOCK_FILE" ]]; then
            local lock_time=$(stat -c %Y "$UPDATE_LOCK_FILE" 2>/dev/null || echo 0)
            local now=$(date +%s)
            if [[ $((now - lock_time)) -lt 300 ]]; then
                debug_log "Update lock active, skipping"
                continue
            fi
            bashio::log.warning "Stale lock detected, removing..."
            rm -f "$UPDATE_LOCK_FILE"
        fi
        touch "$UPDATE_LOCK_FILE"
        local local_ver=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")
        local remote_ver=$(get_latest_version)
		#local remote_ver="1.0.0"  # Test
        local method=$(cat "$METHOD_FILE" 2>/dev/null || echo "unknown")
        
        debug_log "Background update: local=v${local_ver}, remote=v${remote_ver}"
        
        if [[ "$remote_ver" != "unknown" && "$local_ver" != "$remote_ver" ]]; then
            bashio::log.info "Update available: v${remote_ver} (installed: v${local_ver})"
            if [[ "$AUTO_UPDATE" == "true" ]]; then
                local success=false
                if [[ "$method" == "binary" && "$ARCH" == "amd64" ]]; then
                    download_binary "$remote_ver" && success=true
                else
                    install_via_pip && success=true
                fi
                if $success; then
                    bashio::log.info "Update applied, restarting..."
                    rm -f "$UPDATE_LOCK_FILE"
                    bashio::addon.restart
                else
                    bashio::log.error "Update failed"
                    bashio::log.info "Continuing with v${local_ver}"
                    rm -f "$UPDATE_LOCK_FILE"
                fi
            else
                bashio::log.warning "Auto-update disabled"
                rm -f "$UPDATE_LOCK_FILE"
            fi
        else
            debug_log "No updates (local: v${local_ver}, remote: v${remote_ver})"
            rm -f "$UPDATE_LOCK_FILE"
        fi
        date +%s > "$LAST_CHECK_FILE"
    done
}

debug_log "tg-ws-proxy --host $HOST --port $PORT --secret *** $DC_ARGS $EXTRA_ARGS"

if [[ "$AUTO_UPDATE" == "true" ]]; then
    debug_log "Background update active (24h interval)"
    background_update_check &
fi

if [[ "$(cat "$METHOD_FILE" 2>/dev/null)" == "binary" && -x "$CACHE_DIR/tg-ws-proxy" ]]; then
    exec "$CACHE_DIR/tg-ws-proxy" --host "$HOST" --port "$PORT" --secret "$SECRET" $DC_ARGS $EXTRA_ARGS
else
    exec tg-ws-proxy --host "$HOST" --port "$PORT" --secret "$SECRET" $DC_ARGS $EXTRA_ARGS
fi