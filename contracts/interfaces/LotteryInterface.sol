// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

interface LotteryInterface {
    function fulfillRandom(uint) external;
    function results() external;
}