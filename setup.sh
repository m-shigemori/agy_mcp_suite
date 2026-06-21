#!/bin/bash

set -euo pipefail

log_info() { echo -e "\e[32m[INFO]\e[0m $1"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
AGY_CLI_DIR="$HOME/.gemini/antigravity-cli"
AGY_CONFIG_DIR="$HOME/.gemini/config"

ASSUME_YES=false
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -y, --yes     Non-interactive mode (automatically accept prompts)"
    echo "  -h, --help    Show this message"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            ASSUME_YES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

check_prereq() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command '$cmd' is not installed. Please install it and try again."
        exit 1
    fi
}
check_prereq "curl"
check_prereq "python3"

if command -v node &> /dev/null && command -v npx &> /dev/null; then
    log_info "Node.js and npx are already installed: $(node -v)"
else
    set +eu
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        log_info "NVM is already installed. Loading NVM..."
        . "$HOME/.nvm/nvm.sh"
    else
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        . "$HOME/.nvm/nvm.sh"
    fi
    log_info "Installing Node.js LTS..."
    nvm install --lts &> /dev/null
    nvm use --lts &> /dev/null
    nvm alias default 'lts/*' &> /dev/null
    set -eu
fi

if command -v agy &> /dev/null; then
    log_info "Google Antigravity CLI (agy) is already installed."
else
    log_info "Installing Google Antigravity CLI (agy)..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

validate_github_token() {
    local token="$1"
    if [ -z "$token" ]; then
        return 1
    fi

    if [[ ! "$token" =~ ^gh[p|o|u|r]_[a-zA-Z0-9]{36,255}$ ]] && [[ ${#token} -lt 40 ]]; then
        log_warn "Token format does not match typical GitHub Personal Access Token patterns."
    fi

    log_info "Verifying GitHub token validity via API..."
    local http_status
    http_status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $token" https://api.github.com/user)

    if [ "$http_status" -eq 200 ]; then
        log_info "GitHub token verified successfully."
        return 0
    else
        log_error "GitHub API returned HTTP status $http_status. Token may be invalid or expired."
        return 1
    fi
}

GITHUB_TOKEN=""
if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
    log_info "Found GITHUB_PERSONAL_ACCESS_TOKEN in environment."
    if validate_github_token "$GITHUB_PERSONAL_ACCESS_TOKEN"; then
        GITHUB_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN"
    else
        log_warn "Environment GITHUB_PERSONAL_ACCESS_TOKEN is invalid."
    fi
fi

if [ -z "$GITHUB_TOKEN" ]; then
    if [ "$ASSUME_YES" = true ]; then
        log_error "GitHub Token is required but missing or invalid in non-interactive mode."
        exit 1
    fi

    while [ -z "$GITHUB_TOKEN" ]; do
        read -sp "Enter your GitHub Personal Access Token (input is hidden): " GITHUB_TOKEN
        echo
        if [ -z "$GITHUB_TOKEN" ]; then
            log_error "Token is required. Please try again."
        else
            if ! validate_github_token "$GITHUB_TOKEN"; then
                log_warn "Token validation failed."
                read -p "Proceed with this token anyway? [y/N]: " -r PROCEED
                if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
                    GITHUB_TOKEN=""
                fi
            fi
        fi
    done
fi

update_bashrc() {
    local key="$1"
    local val="$2"
    local line="export $key=\"$val\""
    
    touch "$HOME/.bashrc"
    
    if [ ! -f "$HOME/.bashrc.bak" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
        log_info "Created backup of ~/.bashrc at ~/.bashrc.bak"
    fi

    if grep -q "export $key=" "$HOME/.bashrc"; then
        sed "s|export $key=.*|$line|g" "$HOME/.bashrc" > "$HOME/.bashrc.tmp" && mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
    else
        echo "$line" >> "$HOME/.bashrc"
    fi
}

log_info "Updating ~/.bashrc..."
update_bashrc "GITHUB_PERSONAL_ACCESS_TOKEN" "$GITHUB_TOKEN"
update_bashrc "NO_BROWSER" "true"
update_bashrc "COLORTERM" "truecolor"

mkdir -p "$AGY_CLI_DIR"
mkdir -p "$AGY_CONFIG_DIR/skills"

merge_json() {
    local src="$1"
    local dest="$2"
    local placeholder_key="${3:-}"
    local placeholder_val="${4:-}"
    
    python3 - "$src" "$dest" "$placeholder_key" "$placeholder_val" "$REPO_DIR" << 'EOF'
import json
import os
import sys

src_path = sys.argv[1]
dest_path = sys.argv[2]
pkey = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else None
pval = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None
repo_dir = sys.argv[5] if len(sys.argv) > 5 else ""

with open(src_path, 'r') as f:
    src_data = json.load(f)

if pkey and pval:
    def replace_val(obj):
        if isinstance(obj, dict):
            return {k: replace_val(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [replace_val(x) for x in obj]
        elif isinstance(obj, str):
            return obj.replace(pkey, pval)
        return obj
    src_data = replace_val(src_data)

dest_data = {}
if os.path.exists(dest_path):
    try:
        with open(dest_path, 'r') as f:
            dest_data = json.load(f)
    except Exception:
        os.rename(dest_path, dest_path + '.bak')
        dest_data = {}

def deep_merge(dict1, dict2):
    for key, val in dict2.items():
        if key in dict1:
            if isinstance(dict1[key], dict) and isinstance(val, dict):
                deep_merge(dict1[key], val)
            elif isinstance(dict1[key], list) and isinstance(val, list):
                for item in val:
                    if item not in dict1[key]:
                        dict1[key].append(item)
            else:
                dict1[key] = val
        else:
            dict1[key] = val

deep_merge(dest_data, src_data)

if 'trustedWorkspaces' in dest_data:
    ws = dest_data['trustedWorkspaces']
    target_ws = repo_dir
    if target_ws and target_ws not in ws:
        ws.append(target_ws)
    dest_data['trustedWorkspaces'] = ws

with open(dest_path, 'w') as f:
    json.dump(dest_data, f, indent=2)
EOF
}

log_info "Merging settings.json..."
merge_json "config/settings.json" "$AGY_CLI_DIR/settings.json" "HOME_DIR_PLACEHOLDER" "$HOME"

log_info "Merging mcp_config.json..."
merge_json "config/mcp_config.json" "$AGY_CLI_DIR/mcp_config.json" "YOUR_GITHUB_TOKEN_HERE" "$GITHUB_TOKEN"

if [ -f "$AGY_CONFIG_DIR/AGENTS.md" ]; then
    cp "$AGY_CONFIG_DIR/AGENTS.md" "$AGY_CONFIG_DIR/AGENTS.md.bak"
fi
cp config/AGENTS.md "$AGY_CONFIG_DIR/"

cp -r config/skills/* "$AGY_CONFIG_DIR/skills/"
log_info "Successfully installed skills to $AGY_CONFIG_DIR/skills/"

echo
if [ "$ASSUME_YES" = true ]; then
    log_info "Automatically deleting setup repository directory ($REPO_DIR)..."
    rm -rf "$REPO_DIR"
    log_info "Repository directory deleted."
else
    read -p "Delete this setup repository directory ($REPO_DIR)? [y/N]: " -r DELETE_REPO
    if [[ "$DELETE_REPO" =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_DIR"
        log_info "Repository directory deleted."
    else
        log_info "Repository directory kept."
    fi
fi

log_info "Setup completed successfully! Please run 'source ~/.bashrc' to apply environment variables."
