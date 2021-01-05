const Governance = artifacts.require("Governance")
const Randomness = artifacts.require("Randomness")
const RandomnessMock = artifacts.require("RandomnessMock")
// const ResolutionAlarmChainlink = artifacts.require("ResolutionAlarmChainlink")
const ResolutionAlarmCron = artifacts.require("ResolutionAlarmCron")

const { LinkToken } = require('@chainlink/contracts/truffle/v0.4/LinkToken')
const { Oracle } = require('@chainlink/contracts/truffle/v0.6/Oracle')
const { coordinator } = require('@chainlink/test-helpers')

module.exports = async (deployer, network, [defaultAccount, _a1, _a2, _a3, oracleNode]) => {
  var governanceContract = await Governance.deployed()

  // Local (development) networks need their own deployment of the LINK
  // token and the Oracle contract
  if (network === "develop") {
    LinkToken.setProvider(deployer.provider)
    Oracle.setProvider(deployer.provider)

    try {
      link = await deployer.deploy(LinkToken, { from: defaultAccount });
      oracle = await deployer.deploy(Oracle, LinkToken.address, { from: defaultAccount });

      const params = {payment: web3.utils.toWei('0.1', 'ether'), oracles: [oracle.address]};
      const keyHash = coordinator.generateSAID(coordinator.serviceAgreement(params));
      
      randomnessContract = 
        await deployer.deploy(
          RandomnessMock,
          governanceContract.address,
          oracleNode, /*oracle.address*/
          link.address, 
          keyHash
        );
        
      await oracle.setFulfillmentPermission(oracleNode, true, { from: defaultAccount });

      const linkTestBalance = web3.utils.toWei('500', 'ether')
      await link.transfer.sendTransaction(randomnessContract.address, linkTestBalance, { from: defaultAccount })
    } 
    catch (err) {
      console.error(err)
    }
  } else if (network == 'live_rinkeby') {
    await deployer.deploy(
      Randomness,
      governanceContract.address,
      '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
      '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
      '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311'
    )

    /*await deployer.deploy(
      ResolutionAlarmChainlink,
      governanceContract.address,
      '0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e',
      web3.utils.fromAscii('4fff47c3982b4babba6a7dd694c9b204'),
      '0x0000000000000000000000000000000000000000', // auto-detected
      { from: defaultAccount }
    );*/
  } else if (network == 'live_mainnet') {
    await deployer.deploy(
      Randomness,
      governanceContract.address,
      '0xf0d54349aDdcf704F77AE15b96510dEA15cb7952',
      '0x514910771af9ca656af840dff83e8264ecf986ca',
      '0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445'
    )
  }

  resolutionAlarmContract = await deployer.deploy(
    ResolutionAlarmCron,
    governanceContract.address,
    { from: defaultAccount }
  );
}
