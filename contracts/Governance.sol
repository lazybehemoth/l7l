// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * @title Orchestration layer for Chainlink Casino smart-contracts.
 *
 * @dev Controlled by DAO address and is able to add new lotteries,
 * change management and migrate to a new DAO addresses.
 */
contract Governance is Ownable {
    address public manager;
    address payable public beneficiary;

    mapping(address => bool) public lotteryContracts;
    
    address public treasuryContract;

    uint public timeToClaimBooty = 30 days;

    /** 
     * @dev L7L DAO should be in charge of lottery smart-contract.
     */
    constructor(address _manager, address payable _beneficiary) public Ownable() {
        manager = _manager;
        beneficiary = _beneficiary;
    }

    /** 
     * @dev Treasury contract is quite big and doesn't fit 6m gas limit
     * to be initialized in a constructor transaction.
     *
     * @param _treasury Address for treasury contract.
     */
    function initialize(address _treasury) external {
        require(treasuryContract == address(0), "Already initialized");
        treasuryContract = _treasury;
    }

    /** 
     * @dev Check if provided address is part of management group.
     *
     * @param _check Address to check.
     */
    function isManagement(address _check) external view returns (bool) {
        return _check == manager || _check == owner();
    }

    /** 
     * @dev Change lottery smart contract manager.
     *
     * @param _manager Manager address which has access to several actions.
     */
    function assignManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    /** 
     * @dev Change DAO value for recieving casino fees.
     *
     * @param _beneficiary Address for recieving payouts (should be DAO vault contract address).
     */
    function assignBeneficiary(address payable _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    /** 
     * @dev DAO can change booty expiration period to cleanup
     * old contracts.
     *
     * @param _newPeriod How many seconds should pass before booty contract can be destroyed.
     */
    function changeBootyExpiration(uint _newPeriod) external onlyOwner {
        require(_newPeriod > 7 days, "protected from scam");

        timeToClaimBooty = _newPeriod;
    }

    /** 
     * @dev Register lottery smart-contract.
     *
     * @param _lotteryContract Enable lottery smart-contract.
     */
    function enableLotteryContract(address _lotteryContract) external onlyOwner {
        lotteryContracts[_lotteryContract] = true;
    }

    /** 
     * @dev Unregister lottery smart-contract.
     *
     * @param _lotteryContract Disable lottery smart-contract.
     */
    function disableLotteryContract(address _lotteryContract) external onlyOwner {
        lotteryContracts[_lotteryContract] = false;
    }
}