import Onboard from 'bnc-onboard'
import { ethers } from 'ethers/dist/ethers-all.esm.min'
import { defaultNetwork, debounce, RPC_ENDPOINT, INFURA_KEY, currentAddress, currentNetwork } from './config'

import callBalances from './web3/call_balances'

import loadWalletPort from './ports/load_wallet_port'
import commitBetPort from './ports/commit_bet_port'
import claimPort from './ports/claim_port'
import rewardsPort from './ports/rewards_port'
import l7lRewardsPort from './ports/l7l_rewards_port'
import getHistoryPort from './ports/get_history_port'
import getBetsPort from './ports/get_bets_port'
import resolutionPort from './ports/resolution_port'

const initAddressPorts = debounce((app, contracts, appNetworkId, address) => {
  const params = { appNetworkId: appNetworkId, address: address }
  const balances = callBalances(Promise.resolve(params), contracts)
  loadWalletPort(app, balances)

  commitBetPort(app, appNetworkId, contracts)

  claimPort(app, appNetworkId, contracts)

  rewardsPort(app, appNetworkId, contracts)

  l7lRewardsPort(app, appNetworkId, contracts)

  getHistoryPort(app, appNetworkId, contracts)
}, 1000, false)

const resetWallet = (app, network) => {
  if (window.ONBOARD && network != 1337) {
    app.ports.walletConnected.send('')
    app.ports.updateEthWalletBalance.send('0')
    app.ports.updateEthBalanceForClaim.send('0')
    app.ports.updateL7lBalanceForClaim.send('0')
    window.ONBOARD.walletCheck()
  }
}

const initOnboard = (app, contracts) => {
  return Onboard({
    dappId: '91e4a4d4-e476-4f4c-92c1-313e7e834daa',       // [String] The API key created by step one above
    networkId: defaultNetwork,                            // [Integer] The Ethereum network ID your Dapp uses.
    subscriptions: {
      wallet: wallet => {
        if (wallet.provider) {
          window.ethersProvider = new ethers.providers.Web3Provider(wallet.provider)
          window.localStorage.setItem('selectedWallet', wallet.name)
        }
        else {
          window.localStorage.removeItem('selectedWallet')
          window.localStorage.removeItem('selectedNetwork')
          window.localStorage.removeItem('selectedAddress')
        }
      },
      network: network => {
        console.log("NETWORK", network)
        
        if (!network) {
          window.localStorage.removeItem('selectedNetwork')
        } else if (network != 1 && network != 4 && network !== 5777) {
          console.error("Unsupported network", network)
          resetWallet(app, network)
        // Automatically redirect user to a supported network site if needed
        } else if (network == 1 && document.location.hostname === 'rinkeby.le7el.com') {
          document.location.href = 'https://le7el.com'
          return
        } else if (network == 4 && document.location.hostname === 'le7el.com') {
          document.location.href = 'https://rinkeby.le7el.com'
          return
        } else if (!contracts.contract('lottery', network)) {
          console.error("Smart contracts are not deployed to network", network, "yet")
          resetWallet(app, network)
        // Web3 provider considers it's unsafe to change the network without page reload
        } else if (window.localStorage.getItem('selectedNetwork') != network) {
          window.localStorage.setItem('selectedNetwork', network)
          document.location.reload()
          return
        } else {
          window.localStorage.setItem('selectedNetwork', network)

          getBetsPort(app, network, contracts)
          resolutionPort(app, network, contracts)

          initAddressPorts(app, contracts, network, currentAddress())
        }
      },
      address: address => {
        const network = currentNetwork()
        if (!address) {
          window.localStorage.removeItem('selectedAddress')
        } else if (!contracts.contract('lottery', network)) {
          console.error("Smart contracts are not deployed to network", network, "yet")
          resetWallet(app, network)
        } else {
          window.localStorage.setItem('selectedAddress', address)
          initAddressPorts(app, contracts, network, address)
        }
      }
    },
    walletSelect: {
      wallets: [
        { walletName: "metamask", preferred: true },
        { walletName: "coinbase", preferred: true },
        { walletName: "trust", preferred: true, rpcUrl: RPC_ENDPOINT },
        { walletName: "dapper", preferred: true }, 
        {
          walletName: 'trezor',
          appUrl: document.location.href,
          email: 'linkcasino@protonmail.ch',
          rpcUrl: RPC_ENDPOINT,
          preferred: true
        },
        {
          walletName: 'ledger',
          rpcUrl: RPC_ENDPOINT,
          preferred: true
        },
        {
          walletName: "walletConnect",
          infuraKey: INFURA_KEY,
          preferred: true
        },
        { walletName: "status", preferred: true },
        { walletName: "authereum" },
        { walletName: "opera" },
        { walletName: "operaTouch" },
        { walletName: "torus" },
        { walletName: "unilogin" },
        { walletName: "walletLink", rpcUrl: RPC_ENDPOINT, appName: 'link.casino' },
        { walletName: "imToken", rpcUrl: RPC_ENDPOINT },
        { walletName: "meetone" },
        { walletName: "mykey", rpcUrl: RPC_ENDPOINT },
        { walletName: "huobiwallet", rpcUrl: RPC_ENDPOINT },
        { walletName: "hyperpay" },
        { walletName: "wallet.io", rpcUrl: RPC_ENDPOINT },
      ]
    }
  })
}

export default initOnboard