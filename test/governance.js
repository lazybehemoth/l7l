const truffleAssert = require('truffle-assertions');

const Governance = artifacts.require('Governance');

// State persists sequencially for each test
contract('Governance', accounts => {
  const owner = accounts[0];
  const manager = accounts[1];
  const random = accounts[9];

  it('should initialize once', async () => {
    const governance = await Governance.deployed();
    await truffleAssert.fails(
      governance.initialize.sendTransaction(random, { from: owner }),
      null,
      "Already initialized"
    );
  })

  it('should allow owner to change manager', async () => {
    const governance = await Governance.deployed();
    await governance.assignManager.sendTransaction(manager, { from: owner })
    await truffleAssert.fails(
      governance.assignManager.sendTransaction(random, { from: manager }),
      null,
      "Ownable: caller is not the owner"
    );
  })

  it('should allow owner to change beneficiary', async () => {
    const governance = await Governance.deployed();
    await governance.assignBeneficiary.sendTransaction(owner, { from: owner })
    await truffleAssert.fails(
      governance.assignBeneficiary.sendTransaction(manager, { from: manager }),
      null,
      "Ownable: caller is not the owner"
    );
  })

  it('should allow owner to change booty expiration', async () => {
    const governance = await Governance.deployed();
    await governance.changeBootyExpiration.sendTransaction(web3.utils.toBN(1000000000), { from: owner })
    await truffleAssert.fails(
      governance.changeBootyExpiration.sendTransaction(web3.utils.toBN(1), { from: manager }),
      null,
      "Ownable: caller is not the owner"
    );
    await truffleAssert.fails(
      governance.changeBootyExpiration.sendTransaction(web3.utils.toBN(1), { from: owner }),
      null,
      "protected from scam"
    );
  })

  it('should be true for managers', async () => {
    const governance = await Governance.deployed();
    assert.equal(await governance.isManagement.call(owner), true);
    assert.equal(await governance.isManagement.call(manager), true);
    assert.equal(await governance.isManagement.call(random), false);
  })

  it('should allow to enable new lotteries', async () => {
    const governance = await Governance.deployed();
    governance.enableLotteryContract.sendTransaction(accounts[8], { from: owner });
    await truffleAssert.fails(
      governance.enableLotteryContract.sendTransaction(accounts[8], { from: manager }),
      null,
      "Ownable: caller is not the owner"
    );
    assert.equal(await governance.lotteryContracts.call(accounts[8]), true);
  })

  it('should allow to disable old lotteries', async () => {
    const governance = await Governance.deployed();
    governance.disableLotteryContract.sendTransaction(accounts[8], { from: owner });
    await truffleAssert.fails(
      governance.disableLotteryContract.sendTransaction(accounts[8], { from: manager }),
      null,
      "Ownable: caller is not the owner"
    );
    assert.equal(await governance.lotteryContracts.call(accounts[8]), false);
  })
})
