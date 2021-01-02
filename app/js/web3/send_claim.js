import { ethersProvider } from '../config'

export default (appNetworkId, { contract }, updateClaim, notifyConfimations) => {
    const lotteryContract = contract('lottery', appNetworkId)
    const signer = ethersProvider().getSigner()
    const lotteryContractSigner = lotteryContract.connect(signer)

    const treasuryContract = contract('treasury', appNetworkId)
    treasuryContract.on('EthClaimFailure', (destAddr, bootyAddr, error) => {
        console.log(destAddr, bootyAddr, error)
    })
    treasuryContract.on('EthClaimed', (destAddr, i) => {
        console.log(destAddr, i)
    })

    return lotteryContractSigner.claimBooty({ gasLimit: 500000 })
        .then(result => {
            notifyConfimations(result.confirmations)
            return Promise.resolve(result.hash)
        })
        .then(hash => ethersProvider().waitForTransaction(hash))
        .then(({ confirmations }) => {
            notifyConfimations(confirmations)
            updateClaim('0.0')
        })
        .catch(error => {
            console.log('Claim failed', error)
            notifyConfimations(-1)
        })
}