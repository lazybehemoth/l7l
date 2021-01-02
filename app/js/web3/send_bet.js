import { ethersProvider } from '../config'

const DEFAULT_ADDRESS = '0x0000000000000000000000000000000000000000'

const processBetPromise = (betPromise, notifyConfimations) => {
    betPromise
        .then(result => {
            notifyConfimations(result.confirmations)
            return Promise.resolve(result.hash)
        })
        .then(hash => ethersProvider().waitForTransaction(hash))
        .then(({ confirmations }) => {
            notifyConfimations(confirmations)
            return Promise.resolve(true)
        })
        .catch(error => {
            console.error("Bet failed", error)
            notifyConfimations(-1)
        })
}

export default (appNetworkId, { contract }, betType, amount, notifyConfimations) => {
    const lotteryContract = contract('lottery', appNetworkId)
    const signer = ethersProvider().getSigner()
    const lotteryContractSigner = lotteryContract.connect(signer)
    const referrer = localStorage.getItem('referrer') || DEFAULT_ADDRESS

    if (betType === 'GREEN') {
        const betPromise = lotteryContractSigner.betGreen(referrer, { value: amount })
        return processBetPromise(betPromise, notifyConfimations)
    } else if (betType === 'BLUE') {
        const betPromise = lotteryContractSigner.betBlue(referrer, { value: amount })
        return processBetPromise(betPromise, notifyConfimations)
    }
}