#! /usr/bin/env bash
set -e
if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run as root"
  exit 1
fi
TARGET=${1:-"$HOME/opt"}
mkdir -p "$TARGET"
echo "Installing to $TARGET"


######################
## configuradorfnmt ##
######################

# extract configuradorfnmt
(
  TEMPDIR="$(mktemp -d)"
  echo "Extracting configuradorfnmt to $TEMPDIR"
  cd $TEMPDIR
  wget -O configuradorfnmt.deb https://descargas.cert.fnmt.es/Linux/configuradorfnmt_1.0.1-0_amd64.deb
  sha256sum --check <<< "1c3af58017f2532bb9fdf661fce47c751f8cdb1ee88c6b72864ad75c6f74f338 configuradorfnmt.deb"
  ar x configuradorfnmt.deb
  tar xf data.tar.xz
  cd "$TEMPDIR/usr/lib/configuradorfnmt"
  tar xf jre.tar.gz # Should it use the one from the system?
  rm jre.tar.gz
  rm configuradorfnmt.png
  rm configuradorfnmt.js
  mv "$TEMPDIR/usr/lib/configuradorfnmt" "$TARGET"
  rm -rf "$TEMPDIR"
)

# create configuradorfnmt launcher
CONFIGURADOR_FNMT_LAUNCHER="$TARGET/configuradorfnmt/configuradorfnmt"
cat > "$CONFIGURADOR_FNMT_LAUNCHER" << 'EOF'
#!/bin/bash
cd "$( dirname -- "${BASH_SOURCE[0]}" )"
for lib in \
  /usr/lib/x86_64-linux-gnu/libpcsclite.so.1 \
  /usr/lib64/libpcsclite.so.1 \
  /usr/lib/libpcsclite.so.1 \
  /usr/lib/i386-linux-gnu/libpcsclite.so.1 \
; do
  if [[ -e "$lib" ]]; then
    exec ./jre/bin/java -Dsun.security.smartcardio.library=$lib -jar ./configuradorfnmt.jar $*
  fi
done
exec jre/bin/java -jar ./configuradorfnmt.jar $* 
EOF
chmod +x $CONFIGURADOR_FNMT_LAUNCHER

# run its -install flag
$CONFIGURADOR_FNMT_LAUNCHER -install

# set firefox configuradorfnmt prefs (only for currently available profiles)
for PREFS_DIR in $HOME/.mozilla/firefox/*/prefs.js; do
  PREFS_DIR=$(dirname "$PREFS_DIR")
  echo "Adding prefs to $PREFS_DIR"
  if [[ -e "$PREFS_DIR/user.js" ]]; then
    sed -i '/network.protocol-handler.*.fnmtcr/d' "$PREFS_DIR/user.js"
  fi
  cat >> "$PREFS_DIR/user.js" <<EOF 
user_pref("network.protocol-handler.app.fnmtcr","$CONFIGURADOR_FNMT_LAUNCHER");
user_pref("network.protocol-handler.warn-external.fnmtcr",false);
user_pref("network.protocol-handler.external.fnmtcr",true);
EOF
done

## set mime (tweak .desktop to launch from the installation path)
cat > "$HOME/.local/share/applications/configuradorfnmt.desktop" <<EOF
[Desktop Entry]
Version=1.0.1-custom
Type=Application
Terminal=false
Exec=$CONFIGURADOR_FNMT_LAUNCHER %u
Name=ConfiguradorFnmt
MimeType=x-scheme-handler/fnmtcr;
Keywords=fnmt;certificate
Categories=Application
EOF
xdg-mime default configuradorfnmt.desktop x-scheme-handler/fnmtcr


################################################
echo "#########################################"
echo "Remember to password-protect the cert db!"
echo "#########################################"
################################################
