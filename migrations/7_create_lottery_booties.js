const LotteryDoubleEth = artifacts.require("LotteryDoubleEth")

module.exports = async (deployer, network) => {
  const lotteryContract = await LotteryDoubleEth.deployed()

  try {
    await lotteryContract.initialize(1)
    
    if (network.startsWith('live')) {
      await lotteryContract.createBooty()
    } else {
      await lotteryContract.createBooty()
      await lotteryContract.createBooty()
    }
  } 
  catch (err) {
    console.error(err)
  }
}