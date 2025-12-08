#!/bin/sh
# shsh installer - https://github.com/dawnlarsson/shsh
# Usage: curl -fsSL https://raw.githubusercontent.com/dawnlarsson/shsh/main/repo/install.sh | sh
set -e

URL="https://raw.githubusercontent.com/dawnlarsson/shsh/main/shsh.sh"

printf "shsh installer\n"
printf "==============\n\n"

printf "downloading shsh...\n"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$TMP" || { printf "error: download failed\n" >&2; exit 1; }
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TMP" "$URL" || { printf "error: download failed\n" >&2; exit 1; }
else
  printf "error: curl or wget required\n" >&2
  exit 1
fi

chmod +x "$TMP"

# Find best install location
DEST=""
NEEDS_PATH=0

# Check directories already in PATH first
for dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
  case ":$PATH:" in
    *":$dir:"*)
      if [ -w "$dir" ] 2>/dev/null; then
        DEST="$dir/shsh"
        break
      elif [ "$dir" = "/usr/local/bin" ]; then
        DEST="$dir/shsh"
        break
      fi
      ;;
  esac
done

# If nothing in PATH is suitable, use ~/.local/bin
if [ -z "$DEST" ]; then
  mkdir -p "$HOME/.local/bin"
  DEST="$HOME/.local/bin/shsh"
  NEEDS_PATH=1
fi

DEST_DIR=$(dirname "$DEST")

# Install
if [ -w "$DEST_DIR" ] 2>/dev/null; then
  cp "$TMP" "$DEST"
  chmod +x "$DEST"
  printf "installed: %s\n" "$DEST"
else
  printf "installing to %s (requires sudo)...\n" "$DEST"
  sudo cp "$TMP" "$DEST"
  sudo chmod +x "$DEST"
  printf "installed: %s\n" "$DEST"
fi

# Handle PATH setup
if [ "$NEEDS_PATH" = "1" ]; then
  SHELL_RC=""
  PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
  
  case "$SHELL" in
    */bash)
      if [ -f "$HOME/.bash_profile" ]; then
        SHELL_RC="$HOME/.bash_profile"
      elif [ -f "$HOME/.bash_login" ]; then
        SHELL_RC="$HOME/.bash_login"
      else
        SHELL_RC="$HOME/.bashrc"
      fi
      ;;
    */zsh)
      SHELL_RC="$HOME/.zshrc"
      ;;
    */fish)
      SHELL_RC="$HOME/.config/fish/config.fish"
      PATH_EXPORT='set -gx PATH $HOME/.local/bin $PATH'
      mkdir -p "$HOME/.config/fish"
      ;;
    *)
      SHELL_RC="$HOME/.profile"
      ;;
  esac
  
  # Check if PATH is already configured
  ALREADY=0
  if [ -f "$SHELL_RC" ]; then
    if grep -qE '(\.local/bin|HOME/.local/bin)' "$SHELL_RC" 2>/dev/null; then
      ALREADY=1
    fi
  fi
  
  if [ "$ALREADY" = "0" ]; then
    printf '\n# shsh - added by installer\n%s\n' "$PATH_EXPORT" >> "$SHELL_RC"
    printf "added PATH to %s\n" "$SHELL_RC"
  else
    printf "PATH already configured in %s\n" "$SHELL_RC"
  fi
  
  printf "\n"
  printf "\033[1;32m✓ Installation complete!\033[0m\n\n"
  printf "\033[1;33mIMPORTANT:\033[0m To start using shsh, run:\n"
  printf "  \033[1mexec \$SHELL\033[0m\n"
  printf "Or simply open a new terminal.\n"
else
  printf "\n"
  printf "\033[1;32m✓ Installation complete!\033[0m\n"
  printf "shsh is ready to use!\n"
fi

printf "\nRun 'shsh' to get started.\n"