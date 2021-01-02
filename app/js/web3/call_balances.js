import { ethersProvider } from '../config'

export default (selectedAddress, { contract }) => {
    return selectedAddress
        .then(({address, appNetworkId}) => {
            if (!address) throw 'no address for connected wallet'
            if (!appNetworkId) throw 'no network for connected wallet'

            const treasuryContract = contract('treasury', appNetworkId)

            return Promise.all([
                Promise.resolve(address),
                ethersProvider().getBalance(address),
                treasuryContract.payments(address),
                treasuryContract.balanceOfL7l(address)
            ])
        })
}