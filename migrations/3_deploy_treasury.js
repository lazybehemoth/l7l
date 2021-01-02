const L7lLedger = artifacts.require("L7lLedger")
const Governance = artifacts.require("Governance")
const Treasury = artifacts.require("Treasury")

module.exports = async (deployer) => {
  const governanceContract = await Governance.deployed()

  try {
    ledgerContract = await deployer.deploy(L7lLedger, governanceContract.address)
    treasuryContract = await deployer.deploy(Treasury, governanceContract.address, ledgerContract.address)
    await governanceContract.initialize(treasuryContract.address)
  } 
  catch (err) {
    console.error(err)
  }
}