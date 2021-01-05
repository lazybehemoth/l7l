// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import { Randomness } from "../Randomness.sol";

contract RandomnessMock is Randomness {
    constructor(
        address _governance,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) public Randomness(_governance, _vrfCoordinator, _linkToken, _keyHash) { }

    /** 
     * @dev Requests randomness from a user-provided seed (UNSAFE MOCK VERSION)
     *
     * @param userProvidedSeed Seed for random number generation.
     * @param round Current round in scope of specific lottery.
     */
    function getRandom(uint256 userProvidedSeed, uint32 round) external override onlyLotteries {
        require(LINK.balanceOf(address(this)) > linkFee, "Not enough LINK");
        require(randomNumbers[msg.sender][round] == 0, "Round resolution pending");

        // Local environment (to skip complex Chainlink setup)
        bytes32 _requestId = bytes32(userProvidedSeed);
        requestIds[_requestId] = Request({g: msg.sender, r: round});

        randomNumbers[msg.sender][round] = 1;
    }
}