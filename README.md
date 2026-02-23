# Cursor Auto-Update Setup

This package sets up automatic Cursor updates on Ubuntu/Linux. On login, it checks for updates and downloads a new AppImage when available.

## Prerequisites

- Ubuntu/Linux
- Internet connection
- `libfuse2` (installed by `setup.sh` if missing)

## Quick Setup (Recommended)

```bash
git clone <repo-url>
cd cursor-auto-update
chmod +x setup.sh
./setup.sh
```

`setup.sh` will:
- copy `cursor-update.sh` to `~/cursor-update.sh`
- copy icons to `~/.local/share/cursor/`
- create autostart entry at `~/.config/autostart/cursor-update.desktop`
- create manual launcher at `~/.local/share/applications/cursor-update.desktop`
- create Cursor app launcher at `~/.local/share/applications/cursor.desktop`
- run initial download

## Included Files

- `setup.sh`
- `cursor-update.sh`
- `co.anysphere.cursor.png`
- `code.png`
- `README.md`

Desktop entry files are generated during setup and are not included as separate template files.

## Manual Setup

```bash
cp cursor-update.sh ~/cursor-update.sh
chmod +x ~/cursor-update.sh

mkdir -p ~/.local/share/cursor
cp co.anysphere.cursor.png ~/.local/share/cursor/
cp code.png ~/.local/share/cursor/
```

Create autostart entry:

```bash
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
```

Create manual launcher:

```bash
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
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
```

Run the first update check:

```bash
bash ~/cursor-update.sh
```

## How It Works

- Autostart runs `~/cursor-update.sh --auto-close` on login.
- Manual launcher runs `~/cursor-update.sh --no-auto-close`.
- Script compares installed version against latest available version and downloads only when needed.

## Useful Commands

```bash
# Run update check manually
bash ~/cursor-update.sh --no-auto-close

# View logs
tail -f ~/.cursor-update.log

# Check installed version
cat ~/.local/share/cursor/version.txt
```

## Uninstall

```bash
rm -f ~/.config/autostart/cursor-update.desktop
rm -f ~/.local/share/applications/cursor-update.desktop
rm -f ~/.local/share/applications/cursor.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

rm -f ~/cursor-update.sh
rm -f ~/.cursor-update.log

# Optional: remove Cursor AppImage and icons
rm -rf ~/.local/share/cursor
```
