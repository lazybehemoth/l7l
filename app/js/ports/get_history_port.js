import callHistoryPerPage from '../web3/call_history_per_page'

let historySub

export default (app, appNetworkId, contracts) => {
    if (historySub) app.ports.resultsHistoryPage.unsubscribe(historySub)
    historySub = (page) => {
        callHistoryPerPage(appNetworkId, page, contracts, false)
            .then(app.ports.resultsHistory.send)
            .catch(console.error)
    }
    app.ports.resultsHistoryPage.subscribe(historySub)
}