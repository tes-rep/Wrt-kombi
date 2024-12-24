'use strict';
'require baseclass';
'require fs';
'require rpc';
var callSystemBoard = rpc.declare({
   object: 'system',
   method: 'board'
});
var callSystemInfo = rpc.declare({
   object: 'system',
   method: 'info'
});
return baseclass.extend({
   title: _('VPN TOOLS'),
   load: function () {
      return Promise.all([L.resolveDefault(callSystemBoard(), {}), L.resolveDefault(callSystemInfo(), {}), fs.lines('/usr/lib/lua/luci/version.lua')]);
   },
   render: function (data) {
      var boardinfo = data[0],
         systeminfo = data[1],
         luciversion = data[2];
      luciversion = luciversion.filter(function (l) {}).join(' ');
      var fields = [_("zerotir"), zerotier_status, _("openclash"), _clash, _("passwal"), wall];
      var table = E('table', {
         'class': 'table'
      });
      for (var i = 0; i < fields.length; i += 2) {
         table.appendChild(E('tr', {
            'class': 'tr'
         }, [E('td', {
            'class': 'td left',
            'width': '33%'
         }, [fields[i]]), E('td', {
            'class': 'td left'
         }, [(fields[i + 1] != null) ? fields[i + 1] : '?'])]));
      }
      return table;
   }
});