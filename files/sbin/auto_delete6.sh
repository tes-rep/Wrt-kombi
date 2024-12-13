#!/bin/bash

# READ AUTH
if [ -f "/root/TgBotWRT/AUTH" ]; then
    BOT_TOKEN=$(head -n 1 /root/TgBotWRT/AUTH)
    CHAT_ID=$(tail -n 1 /root/TgBotWRT/AUTH)
else
    echo "Berkas AUTH tidak ditemukan."
    exit 1
fi

# Konfigurasi koneksi database
DB_USER="radius"
DB_PASS="radius"
DB_NAME="radius"
DB_HOST="127.0.0.1"

TIMESTAMP=$(date '+%a %b %d %T %Y')

# Function to send Telegram message with image
send_telegram_message() {
    local message=$1
    local image_url="https://cdn-icons-png.freepik.com/256/5626/5626141.png?semt=ais_hybrid"  # Replace with your actual image URL
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendPhoto" -F chat_id="$CHAT_ID" -F photo="$image_url" -F caption="$message" -F parse_mode="HTML"
}

# Dapatkan daftar username dengan terminate_cause 'Session-Timeout'
QUERY="SELECT DISTINCT username FROM radacct WHERE acctterminatecause = 'Session-Timeout';"
USERNAMES=$(mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -se "$QUERY")

if [ -z "$USERNAMES" ]; then
    log_message="$TIMESTAMP : Tidak ada Kode voucher yang Expired.

> Kembali ke /menu"
    echo "$log_message" >> /var/log/auto_delete.log
    send_telegram_message "$log_message"
    exit 0
fi

# Hapus setiap pengguna yang ditemukan
for USERNAME in $USERNAMES; do
    log_message="$TIMESTAMP : Menghapus Kode voucher $USERNAME.

> Kembali ke /menu"
    echo "$log_message" >> /var/log/auto_delete.log
    send_telegram_message "$log_message"

    DELETE_QUERY="DELETE FROM radcheck WHERE username = '$USERNAME';"
    if ! mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"; then
        error_message="$TIMESTAMP : Gagal menghapus dari radcheck untuk $USERNAME."
        echo "$error_message" >> /var/log/auto_delete.log
        send_telegram_message "$error_message"
        continue
    fi

    DELETE_QUERY="DELETE FROM radacct WHERE username = '$USERNAME';"
    if ! mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"; then
        error_message="$TIMESTAMP : Gagal menghapus dari radacct untuk $USERNAME."
        echo "$error_message" >> /var/log/auto_delete.log
        send_telegram_message "$error_message"
        continue
    fi

    DELETE_QUERY="DELETE FROM userbillinfo WHERE username = '$USERNAME';"
    if ! mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"; then
        error_message="$TIMESTAMP : Gagal menghapus dari userbillinfo untuk $USERNAME."
        echo "$error_message" >> /var/log/auto_delete.log
        send_telegram_message "$error_message"
        continue
    fi

    DELETE_QUERY="DELETE FROM userinfo WHERE username = '$USERNAME';"
    if ! mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"; then
        error_message="$TIMESTAMP : Gagal menghapus dari userinfo untuk $USERNAME."
        echo "$error_message" >> /var/log/auto_delete.log
        send_telegram_message "$error_message"
        continue
    fi
done
