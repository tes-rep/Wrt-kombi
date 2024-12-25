#!/bin/bash

# Konfigurasi koneksi database
DB_USER="radmon"
DB_PASS="radmon"
DB_NAME="radmon"
DB_HOST="127.0.0.1"

TIMESTAMP=$(date '+%a %b %d %T %Y')

# Dapatkan daftar username dengan terminate_cause 'Session-Timeout'
QUERY="SELECT DISTINCT username FROM radacct WHERE acctterminatecause = 'Session-Timeout';"
USERNAMES=$(mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -se "$QUERY")

if [ -z "$USERNAMES" ]; then
    echo "$TIMESTAMP : Tidak ada Kode voucher yang Expired." >> /var/log/auto_delete.log
    exit 0
fi

# Hapus setiap pengguna yang ditemukan
for USERNAME in $USERNAMES; do
    echo "$TIMESTAMP : Menghapus Kode voucher $USERNAME." >> /var/log/auto_delete.log

    DELETE_QUERY="DELETE FROM radcheck WHERE username = '$USERNAME';"
    mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"

    DELETE_QUERY="DELETE FROM radacct WHERE username = '$USERNAME';"
    mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"

    DELETE_QUERY="DELETE FROM userbillinfo WHERE username = '$USERNAME';"
    mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"

    DELETE_QUERY="DELETE FROM userinfo WHERE username = '$USERNAME';"
    mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "$DELETE_QUERY"
done
