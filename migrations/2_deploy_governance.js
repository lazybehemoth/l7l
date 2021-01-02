const { singletons } = require('@openzeppelin/test-helpers')

const GovernanceContract = artifacts.require("Governance")

module.exports = async (deployer, network, accounts) => {
  try {
    // In a test environment an ERC777 token requires deploying an ERC1820 registry
    if (!network.startsWith('live')) { 
      await singletons.ERC1820Registry(accounts[0])
    }
    
    governanceContract = await deployer.deploy(GovernanceContract, accounts[0], accounts[0])
  } 
  catch (err) {
    console.error(err)
  }
}