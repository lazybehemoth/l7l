import { ethers } from 'ethers/dist/ethers-all.esm.min'
import { currentAddress } from '../config'
import { saveEvent, getEventsForPage, saveBlockRange, getBlockRange } from '../storage/round_history'

const DEFAULT_ADDRESS = '0x0000000000000000000000000000000000000000'
const BLOCKS_PER_DAY = 6600
const BLOCKS_PER_PAGE = BLOCKS_PER_DAY * 6
const EVEN = ethers.BigNumber.from('2')
const ZERO = ethers.BigNumber.from('0')

const blockRange = (page, currentBlock, cachedFromBlock, cachedToBlock) => {
    const fromBlockMod = page * BLOCKS_PER_PAGE
    const fromBlock = (currentBlock - fromBlockMod) > 0 ? currentBlock - fromBlockMod : 0
    const toBlock = (fromBlock + BLOCKS_PER_PAGE) > currentBlock ? currentBlock : fromBlock + BLOCKS_PER_PAGE

    if (toBlock > cachedToBlock) {
        return [
            cachedToBlock + 1,
            toBlock,
            true
        ]
    } else if (fromBlock < cachedFromBlock) {
        return [
            fromBlock,
            cachedFromBlock - 1,
            true
        ]
    } else {
        return [
            cachedFromBlock,
            cachedToBlock,
            false
        ]
    }
}

function uniqByKeepLast(a, key) {
    return [
        ...new Map(
            a.map(x => [key(x), x])
        ).values()
    ]
}

// Increment is used when current round is completed and new is not started
export default (appNetworkId, page, { contract }, inc) => {
    const perPage = window.innerWidth <= 600 ? 3 : 6
    const from = (page - 1) * perPage + 1
    const to = from + perPage - 1

    let from_, to_, fromBlock, toBlock, queryNew

    const lotteryContract = contract('lottery', appNetworkId)
    const lotteryHistoryContract = contract('history', appNetworkId)
    const address = currentAddress()

    return Promise.all([
        lotteryContract.canContinue(),
        lotteryContract.currentRound(),
        lotteryContract.provider.getBlockNumber(),
        getBlockRange(address || DEFAULT_ADDRESS)
    ])
        .then(([canContinue, currentRound, currentBlock, [cachedFromBlock, cachedToBlock]]) => {
            currentRound = inc || canContinue ? currentRound + 1 : currentRound
            from_ = (currentRound - to) > 0 ? currentRound - to : 0
            to_ = currentRound - from

            let range = blockRange(page, currentBlock, cachedFromBlock, cachedToBlock)
            fromBlock = range[0]
            toBlock = range[1]
            queryNew = range[2]

            console.log(
                'History blocks',
                'not cached', queryNew,
                'current', currentBlock,
                'cacheFrom', cachedFromBlock,
                'cacheTo', cachedToBlock,
                'from', fromBlock,
                'to', toBlock,
            )

            // Keep mind that single Market Maker recycled rounds doesn't generate NewBet events,
            // so that MM address has wrong stats in history (no bet), despite it's participation
            // and possible winning / losses.
            return getEventsForPage(address || DEFAULT_ADDRESS, currentRound, page, perPage)
                .catch(console.error)
                .then(cachedEvents => {
                    let resolveEvents, myBetsEvents
                    if (queryNew) {
                        resolveEvents = lotteryHistoryContract.queryFilter('RoundEnded', fromBlock, toBlock)

                        if (address) {
                            const betsFromBlock = (fromBlock - BLOCKS_PER_DAY) > 0 ? fromBlock - BLOCKS_PER_DAY : 0
                            const myBetsFilter = lotteryHistoryContract.filters.NewBet(null, null, address, null)
                            myBetsEvents = lotteryHistoryContract.queryFilter(myBetsFilter, betsFromBlock, toBlock)
                        } else {
                            myBetsEvents = Promise.resolve([])
                        }
                    } else {
                        resolveEvents = Promise.resolve([])
                        myBetsEvents = Promise.resolve([])
                    }

                    return Promise.all([resolveEvents, myBetsEvents, Promise.resolve(cachedEvents)])
                })
        })
        .then(([events, betEvents, cachedEvents]) => {
            const myBets = betEvents.reduce((acc, {args}) => {
                if (!acc[args.round]) acc[args.round] = {}

                // Multiple bets in a same round are resolved in a complex way
                if (acc[args.round][args.side]) {
                    acc[args.round][args.side] = acc[args.round][args.side].add(args.amount)
                } else {
                    acc[args.round][args.side] = args.amount
                }
                return acc
            }, {})

            let parsedEvents = events.map(({args, transactionHash}) => {
                let data = {
                    round: args.round,
                    transactionHash: transactionHash,
                    result: args.randomness.toString(),
                    totalBooty: args.totalBooty.toString(),
                    totalWinners: args.totalWinners.toString(),
                    myBetSide: null,
                    myBetAmount: null
                }
                
                if (myBets[args.round] && args.totalBooty.gt(ZERO)) {
                    let myWin = ZERO, myBet = ZERO, myLose = ZERO, mySaldo = ZERO, myGreen = ZERO, myBlue = ZERO

                    if (myBets[args.round][0]) myBlue = myBets[args.round][0]
                    if (myBets[args.round][1]) myGreen = myBets[args.round][1]

                    if (args.randomness.mod(EVEN).toString() === '0') {
                        myBet = myBet.add(myBlue)
                        myWin = myWin.add(args.totalBooty.mul(myBet).div(args.totalWinners))
                        myLose = myLose.add(myGreen)
                    }
                    
                    if (args.randomness.mod(EVEN).toString() === '1') {
                        myBet = myBet.add(myGreen)
                        myWin = myWin.add(args.totalBooty.mul(myBet).div(args.totalWinners))
                        myLose = myLose.add(myBlue)
                    }

                    mySaldo = myWin.sub(myLose).sub(myBet)
                    if (!mySaldo.eq(ZERO)) {
                        data.myBetSide = myGreen.gt(myBlue) ? 'GREEN' : 'BLUE'
                        data.myBetAmount = mySaldo.toString()
                    }
                }

                // async side-effect
                saveEvent(address || DEFAULT_ADDRESS, data)
                return data
            })

            // async side-effect
            saveBlockRange(address || DEFAULT_ADDRESS, fromBlock, toBlock)

            const allEvents = cachedEvents
                .concat(parsedEvents)
                .filter(({round}) => round >= from_ && round <= to_)
                .sort((a, b) => a.round > b.round)

            return Promise.resolve(uniqByKeepLast(allEvents, (i) => i.round))
        })
}
