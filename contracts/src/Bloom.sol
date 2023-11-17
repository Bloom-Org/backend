// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC721} from "./interfaces/IERC721.sol";

contract BloomCore {
    address public OPEN_ACTION_CONTRACT;

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

    modifier onlyOpenAction() {
        require(msg.sender == OPEN_ACTION_CONTRACT);
        _;
    }

    mapping(uint256 profileId => mapping(uint256 pubId => Promotion))
        public promotions;

    address public constant lensHubProxyContract =
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
            IERC721(lensHubProxyContract).ownerOf(profileId) ==
                transactionExecutor,
            "You are not the owner of this post"
        );

        IERC20(token).transferFrom(transactionExecutor, address(this), budget);

		// create new empty uint256 array
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
        // TODO: add follower check
    }

    // Getters
    function getPromotion(
        uint256 profileId,
        uint256 pubId
    ) external view returns (Promotion memory) {
        return promotions[profileId][pubId];
    }
}
