import onClaim from '../web3/on_claim'
import sendClaim from '../web3/send_claim'

let currentClaimSub

export default (app, appNetworkId, contracts) => {
    onClaim(appNetworkId, contracts, app.ports.updateEthWalletBalance.send)

    if (currentClaimSub) app.ports.claimEth.unsubscribe(currentClaimSub)
    currentClaimSub = () => {
        sendClaim(appNetworkId, contracts, app.ports.updateEthBalanceForClaim.send, app.ports.claimEthState.send)
    }
    app.ports.claimEth.subscribe(currentClaimSub)  
}