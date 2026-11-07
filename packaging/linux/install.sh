#!/bin/sh
# Günlük Görevler: Linux kurulumu (yönetici izni gerekmez).
# Bu klasörde çalıştır:  ./install.sh
# Kaldırmak için:        ./install.sh --kaldir
# Görevler ~/.local/share/gunluk_gorevler içinde durur; kaldırmak onları silmez.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
DEST="$HOME/.local/opt/gunluk-gorevler"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/256x256/apps"
ID=com.gunlukgorevler.gunluk_gorevler

if [ "${1:-}" = "--kaldir" ]; then
  rm -rf "$DEST"
  rm -f "$APPS/$ID.desktop" "$ICONS/$ID.png"
  echo "Kaldırıldı. Görevlerin ~/.local/share/gunluk_gorevler içinde duruyor."
  exit 0
fi

mkdir -p "$DEST" "$APPS" "$ICONS"
cp -R "$HERE/bundle/." "$DEST/"
cp "$HERE/gunluk-gorevler.png" "$ICONS/$ID.png"
cat > "$APPS/$ID.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Günlük Görevler
Comment=Her gün tik atılan görev listesi
Exec="$DEST/gunluk_gorevler"
Icon=$ID
Terminal=false
Categories=Office;Utility;
StartupWMClass=$ID
DESKTOP
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1 || true
echo "Kuruldu: uygulama menüsünde 'Günlük Görevler'. Doğrudan açmak için: $DEST/gunluk_gorevler"
