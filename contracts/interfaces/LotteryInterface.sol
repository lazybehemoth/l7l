// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface LotteryInterface {
    function fulfillRandom(uint) external;
    function results() external;
}