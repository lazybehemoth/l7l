import { ethersProvider } from './config'
import { ethers } from 'ethers/dist/ethers-all.esm.min'

import governanceArtifact from '../../build/contracts/Governance.json'
import lotteryArtifact from '../../build/contracts/LotteryDoubleEth.json'
import historyArtifact from '../../build/contracts/LotteryDoubleEthHistory.json'
import randomnessArtifact from '../../build/contracts/Randomness.json'
import treasuryArtifact from '../../build/contracts/Treasury.json'
import bootyArtifact from '../../build/contracts/Booty.json'

let contracts = {}
let subscriptions = {}

const defaultLoader = (appNetworkId, provider, networks, abi) => {
    let deployedNetwork = networks[appNetworkId]
    if (!deployedNetwork) {
        console.log('Unsupported network', appNetworkId)
        return null
    }

    return new ethers.Contract(deployedNetwork.address, abi, provider)
}

const lazyContract = (name, appNetworkId, provider, {networks, abi}, loader) => {
    const key = `${name}-${appNetworkId}`

    if (!loader) {
        loader = defaultLoader
    }

    if (!contracts[key]) {
        contracts[key] = loader(appNetworkId, provider, networks, abi)
        return contracts[key]
    } else {
        if (Promise.resolve(contracts[key]) === contracts[key]) {
            return contracts[key].then(c => c.connect(provider))
        } else {
            return contracts[key].connect(provider)
        }
    }
}

const contract = (contractName, appNetworkId) => {
    switch (contractName) {
        case 'governance':
            return lazyContract(contractName, appNetworkId, ethersProvider(), governanceArtifact)

        case 'lottery':
            return lazyContract(contractName, appNetworkId, ethersProvider(), lotteryArtifact)

        case 'history':
            return lazyContract(contractName, appNetworkId, ethersProvider(), historyArtifact)

        case 'treasury':
            return lazyContract(contractName, appNetworkId, ethersProvider(), treasuryArtifact)

        case 'randomness':
            return lazyContract(contractName, appNetworkId, ethersProvider(), randomnessArtifact)

        default:
            return null
    }
}

const contractPromise = (contractName, appNetworkId) => {
    let name, arg1
    if (Array.isArray(contractName)) {
        [name, arg1] = contractName
        if (name) contractName = name
    }

    switch (contractName) {
        /*case 'treasury':
            return Promise.resolve(lazyContract('treasury', appNetworkId, ethersProvider(), treasuryArtifact, (appNetworkId, provider, _, abi) => {
                return contract('governance', appNetworkId).treasuryContract()
                    .then(addr => Promise.resolve(new ethers.Contract(addr, abi, provider)))
            }))*/

        case 'currentBooty':
            return contract('lottery', appNetworkId).currentBooty()
                .then(bootyAddr => {
                    return Promise.resolve(new ethers.Contract(bootyAddr, bootyArtifact.abi, ethersProvider()))
                })

        case 'booty':
            return Promise.resolve(new ethers.Contract(arg1, bootyArtifact.abi, ethersProvider()))

        default:
            return Promise.resolve(contract(contractName, appNetworkId))
    }
}

// Subscribe only once for the same event
const subOnceToContract = (contractName, appNetworkId, event, eventFilter, fn) => {
    const key = `${contractName}-${appNetworkId}-${event}`
    const c = contractPromise(contractName, appNetworkId)

    if (!subscriptions[key]) {
        subscriptions[key] = true
        return c.then(cnt => cnt.on(eventFilter, fn))
    } else {
        return c
    }
}

export default { contract, contractPromise, subOnceToContract }