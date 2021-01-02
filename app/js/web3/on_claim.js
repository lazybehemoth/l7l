import { ethersProvider, currentAddress } from '../config'

export default (appNetworkId, { contract, subOnceToContract }, onBalanceUpdate) => {
    const treasuryContract = contract('treasury', appNetworkId)
    const address = currentAddress()
    const filter = treasuryContract.filters.EthClaimed(address, null)

    subOnceToContract('treasury', appNetworkId, `EthClaimed-${address}`, filter, (address, _event) => {
        if (address.toLowerCase() !== currentAddress()) return

        return ethersProvider().getBalance(address)
            .then(ethBalance => {
                onBalanceUpdate(ethBalance.toString())
            })  
    }).catch(console.error)
}