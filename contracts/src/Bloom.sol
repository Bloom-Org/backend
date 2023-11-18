// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "./interfaces/IERC721.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";
import {FunctionsClient} from "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract Bloom is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    uint32 gasLimit = 300000;
    bytes32 donID =
        0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000;
    uint64 subscriptionId = 817;
    string source =
        "const profileId = args[0];"
        "const followersQuery = await Functions.makeHttpRequest({"
        "url: `https://api-v2-mumbai.lens.dev`,"
        "method: 'POST',"
        "headers: {"
        "'Content-Type': 'application/json',"
        "},"
        "data: {"
        "query: `{"
        "profile(request: { forProfileId: ${profileId} }) {"
        "stats {"
        "followers"
        "}"
        "}"
        "}`,"
        "},"
        "});"
        "return Functions.encodeUint256(followersQuery.data.data.profile.stats.followers);";

    address public OPEN_ACTION_CONTRACT;
    ILensHub public lensHub =
        ILensHub(0xC1E77eE73403B8a7478884915aA599932A677870);

    bytes32 public s_lastRequestId;

    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);

    // Function events
    event PromotionCreated(
        uint256 profileId,
        uint256 pubId,
        uint256 budget,
        uint256 rewardPerMirror,
        uint256 minFollowers,
        uint256 bufferPeriod
    );

    event PostPromoted(
        uint256 profileId,
        uint256 pubId,
        uint256 mirrorId,
        uint256 promoterId
    );

    constructor(
        address router
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    struct Promotion {
        uint256 budget;
        uint256 rewardPerMirror;
        uint256 minFollowers;
        uint256 bufferPeriod;
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

    Promotion[] public allPromotions;
    mapping(uint256 profileId => Promotion[]) promotionsByCreator;

    mapping(uint256 profileId => mapping(uint256 pubId => Promotion))
        public promotions;

    mapping(bytes32 => uint256) private promotionProfileIdTmp;
    mapping(bytes32 => uint256) private promotionPubIdTmp;
    mapping(bytes32 => uint256) private mirrorIdTmp;
    mapping(bytes32 => uint256) private promoterIdTmp;

    mapping(uint256 profileId => PromotedPost[]) public promotedPosts;

    address public constant lensHubAddress =
        0xC1E77eE73403B8a7478884915aA599932A677870;

    function setOpenActionContract(address contract_address) public onlyOwner {
        OPEN_ACTION_CONTRACT = contract_address;
    }

    function getFollowers(
        string[] memory args,
        uint256 promotionProfileId,
        uint256 promotionPubId,
        uint256 mirrorId,
        uint256 promoterId
    ) public returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        if (args.length > 0) req.setArgs(args);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        promotionProfileIdTmp[s_lastRequestId] = promotionProfileId;
        promotionPubIdTmp[s_lastRequestId] = promotionPubId;
        mirrorIdTmp[s_lastRequestId] = mirrorId;
        promoterIdTmp[s_lastRequestId] = promoterId;

        return s_lastRequestId;
    }

    function filterInvalidPromotedPosts(
        uint256 profileId,
        uint256 pubId
    ) private {
        Promotion storage promotion = promotions[profileId][pubId];

        for (uint256 i = 0; promotion.promoterIds.length > i; i++) {
            PromotedPost[] memory posts = promotedPosts[
                promotion.promoterIds[i]
            ];
            PromotedPost memory promotedPost;

            for (uint256 j = 0; j < posts.length; j++) {
                if (posts[j].pubId == pubId) {
                    promotedPost = posts[j];
                }
            }

            if (
                bytes(
                    lensHub
                        .getPublication(
                            promotedPost.profileId,
                            promotedPost.mirrorId
                        )
                        .contentURI
                ).length ==
                0 &&
                !promotedPost.claimed &&
                promotedPost.timestamp + promotion.bufferPeriod >
                block.timestamp
            ) {
                for (uint256 j = 0; j < promotion.promoterIds.length; j++) {
                    if (promotion.promoterIds[j] == promotion.promoterIds[i]) {
                        uint256[] memory promoters = promotions[profileId][
                            pubId
                        ].promoterIds;
                        promotions[profileId][pubId].promoterIds[j] = promoters[
                            promoters.length - 1
                        ];
                        promotions[profileId][pubId].promoterIds.pop();
                    }
                }
                uint256 promoterId = promotion.promoterIds[i];
                for (uint256 j = 0; j < promotedPosts[promoterId].length; j++) {
                    if (
                        promotedPosts[promoterId][j].pubId ==
                        promotedPost.pubId &&
                        promotedPosts[promoterId][j].profileId ==
                        promotedPost.profileId
                    ) {
                        promotedPosts[promoterId][j] = promotedPosts[
                            promoterId
                        ][promotedPosts[promoterId].length - 1];
                        promotedPosts[promoterId].pop();
                    }
                }
            }
        }
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }

        uint256 promotionProfileId = promotionProfileIdTmp[requestId];
        uint256 promotionPubId = promotionPubIdTmp[requestId];
        uint256 mirrorId = mirrorIdTmp[requestId];
        uint256 promoterId = promoterIdTmp[requestId];

        Promotion storage promotion = promotions[promotionProfileId][
            promotionPubId
        ];

        require(
            uint256(bytes32(response)) >= promotion.minFollowers,
            "Your follower count is too low to promote this post."
        );

        if (
            promotion.budget >
            (promotion.rewardPerMirror * promotion.promoterIds.length)
        ) {
            PromotedPost memory promotedPost = PromotedPost(
                promotionProfileId,
                promotionPubId,
                mirrorId,
                block.timestamp,
                false
            );

            promotion.promoterIds.push(promoterId);
            promotedPosts[promoterId].push(promotedPost);
        } else {
            filterInvalidPromotedPosts(promotionProfileId, promotionPubId);
        }
    }

    function isInUintArray(
        uint256[] memory arr,
        uint256 elem
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == elem) {
                return true;
            }
        }
        return false;
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
            isInUintArray(promotion.promoterIds, promoterId),
            "You have already promoted this post"
        );

        string[] memory args = new string[](1);
        args[0] = string(abi.encodePacked("0x", Strings.toString(promoterId)));
        getFollowers(
            args,
            promotionProfileId,
            promotionPubId,
            mirrorId,
            promoterId
        );

        emit PostPromoted(profileId, pubId, mirrorId, promoterId);
    }

    function createPromotion(
        address transactionExecutor,
        uint256 profileId,
        uint256 pubId,
        uint256 budget,
        uint256 rewardPerMirror,
        uint256 minFollowers,
        uint256 bufferPeriod
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

        Promotion memory promotion = Promotion(
            budget,
            rewardPerMirror,
            minFollowers,
            bufferPeriod,
            promoterIds
        );

        promotions[profileId][pubId] = promotion;
        promotionsByCreator[profileId] = promotion;
        allPromotions.push(promotion);

        emit PromotionCreated(
            profileId,
            pubId,
            budget,
            rewardPerMirror,
            minFollowers,
            bufferPeriod
        );
    }

    function withdraw(
        uint256 profileId,
        uint256 pubId,
        uint256 amount
    ) external onlyProfileOwner(profileId) {
        Promotion storage promotion = promotions[profileId][pubId];

        filterInvalidPromotedPosts(profileId, pubId);

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
            Promotion storage promotion = promotions[profileId][
                promotedPost.pubId
            ];
            if (
                !promotedPost.claimed &&
                bytes(
                    lensHub
                        .getPublication(
                            promotedPost.profileId,
                            promotedPost.mirrorId
                        )
                        .contentURI
                ).length ==
                0
            ) {
                if (
                    promotedPost.timestamp + promotion.bufferPeriod <
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

    // Getters
    function getPromotion(
        uint256 profileId,
        uint256 pubId
    ) external view returns (Promotion memory) {
        return promotions[profileId][pubId];
    }

    function getPromotionsByCreatorId(
        uint256 profileId
    ) external view returns (Promotion[] memory) {
        return promotionsByCreator[profileId];
    }

    function getAllPromotions() external view returns (Promotion[] memory) {
        return allPromotions;
    }
}
