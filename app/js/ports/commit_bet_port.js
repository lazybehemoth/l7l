import sendBet from '../web3/send_bet'

let currentBetBlueSub, currentBetGreenSub

export default (app, appNetworkId, contracts) => {
    if (currentBetBlueSub) app.ports.betBlue.unsubscribe(currentBetBlueSub)
    currentBetBlueSub = amount => {
        sendBet(appNetworkId, contracts, 'BLUE', amount, app.ports.betCommitment.send, app.ports.roundEndsIn.send)
    }
    app.ports.betBlue.subscribe(currentBetBlueSub)

    if (currentBetGreenSub) app.ports.betGreen.unsubscribe(currentBetGreenSub)
    currentBetGreenSub = amount => {
        sendBet(appNetworkId, contracts, 'GREEN', amount, app.ports.betCommitment.send, app.ports.roundEndsIn.send)
    }
    app.ports.betGreen.subscribe(currentBetGreenSub)
}