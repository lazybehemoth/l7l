import { currentAddress } from '../config'

const parseBets = (bets) => {
    return bets.map(({args}) => {
        return { address: args.player, amount: args.amount.toString() }
    })
}

const isUniqueBet = (bets, newBet) =>  {
    return bets.filter(bet => bet.address === newBet.address && bet.amount === newBet.amount).length == 0
}

let totalGreenBooty, totalBlueBooty, greenBets = [], blueBets = []

export default async (appNetworkId, { contract, contractPromise }, notifyGreenBets, notifyBlueBets) => {
    const lotteryContract = contract('lottery', appNetworkId)
    const lotteryHistoryContract = contract('history', appNetworkId)
    const currentBootyContract = await contractPromise('currentBooty', appNetworkId)
    const currentRound = await lotteryContract.currentRound()

    // It's possible to miss 2 identical bets for the same side from the same player, 
    // but we ignore such edge case (such bet can be seen with page refresh)
    lotteryHistoryContract.on('NewBet', (round, side, player, amount) => {
        console.log('NewBet', currentRound, round, side, player, amount);

        if (round !== currentRound) return

        const newBet = { address: player, amount: amount.toString() }

        console.log(side.toString(), side.toString() === '0', isUniqueBet(blueBets, newBet), newBet)

        if (side.toString() === '0' && isUniqueBet(blueBets, newBet)) {
            totalBlueBooty = totalBlueBooty.add(amount)
            blueBets.unshift(newBet)
            notifyBlueBets(totalBlueBooty.toString(), blueBets)
        }

        if (side.toString() === '1' && isUniqueBet(greenBets, newBet)) {
            totalGreenBooty = totalGreenBooty.add(amount)
            greenBets.unshift(newBet)
            notifyGreenBets(totalGreenBooty.toString(), greenBets)
        }
    })

    // No bets are possible in this gap
    if (await lotteryContract.canContinue()) {
        notifyBlueBets('0', [])
        notifyGreenBets('0', [])

        return Promise.all([
            Promise.resolve('0'),
            Promise.resolve('0'),
            Promise.resolve([]),
            Promise.resolve([])
        ])
    }

    const address = currentAddress()
    const greenBetsFilter = currentBootyContract.filters.Bet(null, null, 1, currentRound)
    const blueBetsFilter = currentBootyContract.filters.Bet(null, null, 0, currentRound)
    const currentBlock = await currentBootyContract.provider.getBlockNumber()
    const allGreenBets = currentBootyContract.queryFilter(greenBetsFilter, currentBlock - (6600 * 30), currentBlock)
    const allBlueBets = currentBootyContract.queryFilter(blueBetsFilter, currentBlock - (6600 * 30), currentBlock)

    return Promise.all([
        currentBootyContract.totalGreen(),
        currentBootyContract.totalBlue(),
        allGreenBets,
        allBlueBets
    ]).then(([_totalGreenBooty, _totalBlueBooty, _greenBets, _blueBets]) => {
        console.log(_greenBets, _blueBets)
        if (address !== currentAddress()) return // switched address

        totalGreenBooty = _totalGreenBooty
        totalBlueBooty = _totalBlueBooty
        greenBets = parseBets(_greenBets)
        blueBets = parseBets(_blueBets)

        notifyBlueBets(totalBlueBooty.toString(), blueBets)
        notifyGreenBets(totalGreenBooty.toString(), greenBets)

        return Promise.all([totalGreenBooty, totalBlueBooty, greenBets, blueBets])
    })
    .catch(console.error)
}