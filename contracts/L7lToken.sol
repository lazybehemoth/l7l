// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

import { GovernanceInterface } from "./interfaces/GovernanceInterface.sol";

/** 
 * @title L7L token is used to stake for governance of LE7EL
 
 * @dev L7L token is rewarded to players and used as an incentive measure.
 */
contract L7lToken is ERC777 {
    /** 
     * @dev Distribution of initial supply.
     *
     * Of total supply of 100m L7L:
     * 20% goes to LE7EL developers
     * 10% is reserved for future IDO (managed by DAO)
     * 70% is reserved for rewards to Casino players (managed by DAO)
     *
     * for security reasons L7L reward pool will be kept in DAO vault
     * top up is planned with 1m L7L batches
     *
     * @param _governance Governance contract address.
     * @param defaultOperators Contract addresses which can freely interact with L7L tokens.
     */
    constructor(address _governance, address[] memory defaultOperators) public ERC777("LE7EL", "L7L", defaultOperators) {
        GovernanceInterface TrustedGovernance = GovernanceInterface(_governance);
        address beneficiaryAddress = TrustedGovernance.beneficiary();
        address managerAddress = TrustedGovernance.manager();

        _mint(managerAddress, 20000000 * 10 ** 18, "", "");
        _mint(beneficiaryAddress, 80000000 * 10 ** 18, "", "");
    }
}
