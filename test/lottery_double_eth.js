const Governance = artifacts.require('Governance');
const Lottery = artifacts.require('LotteryDoubleEth');
const L7lLedger = artifacts.require('L7lLedger');
const Randomness = artifacts.require('RandomnessMock');
const Treasury = artifacts.require('Treasury');
const Booty = artifacts.require('Booty');
const ResolutionAlarm = artifacts.require('ResolutionAlarmCron');
const truffleAssert = require('truffle-assertions');

function ether(value) {
  return web3.utils.toWei(value, 'ether');
}

const baseBet = ether('0.1');
const higherBet = ether('0.15');
const ZERO_ADDR = '0x0000000000000000000000000000000000000000';

// State persists sequencially for each test
contract('LotteryDoubleEth', accounts => {
  it('should have valid initial state', async () => {
    const governance = await Governance.deployed();
    const treasury = await governance.treasuryContract().then(addr => Treasury.at(addr));
    const reward = await treasury.payments.call(accounts[1]);
    const l7lReward = await treasury.balanceOfL7l.call(accounts[1]);
    assert.equal(reward.toString(), '0', 'should be none');
    assert.equal(l7lReward.toString(), '0', 'should be none');
  })

  it('should allow to bet for blue or green', async () => {
    const instance = await Lottery.deployed();
    const booty = await instance.TrustedBooties.call(1).then(addr => Booty.at(addr));

    await instance.daoSetL7lReward(100, { from: accounts[0] });
    await instance.daoInfluencerReward(accounts[1], 20, { from: accounts[0] });
    await instance.betGreen.sendTransaction(ZERO_ADDR, { from: accounts[1], value: baseBet });
    await instance.betBlue.sendTransaction(accounts[1], { from: accounts[2], value: higherBet });

    assert.equal(await booty.greenPayees.call(0), accounts[1], 'should be first account');
    assert.equal(await booty.bluePayees.call(0), accounts[2], 'should be second account');

    totalBooty = await booty.totalShares.call();
    assert.equal(totalBooty.toString(), ether('0.2475'), 'total booty should be 0.2475 eth');
  });

  it("shouldn't allow recycling if there are bets", async () => {
    const instance = await Lottery.deployed();
    const currentRound = await instance.currentRound.call().then(val => val.toNumber());

    await truffleAssert.fails(
      instance.daoRecycleBooty.sendTransaction(currentRound, { from: accounts[0] }),
      null,
      "clear payouts first"
    );
  })

  it("shouldn't allow resolution for a paused contract", async () => {
    const instance = await Lottery.deployed();

    await instance.daoToggleLock.sendTransaction({ from: accounts[0] });

    await truffleAssert.fails(
      instance.results.sendTransaction({ from: accounts[0] }),
      null,
      "LE7EL Random is temporary closed"
    );

    await instance.daoToggleLock.sendTransaction({ from: accounts[0] });
  })

  it('should assign unspecified bets equally to both sides', async () => {
    const instance = await Lottery.deployed();
    const booty = await instance.TrustedBooties.call(1).then(addr => Booty.at(addr));

    await instance.sendTransaction({ from: accounts[1], value: higherBet });
    greenBet = await booty.greenShares.call(accounts[1]);
    assert.equal(greenBet.toString(), ether('0.17325'), 'green bet should be (0.099+0.07425)=0.17325 eth');
    blueBet = await booty.blueShares.call(accounts[1]);
    assert.equal(blueBet.toString(), ether('0.07425'), 'blue bet should be 0.07425 eth');

    await instance.sendTransaction({ from: accounts[2], value: baseBet });
    greenBet = await booty.greenShares.call(accounts[2]);
    assert.equal(greenBet.toString(), ether('0.0495'), 'green bet should be 0.0495 eth');
    blueBet = await booty.blueShares.call(accounts[2]);
    assert.equal(blueBet.toString(), ether('0.198'), 'blue bet should be (0.1485+0.0495)=0.198 eth');
  });

  it('should reward bets with L7L tokens', async () => {
    const governance = await Governance.deployed();
    const l7lLedger = await governance.treasuryContract()
      .then(addr => Treasury.at(addr))
      .then(treasury => treasury.TrustedL7lLedger())
      .then(addr => L7lLedger.at(addr))

    l7lReward1 = await l7lLedger.depositsOf(accounts[1]).then(bal => bal.toString());
    assert.equal(l7lReward1, ether('28'), 'reward for the first account should be 25 + 3 ref reward in L7L');

    l7lReward2 = await l7lLedger.depositsOf(accounts[2]).then(bal => bal.toString());
    assert.equal(l7lReward2, ether('26.5'), 'reward for the second account should be 25 + 1.5 ref reward in L7L');

    l7lReward3 = await l7lLedger.depositsOf(accounts[3]).then(bal => bal.toString());
    assert.equal(l7lReward3, '0', 'reward for the third account should be 0 L7L');
  });

  it('should have valid bet ledger', async () => {
    const instance = await Lottery.deployed();
    const booty = await instance.TrustedBooties.call(1).then(addr => Booty.at(addr));

    greenBet1 = await booty.greenShares.call(accounts[1]);
    assert.equal(greenBet1.toString(), ether('0.17325'), 'first account bet is (0.099+0.07425)=0.17325 eth');

    blueBet1 = await booty.blueShares.call(accounts[2]);
    assert.equal(blueBet1.toString(), ether('0.198'), 'first account bet is (0.1485+0.0495)=0.198 eth');

    blueBet3 = await booty.blueShares.call(accounts[3]);
    assert.equal(blueBet3.toString(), '0', 'third account bet is 0 eth');
  });

  it('should resolve bets', async () => {
    const instance = await Lottery.deployed();
    const randomness = await Randomness.deployed();
    const governance = await Governance.deployed();
    const treasury = await governance.treasuryContract().then(addr => Treasury.at(addr));
    const booty = await instance.TrustedBooties.call(1).then(addr => Booty.at(addr));

    await instance.results.sendTransaction({ from: accounts[0] });
    state = await instance.state();
    const seed = await instance.lastSeed();
    assert.equal(state, 2, 'should be in RESOLUTION state');
    
    const totalBooty = await web3.eth.getBalance(booty.address)
      .then(bal => web3.utils.toBN(bal));

    const casinoShare = await web3.eth.getBalance(instance.address)
      .then(bal => web3.utils.toBN(bal));

    assert.equal(totalBooty.toString(), ether('0.495'), 'should be 0.495 ETH');
    assert.equal(casinoShare.toString(), ether('0.005'), 'should be 0.005 ETH');

    const casinoBalance = await governance.beneficiary()
      .then(addr => web3.eth.getBalance(addr))
      .then(bal => web3.utils.toBN(bal));

    const account2Bet = await booty.blueShares(accounts[2]);
    
    // Distribute booty to Blue team
    await randomness.rawFulfillRandomness.sendTransaction(seed, 10, { from: accounts[4] });
    await instance.daoWithdraw.sendTransaction({ from: accounts[0] });

    const _casinoBalance = await governance.beneficiary()
      .then(addr => web3.eth.getBalance(addr))
      .then(bal => web3.utils.toBN(bal));

    assert.equal(_casinoBalance.gte(casinoBalance), true, 'should increase casino balance by ~0.005 ETH minus gas');

    const totalTickets = await booty.totalBlue();
    const plannedReward = totalBooty.mul(account2Bet).div(totalTickets);
    const reward = await treasury.payments.call(accounts[2]);

    assert.equal(reward.toString(), plannedReward.toString(), 'should be about ~0.36 ETH');

    const balance2 = await web3.eth.getBalance(accounts[2]).then(amount => web3.utils.toBN(amount));
    await instance.claimBooty.sendTransaction({ from: accounts[2] });
    const _balance2 = await web3.eth.getBalance(accounts[2]).then(amount => web3.utils.toBN(amount));
    assert.equal(_balance2.gt(balance2), true, 'should be more ETH (some will be lost on gas)');

    const noClaim = await booty.unlockedBalanceOf(accounts[3]);
    assert.equal(noClaim.toString(), '0', 'should be nothing');

    const leftToClaim = await booty.unlockedBalanceOf(accounts[1]);
    assert.equal(leftToClaim.toString(), ether('0.135'), 'should be ~0.135');
    await instance.claimBooty.sendTransaction({ from: accounts[1] });

    const emptyBooty = await web3.eth.getBalance(booty.address).then(bal => web3.utils.toBN(bal));
    assert.equal(emptyBooty.lt(web3.utils.toBN('10')), true, 'Should be empty, or close to empty <10 wei allowed');

    assert.equal(await booty.state(), 3, 'Should be in BlueWon');
    assert.equal(await instance.currentRound(), 2, 'Should be round 2');
    assert.notEqual(await instance.TrustedBooties.call(2), ZERO_ADDR, 'Should be non empty address');
    assert.equal(await instance.state(), 0, 'should be in OPEN state');
  });

  it("should allow recycling if there are no bets", async () => {
    const instance = await Lottery.deployed();
    const currentRound = await instance.currentRound.call().then(val => val.toNumber());
    const booty = await instance.TrustedBooties.call(currentRound - 1).then(addr => Booty.at(addr));
    
    await instance.daoRecycleBooty.sendTransaction(currentRound - 1, { from: accounts[0] });

    const totalShares = await booty.totalShares.call();
    const totalReleased = await booty.totalReleased.call();
    const totalGreen = await booty.totalGreen.call();
    const totalBlue = await booty.totalBlue.call();
    assert.equal(totalShares.toString(), '0', 'Should be 0');
    assert.equal(totalReleased.toString(), '0', 'Should be 0');
    assert.equal(totalGreen.toString(), '0', 'Should be 0');
    assert.equal(totalBlue.toString(), '0', 'Should be 0');

    const ac1g = await booty.greenShares.call(accounts[1]);
    const ac2g = await booty.greenShares.call(accounts[2]);
    const ac3g = await booty.greenShares.call(accounts[3]);
    assert.equal(ac1g.toString(), '0', 'Should be 0');
    assert.equal(ac2g.toString(), '0', 'Should be 0');
    assert.equal(ac3g.toString(), '0', 'Should be 0');

    const ac1b = await booty.blueShares.call(accounts[1]);
    const ac2b = await booty.blueShares.call(accounts[2]);
    const ac3b = await booty.blueShares.call(accounts[3]);
    assert.equal(ac1b.toString(), '0', 'Should be 0');
    assert.equal(ac2b.toString(), '0', 'Should be 0');
    assert.equal(ac3b.toString(), '0', 'Should be 0');

    const ac1r = await booty.released.call(accounts[1]);
    const ac2r = await booty.released.call(accounts[2]);
    const ac3r = await booty.released.call(accounts[3]);
    assert.equal(ac1r.toString(), '0', 'Should be 0');
    assert.equal(ac2r.toString(), '0', 'Should be 0');
    assert.equal(ac3r.toString(), '0', 'Should be 0');

    await truffleAssert.fails(
      booty.bluePayees.call(0),
      null,
      'invalid opcode'
    );

    await truffleAssert.fails(
      booty.greenPayees.call(0),
      null,
      'invalid opcode'
    );
  })

  it('should be possible to play in a new round with a single MM', async () => {
    const instance = await Lottery.deployed();
    const booty = await instance.TrustedBooties.call(2).then(addr => Booty.at(addr));

    await instance.sendTransaction({ from: accounts[5], value: higherBet });

    const totalBooty = await booty.totalShares.call();
    assert.equal(totalBooty.toString(), ether('0.1485'), 'total booty should be 0.1485 eth');
  });

  it('should auto-recycle the current round with a single market maker', async () => {
    const instance = await Lottery.deployed();
    const currentRound = await instance.currentRound.call().then(val => val.toNumber());
    const booty = await instance.TrustedBooties.call(currentRound).then(addr => Booty.at(addr));

    await instance.daoChangePeriod.sendTransaction(0, { from: accounts[0] }); // to use alarm clock resolution
    await instance.results.sendTransaction({ from: accounts[0] });

    const newRound = await instance.currentRound.call().then(val => val.toNumber());
    assert.equal(currentRound + 1, newRound, 'should start a new round');

    const newBooty = await instance.TrustedBooties.call(newRound).then(addr => Booty.at(addr));
    assert.equal(booty.address, newBooty.address, 'should be the same recycled booty');
  });

  it('should allow to resolve recycled rounds normally, through cron alarm', async () => {
    const instance = await Lottery.deployed();
    const randomness = await Randomness.deployed();
    const resolution_alarm = await ResolutionAlarm.deployed();
    const booty = await instance.TrustedBooties.call(3).then(addr => Booty.at(addr));

    await instance.sendTransaction({ from: accounts[6], value: higherBet });

    const totalBooty = await booty.totalShares.call();
    assert.equal(totalBooty.toString(), ether('0.2970'), 'total booty should be 0.2970 eth');

    await truffleAssert.fails(
      resolution_alarm.fulfillAlarm.sendTransaction({ from: accounts[0] }),
      null,
      'Only alarm nodes'
    );
    await resolution_alarm.enableAlarmNode.sendTransaction(accounts[9], { from: accounts[0] });
    await resolution_alarm.fulfillAlarm.sendTransaction({ from: accounts[9] });
    const seed = await instance.lastSeed();
    await randomness.rawFulfillRandomness.sendTransaction(seed, 10, { from: accounts[4] });

    const leftToClaim1 = await booty.unlockedBalanceOf(accounts[5]);
    assert.equal(leftToClaim1.toString(), ether('0.1485'), 'should be 0.1485');

    const leftToClaim2 = await booty.unlockedBalanceOf(accounts[6]);
    assert.equal(leftToClaim2.toString(), ether('0.1485'), 'should be 0.1485');
  });

  it('should gracefully handle treasury withdrawal failures', async () => {
    const instance = await Lottery.deployed();
    const randomness = await Randomness.deployed();

    // Cleanup for previous wins (just in case);
    await instance.claimBooty.sendTransaction({ from: accounts[5]});

    await instance.sendTransaction({ from: accounts[6], value: higherBet });
    await instance.betBlue.sendTransaction(ZERO_ADDR, { from: accounts[5], value: higherBet });
    const balance1 = await web3.eth.getBalance(accounts[5]).then(amount => web3.utils.toBN(amount));
    await instance.claimBooty.sendTransaction({ from: accounts[5]});
    const balance2 = await web3.eth.getBalance(accounts[5]).then(amount => web3.utils.toBN(amount));
    assert.equal(balance2.sub(balance1).lt(web3.utils.toBN(1)), true, 'should be the same or a bit less because of gas expenses');
    
    await instance.results.sendTransaction({ from: accounts[0] });
    const seed = await instance.lastSeed();
    await randomness.rawFulfillRandomness.sendTransaction(seed, 10, { from: accounts[4] });
    await instance.claimBooty.sendTransaction({ from: accounts[5]});
    const balance3 = await web3.eth.getBalance(accounts[5]).then(amount => web3.utils.toBN(amount));
    assert.equal(balance3.gt(balance2), true, 'should be greater');
  });
});
