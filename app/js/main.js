import { currentNetwork, currentAddress } from './config'
import initOnboard from './onboard'
import contracts from './contracts'

import connectWalletPort from './ports/connect_wallet_port'
import getHistoryPort from './ports/get_history_port'
import getBetsPort from './ports/get_bets_port'
import resolutionPort from './ports/resolution_port'

// Initial data passed to Elm (should match `Flags` defined in `Shared.elm`)
// https://guide.elm-lang.org/interop/flags.html
const flags = {
    url: location.href.replace('/#/', '/'),
    https: location.protocol === "https",
    domain: location.hostname,
    http_port: parseInt(location.port) || 443,
    x2eth_address: contracts.contract('lottery', currentNetwork()).address,
    x2eth_history_address: contracts.contract('history', currentNetwork()).address,
    inner_width: window.innerWidth,
    inner_height: window.innerHeight,
    closed_earn_l7l_modal: localStorage.getItem('closedEarnL7LModal') ? true : false
}

// Start our Elm application
const app = Elm.Main.init({
    flags: flags,
    node: document.getElementById('elm-main')
})
const onboard = initOnboard(app, contracts)

// Inform app of browser navigation (the BACK and FORWARD buttons)
window.addEventListener('popstate', function () {
    app.ports.onUrlChange.send(location.href.replace('/#/', '/'));
});

// Change the URL upon request, inform app of the change.
app.ports.pushUrl.subscribe(function(url) {
    history.pushState({}, '', url);
    app.ports.onUrlChange.send(location.href.replace('/#/', '/'));
});

// Change the URL upon request (hardcore redirect).
app.ports.externalUrl.subscribe(function(url) {
    document.location.href = url;
});

// Save closed L7L earning popup state.
app.ports.closeEarnL7L.subscribe(function(_) {
    localStorage.setItem('closedEarnL7LModal', 'true');
})

// Copy ref link to clipboard
const clipboard = new ClipboardJS('#ref-link-copy');
clipboard.on('success', function(e) {
    const tooltip = document.getElementById('ref-link-copied');
    tooltip.style.display = 'block';
    setTimeout(() => {
        tooltip.style.display = 'none';
    }, 1500)
});


// Ports go here
// https://guide.elm-lang.org/interop/ports.html

connectWalletPort(onboard, app)

// Before user connects wallet, we get bets, history and track progresss for current round
if (!currentAddress()) {
    getBetsPort(app, currentNetwork(), contracts)
    getHistoryPort(app, currentNetwork(), contracts)
    resolutionPort(app, currentNetwork(), contracts)
}
