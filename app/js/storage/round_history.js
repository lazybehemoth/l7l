import Dexie from 'dexie'

const DEFAULT_ADDRESS = '0x0000000000000000000000000000000000000000'

const db = new Dexie("RoundHistory")
db.version(1).stores({
    rounds: "&[address+round],myBetSide,myBetAmount",
    blocks: "&address,firstBlock,lastBlock"
})

const saveBlockRange = (address, firstBlock, lastBlock) => {
    address = address || DEFAULT_ADDRESS
    return db.blocks.get(address)
        .then((data) => {
            if (!data) return db.blocks.add({address, firstBlock, lastBlock})
            return db.blocks.update(address, {
                firstBlock: firstBlock < data.firstBlock ? firstBlock : data.firstBlock,
                lastBlock: lastBlock > data.lastBlock ? lastBlock : data.lastBlock
            })
        })
}

const getBlockRange = (address) => {
    address = address || DEFAULT_ADDRESS
    return db.blocks
        .get(address)
        .then((data) => data && data.lastBlock ? [data.firstBlock, data.lastBlock] : [0, 0])
        .catch(Dexie.DataError, _ => [0, 0])
}

const saveEvent = (address, event) => {
    address = address || DEFAULT_ADDRESS
    event['address'] = address
    return db.rounds.where(['address+round'])
        .equals([address, event.round])
        .first()
        .then((data) => {
            if (!data) {
                return db.rounds.add(event)
            } else if (!data.myBetAmount)  {
                return db.rounds.put(event)
            }
            return Promise.resolve(data)
        })
}

const getEventsForPage = (address, currentRound, page, perPage) => {
    address = address || DEFAULT_ADDRESS
    const from = currentRound - (page * perPage)
    const to = from + (page * perPage)
    return db.rounds
        .where(['address+round'])
        .between([address, from], [address, to])
        .toArray()
        .then(events => events.map(event => {
            delete event.address
            return event
        }))
}

export { saveEvent, getEventsForPage, saveBlockRange, getBlockRange }