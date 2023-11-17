// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC721} from "./interfaces/IERC721.sol";

contract BloomCore {
    address public OPEN_ACTION_CONTRACT;

	// 3 days
	uint256 constant REWARD_BUFFER_PERIOD = 60 * 60 * 24 * 3;

    constructor(address _openActionContract) {
        OPEN_ACTION_CONTRACT = _openActionContract;
    }

    // TODO: Potentially add transactionExecutor
    struct Promotion {
        address transactionExecutor;
        uint256 profileId;
        uint256 pubId;
        uint256 budget;
        address token;
        uint256 rewardPerMirror;
        uint256 minFollowers;
        uint256[] promoters;
    }

	struct Promote {
		uint256 profileId;
        uint256 pubId;
		uint256 rewardPerMirror;
		uint256 timestamp;
	}

    modifier onlyOpenAction() {
        require(msg.sender == OPEN_ACTION_CONTRACT);
        _;
    }

	modifier onlyProfileOwner(uint256 profileId) {
		require(IERC721(lensHubAddress).ownerOf(profileId) == msg.sender, "You are not the profile owner");
		_;
	}

    mapping(uint256 profileId => mapping(uint256 pubId => Promotion))
        public promotions;

	mapping(uint256 profileId => Promote[]) public promotedPosts;

    address public constant lensHubAddress =
        0xC1E77eE73403B8a7478884915aA599932A677870;

    function createPromotion(
        address transactionExecutor,
        uint256 profileId,
        uint256 pubId,
        uint256 budget,
        address token,
        uint256 rewardPerMirror,
        uint256 minFollowers
    ) external onlyOpenAction {
        require(
            IERC721(lensHubAddress).ownerOf(profileId) ==
                transactionExecutor,
            "You are not the owner of this post"
        );

        IERC20(token).transferFrom(transactionExecutor, address(this), budget);

		uint256[] memory promoters = new uint256[](0);

        promotions[profileId][pubId] = Promotion(
            transactionExecutor,
            profileId,
            pubId,
            budget,
            token,
            rewardPerMirror,
            minFollowers,
			promoters
        );
    }

    function promote(
        uint256 promotionProfileId,
        uint256 promotionPubId,
        uint256 promoterId
    ) external onlyOpenAction {
        Promotion storage promotion = promotions[promotionProfileId][
            promotionPubId
        ];
        // TODO: add follower check + other necessary checks

		promotion.promoters.push(promoterId);

		Promote memory promoted = Promote(
			promotionProfileId,
        	promotionPubId,
			promotion.rewardPerMirror,
			block.timestamp
		);

		promotedPosts[promoterId].push(promoted);
    }

	function withdraw(
        uint256 profileId,
        uint256 pubId,
        uint256 amount
    ) external onlyProfileOwner(profileId) {
        require(
            IERC721(lensHubAddress).ownerOf(profileId) == msg.sender,
            "Only the profile owner can withdraw"
        );
        Promotion storage promotion = promotions[profileId][pubId];

		uint256 availableBudget = promotion.budget - (promotion.promoters.length * promotion.rewardPerMirror);

        require(
			availableBudget > amount,
            "Available budget is less than amount"
        );

        promotion.budget -= amount;
        IERC20(promotion.token).transfer(msg.sender, amount);
    }

	function claimRewards(uint256 profileId) external onlyProfileOwner(profileId) {

	}

    // Getters
    function getPromotion(
        uint256 profileId,
        uint256 pubId
    ) external view returns (Promotion memory) {
        return promotions[profileId][pubId];
    }
}
