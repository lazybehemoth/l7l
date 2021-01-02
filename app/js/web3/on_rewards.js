import { currentAddress } from '../config'

export default async (
    appNetworkId,
    { contract, contractPromise, subOnceToContract },
    address,
    updateEthBalanceForClaim,
    updateL7lBalanceForClaim,
    notifyResult
) => {
    const lotteryContract = contract('lottery', appNetworkId)
    const treasuryContract = await contractPromise('treasury', appNetworkId)
    const loserRewardCof = await lotteryContract.loserRewardCof()
    
    subOnceToContract('history', appNetworkId, `RoundEnded-${address}`, 'RoundEnded', (round, randomness, totalBooty, totalWinners, e) => {
        console.log('RoundEnded', round, randomness, totalBooty, totalWinners, e)

        if (address.toLowerCase() !== currentAddress()) return
        if (randomness.toString() === '0') return
        if (localStorage.getItem(`resultAcknowledged-${address}-${e.blockNumber}`) != null) return

        return lotteryContract.lastRoundPlayed(address)
            .then((lastRoundPlayed) => {
                console.log("Last played", lastRoundPlayed, round)
                if (lastRoundPlayed != round) return Promise.resolve(null)
                
                return lotteryContract.TrustedBooties(round)
            })
            .then(bootyAddr => contractPromise(['booty', bootyAddr]))
            .then(bootyContract => Promise.all([bootyContract.losesOf(address), bootyContract.unlockedBalanceOf(address)]))
            .then(([loses, wins]) => {
                if (address.toLowerCase() !== currentAddress()) return Promise.resolve(null)
                if (loses.toString() === '0' && wins.toString() === '0') return Promise.resolve(null)

                if (loses.gt(wins)) {
                    notifyResult({
                        win: false,
                        block: e.blockNumber,
                        transactionHash: e.transactionHash,
                        round: round,
                        address: address,
                        amount: loses.mul(loserRewardCof).toString(),
                        result: randomness.toString()
                    })
                } else {
                    notifyResult({
                        win: true,
                        block: e.blockNumber,
                        transactionHash: e.transactionHash,
                        round: round,
                        address: address,
                        amount: wins.sub(loses).toString(),
                        result: randomness.toString()
                    })
                }

                if (wins.toString() !== '0') {
                    return treasuryContract.payments(address)
                        .then((balance) => updateEthBalanceForClaim(balance.toString()))
                } else {
                    return Promise.resolve(true);
                }
            })
    }).catch(console.error)

    const rewardFilter = treasuryContract.filters.L7lRewarded(address, null)
    subOnceToContract('treasury', appNetworkId, `L7lRewarded-${address}`, rewardFilter, (address, a, e) => {
        console.log('L7lRewarded', address, a, e)

        if (address.toLowerCase() !== currentAddress()) return

        return treasuryContract.balanceOfL7l(address)
            .then((balance) => updateL7lBalanceForClaim(balance.toString()))
    }).catch(console.error)
}