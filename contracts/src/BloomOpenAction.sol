// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {HubRestricted} from "lens/HubRestricted.sol";
import {Types} from "lens/Types.sol";
import {IPublicationActionModule} from "./interfaces/IPublicationActionModule.sol";
import {Bloom} from "./Bloom.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract BloomOpenAction is HubRestricted, IPublicationActionModule {
    // TODO: Add contract address
    Bloom public bloom = Bloom();
    ILensHub public lensHub;

    constructor(
        address lensHubProxyContract
    ) HubRestricted(lensHubProxyContract) {
        lensHub = ILensHub(lensHubProxyContract);
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (uint256 budget, uint256 rewardPerMirror, uint256 minFollowers) = abi
            .decode(data, (uint256, uint256, uint256));

        bloom.createPromotion(
            transactionExecutor,
            profileId,
            pubId,
            budget,
            rewardPerMirror,
            minFollowers
        );

        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {
        lensHub.mirror(
            params.actorProfileId,
            "",
            params.publicationActedProfileId,
            params.publicationActedId,
            []
            [],
            bytes(0)
        );

        bloom.promote(
            params.publicationActedProfileId,
            params.publicationActedId,
            promoterId,
            mirrorId
        );
    }
}
