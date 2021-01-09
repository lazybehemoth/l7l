import callHistoryPerPage from '../web3/call_history_per_page'
import callBets from '../web3/call_bets'
import callRoundEndsIn from '../web3/call_round_ends_in'

export default (app, appNetworkId, contracts) => {
    const lotteryHistoryContract = contracts.contract('history', appNetworkId)
   
    lotteryHistoryContract.on("RoundStarted", (round, endsAfter, event) => {
        console.log("RoundStarted", event)

        //const now = new Date()  
        //const secondsSinceEpoch = Math.round(now.getTime() / 1000)

        app.ports.currentRound.send(round)
        app.ports.roundEndsIn.send(-50000 /*endsAfter.toNumber() - secondsSinceEpoch*/)
        app.ports.greenBets.send([])
        app.ports.blueBets.send([])
        app.ports.totalBlueBooty.send('0')
        app.ports.totalGreenBooty.send('0')

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
    });

    lotteryHistoryContract.on("RoundEnded", (round, randomness, totalBooty, totalWinners, event) => {
        console.log("RoundEnded", round, randomness, totalBooty, totalWinners, event)

        callHistoryPerPage(appNetworkId, 1, contracts, true)
            .then(app.ports.resultsHistory.send)
            .catch(console.error)
    })

    callRoundEndsIn(appNetworkId, contracts, app.ports.roundEndsIn.send)
        .catch(console.error)
}
