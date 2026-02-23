#!/bin/bash

INSTALL_DIR="$HOME/.local/share/cursor"
TEMP_DIR="/tmp/cursor-update"
LOG_FILE="$HOME/.cursor-update.log"

# Parse command line arguments
AUTO_CLOSE=false
if [ "$1" = "--auto-close" ]; then
    AUTO_CLOSE=true
elif [ "$1" = "--no-auto-close" ]; then
    AUTO_CLOSE=false
fi

# Wait for DISPLAY to be available (max 30 seconds)
WAIT_COUNT=0
while [ -z "$DISPLAY" ] && [ $WAIT_COUNT -lt 30 ]; do
    # Try to get DISPLAY from the user's session
    DISPLAY=$(ps e -u "$USER" | grep -oP 'DISPLAY=\K[^\s]+' | head -1)
    if [ -z "$DISPLAY" ]; then
        # Try common display values
        for d in ":0" ":1" ":0.0" ":1.0"; do
            if xset q &>/dev/null 2>&1; then
                export DISPLAY="$d"
                break
            fi
        done
    fi
    if [ -z "$DISPLAY" ]; then
        sleep 1
        WAIT_COUNT=$((WAIT_COUNT + 1))
    fi
done

# Function that does the actual update check
do_update_check() {
    echo "=========================================="
    echo "  Cursor Update Check"
    echo "=========================================="
    echo ""
    
    echo "$(date): Starting Cursor update check..." | tee -a "$LOG_FILE"
    echo "Checking for updates..."
    echo ""
    
    # Get the base version from download page
    BASE_VERSION=$(curl -sL https://www.cursor.com/download | grep -oP 'linux-x64/cursor/\K[0-9]+\.[0-9]+' | head -1)
    
    if [ -z "$BASE_VERSION" ]; then
        echo "❌ Failed to fetch base version from download page" | tee -a "$LOG_FILE"
        echo "$(date): Failed to fetch base version from download page" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Follow the redirect to get the actual download URL with full version
    REDIRECT_URL=$(curl -sL -I "https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/$BASE_VERSION" 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r\n')
    
    if [ -n "$REDIRECT_URL" ]; then
        # Extract full version from redirect URL (e.g., Cursor-2.3.41-x86_64.AppImage)
        LATEST_VERSION=$(echo "$REDIRECT_URL" | grep -oP 'Cursor-\K[0-9]+\.[0-9]+\.[0-9]+')
    fi
    
    # If we couldn't get full version from redirect, use base version
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION="$BASE_VERSION"
    fi
    
    # Check current version - read from version.txt first (most reliable)
    CURRENT_VERSION=""
    if [ -f "$INSTALL_DIR/version.txt" ]; then
        CURRENT_VERSION=$(cat "$INSTALL_DIR/version.txt" | tr -d '[:space:]')
    fi
    
    # Fallback: try to extract version from AppImage if version.txt doesn't exist
    if [ -z "$CURRENT_VERSION" ] && [ -f "$INSTALL_DIR/cursor.AppImage" ]; then
        APPIMAGE_VERSION=$("$INSTALL_DIR/cursor.AppImage" --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$APPIMAGE_VERSION" ]; then
            CURRENT_VERSION="$APPIMAGE_VERSION"
        fi
    fi
    
    echo "Current version: $CURRENT_VERSION"
    echo "Latest version:  $LATEST_VERSION"
    echo ""
    echo "$(date): Current version: $CURRENT_VERSION, Latest version: $LATEST_VERSION" | tee -a "$LOG_FILE"
    
    # Compare versions - exact match
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo "✅ Already up to date (version $CURRENT_VERSION)"
        echo "$(date): Already up to date (version $CURRENT_VERSION)" | tee -a "$LOG_FILE"
        return 0
    fi
    
    # If current version is empty, we need to download
    if [ -z "$CURRENT_VERSION" ]; then
        echo "📥 No current version found, downloading latest..."
        echo "$(date): No current version found, downloading latest..." | tee -a "$LOG_FILE"
    else
        echo "🔄 Update available: $CURRENT_VERSION -> $LATEST_VERSION"
        echo "$(date): Update available: $CURRENT_VERSION -> $LATEST_VERSION" | tee -a "$LOG_FILE"
    fi
    
    # Construct the download URL
    DOWNLOAD_URL="https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/$BASE_VERSION"
    
    # Follow redirects to get the actual download URL
    ACTUAL_URL=$(curl -sL -I "$DOWNLOAD_URL" 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r\n')
    
    if [ -z "$ACTUAL_URL" ]; then
        ACTUAL_URL="$DOWNLOAD_URL"
    fi
    
    # Extract actual version from final URL to ensure we save the correct version
    FINAL_VERSION=$(echo "$ACTUAL_URL" | grep -oP 'Cursor-\K[0-9]+\.[0-9]+\.[0-9]+')
    if [ -n "$FINAL_VERSION" ]; then
        LATEST_VERSION="$FINAL_VERSION"
    fi
    
    echo "$(date): Download URL: $ACTUAL_URL" | tee -a "$LOG_FILE"
    
    # Download latest version
    echo ""
    echo "📥 Downloading version $LATEST_VERSION..."
    echo "$(date): Downloading version $LATEST_VERSION..." | tee -a "$LOG_FILE"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Use wget with progress bar and follow redirects
    wget --progress=bar:force:noscroll --show-progress "$ACTUAL_URL" -O cursor.AppImage 2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo ""
        echo "❌ Download failed"
        echo "$(date): Download failed" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Verify the downloaded file
    if [ ! -f "cursor.AppImage" ]; then
        echo ""
        echo "❌ Downloaded file not found"
        echo "$(date): Downloaded file not found" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Make executable
    chmod +x cursor.AppImage
    
    # Move to installation directory
    mkdir -p "$INSTALL_DIR"
    mv cursor.AppImage "$INSTALL_DIR/cursor.AppImage"
    echo "$LATEST_VERSION" > "$INSTALL_DIR/version.txt"
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    echo ""
    echo "✅ Successfully updated to version $LATEST_VERSION"
    echo "$(date): Successfully updated to version $LATEST_VERSION" | tee -a "$LOG_FILE"
    return 0
}

# Check if we're already in a terminal (interactive) or if DISPLAY is not set
if [ -t 0 ] && [ -n "$DISPLAY" ]; then
    # Already in a terminal, just run the update check
    do_update_check
    if [ "$AUTO_CLOSE" = true ]; then
        echo ""
        echo "Closing in 3 seconds..."
        sleep 3
    else
        echo ""
        echo "Press any key to close..."
        read -n 1 -s
    fi
else
    # Not in a terminal or no DISPLAY, check if we can open a terminal
    # Detect which terminal emulator is available
    TERMINAL=""
    if command -v gnome-terminal &> /dev/null; then
        TERMINAL="gnome-terminal"
    elif command -v xterm &> /dev/null; then
        TERMINAL="xterm"
    elif command -v konsole &> /dev/null; then
        TERMINAL="konsole"
    elif command -v xfce4-terminal &> /dev/null; then
        TERMINAL="xfce4-terminal"
    elif command -v mate-terminal &> /dev/null; then
        TERMINAL="mate-terminal"
    elif command -v lxterminal &> /dev/null; then
        TERMINAL="lxterminal"
    fi
    
    # If no DISPLAY or no terminal, run silently and log only
    if [ -z "$TERMINAL" ] || [ -z "$DISPLAY" ]; then
        do_update_check
        exit $?
    fi
    
    # Export the function and variables so they're available in the terminal
    export -f do_update_check
    export INSTALL_DIR TEMP_DIR LOG_FILE AUTO_CLOSE
    
    # Build the command to run in terminal
    if [ "$AUTO_CLOSE" = true ]; then
        TERMINAL_CMD="do_update_check; echo ''; echo 'Closing in 3 seconds...'; sleep 3"
    else
        TERMINAL_CMD="do_update_check; echo ''; echo 'Press any key to close...'; read -n 1 -s"
    fi
    
    # Open terminal and run the update check function directly
    case "$TERMINAL" in
        gnome-terminal)
            if ! gnome-terminal --title="Cursor Update Check" -- bash -c "$TERMINAL_CMD" 2>/dev/null; then
                do_update_check
            fi
            ;;
        xterm)
            xterm -title "Cursor Update Check" -e "bash -c '$TERMINAL_CMD'" 2>/dev/null &
            ;;
        konsole)
            konsole --title "Cursor Update Check" -e bash -c "$TERMINAL_CMD" 2>/dev/null &
            ;;
        xfce4-terminal)
            xfce4-terminal --title="Cursor Update Check" -e "bash -c \"$TERMINAL_CMD\"" 2>/dev/null &
            ;;
        mate-terminal)
            mate-terminal --title="Cursor Update Check" -e "bash -c \"$TERMINAL_CMD\"" 2>/dev/null &
            ;;
        lxterminal)
            lxterminal --title="Cursor Update Check" -e "bash -c \"$TERMINAL_CMD\"" 2>/dev/null &
            ;;
    esac
fi
