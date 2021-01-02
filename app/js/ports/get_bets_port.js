import callBets from '../web3/call_bets'

export default (app, appNetworkId, contracts) => {
    callBets(
        appNetworkId,
        contracts,
        (totalBooty, bets) => {
            app.ports.totalGreenBooty.send(totalBooty)
            app.ports.greenBets.send(bets)
        },
        (totalBooty, bets) => {
            app.ports.totalBlueBooty.send(totalBooty)
            app.ports.blueBets.send(bets)
        }
    )
}