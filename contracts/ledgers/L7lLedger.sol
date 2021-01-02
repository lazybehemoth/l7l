// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./ERC777OperatorLedger.sol";

import { GovernanceInterface } from "../interfaces/GovernanceInterface.sol";

/** 
 * @title L7L implementation of ERC777OperatorLedger escrow.
 * @dev Adds vesting for L7L earned by players.
 */
contract L7lLedger is ERC777OperatorLedger {
    GovernanceInterface public TrustedGovernance;
    bool public withdrawalAllowed = false; // Vested before IDO or DAO vote

    modifier onlyDAO() {
        require(msg.sender == TrustedGovernance.owner(), "Only owner");
        _;
    }

    /** 
     * @dev L7L DAO can enable withdrawal of L7L tokens from player balances.
     */
    constructor(address _governance) public ERC777OperatorLedger() {
        TrustedGovernance = GovernanceInterface(_governance);
    }

    /** 
     * @dev Tap initial L7L rewards from DAO balance.
     *
     * @param _token L7L token address.
     */
    function initialize(address _token, address _treasury) public onlyDAO {
        super.initialize(_token);
        
        transferOwnership(_treasury);

        TrustedToken.operatorSend(TrustedGovernance.beneficiary(), address(this), 1000000 * 10 ** 18, "", "");
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payee) public virtual override {
        require(withdrawalAllowed, "payee is not allowed to withdraw");

        super.withdraw(payee);
    }

    /**
     * @dev Allow withdraw of L7L tokens after IDO or as voted by DAO.
     */
    function daoPermitWithdrawal() external onlyDAO {
        withdrawalAllowed = true;
    }

    /**
     * @dev Withdraw reserved L7L rewards back to beneficiary.
     */
    function daoDumpRewards() external onlyDAO {
        TrustedToken.operatorSend(address(this), TrustedGovernance.beneficiary(), TrustedToken.balanceOf(address(this)), "", "");
    }

    /**
     * @dev Change treasury contract.
     *
     * @param _treasury Set new Treasury contract.
     */
    function daoSetTreasury(address _treasury) external onlyDAO {
        transferOwnership(_treasury);
    }
}