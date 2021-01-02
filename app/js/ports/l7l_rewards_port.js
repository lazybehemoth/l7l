import { currentAddress } from '../config'

export default (app, appNetworkId, contracts) => {
    const lotteryContract = contracts.contract('lottery', appNetworkId)
    const refCof = localStorage.getItem('referrer') ? 10 : 0

    Promise.all([
        lotteryContract.rewardCof(),
        lotteryContract.pendingL7lRewards(currentAddress())
    ])
        .then(([rewardCof, pendingL7l]) => {
            app.ports.updateL7lReward.send(rewardCof.toNumber() + refCof)
            app.ports.updatePendingL7lReward.send(pendingL7l.toString())
        })
        .catch(console.error)
}