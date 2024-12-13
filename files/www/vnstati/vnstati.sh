#!/bin/bash
vnstati -s -i br-hotspot -o /www/vnstati/br-hotspot_vnstat_s.png
vnstati -5 -i br-hotspot -o /www/vnstati/br-hotspot_vnstat_5.png
vnstati -h -i br-hotspot -o /www/vnstati/br-hotspot_vnstat_h.png
vnstati -d -i br-hotspot -o /www/vnstati/br-hotspot_vnstat_d.png
vnstati -m -i br-hotspot -o /www/vnstati/br-hotspot_vnstat_m.png
vnstati -y -i br-hotspot -o /www/vnstati/br-hotspot_vnstat_y.png
vnstati -t -i br-hotspot -o /www/vnstati/br-hotspot_vnstat_t.png