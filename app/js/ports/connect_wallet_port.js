const connectWallet = (onboard, prevSelWallet) => {
    const selectedAddress =
        (prevSelWallet != null ? onboard.walletSelect(prevSelWallet) : onboard.walletSelect())
            .then((result) => {
                if (!result) throw "invalid wallet"

                return onboard.walletCheck()
            })
            .then((result) => {
                if (!result) throw "invalid wallet address"

                const currentState = onboard.getState()
                return Promise.resolve(currentState)
            })

    return selectedAddress;
}

const changeWallet = (app, onboard) => {
    onboard.walletReset()
    
    app.ports.walletConnected.send('')
    app.ports.updateEthWalletBalance.send('0')
    app.ports.updateEthBalanceForClaim.send('0')
    app.ports.updateL7lBalanceForClaim.send('0')
}

export default (onboard, app) => {
    const prevSelWallet = window.localStorage.getItem('selectedWallet')
  
    // call wallet select with that value if it exists
    if (prevSelWallet != null) {
        connectWallet(onboard, prevSelWallet)
    }

    app.ports.connectWallet.subscribe(async () => {
        connectWallet(onboard, null)
    })

    app.ports.changeWallet.subscribe(async () => {
        changeWallet(app, onboard)
    })
}