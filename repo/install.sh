#!/bin/sh
set -e

URL="https://raw.githubusercontent.com/dawnlarsson/shsh/main/shsh.sh"

echo "Downloading shsh..."

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o /tmp/shsh_installer
elif command -v wget >/dev/null 2>&1; then
  wget -qO /tmp/shsh_installer "$URL"
else
  echo "Error: neither curl nor wget found."
  exit 1
fi

chmod +x /tmp/shsh_installer
/tmp/shsh_installer install

rm /tmp/shsh_installer