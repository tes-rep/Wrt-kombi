'use strict';
'require rpc';
'require poll';
'require view';
'require fs';
'require uci';

let nikki;
try {
    nikki = require('tools.nikki');
} catch (e) {
    nikki = {
        status: () => Promise.resolve(false),
        version: () => Promise.resolve({ app:'', core:'' })
    };
}

function renderBox(name, state, extra = '') {
    const gradients = {
        running: 'linear-gradient(to right, #00c853, #64dd17)',
        stopped: 'linear-gradient(to right, #e53935, #ef5350)',
        not_installed: 'linear-gradient(to right, #546e7a, #90a4ae)'
    };

    const icons = {
        running: '🟢',
        stopped: '🔴',
        not_installed: '⚫'
    };

    const label = {
        running: 'Running',
        stopped: 'Stopped',
        not_installed: 'Not Installed'
    };

    return E('div', {
        style: `
            margin-bottom: 0.5em;
            padding: 0.5em;
            border-radius: 6px;
            background: ${gradients[state]};
            color: white;
            font-weight: bold;
        `
    }, [`${icons[state]} ${name}: ${label[state]}${extra ? ' - ' + extra : ''}`]);
}

const callSSRPlusStatus = rpc.declare({
    object: 'luci.ssrlib',
    method: 'status',
    expect: { '': {} }
});

function safeCallStatus(call) {
    return call().then(res => {
        return res && typeof res.running !== 'undefined'
            ? (res.running ? 'running' : 'stopped')
            : 'not_installed';
    }).catch(() => 'not_installed');
}

function fetchOpenClashStatus() {
    return fetch(L.url('admin/services/openclash/status'))
        .then(res => res.ok ? res.json() : null)
        .then(data => {
            if (!data) return { state: 'not_installed' };
            return {
                state: data.clash ? 'running' : 'stopped',
                core: data.core_type || ''
            };
        }).catch(() => ({ state: 'not_installed' }));
}

function fetchPasswallStatus() {
    return fetch(L.url('admin/services/passwall/index_status'))
        .then(res => res.ok ? res.json() : null)
        .then(data => {
            if (!data) return 'not_installed';
            return data.tcp_node_status ? 'running' : 'stopped';
        })
        .catch(() => 'not_installed');
}

function fetchNikkiStatus() {
    return Promise.all([
        nikki.status(),
        nikki.version()
    ]).then(([status, version]) => {
        const appVer = version?.app || '';
        const coreVer = version?.core || '';
        const extra = [appVer && `App ${appVer}`, coreVer && `Core ${coreVer}`].filter(Boolean).join(' | ');
        return {
            state: status ? 'running' : 'stopped',
            version: extra
        };
    }).catch(() => ({
        state: 'not_installed',
        version: ''
    }));
}

function fetchTailscaleStatus() {
    return fs.exec('/sbin/ip', ['-s', '-j', 'address']).then(res => {
        if (res.code !== 0 || !res.stdout) return 'not_installed';
        try {
            const interfaces = JSON.parse(res.stdout.trim());
            const tailscaleIfaces = interfaces.filter(i => i.ifname && i.ifname.match(/^tailscale[0-9]+$/));
            return tailscaleIfaces.length > 0 ? 'running' : 'stopped';
        } catch (e) {
            return 'not_installed';
        }
    }).catch(() => 'not_installed');
}

return view.extend({
    title: _('VPN TOOLS'),
    load: function () {
        return Promise.all([
            fetchOpenClashStatus(),
            fetchPasswallStatus(),
            safeCallStatus(callSSRPlusStatus),
            fetchNikkiStatus(),
            fetchTailscaleStatus()
        ]);
    },

    render: function ([openclash, passwall, ssrplus, nikki, tailscale]) {
        const container = E('div', { class: 'cbi-map' }, [
            E('div', { id: 'status_openclash' }, renderBox('OpenClash', openclash.state, openclash.core)),
            E('div', { id: 'status_passwall' }, renderBox('Passwall', passwall)),
            E('div', { id: 'status_ssrplus' }, renderBox('SSR Plus', ssrplus)),
            E('div', { id: 'status_nikki' }, renderBox('Nikki Core', nikki.state, nikki.version)),
            E('div', { id: 'status_tailscale' }, renderBox('Tailscale', tailscale))
        ]);

        poll.add(function () {
            return Promise.all([
                fetchOpenClashStatus(),
                fetchPasswallStatus(),
                safeCallStatus(callSSRPlusStatus),
                fetchNikkiStatus(),
                fetchTailscaleStatus()
            ]).then(([openclash, passwall, ssrplus, nikki, tailscale]) => {
                document.getElementById('status_openclash').innerHTML = renderBox('OpenClash', openclash.state, openclash.core).outerHTML;
                document.getElementById('status_passwall').innerHTML = renderBox('Passwall', passwall).outerHTML;
                document.getElementById('status_ssrplus').innerHTML = renderBox('SSR Plus', ssrplus).outerHTML;
                document.getElementById('status_nikki').innerHTML = renderBox('Nikki Core', nikki.state, nikki.version).outerHTML;
                document.getElementById('status_tailscale').innerHTML = renderBox('Tailscale', tailscale).outerHTML;
            });
        });

        return container;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
