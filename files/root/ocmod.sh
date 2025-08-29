#!/bin/sh

# === KONFIGURASI PATH ===
LUCI_PATH="/usr/lib/lua/luci"
CTRL_FILE="$LUCI_PATH/controller/openclash.lua"
FORM_SETTINGS_FILE="$LUCI_PATH/model/cbi/openclash/settings.lua"
VIEW_OCEDITOR="$LUCI_PATH/view/openclash/oceditor.htm"
FORM_CLIENT_FILE="$LUCI_PATH/model/cbi/openclash/client.lua"
STATUS_FILE="$LUCI_PATH/view/openclash/status.htm"
LOG_FILE="/root/houjie-wrt.log"

# Fungsi untuk menulis log
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Log Start
log_message "Memulai patch OpenClash..."

# === PATCH settings.lua (hapus deskripsi panjang multi-baris) ===
echo "[✔] Patch m.description di settings.lua"
log_message "Memulai patch settings.lua"
if grep -q '^m\.description *= ' "$FORM_SETTINGS_FILE"; then
  cp "$FORM_SETTINGS_FILE" "${FORM_SETTINGS_FILE}.bak"
  awk '
  BEGIN {skip=0}
  /^m\.description *=/ {print "m.description = translate(\" \")"; skip=1; next}
  skip && /^[ \t]*[."]/{next}
  {skip=0; print}
  ' "${FORM_SETTINGS_FILE}.bak" > "$FORM_SETTINGS_FILE"
  echo "[✓] Berhasil mengganti m.description dengan satu baris kosong"
  log_message "Patch settings.lua berhasil"
else
  echo "[ℹ] Tidak ditemukan m.description di settings.lua"
  log_message "Tidak ditemukan m.description di settings.lua"
fi

# === PATCH controller.lua ===
echo "[✔] Patch controller.lua (sisipkan oceditor setelah config)"
log_message "Memulai patch controller.lua"

TARGET_LINE='entry({"admin", "services", "openclash", "config"},form("openclash/config"),_("Config Manage"), 80).leaf = true'
OCEDITOR_LINE='entry({"admin", "services", "openclash", "oceditor"}, template("openclash/oceditor"), _("Config Editor"), 90).leaf = true'

if [ -f "$CTRL_FILE" ]; then
  cp "$CTRL_FILE" "${CTRL_FILE}.bak"
  sed -i '/openclash", "oceditor"/d' "$CTRL_FILE"
  if grep -qF "$TARGET_LINE" "$CTRL_FILE"; then
    sed -i "/$(echo "$TARGET_LINE" | sed 's/[^^]/[&]/g; s/\^/\\^/g')/a\\
$OCEDITOR_LINE" "$CTRL_FILE"
    echo "[✓] Entry oceditor berhasil disisipkan setelah entry config"
    log_message "Entry oceditor berhasil disisipkan setelah config"
  else
    echo "[⚠️] Tidak ditemukan entry config utama, gagal menyisipkan oceditor"
    log_message "Tidak ditemukan entry config utama"
  fi
  sed -i 's/\(entry({.*"log".*Server Logs".*\), *90)/\1, 100)/' "$CTRL_FILE"
else
  echo "[✘] File controller tidak ditemukan: $CTRL_FILE"
  log_message "File controller tidak ditemukan"
fi

# === PATCH client.lua ===
echo "[✔] Patch client.lua"
log_message "Memulai patch client.lua"
if [ -f "$FORM_CLIENT_FILE" ]; then
  cp "$FORM_CLIENT_FILE" "${FORM_CLIENT_FILE}.bak"
  sed -i 's/translate("OpenClash")/translate(" ")/' "$FORM_CLIENT_FILE"
  sed -i 's/translate("A Clash Client For OpenWrt")/translate(" ")/' "$FORM_CLIENT_FILE"
  sed -i '/m:append(Template("openclash\/developer"))/d' "$FORM_CLIENT_FILE"
  echo "[✓] client.lua berhasil dipangkas"
  log_message "client.lua berhasil dipangkas"
else
  echo "[⚠️] File $FORM_CLIENT_FILE tidak ditemukan"
  log_message "File $FORM_CLIENT_FILE tidak ditemukan"
fi

# === BUAT VIEW ocEditor ===
if [ ! -f "$VIEW_OCEDITOR" ]; then
  echo "[✔] Membuat view oceditor.htm"
  mkdir -p "$(dirname "$VIEW_OCEDITOR")"
  cat << 'EOF' > "$VIEW_OCEDITOR"
<%+header%>
<div class="cbi-map">
  <iframe id="oceditor" style="width: 100%; min-height: 650px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
  document.getElementById("oceditor").src = window.location.protocol + "//" + window.location.host + "/tinyfm/oceditor.php";
</script>
<%+footer%>
EOF
else
  echo "[ℹ] File oceditor.htm sudah ada, lewati"
  log_message "File oceditor.htm sudah ada"
fi

# === PATCH darkmode status.htm ===
if [ -f "$STATUS_FILE" ]; then
  echo "[✔] Menambahkan style darkmode di status.htm"
  cp "$STATUS_FILE" "${STATUS_FILE}.bak"
  sed -i '/<style>/a\
body {\n  background-color: #1f2937 !important;\n  color: #e5e7eb !important;\n}' "$STATUS_FILE"
  sed -i 's/<div class="oc">/<div class="oc" data-darkmode="true">/' "$STATUS_FILE"
else
  echo "[⚠️] File status.htm tidak ditemukan"
  log_message "File status.htm tidak ditemukan"
fi

# === BUAT SYMLINK ===
echo "[✔] Memastikan symlink openclash → /www/tinyfm/openclash"
create_safe_openclash_symlink() {
  local target="/etc/openclash"
  local link="/www/tinyfm/openclash"
  mkdir -p /www/tinyfm
  if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$target" ]; then
    echo "[✓] Symlink sudah benar: $link → $target"
    log_message "Symlink sudah benar: $link → $target"
    return 0
  fi
  if [ -e "$link" ]; then
    echo "[!] Menghapus $link karena bukan symlink yang benar"
    log_message "Menghapus $link karena bukan symlink yang benar"
    rm -rf "$link"
  fi
  ln -sf "$target" "$link" && echo "[+] Symlink dibuat: $link → $target"
  log_message "Symlink dibuat: $link → $target"
}
create_safe_openclash_symlink

echo "[✅] Semua patch berhasil diterapkan!"
log_message "Semua patch berhasil diterapkan!"
