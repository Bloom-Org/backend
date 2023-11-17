// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from './interfaces/IERC20.sol';

contract BloomCore {
	// TODO: Potentially add transactionExecutor
    struct Promotion {
        uint256 profileId;
        uint256 pubId;
        uint256 budget;
		address token;
        uint256 rewardPerMirror;
		uint256 minFollowers;
    }

    mapping(uint256 profileId => mapping(uint256 pubId => Promotion))
        public promotions;

	function createPromotion(
		uint256 profileId,
		uint256 pubId,
		uint256 budget,
		address token,
		uint256 rewardPerMirror,
		uint256 minFollowers
	) external {

		// TODO: add checks

		IERC20(token).safeTransferFrom(msg.sender, address(this), budget);

		promotions[profileId][pubId] = Promotion(
			profileId,
			pubId,
			budget,
			token,
			rewardPerMirror,
			minFollowers
		);
	}



	function getPromotion(uint256 profileId, uint256 pubId)
		external
		view
		returns (Promotion memory)
	{
		return promotions[profileId][pubId];
	}
}
