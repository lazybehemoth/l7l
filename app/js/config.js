import { ethers } from 'ethers/dist/ethers-all.esm.min'

let RPC_ENDPOINT = 'https://mainnet.infura.io/v3/296c495e5dbc4f95ad4bbf1e4ea0de5e'
const INFURA_KEY = '296c495e5dbc4f95ad4bbf1e4ea0de5e'

let defaultEthersProvider, defaultNetwork = 1 // Production

if (document.location.hostname.startsWith('rinkeby') || document.location.search.startsWith('?rinkeby')) {
  defaultNetwork = 4              // Rinkeby
  RPC_ENDPOINT = 'https://rinkeby.infura.io/v3/296c495e5dbc4f95ad4bbf1e4ea0de5e'
}

if (document.location.hostname === 'localhost' || document.location.hostname.startsWith('192.168')) {
  defaultNetwork = 5777           // Local ganache
  const host = document.location.hostname === 'localhost' ? '127.0.0.1' : document.location.hostname
  defaultEthersProvider = new ethers.providers.JsonRpcProvider(`http://${document.location.hostname}:8545`)
  RPC_ENDPOINT = `http://${host}:8545`
} else {
  defaultEthersProvider = ethers.getDefaultProvider(defaultNetwork)
}

if (!localStorage.getItem('referrer')) {
  const result = location.search.match(/ref=(\w{42})/)
  if (result) {
    let referrer;
    [, referrer] = result
    localStorage.setItem('referrer', referrer)
  }
}

const ethersProvider = () => {
  if (window.ethersProvider) {
    return window.ethersProvider
  } else {
    return defaultEthersProvider
  }
}

const currentNetwork = () => {
  const selectedNetwork = window.localStorage.getItem('selectedNetwork')
  return selectedNetwork || defaultNetwork
}

const currentAddress = () => {
  return window.localStorage.getItem('selectedAddress')
}

function debounce(callback, wait, immediate = false) {
  let timeout = null 
  
  return function() {
    const callNow = immediate && !timeout
    const next = () => callback.apply(this, arguments)
    
    clearTimeout(timeout)
    timeout = setTimeout(next, wait)

    if (callNow) {
      next()
    }
  }
}

export {
  RPC_ENDPOINT,
  INFURA_KEY,
  debounce,
  ethersProvider,
  defaultEthersProvider,
  defaultNetwork,
  currentNetwork,
  currentAddress
}