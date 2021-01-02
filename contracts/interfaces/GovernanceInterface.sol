// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface GovernanceInterface {
    function owner() external view returns (address);
    function manager() external view returns (address);
    function isManagement(address) external view returns (bool);
    function beneficiary() external view returns (address payable);
    function treasuryContract() external view returns (address);
    function lotteryContracts(address) external view returns (bool);
    function timeToClaimBooty() external view returns (uint);
}