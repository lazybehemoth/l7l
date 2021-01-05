// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./vendor/chainlink/ChainlinkClient.sol";
import "./vendor/chainlink/interfaces/LinkTokenInterface.sol";

import { GovernanceInterface } from "./interfaces/GovernanceInterface.sol";
import { LotteryInterface } from "./interfaces/LotteryInterface.sol";

/** 
 * @title Helper contract to restart lotteries after fixed periods of time.
 * @dev Resolve lottery results in a supplied period.
 */
contract ResolutionAlarmChainlink is ChainlinkClient {
    GovernanceInterface public immutable TrustedGovernance;
    LinkTokenInterface public TrustedLink;
    LotteryInterface public TrustedLottery;
    
    uint256 public alarmOracleFee = 1000000000000000000; // 1 LINK
    address public immutable CHAINLINK_ALARM_ORACLE;
    bytes32 public immutable CHAINLINK_ALARM_JOB_ID;
    
    modifier onlyMyLottery() {
        require(msg.sender == address(TrustedLottery), "Only lotteries");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == TrustedGovernance.owner(), "Only owner");
        _;
    }

    /** 
     * @dev L7L DAO should be in charge of Alarm contract.
     *
     * @param _governance Governance contract address.
     * @param _oracle Chainlink alarm oracle address.
     * @param _job_id Chainlink job id for alarms.
     * @param _link Link token address, pass 0x00.. for auto assigment.
     */
    constructor(address _governance, address _oracle, bytes32 _job_id, address _link) public {
        TrustedGovernance = GovernanceInterface(_governance);
        CHAINLINK_ALARM_ORACLE = _oracle;
        CHAINLINK_ALARM_JOB_ID = _job_id;

        if (_link == address(0)) {
            setPublicChainlinkToken();
            TrustedLink = LinkTokenInterface(chainlinkTokenAddress());
        } else {
            TrustedLink = LinkTokenInterface(_link);
        }
    }

    /**
     * @dev Set lottery contract controlled by this alarm,
     * unprotected because called once.
     *
     * @param _lottery Lottery contract to be alarmed.
     */
    function initialize(address _lottery) external {
        require(address(TrustedLottery) == address(0), "Lottery is immutable");

        TrustedLottery = LotteryInterface(_lottery);
    }

    /**
     * @dev Lottery should fulfill in lotteryPeriod minutes.
     *
     * @param _period Minutes until lottery resolution.
     */
    function setAlarm(uint32 _period) external virtual onlyMyLottery {
        require(TrustedLink.balanceOf(address(this)) > alarmOracleFee, "Not enough LINK");

        Chainlink.Request memory req = buildChainlinkRequest(CHAINLINK_ALARM_JOB_ID, address(this), this.fulfillAlarm.selector);
        req.addUint("until", now + _period);
        sendChainlinkRequestTo(CHAINLINK_ALARM_ORACLE, req, alarmOracleFee);
    }

    /** 
     * @dev Call resolution lottery function when alarm notification comes from Chainlink.
     */
    function fulfillAlarm(bytes32 _requestId) public recordChainlinkFulfillment(_requestId) {
        TrustedLottery.results();
    }

    /** 
     * @dev Used to update Chainlink alarm oracle fee.
     * @param _alarmOracleFee Alarm fee in LINK
     */
    function daoAlarmOracleFee(uint64 _alarmOracleFee) external onlyDAO {
        alarmOracleFee = _alarmOracleFee;
    }

    /** 
     * @dev Withdraw unused LINK in case of migration / shutdown.
     */
    function daoWithdrawLink() external onlyDAO {
        TrustedLink.transfer(TrustedGovernance.beneficiary(), TrustedLink.balanceOf(address(this)));
    }
    
    /** 
     * @dev Used to upgrade to a new contract version.
     */
    function daoDie() external onlyDAO {
        address payable beneficiary = TrustedGovernance.beneficiary();
        TrustedLink.transfer(beneficiary, TrustedLink.balanceOf(address(this)));
        selfdestruct(beneficiary);
    }
}