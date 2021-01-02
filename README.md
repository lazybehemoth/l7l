# ![Le7el DAO](app/public/logo.png)

### [Rinkeby](https://rinkeby.le7el.com/)&nbsp;&nbsp;&nbsp;&nbsp;[Mainnet](https://le7el.com)

For general overview of our product and more information on how this works, head over to the [docs site](https://docs.le7el.com).


# How it works

## Backend
> This application was built in __solidity v0.6.12__ with [truffle](https://www.trufflesuite.com) for Ethereum blockchain.

Check out the [the source code](./contracts) to get a feel for the project structure!

```
contracts/
  connectors/...
  games/...
  interfaces/...
  ledgers/...
  mocks/...
  vendor/...
  Booty.sol
  Governance.sol
  L7lToken.sol
  Migrations.sol
  Randomness.sol
  ResolutionAlarmChainlink.sol
  ResolutionAlarmCron.sol
  Treasury.sol
```

## Frontend
> This application was built with [elm-spa](https://elm-spa.dev) and [elm-ui](https://elm-ui.netlify.app). 

Uses [elm ports](https://guide.elm-lang.org/interop/ports.html) for web3 interactions with [ethers.js](https://docs.ethers.io/v5/).

[Index db storage](https://dexie.org) is used to cache historical bet results to reduce load on public Ethereum nodes.

It was developed to be hosted on [IPSF](https://ipfs.io/).

Check out the [the source code](./app/src) for more details.

```
src/
  Components/...
  Pages/...
  Spa/...
  Config.elm
  Main.elm
  Shared.elm
  Ports.elm
  Utils.elm
```

# Getting started

Install [elm 0.19.1](https://guide.elm-lang.org/install/elm.html), [elm-spa](https://www.elm-spa.dev/guide/installation), [truffle](https://www.trufflesuite.com), [ganache](https://www.trufflesuite.com/ganache) and [nodejs](https://nodejs.org) (tested on v14.11.0).

You may need to create to following files:

* `.secret` - 12 words to access private key for deployments to rinkeby / mainnet;
* `.secret.etherscan` - [Etherscan](https://etherscan.io) API key for contract verification.

Configure Ganache according to provided `truffle-config.js` (by default, we run it on 8545 port), then execute the following terminal commands:

```
npm install
npm migrate:dev

cd app
npm install
npm run dev
npm run dev:webpack
```

# Testing

```
npm run test
```

## Local testing
You can use the following truffle script to resolve rounds manually on your local deployment:

```
var HDWalletProvider = require("@truffle/hdwallet-provider")

const MNEMONIC = 'FILL ME'
let provider = new HDWalletProvider({
    mnemonic: {
       phrase: MNEMONIC
    },
    //addressIndex: 4,
    numberOfAddresses: 5,
    providerOrUrl: "http://localhost:8545"
});

module.exports = async function(callback) {
    const Lottery = artifacts.require("LotteryDoubleEth")
    const Randomness = artifacts.require("RandomnessMock")

    const l = await Lottery.deployed()
    l.createBooty.sendTransaction({ from: provider.getAddress(0) }).then(console.log)

    await Lottery.deployed()
        .then(lottery => {
            return Promise.all([
                Promise.resolve(lottery),
                lottery.results.sendTransaction({ from: provider.getAddress(0) }) // Promise.resolve(true), //
            ])
        })
        .then(([lottery, reciept]) => {
            console.log('Results', reciept)

            return Promise.all([
                lottery.lastSeed(),
                Lottery.deployed()
                    .then(lottery => lottery.TrustedRandomness())
                    .then(addr => Randomness.at(addr))
            ])
        })
        .then(([seed, randomness]) => {
            account = provider.getAddress(4) 
            const random = Math.floor(Math.random() * Math.floor(1000))
            return randomness.rawFulfillRandomness.sendTransaction(seed, random.toString(), { from: account })
        })
        .then((result) => {
            console.log('Randomness', result)
            callback(true)
        })
        .catch(callback)
};
```