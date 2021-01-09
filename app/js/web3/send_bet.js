import { ethersProvider } from '../config'
import callRoundEndsIn from './call_round_ends_in'

const DEFAULT_ADDRESS = '0x0000000000000000000000000000000000000000'

const processBetPromise = (contracts, appNetworkId, betPromise, notifyConfimations, roundEndsIn) => {
    betPromise
        .then(result => {
            notifyConfimations(result.confirmations)
            return Promise.resolve(result.hash)
        })
        .then(hash => ethersProvider().waitForTransaction(hash))
        .then(({ confirmations }) => {
            notifyConfimations(confirmations)
            return callRoundEndsIn(appNetworkId, contracts, roundEndsIn, 86400)
        })
        .catch(error => {
            console.error("Bet failed", error)
            notifyConfimations(-1)
        })
}

export default (appNetworkId, contracts, betType, amount, notifyConfimations, roundEndsIn) => {
    const lotteryContract = contracts.contract('lottery', appNetworkId)
    const signer = ethersProvider().getSigner()
    const lotteryContractSigner = lotteryContract.connect(signer)
    const referrer = localStorage.getItem('referrer') || DEFAULT_ADDRESS

    if (betType === 'GREEN') {
        const betPromise = lotteryContractSigner.betGreen(referrer, { value: amount })
        return processBetPromise(contracts, appNetworkId, betPromise, notifyConfimations, roundEndsIn)
    } else if (betType === 'BLUE') {
        const betPromise = lotteryContractSigner.betBlue(referrer, { value: amount })
        return processBetPromise(contracts, appNetworkId, betPromise, notifyConfimations, roundEndsIn)
    }
}