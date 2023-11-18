// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract Bloom {
    address public OPEN_ACTION_CONTRACT;
    ILensHub public lensHub =
        ILensHub(0xC1E77eE73403B8a7478884915aA599932A677870);

    // 3 days
    uint256 constant REWARD_BUFFER_PERIOD = 60 * 60 * 24 * 3;

    constructor(address _openActionContract) {
        OPEN_ACTION_CONTRACT = _openActionContract;
    }

    struct Promotion {
        uint256 budget;
        uint256 rewardPerMirror;
        uint256 minFollowers;
        uint256[] promoterIds;
    }

    struct PromotedPost {
        uint256 profileId;
        uint256 pubId;
        uint256 mirrorId;
        uint256 timestamp;
        bool claimed;
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

    mapping(uint256 profileId => PromotedPost[]) public promotedPosts;

    address public constant lensHubAddress =
        0xC1E77eE73403B8a7478884915aA599932A677870;

    function createPromotion(
        address transactionExecutor,
        uint256 profileId,
        uint256 pubId,
        uint256 budget,
        uint256 rewardPerMirror,
        uint256 minFollowers
    ) external payable onlyOpenAction {
        require(
            promotions[profileId][pubId].rewardPerMirror == 0,
            "Promotion already exists"
        );
        (bool sent, bytes memory data) = transactionExecutor.call{
            value: budget
        }("");
        require(sent, "Failed to send budget");

        uint256[] memory promoterIds;

        promotions[profileId][pubId] = Promotion(
            budget,
            rewardPerMirror,
            minFollowers,
            promoterIds
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

        require(
            // TODO: Not working (require promoterId NOT in promotion.promoterIds)
            promotion.promoterIds.indexOf(promoterId) == -1,
            "You have already promoted this post"
        );

        // TODO: add follower check + other necessary checks (not working)
        require(lensHub.getProfile(promoterId) >= promotion.minFollowers);

        if (
            promotion.budget >
            (promotion.rewardPerMirror * promotion.promoterIds.length)
        ) {
            PromotedPost memory promotedPost = PromotedPost(
                promotionProfileId,
                promotionPubId,
                mirrorId,
                block.timestamp
            );

            promotion.promoterIds.push(promoterId);
            promotedPosts[promoterId].push(promotedPost);
        } else {
            filterInvalidPromotedPosts(promotionProfileId, promotionPubId);
        }
    }

    function withdraw(
        uint256 profileId,
        uint256 pubId,
        uint256 amount
    ) external onlyProfileOwner(profileId) {
        Promotion storage promotion = promotions[profileId][pubId];

        // TODO:

        uint256 availableBudget = promotion.budget -
            (promotion.promoterIds.length * promotion.rewardPerMirror);

        require(
            availableBudget >= amount,
            "Available budget is less than amount"
        );

        promotion.budget -= amount;
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send tokens");
    }

    function claimRewards(
        uint256 profileId
    ) external onlyProfileOwner(profileId) {
        PromotedPost[] storage _promotedPosts = promotedPosts[profileId];
        require(_promotedPosts.length > 0, "You have nothing to claim");

        for (uint256 i; _promotedPosts.length > i; i++) {
            PromotedPost storage promotedPost = _promotedPosts[i];

            if (
                !promotedPost.claimed &&
                lensHub
                    .getPublication(
                        promotedPost.profileId,
                        promotedPost.mirrorId
                    )
                    .contentURI ==
                ""
            ) {
                // TODO: check if promote.mirrorId still exists)
                // User can only claim if the buffer period has passed since the mirror was created
                if (
                    promotedPost.timestamp + REWARD_BUFFER_PERIOD <
                    block.timestamp
                ) {
                    Promotion memory _promotion = promotions[
                        promotedPost.profileId
                    ][promotedPost.pubId];
                    (bool sent, bytes memory data) = IERC721(lensHubAddress)
                        .ownerOf(profileId)
                        .call{value: _promotion.rewardPerMirror}("");

                    require(sent, "Failed to send reward");

                    promotedPost.claimed = true;
                }
            }
        }
    }

    function filterInvalidPromotedPosts(
        uint256 profileId,
        uint256 pubId
    ) external {
        Promotion storage promotion = promotions[profileId][pubId];

        for (uint265 i; promotion.promoterIds.length > i; i++) {
            PromotedPost storage promotedPost = promotedPosts[
                promotion.promoterIds[i]
            ];

            if (
                lensHub
                    .getPublication(
                        promotedPost.profileId,
                        promotedPost.mirrorId
                    )
                    .contentURI ==
                "" &&
                !promotedPost.claimed &&
                promotedPost.timestamp + REWARD_BUFFER_PERIOD > block.timestamp
            ) {
                // TODO: Remove promoterId from promotion.promoterIds
                // TODO: Remove PromotedPost from promotedPosts[promoterId]
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
