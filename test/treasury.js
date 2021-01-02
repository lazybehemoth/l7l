const Governance = artifacts.require("Governance");
const Treasury = artifacts.require("Treasury");
const Booty = artifacts.require("Booty");
const L7lLedger = artifacts.require("L7lLedger");
const L7lToken = artifacts.require("L7lToken");
const truffleAssert = require('truffle-assertions');

const { assert } = require('chai');

function ether(value) {
  return web3.utils.toWei(value, 'ether');
}

// State persists sequencially for each test
contract("Treasury", accounts => {
  const owner = accounts[0];
  const player = accounts[1];
  const lotteryAddress = accounts[5];

  // Fake account[5] as lottery contract to 
  // execute treasury requests in a name of lottery
  before(async () => {
    const governance = await Governance.deployed();
    await governance.enableLotteryContract.sendTransaction(lotteryAddress,  { from: owner });
  });

  const testAmount = ether('0.1');
  
  it("should return 0.1 ETH on balance", async () => {
    const instance = await Governance.deployed()
      .then(governance => governance.treasuryContract())
      .then(treasuryAddr => Treasury.at(treasuryAddr));

    await truffleAssert.fails(
      instance.withdrawPayments.sendTransaction(player, { from: lotteryAddress }),
      null,
      "nothing to withdraw"
    );

    await instance.createBooty.sendTransaction({ from: lotteryAddress });
    const totalBooties = await instance.totalBooties.call();
    const bootyAddr = await instance.allBooties.call(totalBooties - 1);
    await instance.registerPlayerBooty.sendTransaction(player, bootyAddr, { from: lotteryAddress });
    
    const booty = await Booty.at(bootyAddr);
    await booty.useForRound.sendTransaction(1, { from: lotteryAddress });
    await booty.greenBet.sendTransaction(player, { from: lotteryAddress, value: testAmount });
    await booty.declareGreenWin.sendTransaction({ from: lotteryAddress });

    const amount = await instance.payments.call(player);
    assert.equal(amount.toString(), testAmount, "Invalid balance");
  });

  it("should withdraw 0.1 ETH from balance to account", async () => {
    const instance = await Governance.deployed()
      .then(governance => governance.treasuryContract())
      .then(treasuryAddr => Treasury.at(treasuryAddr));

    const before = await web3.eth.getBalance(player);
    await instance.withdrawPayments.sendTransaction(player, { from: lotteryAddress });
    const after = await web3.eth.getBalance(player);
    assert.equal(after - before, testAmount, "Invalid balance");
  });

  it("should return 1 L7L on balance", async () => {
    const instance = await Governance.deployed()
      .then(governance => governance.treasuryContract())
      .then(treasuryAddr => Treasury.at(treasuryAddr));

    await instance.rewardL7l.sendTransaction(player, ether('1'), { from: lotteryAddress });
    const l7lBalance = await instance.balanceOfL7l.call(player);
    assert.equal(l7lBalance.toString(), ether('1'), "Invalid balance");
  });

  it("shouldn't withdraw 1 L7L from player balance before vesting", async () => {
    const instance = await Governance.deployed()
      .then(governance => governance.treasuryContract())
      .then(treasuryAddr => Treasury.at(treasuryAddr));

    await truffleAssert.fails(
      instance.withdrawL7l.sendTransaction(player, { from: player }),
      null,
      "payee is not allowed to withdraw"
    );
  });

  it("should withdraw 1 L7L from player balance after vesting", async () => {
    const instance = await Governance.deployed()
      .then(governance => governance.treasuryContract())
      .then(treasuryAddr => Treasury.at(treasuryAddr));
      
    const ledger = await instance.TrustedL7lLedger.call()
      .then(ledgerAddr => L7lLedger.at(ledgerAddr));

    await ledger.daoPermitWithdrawal.sendTransaction({ from: owner });
    await instance.withdrawL7l.sendTransaction(player, { from: player });
    const l7lBalance = await instance.balanceOfL7l.call(player);
    assert.equal(l7lBalance.toString(), ether('0'), "Invalid balance");
  });

  it("should allow to withdraw unused L7L rewards", async () => {
    const instance = await Governance.deployed()
      .then(governance => governance.treasuryContract())
      .then(treasuryAddr => Treasury.at(treasuryAddr));
      
    const ledgerAddr = await instance.TrustedL7lLedger.call()
    const ledger = await L7lLedger.at(ledgerAddr);
    const token = await L7lToken.deployed();

    const l7lBalance1 = await token.balanceOf.call(owner);
    await ledger.daoDumpRewards.sendTransaction({ from: owner });
    const l7lBalance2 = await token.balanceOf.call(owner);
    assert.equal(l7lBalance2.gt(l7lBalance1), true, "Should increase beneficiary balance");

    const l7lBalance3 = await token.balanceOf.call(ledgerAddr);
    assert.equal(l7lBalance3.toString(), '0', "Should be 0");
  });
});