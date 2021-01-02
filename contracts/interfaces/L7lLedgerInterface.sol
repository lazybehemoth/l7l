// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface L7lLedgerInterface {
    function depositsOf(address payee) external view returns(uint256);
    function depositFor(address dest, uint256 amount) external;
    function withdraw(address payee) external;
}