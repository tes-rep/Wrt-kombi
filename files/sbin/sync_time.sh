#!/bin/sh
# Sinkronisasi Jam Menggunakan Bug gedebug
# Make By @Maizil - Mutiara-Wrt

if [ "$#" -ne 1 ]; then
    echo "Penggunaan: $0 <Bug_Provider>"
    exit 1
fi

provider_bug=$1

date_gmt=$(curl -sI "$provider_bug" | grep -i "^Date:" | sed 's/Date: //I')

if [ -n "$date_gmt" ]; then
    day=$(echo $date_gmt | awk '{print $1}')
    date_num=$(echo $date_gmt | awk '{print $2}')
    month=$(echo $date_gmt | awk '{print $3}')
    year=$(echo $date_gmt | awk '{print $4}')
    time=$(echo $date_gmt | awk '{print $5}')

    case "$month" in
        Jan) month_num=1 ;;
        Feb) month_num=2 ;;
        Mar) month_num=3 ;;
        Apr) month_num=4 ;;
        May) month_num=5 ;;
        Jun) month_num=6 ;;
        Jul) month_num=7 ;;
        Aug) month_num=8 ;;
        Sep) month_num=9 ;;
        Oct) month_num=10 ;;
        Nov) month_num=11 ;;
        Dec) month_num=12 ;;
        *) echo "Invalid : $month" && exit 1 ;;
    esac

    hour=$(echo $time | awk -F: '{print $1}')
    minute=$(echo $time | awk -F: '{print $2}')
    second=$(echo $time | awk -F: '{print $3}')

    if ! [[ "$hour" =~ ^[0-9]+$ ]]; then
        echo "Invalid : $hour" && exit 1
    fi

    hour_no_zero=$(printf "%d" "$hour")

    timezone=$(busybox date +%Z)

    case "$timezone" in
        WIB) offset=7 ;;
        WITA) offset=8 ;;
        WIT) offset=9 ;;
        *) 
            echo "Invalid Timezone $timezone, Set To WIB"
            offset=7 ;;
    esac

    local_time=$((hour_no_zero + offset))

    if [ "$local_time" -ge 24 ]; then
        local_time=$((local_time - 24))
        date_num=$((date_num + 1))
        if [ "$date_num" -gt 31 ]; then
            date_num=1
            month_num=$((month_num + 1))
            if [ "$month_num" -gt 12 ]; then
                month_num=1
                year=$((year + 1))
            fi
        fi
    fi

    time_local=$(printf "%02d:%02d:%02d" "$local_time" "$minute" "$second")

    date_local="$year-$month_num-$date_num $time_local"
    
    busybox date -s "$date_local"
else
    echo "Failed get date from $provider_bug."
fi
