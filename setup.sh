#!/bin/bash

# setup.sh - Google Antigravity CLI (agy) & MCP Setup Script
# Refactored for safety, idempotency, and user convenience.

set -euo pipefail

# Print styled messages
log_info() { echo -e "\e[32m[INFO]\e[0m $1"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

REPO_DIR=$(pwd)
AGY_CLI_DIR="$HOME/.gemini/antigravity-cli"
AGY_CONFIG_DIR="$HOME/.gemini/config"

# 1. Setup Node.js via NVM (Skip if node/npx is already available or NVM is installed)
if command -v node &> /dev/null && command -v npx &> /dev/null; then
    log_info "Node.js and npx are already installed: $(node -v)"
else
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        log_info "NVM is already installed. Loading NVM..."
        # shellcheck disable=SC1090
        . "$HOME/.nvm/nvm.sh"
    else
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        # shellcheck disable=SC1090
        . "$HOME/.nvm/nvm.sh"
    fi
    log_info "Installing Node.js LTS..."
    nvm install --lts &> /dev/null
    nvm use --lts &> /dev/null
    nvm alias default 'lts/*' &> /dev/null
fi

# 2. Install Google Antigravity CLI (agy) if not installed
if command -v agy &> /dev/null; then
    log_info "Google Antigravity CLI (agy) is already installed."
else
    log_info "Installing Google Antigravity CLI (agy)..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

# 3. GitHub Token Input & Validation
GITHUB_TOKEN=""
if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
    log_info "Found GITHUB_PERSONAL_ACCESS_TOKEN in environment."
    GITHUB_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN"
fi

if [ -z "$GITHUB_TOKEN" ]; then
    while [ -z "$GITHUB_TOKEN" ]; do
        read -sp "Enter your GitHub Personal Access Token (input is hidden): " GITHUB_TOKEN
        echo
        if [ -z "$GITHUB_TOKEN" ]; then
            log_error "Token is required. Please try again."
        fi
    done
fi

# 4. Update .bashrc idempotently
update_bashrc() {
    local key="$1"
    local val="$2"
    local line="export $key=\"$val\""
    if grep -q "export $key=" "$HOME/.bashrc"; then
        # Replace existing export
        sed -i -e "s|export $key=.*|$line|g" "$HOME/.bashrc"
    else
        # Append new export
        echo "$line" >> "$HOME/.bashrc"
    fi
}

log_info "Updating ~/.bashrc..."
update_bashrc "GITHUB_PERSONAL_ACCESS_TOKEN" "$GITHUB_TOKEN"
update_bashrc "NO_BROWSER" "true"
update_bashrc "COLORTERM" "truecolor"

# Ensure directories exist
mkdir -p "$AGY_CLI_DIR"
mkdir -p "$AGY_CONFIG_DIR/skills"

# Helper Python script to merge JSON safely without overwriting existing user settings
merge_json() {
    local src="$1"
    local dest="$2"
    local placeholder_key="${3:-}"
    local placeholder_val="${4:-}"
    
    python3 -c "
import json, os, sys
src_path = sys.argv[1]
dest_path = sys.argv[2]
pkey = sys.argv[3] if len(sys.argv) > 3 else None
pval = sys.argv[4] if len(sys.argv) > 4 else None

with open(src_path, 'r') as f:
    src_data = json.load(f)

# Apply placeholder replacements to source data if specified
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
        # If destination JSON is corrupted, backup and start fresh
        os.rename(dest_path, dest_path + '.bak')
        dest_data = {}

# Merge functions
def deep_merge(dict1, dict2):
    for key, val in dict2.items():
        if key in dict1:
            if isinstance(dict1[key], dict) and isinstance(val, dict):
                deep_merge(dict1[key], val)
            elif isinstance(dict1[key], list) and isinstance(val, list):
                # Merge lists, avoiding duplicates
                for item in val:
                    if item not in dict1[key]:
                        dict1[key].append(item)
            else:
                dict1[key] = val
        else:
            dict1[key] = val

deep_merge(dest_data, src_data)

# Ensure current workspace is trusted
if 'trustedWorkspaces' in dest_data:
    ws = dest_data['trustedWorkspaces']
    target_ws = '$REPO_DIR'
    if target_ws not in ws:
        ws.append(target_ws)
    dest_data['trustedWorkspaces'] = ws

with open(dest_path, 'w') as f:
    json.dump(dest_data, f, indent=2)
" "$src" "$dest" "$placeholder_key" "$placeholder_val"
}

# 5. Copy and Merge Configurations
log_info "Merging settings.json..."
merge_json "config/settings.json" "$AGY_CLI_DIR/settings.json" "HOME_DIR_PLACEHOLDER" "$HOME"

log_info "Merging mcp_config.json..."
merge_json "config/mcp_config.json" "$AGY_CLI_DIR/mcp_config.json" "YOUR_GITHUB_TOKEN_HERE" "$GITHUB_TOKEN"

# Copy Agents.md (Create backup if exists)
if [ -f "$AGY_CONFIG_DIR/AGENTS.md" ]; then
    cp "$AGY_CONFIG_DIR/AGENTS.md" "$AGY_CONFIG_DIR/AGENTS.md.bak"
fi
cp config/AGENTS.md "$AGY_CONFIG_DIR/"

# Copy skills
cp -r config/skills/* "$AGY_CONFIG_DIR/skills/"
log_info "Successfully installed skills to $AGY_CONFIG_DIR/skills/"

# 6. Repository Cleanup prompt
echo
read -p "Delete this setup repository directory ($REPO_DIR)? [y/N]: " -r DELETE_REPO
if [[ "$DELETE_REPO" =~ ^[Yy]$ ]]; then
    rm -rf "$REPO_DIR"
    log_info "Repository directory deleted."
else
    log_info "Repository directory kept."
fi

log_info "Setup completed successfully! Please run 'source ~/.bashrc' to apply environment variables."
