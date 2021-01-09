import { ethers } from 'ethers/dist/ethers-all.esm.min'  

export default async (appNetworkId, { contract, contractPromise }, roundEndsIn, defaultTimer = -50000) => {
    const lotteryContract = contract('lottery', appNetworkId)

    return contractPromise('currentBooty', appNetworkId)
        .then(bouty => {
            return Promise.all([
                lotteryContract.canContinue(),
                lotteryContract.endsAfter(),
                bouty.totalGreen(),
                bouty.totalBlue()
            ])
        })
        .then(([canContinue, endsAfter, totalGreen, totalBlue]) => {
            if (canContinue) {
                roundEndsIn(-1)
            // Only auto market making in a booty contract
            } else if (totalGreen.eq(totalBlue) && totalGreen.lt(ethers.BigNumber.from('2500000000000000000'))) {
                roundEndsIn(defaultTimer)
            } else {
                const now = new Date()
                const secondsSinceEpoch = Math.round(now.getTime() / 1000)
                roundEndsIn(endsAfter.toNumber() - secondsSinceEpoch)
            }
        })
        .catch(console.error)
}
