// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {HubRestricted} from "./HubRestricted.sol";
import {Types} from "./Types.sol";
import {IPublicationActionModule} from "./interfaces/IPublicationActionModule.sol";
import {Bloom} from "./Bloom.sol";
import {ILensHub} from "./interfaces/ILensHub.sol";

contract BloomOpenAction is HubRestricted, IPublicationActionModule {
    Bloom public bloom;
    ILensHub public lensHub;

    constructor(
        address lensHubProxyContract,
        address bloomContractAddress
    ) HubRestricted(lensHubProxyContract) {
        lensHub = ILensHub(lensHubProxyContract);
        bloom = Bloom(bloomContractAddress);
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (
            uint256 budget,
            uint256 rewardPerMirror,
            uint256 minFollowers,
            uint256 bufferPeriod
        ) = abi.decode(data, (uint256, uint256, uint256, uint256));

        bloom.createPromotion(
            transactionExecutor,
            profileId,
            pubId,
            budget,
            rewardPerMirror,
            minFollowers,
            bufferPeriod
        );

        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {
        uint256 mirrorId = lensHub.mirror(
            abi.encode(
                params.actorProfileId,
                "",
                params.publicationActedProfileId,
                params.publicationActedId,
                uint256[],
                uint256[],
                bytes()
            )
        );

        bloom.promote(
            params.publicationActedProfileId,
            params.publicationActedId,
            params.actorProfileId,
            mirrorId
        );
    }
}
