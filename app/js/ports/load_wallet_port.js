export default (app, balances) => {
    return balances
        .then(([address, ethBalance, ethToClaim, l7lToClaim]) => {
            app.ports.walletConnected.send(address)
            app.ports.updateEthWalletBalance.send(ethBalance.toString())
            app.ports.updateEthBalanceForClaim.send(ethToClaim.toString())
            app.ports.updateL7lBalanceForClaim.send(l7lToClaim.toString())

            return Promise.resolve(address)
        })
}