#!/bin/bash
# Cursor Auto-Update Setup Script
# This script automates the setup process
set -e
echo "🚀 Setting up Cursor Auto-Update..."
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Copy update script
echo "📝 Copying update script..."
cp cursor-update.sh ~/cursor-update.sh
chmod +x ~/cursor-update.sh
echo "✅ Update script installed: ~/cursor-update.sh"

# Step 2: Create Cursor directory and copy icons
echo ""
echo "🖼️  Copying icons..."
mkdir -p ~/.local/share/cursor
cp co.anysphere.cursor.png ~/.local/share/cursor/
cp code.png ~/.local/share/cursor/
echo "✅ Icons installed: ~/.local/share/cursor/"

# Step 3: Install libfuse2 if not present
echo ""
echo "📦 Checking libfuse2 dependency..."
if ! dpkg -s libfuse2 &>/dev/null; then
    echo "   libfuse2 not found, installing..."
    sudo apt-get install -y libfuse2
    echo "✅ libfuse2 installed"
else
    echo "✅ libfuse2 already installed"
fi

# Step 4: Set up autostart
echo ""
echo "🔄 Setting up autostart..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/cursor-update.desktop << EOF
[Desktop Entry]
Type=Application
Name=Cursor Update Check
Exec=$HOME/cursor-update.sh --auto-close
Icon=$HOME/.local/share/cursor/co.anysphere.cursor.png
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Check for Cursor updates on login
EOF
chmod +x ~/.config/autostart/cursor-update.desktop
echo "✅ Autostart configured: ~/.config/autostart/cursor-update.desktop"

# Step 5: Set up manual launcher
echo ""
echo "📱 Setting up manual launcher..."
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/cursor-update.desktop << EOF
[Desktop Entry]
Name=Cursor Update Check
Comment=Check for Cursor updates manually
Exec=$HOME/cursor-update.sh --no-auto-close
Icon=$HOME/.local/share/cursor/co.anysphere.cursor.png
Type=Application
Categories=System;
Terminal=false
EOF
chmod +x ~/.local/share/applications/cursor-update.desktop
echo "✅ Manual launcher installed: ~/.local/share/applications/cursor-update.desktop"

# Step 6: Create Cursor app desktop entry
echo ""
echo "🖱️  Creating Cursor app launcher..."
cat > ~/.local/share/applications/cursor.desktop << EOF
[Desktop Entry]
Type=Application
Name=Cursor
Comment=The AI Code Editor
Exec=$HOME/.local/share/cursor/cursor.AppImage --no-sandbox
Icon=$HOME/.local/share/cursor/co.anysphere.cursor.png
Categories=Development;IDE;TextEditor;
MimeType=text/plain;inode/directory;
StartupWMClass=Cursor
Terminal=false
EOF
echo "✅ Cursor app launcher installed: ~/.local/share/applications/cursor.desktop"

# Step 7: Run initial update to download Cursor
echo ""
echo "⬇️  Running initial Cursor download..."
bash ~/cursor-update.sh
echo "✅ Cursor downloaded"

# Step 8: Refresh desktop database
echo ""
echo "🔁 Refreshing desktop database..."
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
echo "✅ Desktop database updated"

echo ""
echo "✨ Setup complete!"
echo ""
echo "📋 What happens next:"
echo "   • On your next login, Cursor will check for updates automatically"
echo "   • You can manually check for updates from the application menu: 'Cursor Update Check'"
echo "   • Update logs are saved to: ~/.cursor-update.log"
echo ""
echo "🧪 Test the setup:"
echo "   bash ~/cursor-update.sh --auto-close"
echo ""
