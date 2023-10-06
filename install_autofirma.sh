#! /usr/bin/env bash
set -e
if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run as root"
  exit 1
fi
TARGET=${1:-"$HOME/opt/"}
mkdir -p "$TARGET"
echo "Installing to $TARGET"


###############
## AutoFirma ##
###############

if ! hash java; then
  echo "java unavailable for AutoFirma" # Should it use the jre included with configuradorfnmt?
  exit 2
fi

# extract AutoFirma
(
  TEMPDIR="$(mktemp -d)"
  echo "Extracting autofirma to $TEMPDIR"
  cd $TEMPDIR
  curl --output autofirma.zip https://estaticos.redsara.es/comunes/autofirma/currentversion/AutoFirma_Linux_Debian.zip
  sha256sum --check <<< "5b0660a9e1fbcba6aa81c8142429084e72f9d2b306c6bc1c73b7c860e6c81ab9 autofirma.zip"
  unzip autofirma.zip
  ar x AutoFirma_1_8_2.deb
  tar -xzf data.tar.gz

  # Not installing the CA system wide
  mkdir -p "$TARGET"
  mv usr/lib/AutoFirma $TARGET
  cd "$TARGET/AutoFirma"

  java -jar ./AutoFirmaConfigurador.jar
  SCRIPT="./script.sh"
  if [ -f "$SCRIPT" ]; then
    chmod +x "$SCRIPT"
    "$SCRIPT"
    rm "$SCRIPT"
  fi
  chmod -x ./AutoFirma.jar
  rm -rf "$TEMPDIR"
)

# create AutoFirma launcher
AFIRMA_LAUNCHER="$TARGET/AutoFirma/autofirma"
cat > "$AFIRMA_LAUNCHER" << 'EOF'
#!/bin/bash
cd "$( dirname -- "${BASH_SOURCE[0]}" )"
exec java -Djdk.tls.maxHandshakeMessageSize=65536 -jar AutoFirma.jar "$@"
EOF
chmod +x $AFIRMA_LAUNCHER

# set firefox AutoFirma prefs (only for currently available profiles)
for PREFS_DIR in $HOME/.mozilla/firefox/*/prefs.js; do
  PREFS_DIR=$(dirname "$PREFS_DIR")
  echo "Adding prefs to $PREFS_DIR"
  if [[ -e "$PREFS_DIR/user.js" ]]; then
    sed -i '/network.protocol-handler.*.afirma/d' "$PREFS_DIR/user.js"
  fi
  cat >> "$PREFS_DIR/user.js" <<EOF 
user_pref("network.protocol-handler.app.afirma","$AFIRMA_LAUNCHER");
user_pref("network.protocol-handler.warn-external.afirma",false);
user_pref("network.protocol-handler.external.afirma",true);
EOF
done

# set mime (tweak .desktop to launch from the installation path)
cat > "$HOME/.local/share/applications/afirma.desktop" <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=1.8.2-custom
Name=AutoFirma
Type=Application
Terminal=false
Categories=Office;Utilities;Signature;Java
Exec=$AFIRMA_LAUNCHER %U
GenericName=Herramienta de firma
Comment=Herramienta de firma
MimeType=x-scheme-handler/afirma;
StartupNotify=true
StartupWMClass=autofirma
EOF
xdg-mime default afirma.desktop x-scheme-handler/afirma


################################################
echo "#########################################"
echo "Remember to password-protect the cert db!"
echo "#########################################"
################################################
