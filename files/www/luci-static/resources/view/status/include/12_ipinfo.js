/* This is free software, licensed under the Apache License, Version 2.0
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 *  Contributor: BobbyUnknown telegram https://t.me/BobbyUn_kown
 */

'use strict';
'require view';
'require uci';
'require fs';

return view.extend({
	title: _('IP Information'),
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	load: function () {
		return uci.load('ipinfo').then(function() {
			var data = uci.sections('ipinfo');
			var jsonData = {};
			var token = data[0].token;
			if (data[0].enable === '0') {
				jsonData.uci = {
					enable: data[0].enable
				};
				return jsonData;
			} else {
				return fs.exec('curl', ['-s', '-m', '5', '-o', '/dev/null', 'https://www.google.com']).then(function(result) {
					if (result.code === 0) {
						if (data.length > 0) {
							var item = data[0];
							jsonData.uci = {
								enable: item.enable,
								isp: item.isp,
								loc: item.loc,
								co: item.co
							};
						} else {
							jsonData.uci = null;
						};
						return fs.exec('curl', ['-sL', `api.ipgeolocation.io/ipgeo?apiKey=${token}`]).then(function(result) { // Gunakan token dari konfigurasi
							var data = JSON.parse(result.stdout);
							if (data.message && data.message.includes('exceeded the limit')) {
								jsonData.error = _('Anda telah melebihi batas 1000 permintaan per hari, Silakan ganti TOKEN ANDA.');
							} else {
								jsonData.json = data;
							}
							return jsonData;
						});
					} else {
						return jsonData;
					};
				});
			};
		});
	},
	render: function (data) {
		var container;
		var table = E('table', {'class': 'table'});
		
		var style = E('style', {}, `
			.status-label {
				padding: 3px 8px;
				border-radius: 3px;
				font-weight: bold;
				display: inline-block;
			}
			.status-connected {
				background-color: #8bc34a;
				color: red;
			}
			.status-disconnected {
				background-color: #f44336;
				color: white;
			}
		`);
		document.head.appendChild(style);

		var statusRow = E('tr', {'class': 'tr'}, [
			E('td', {'class': 'td left', 'width': '33%'}, _('Status Internet')),
			E('td', {'class': 'td left'}, 
				data.uci && data.uci.enable === '1' && data.json ? 
				E('span', {'class': 'status-label status-connected'}, _('urep')) : 
				E('span', {'class': 'status-label status-disconnected'}, _('modar'))
			)
		]);
		table.appendChild(statusRow);

		if (!data || Object.keys(data).length === 0) {
			var row = E('tr', {'class': 'tr'}, [
			]);
			table.appendChild(row);
			return table;
		} else if (data.error) {
			var row = E('tr', {'class': 'tr'}, [
				E('td', {'class': 'td'}, _(data.error))
			]);
			table.appendChild(row);
			return table;
		} else if (data.uci && data.uci.enable === '1') {
			var hasData = false;
			var categories = ['isp', 'loc', 'co'];
			var propertiesToShow = {
				'ip': _('IP Publik'),
				'isp': _('ISP'),
				'organization': _('Organisasi'),
				'country_name_official': _('Nama resmi negara'),
				'city': _('City'),
				'country_name': _('Negara'),
				'time_zone.name': _('Zona Waktu'),
				'latitude': _('Latitude'),
				'longitude': _('Longitude')
			};
			var dataUci = {
				'ip': 'ip',
				'isp': 'isp',
				'organization': 'organization',
				'country_name_official': 'country_name_official',
				'city': 'city',
				'country_name': 'country_name',
				'time_zone.name': 'time_zone.name',
				'latitude': 'latitude',
				'longitude': 'longitude'
			};

			function showDataWithLoading(key, label, value) {
				var row = E('tr', {'class': 'tr'}, [
					E('td', {'class': 'td left', 'width': '33%'}, label),
					E('td', {'class': 'td left'}, E('div', {'class': 'loading'}, [
						E('div', {'class': 'spinner'}),
						E('span', {}, _('nteni sek...'))
					]))
				]);
				table.appendChild(row);

				setTimeout(() => {
					var displayValue = value || '-';
					if (key === 'country_name' && data.json.country_emoji) {
						displayValue += ' ' + data.json.country_emoji;
					}
					if (key === 'time_zone.name' && data.json.time_zone.current_time) {
						displayValue += ' ' + data.json.time_zone.current_time;
					}
					if (key === 'city' && data.json.state_prov) {
						displayValue += ' ' + data.json.state_prov;
					}
					row.querySelector('.loading').textContent = displayValue;
				}, 1000);
			}

			if (data.json) {
				categories.forEach(function(category) {
					if (data.uci[category]) {
						data.uci[category].forEach(function(key) {
							var propKey = Object.keys(dataUci).find(k => dataUci[k] === key);
							if (propKey) {
								hasData = true;
								var value = propKey.split('.').reduce((o, i) => o ? o[i] : null, data.json);
								showDataWithLoading(propKey, propertiesToShow[propKey], value);
							}
						});
					}
				});
			}
			if (!hasData) {
				var row = E('tr', {'class': 'tr'}, [
					E('td', {'class': 'td'}, _('Tidak ada data tersedia, silakan periksa pengaturan.'))
				]);
				table.appendChild(row);
			}
			return table;
		} else if (data.uci && data.uci.enable !== '1') {
			return container;
		};
	}
});
