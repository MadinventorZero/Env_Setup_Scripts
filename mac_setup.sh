#!/bin/bash

# Setup a script for macOS environment
# Configure Github, Homebrew, Bash profile, NVM, and Node.js
# Provide prompts for user input where necessary with valid default options for a standard configuration

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

prompt_with_default() {
    local prompt_text="$1"
    local default_value="$2"
    local user_input=""
    
    read -p "$prompt_text (default: $default_value): " user_input
    echo "${user_input:-$default_value}"
}

prompt_yes_no() {
    local prompt_text="$1"
    local default_value="${2:-y}"
    local response=""
    
    if [[ "$default_value" == "y" ]]; then
        read -p "$prompt_text (Y/n): " response
        response="${response:-y}"
    else
        read -p "$prompt_text (y/N): " response
        response="${response:-n}"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

print_header "macOS Development Environment Setup"
echo "This script will configure your macOS environment for development."
echo "You'll be prompted for configuration options with sensible defaults."

# ============================================================================
# 1. HOMEBREW SETUP
# ============================================================================
print_header "Step 1: Homebrew Installation"

if command -v brew &> /dev/null; then
    print_success "Homebrew is already installed"
    if prompt_yes_no "Update Homebrew?"; then
        brew update
        print_success "Homebrew updated"
    fi
else
    if prompt_yes_no "Install Homebrew?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew installed"
    else
        print_warning "Homebrew installation skipped"
    fi
fi

# ============================================================================
# 2. GITHUB CONFIGURATION
# ============================================================================
print_header "Step 2: GitHub Configuration"

if prompt_yes_no "Configure GitHub?"; then
    # Get current git config values
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    git_name=$(prompt_with_default "GitHub name" "${current_name:-John Doe}")
    git_email=$(prompt_with_default "GitHub email" "${current_email:-you@example.com}")
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    # Configure git settings
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    
    print_success "GitHub configured"
    echo -e "  Name: $git_name"
    echo -e "  Email: $git_email"
    
    # SSH key setup
    if prompt_yes_no "Setup GitHub SSH key?"; then
        ssh_key_path="$HOME/.ssh/id_ed25519"
        
        if [[ -f "$ssh_key_path" ]]; then
            print_warning "SSH key already exists at $ssh_key_path"
        else
            ssh_key_email=$(prompt_with_default "SSH key email" "$git_email")
            ssh-keygen -t ed25519 -C "$ssh_key_email" -f "$ssh_key_path" -N ""
            
            # Add to SSH agent
            eval "$(ssh-agent -s)"
            ssh-add --apple-use-keychain "$ssh_key_path"
            
            print_success "SSH key created"
            echo -e "\n${YELLOW}Add this key to GitHub:${NC}"
            cat "$ssh_key_path.pub"
            echo ""
        fi
    fi
else
    print_warning "GitHub configuration skipped"
fi

# ============================================================================
# 3. NVM AND NODE.JS SETUP
# ============================================================================
print_header "Step 3: NVM and Node.js Installation"

# Check for existing NVM installation
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    print_success "NVM is already installed"
    source "$HOME/.nvm/nvm.sh"
else
    if prompt_yes_no "Install NVM (Node Version Manager)?"; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # Source NVM in current session
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
        
        print_success "NVM installed"
    else
        print_warning "NVM installation skipped"
        exit 0
    fi
fi

# Install Node.js
if command -v node &> /dev/null; then
    current_node_version=$(node -v)
    print_success "Node.js is already installed: $current_node_version"
    
    if prompt_yes_no "Install a different Node.js version?"; then
        node_version=$(prompt_with_default "Node.js version" "lts/iron")
        nvm install "$node_version"
        nvm use "$node_version"
        print_success "Node.js $node_version installed and activated"
    fi
else
    node_version=$(prompt_with_default "Node.js version to install" "lts/iron")
    nvm install "$node_version"
    nvm use "$node_version"
    nvm alias default "$node_version"
    print_success "Node.js $node_version installed"
fi

# ============================================================================
# 4. BASH PROFILE CONFIGURATION
# ============================================================================
print_header "Step 4: Bash Profile Configuration"

bash_profile="$HOME/.bash_profile"
zsh_profile="$HOME/.zshrc"

# Detect shell
if [[ -n "$ZSH_VERSION" ]]; then
    shell_profile="$zsh_profile"
    shell_name="zsh"
else
    shell_profile="$bash_profile"
    shell_name="bash"
fi

# Create bash profile if it doesn't exist
if [[ ! -f "$bash_profile" ]]; then
    touch "$bash_profile"
    print_success "Created $bash_profile"
fi

# Create zsh profile if it doesn't exist
if [[ ! -f "$zsh_profile" ]]; then
    touch "$zsh_profile"
    print_success "Created $zsh_profile"
fi

# Add NVM to profiles
nvm_config='
# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
'

# Check and add to bash_profile
if ! grep -q "NVM_DIR" "$bash_profile"; then
    echo "$nvm_config" >> "$bash_profile"
    print_success "NVM configuration added to $bash_profile"
fi

# Check and add to zsh profile
if ! grep -q "NVM_DIR" "$zsh_profile"; then
    echo "$nvm_config" >> "$zsh_profile"
    print_success "NVM configuration added to $zsh_profile"
fi

# Add useful aliases and functions
aliases_config='
# Development Aliases
alias ll="ls -lah"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline -10"
'

if ! grep -q "Development Aliases" "$bash_profile"; then
    echo "$aliases_config" >> "$bash_profile"
    print_success "Development aliases added to $bash_profile"
fi

if ! grep -q "Development Aliases" "$zsh_profile"; then
    echo "$aliases_config" >> "$zsh_profile"
    print_success "Development aliases added to $zsh_profile"
fi

# ============================================================================
# 5. OPTIONAL DEVELOPMENT TOOLS
# ============================================================================
print_header "Step 5: Optional Development Tools"

if prompt_yes_no "Install additional development tools (git, curl, wget)?"; then
    brew install git curl wget
    print_success "Development tools installed"
fi

if prompt_yes_no "Install Node package manager alternatives (yarn, pnpm)?"; then
    npm install -g yarn pnpm
    print_success "Package managers installed"
fi

if prompt_yes_no "Install code formatter (prettier)?"; then
    npm install -g prettier
    print_success "Prettier installed globally"
fi

# ============================================================================
# COMPLETION
# ============================================================================
print_header "Setup Complete!"

echo -e "${GREEN}Your macOS development environment has been configured!${NC}\n"
echo "Summary of installed/configured tools:"
echo "  • Homebrew: $(brew --version | head -n1)"
echo "  • Git: $(git --version)"
echo "  • Node.js: $(node -v)"
echo "  • npm: $(npm -v)"

if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    echo "  • NVM: installed"
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Reload your shell: source $shell_profile"
echo "2. Verify Node.js: node -v && npm -v"
echo "3. Clone your repositories and start coding!"

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    echo -e "\n${YELLOW}SSH Key Tip:${NC}"
    echo "Your SSH key has been created. Add it to GitHub at:"
    echo "https://github.com/settings/keys"
fi

echo ""
