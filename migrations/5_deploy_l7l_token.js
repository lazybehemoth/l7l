const L7lLedger = artifacts.require("L7lLedger")
const L7lToken = artifacts.require("L7lToken")
const Governance = artifacts.require("Governance")
const Treasury = artifacts.require("Treasury")

module.exports = async (deployer) => {
  var governanceContract = await Governance.deployed()

  try {
    treasuryAddr = await governanceContract.treasuryContract()
    l7lLedgerAddr = await Treasury.at(treasuryAddr)
      .then(treasuryContract => treasuryContract.TrustedL7lLedger())
      
    l7lTokenContract = await deployer.deploy(L7lToken, governanceContract.address, [l7lLedgerAddr])
    await L7lLedger.at(l7lLedgerAddr)
      .then(ledger => ledger.initialize(l7lTokenContract.address, treasuryAddr))
  } 
  catch (err) {
    console.error(err)
  }
}
