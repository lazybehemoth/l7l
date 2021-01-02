const Governance = artifacts.require("Governance");
const Randomness = artifacts.require("RandomnessMock");
const Lottery = artifacts.require("LotteryDoubleEth");

const { Oracle } = require('@chainlink/contracts/truffle/v0.6/Oracle');

const { assert } = require('chai');

// State persists sequencially for each test
contract("Randomness", accounts => {
  const owner = accounts[0];
  const oracleNode = accounts[1];
  const lotteryAddress = accounts[5];

  // Fake account[5] as lottery contract to 
  // execute randomness requests in a name  of lottery
  before(async () => {
    const governance = await Governance.deployed();
    await governance.enableLotteryContract.sendTransaction(lotteryAddress,  { from: owner });

    const oc = await Oracle.deployed();
    await oc.setFulfillmentPermission(oracleNode, true, { from: owner });
  });
  
  it("should request random number", async () => {
    const lottery = await Lottery.deployed();
    const round = await lottery.currentRound();
    const instance = await Randomness.deployed();

    instance.getRandom.sendTransaction(100000000, round, { from: lotteryAddress });
    const random = await instance.randomNumbers(lotteryAddress, round);
    assert.equal(random.toString(), '1', "Random not requested");
  });
});