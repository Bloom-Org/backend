// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC721} from "./interfaces/IERC721.sol";

contract Bloom {
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
        uint256 rewardPerMirror;
        uint256 minFollowers;
        uint256[] promoters;
    }

    struct Promote {
        uint256 profileId;
        uint256 pubId;
        uint256 mirrorId;
        uint256 timestamp;
    }

    modifier onlyOpenAction() {
        require(msg.sender == OPEN_ACTION_CONTRACT);
        _;
    }

    modifier onlyProfileOwner(uint256 profileId) {
        require(
            IERC721(lensHubAddress).ownerOf(profileId) == msg.sender,
            "You are not the profile owner"
        );
        _;
    }

    mapping(uint256 profileId => mapping(uint256 pubId => Promotion))
        public promotions;

    mapping(uint256 profileId => Promote[]) public promotedPosts;

    address public constant lensHubAddress =
        0xC1E77eE73403B8a7478884915aA599932A677870;

    function createPromotion(
        uint256 profileId,
        uint256 pubId,
        uint256 budget,
        uint256 rewardPerMirror,
        uint256 minFollowers
    ) external payable {
        require(
            IERC721(lensHubAddress).ownerOf(profileId) == transactionExecutor,
            "You are not the owner of this post"
        );
        require(msg.value == budget, "You need to send the budget amount");

        uint256[] memory promoters = new uint256[](0);

        promotions[profileId][pubId] = Promotion(
            msg.sender,
            profileId,
            pubId,
            budget,
            rewardPerMirror,
            minFollowers,
            promoters
        );
    }

    function promote(
        uint256 promotionProfileId,
        uint256 promotionPubId,
        uint256 promoterId,
        uint256 mirrorId
    ) external onlyOpenAction {
        Promotion storage promotion = promotions[promotionProfileId][
            promotionPubId
        ];

        // TODO: add follower check + other necessary checks

        // TODO: check if rewards are still distributed

        if (
            promotion.budget ==
            (promotion.rewardPerMirror * promotion.promoters.length)
        ) {
            for (uint256 i; promotion.promoters.length > i; i++) {
                Promote storage promote = promotedPosts[promotion.promoters[i]][
                    promotionPubId
                ];
                // TODO check if promote.mirrorId exists
            }
        }

        promotion.promoters.push(promoterId);

        Promote memory promoted = Promote(
            promotionProfileId,
            promotionPubId,
            mirrorId,
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

        uint256 availableBudget = promotion.budget -
            (promotion.promoters.length * promotion.rewardPerMirror);

        require(
            availableBudget > amount,
            "Available budget is less than amount"
        );

        promotion.budget -= amount;
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send tokens");
    }

    function claimRewards(
        uint256 profileId
    ) external onlyProfileOwner(profileId) {
        Promote[] storage _promotedPosts = promotedPosts[profileId];
        require(_promotedPosts.length > 0, "You have nothing to claim");

        for (uint256 i; _promotedPosts.length > i; i++) {
            Promote storage promote = _promotedPosts[i];

            // TODO: check if promote.mirrorId still exists

            // User can only claim if the buffer period has passed since the mirror was created
            if (promote.timestamp + REWARD_BUFFER_PERIOD < block.timestamp) {
                Promotion memory _promotion = promotions[promote.profileId][
                    promote.pubId
                ];
                (bool sent, bytes memory data) = IERC721(lensHubAddress)
                    .ownerOf(profileId)
                    .call{value: _promotion.rewardPerMirror}("");

                require(sent, "Failed to send reward");
            }
        }
    }

    // Getters
    function getPromotion(
        uint256 profileId,
        uint256 pubId
    ) external view returns (Promotion memory) {
        return promotions[profileId][pubId];
    }
}
