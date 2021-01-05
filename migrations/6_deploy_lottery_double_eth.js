const LotteryDoubleEth = artifacts.require("LotteryDoubleEth")
const LotteryDoubleEthHistory = artifacts.require("LotteryDoubleEthHistory")
const Governance = artifacts.require("Governance")
const Treasury = artifacts.require("Treasury")
const Randomness = artifacts.require("Randomness")
const RandomnessMock = artifacts.require("RandomnessMock")
//const ResolutionAlarmChainlink = artifacts.require("ResolutionAlarmChainlink")
const ResolutionAlarmCron = artifacts.require("ResolutionAlarmCron")

module.exports = async (deployer, network) => {
  const governanceContract = await Governance.deployed()
  const treasuryContract = await Treasury.deployed()
  let resolutionAlarmContract, randomnessContract;

  randomnessContract = network.startsWith('live') ? await Randomness.deployed() : await RandomnessMock.deployed()
  //resolutionAlarmContract = network == 'live_rinkeby' ? await ResolutionAlarmChainlink.deployed() : await ResolutionAlarmCron.deployed()
  resolutionAlarmContract = await ResolutionAlarmCron.deployed()

  try {
    historyContract = await deployer.deploy(LotteryDoubleEthHistory, governanceContract.address)

    lotteryContract = await deployer.deploy(
      LotteryDoubleEth,
      governanceContract.address,
      treasuryContract.address,
      resolutionAlarmContract.address,
      randomnessContract.address,
      historyContract.address
    )
    
    await governanceContract.enableLotteryContract(lotteryContract.address)
    await resolutionAlarmContract.initialize(lotteryContract.address)
    // We initialise lottery in separate  migration because it's big transaction 
    // likely to fail in live networks
  } 
  catch (err) {
    console.error(err)
  }
}
