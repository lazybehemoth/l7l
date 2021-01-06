/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like truffle-hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

const HDWalletProvider = require("@truffle/hdwallet-provider")
// const infuraKey = "fj4jll3k.....";
//
const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();
const deployKey = fs.readFileSync(".secret.mainnet").toString().trim();

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
    // development: {
    //   host: "127.0.0.1",     // Localhost (default: none)
    //   port: 7545,            // Standard Ethereum port (default: none)
    //   network_id: "*",       // Any network (default: none)
    // },
    
    develop: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 5777,
      gasPrice: 80000000000,
      gas: 9721975
    },

    live_rinkeby: {
      provider: () => new HDWalletProvider({ 
        mnemonic: { phrase: mnemonic },
        addressIndex: 2,
        numberOfAddresses: 1,
        providerOrUrl: 'https://rinkeby.infura.io/v3/296c495e5dbc4f95ad4bbf1e4ea0de5e' // public Infura
      }),
      network_id: 4,       // Rinkeby's id
      from: '0xeEdcC6F843B5E78ce9873Ff1eF282ed8b8a142C6',
      gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
      //gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 0,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },

    live_mainnet: {
      provider: () => new HDWalletProvider({ 
        privateKeys: [deployKey],
        providerOrUrl: 'https://mainnet.infura.io/v3/296c495e5dbc4f95ad4bbf1e4ea0de5e' // public Infura
      }),
      network_id: 1,       // Mainnet's id
      from: '0xA00A92cf63e5675191D33093F0cf8C0Fc4d337e9',
      gasPrice: 80000000000,  // 80 gwei (in wei) (default: 100 gwei)
      //gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 0,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },

    // live: {
    //   provider: () => {
    //     return new HDWalletProvider(process.env.MNEMONIC, process.env.RPC_URL);
    //   },
    //   network_id: "*",
    //   // ~~Necessary due to https://github.com/trufflesuite/truffle/issues/1971~~
    //   // Necessary due to https://github.com/trufflesuite/truffle/issues/3008
    //   skipDryRun: true,
    //   // Ropsten
    //   linkAddress: "0x20fE562d797A42Dcb3399062AE9546cd06f63280",
    // },

    // Another network with more advanced options...
    // advanced: {
      // port: 8777,             // Custom port
      // network_id: 1342,       // Custom network
      // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
      // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
      // from: <address>,        // Account to send txs from (default: accounts[0])
      // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    // },

    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    // ropsten: {
      // provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
      // network_id: 3,       // Ropsten's id
      // gas: 5500000,        // Ropsten has a lower block limit than mainnet
      // confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      // timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      // skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    // },

    // Useful for private networks
    // private: {
      // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
      // network_id: 2111,   // This network is yours, in the cloud.
      // production: true    // Treats this network as if it was a public net. (default: false)
    // }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
    reporter: 'eth-gas-reporter',
    reporterOptions : {
      currency: 'USD',
      gasPrice: 80,
      onlyCalledMethods: true,
      showTimeSpent: true,
      excludeContracts: ['Migrations']
    }
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.12",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },

  plugins: [
    'truffle-plugin-verify',
    'truffle-contract-size'
  ],
  api_keys: {
    etherscan: fs.readFileSync(".secret.etherscan").toString().trim()
  }

  // compilers: {
  //   external: {
  //     command: "solc ./contracts/*",
  //     targets: [{
  //       path: "./build/contracts",
  //     }]
  //   }
  // }
  //compilers: {
  //  solc: {
      // version: "0.5.1",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
  //  }
  //}
}
