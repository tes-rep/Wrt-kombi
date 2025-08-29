#!/bin/sh
set -e

# === Konfigurasi file ===
INDEX_UT="/usr/share/ucode/luci/template/admin_status/index.ut"
SYSTEM_JS="/www/luci-static/resources/view/status/include/10_system.js"
LOG_FILE="/root/houjie-wrt.log"
DATESTAMP=$(date +%Y%m%d%H%M%S)

log_message() {
    LEVEL=$1
    MSG=$2
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$LEVEL] - $MSG" >> "$LOG_FILE"
}

backup_file() {
    FILE=$1
    BACKUP="${FILE}.bak.${DATESTAMP}"
    if cp "$FILE" "$BACKUP"; then
        log_message "INFO" "Backup $FILE → $BACKUP"
        echo "$BACKUP"
    else
        log_message "ERROR" "Gagal backup $FILE"
        return 1
    fi
}

# === Patch index.ut ===
if [ ! -f "$INDEX_UT" ]; then
    log_message "ERROR" "File $INDEX_UT tidak ditemukan!"
    echo "[✘] File $INDEX_UT tidak ditemukan!"
else
    if grep -q 'id="cpuusage"' "$INDEX_UT"; then
        echo "[!] Patch index.ut sudah ada, dilewati."
        log_message "WARN" "Patch index.ut sudah ada, dilewati."
    else
        INDEX_BACKUP=$(backup_file "$INDEX_UT")
        TMP_INDEX=$(mktemp)
        PATCH_INDEX=$(cat <<'EOF'
<div id="cpuusage">Loading CPU usage...</div>
<div id="tempcpu">Loading CPU temp...</div>

<script type="text/javascript">//<![CDATA[
    window.setTimeout(
        function() {
            XHR.poll(3, '{{ dispatcher.build_url("admin/status/realtime/cpuusage1") }}', null,
                function(x, json)
                {
                    if (e = document.getElementById('cpuusage'))
                        e.innerHTML = String.format('%1f %', json[0].cpu / 2);
                }
            );
            XHR.run();
        }
    );
//]]></script>

<script type="text/javascript">//<![CDATA[
    window.setTimeout(
        function() {
            XHR.poll(3, '{{ dispatcher.build_url("admin/status/realtime/temperature1") }}', null,
                function(x, json)
                {
                    if (e = document.getElementById('tempcpu'))
                        e.innerHTML = String.format('%1f&deg;C', json[0].cpu / 1000);
                }
            );
            XHR.run();
        }
    );
//]]></script>
EOF
)
        awk -v patch="$PATCH_INDEX" '
        {
            if ($0 ~ /\{\% *include\(.*footer.*\) *\%\}/) { print patch }
            print
        }' "$INDEX_UT" > "$TMP_INDEX" && mv "$TMP_INDEX" "$INDEX_UT"
        echo "[+] Patch index.ut selesai."
        log_message "INFO" "Patch index.ut berhasil disisipkan CPU Usage & Temperature."
    fi
fi

# === Patch 10_system.js ===
if [ ! -f "$SYSTEM_JS" ]; then
    log_message "ERROR" "File $SYSTEM_JS tidak ditemukan!"
    echo "[✘] File $SYSTEM_JS tidak ditemukan!"
else
    if grep -q 'tempcpu' "$SYSTEM_JS"; then
        echo "[!] Patch 10_system.js sudah ada, dilewati."
        log_message "WARN" "Patch 10_system.js sudah ada, dilewati."
    else
        SYSTEM_BACKUP=$(backup_file "$SYSTEM_JS")
        TMP_JS=$(mktemp)
        awk '
        BEGIN { temp_patched=0; fw_patched=0 }
        /var fields *= *\[/ {
            print
            while(getline){
                if ($0 ~ /Firmware Version/) { next }
                if (fw_patched==0 && $0 ~ /Target Platform/) {
                    print "    _(\"\Firmware Version\"), (L.isObject(boardinfo.release) ? boardinfo.release.description + \" / \" : \"\") + \"HOUJIE-WRT\","
                    fw_patched=1
                }
                if ($0 ~ /\];/ && temp_patched==0) {
                    print "    _(\"\Temperature\"), tempcpu,"
                    print "    _(\"\CPU Usage\"), cpuusage"
                    temp_patched=1
                }
                print
                if (fw_patched==1 && temp_patched==1 && $0 ~ /\];/) break
            }
            while(getline){ print }
            exit
        }
        { print }' "$SYSTEM_JS" > "$TMP_JS" && mv "$TMP_JS" "$SYSTEM_JS"
        echo "[+] Patch 10_system.js selesai."
        log_message "INFO" "Patch 10_system.js berhasil diterapkan."
    fi
fi

# === Set permission & reload LuCI ===
chmod 644 "$SYSTEM_JS" "$INDEX_UT"
log_message "INFO" "Permission 644 diterapkan ke file patch."

if /etc/init.d/uhttpd restart; then
    log_message "INFO" "uHTTPd direstart untuk reload LuCI."
else
    log_message "ERROR" "Gagal restart uHTTPd!"
fi

echo "[✅] Semua patch selesai. Silakan reload browser LuCI."
log_message "INFO" "Semua patch berhasil diterapkan dan LuCI di-reload."
