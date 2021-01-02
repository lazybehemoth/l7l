import { currentAddress } from '../config'

import onRewards from '../web3/on_rewards'

import l7lRewardsPort from './l7l_rewards_port'

let resultAcknowledgeSub

export default (app, appNetworkId, contracts) => {
    if (resultAcknowledgeSub) app.ports.resultAcknowledged.unsubscribe(resultAcknowledgeSub)
    resultAcknowledgeSub = block => {
        localStorage.setItem(`resultAcknowledged-${currentAddress()}-${block}`, 'true')
        
        // Update pending L7L rewards after lose acknowledgement
        l7lRewardsPort(app, appNetworkId, contracts)
    }
    app.ports.resultAcknowledged.subscribe(resultAcknowledgeSub)

    onRewards(
        appNetworkId,
        contracts,
        currentAddress(),
        app.ports.updateEthBalanceForClaim.send,
        app.ports.updateL7lBalanceForClaim.send,
        app.ports.notifyResult.send
    )
}