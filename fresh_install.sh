#!/bin/bash

# Exit on any error
set -e

# Error handling function
handle_error() {
    echo "Error occurred in script at line $1"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Check if running as root (which we don't want)
if [ "$(id -u)" = "0" ]; then
    echo "This script should not be run as root"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check package manager
check_package_manager() {
    if command_exists apt; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    else
        echo "Unsupported package manager"
        exit 1
    fi
}

# Function to install packages based on package manager
install_packages() {
    local pkg_manager=$(check_package_manager)
    case $pkg_manager in
        "apt")
            sudo apt update
            sudo apt install -y git vim tmux curl zsh python3 flatpak
            ;;
        "dnf"|"yum")
            sudo $pkg_manager update -y
            sudo $pkg_manager install -y git vim tmux curl zsh python3 flatpak
            ;;
        *)
            echo "Unsupported package manager"
            exit 1
            ;;
    esac
}

# Function to create or append to a file with backup
append_or_create() {
    local file="$1"
    local content="$2"
    
    # Create backup if file exists
    if [ -f "$file" ]; then
        echo "Creating backup of $file"
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$file")"
    
    if [ -f "$file" ]; then
        echo "Appending to $file"
        echo "$content" >> "$file"
    else
        echo "Creating $file"
        echo "$content" > "$file"
    fi
}

# Install packages
echo "Installing required packages..."
install_packages

# Install Oh My Zsh with error handling
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        export RUNZSH=no  # Prevent automatic zsh switch
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Oh My Zsh already installed"
    fi
}

install_oh_my_zsh

# Vim configuration
vim_config="
set laststatus=2
set t_Co=256
set number
syntax on
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent! loadview
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')
  Plug 'vim-airline/vim-airline'
  Plug 'morhetz/gruvbox'
  Plug 'mattn/emmet-vim'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-sensible'
  Plug 'junegunn/seoul256.vim'
call plug#end()
"
append_or_create "$HOME/.vimrc" "$vim_config"

# Tmux configuration
install_tmux_config() {
    local temp_dir=$(mktemp -d)
    echo "Cloning tmux config to $temp_dir"
    if git clone https://github.com/jiimothy/tmux_config.git "$temp_dir"; then
        if [ -f "$temp_dir/tmux_config.sh" ]; then
            chmod +x "$temp_dir/tmux_config.sh"
            (cd "$temp_dir" && ./tmux_config.sh)
        else
            echo "tmux_config.sh not found in repository"
            exit 1
        fi
    else
        echo "Failed to clone tmux config repository"
        exit 1
    fi
    rm -rf "$temp_dir"
}

install_tmux_config

# Your existing zsh_config (abbreviated for brevity)
zsh_config="... your existing zsh configuration ..."
append_or_create "$HOME/.zshrc" "$zsh_config"

# Optional: Install Nerd Fonts
install_nerd_fonts() {
    read -p "Would you like to install Nerd Fonts? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local temp_dir=$(mktemp -d)
        echo "Cloning Nerd Fonts installer to $temp_dir"
        if git clone https://github.com/fam007e/nerd_fonts_installer.git "$temp_dir"; then
            (cd "$temp_dir" && chmod +x nerdfonts_installer.sh && ./nerdfonts_installer.sh)
        else
            echo "Failed to clone Nerd Fonts installer"
            exit 1
        fi
        rm -rf "$temp_dir"
    fi
}

# Uncomment to enable Nerd Fonts installation
# install_nerd_fonts

echo "Configuration complete! Please restart your terminal for changes to take effect."
