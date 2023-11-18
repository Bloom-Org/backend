// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {HubRestricted} from "./HubRestricted.sol";
import {IPublicationActionModule} from "./interfaces/IPublicationActionModule.sol";
import {Bloom} from "./Bloom.sol";
import {ILensHub, Types} from "./interfaces/ILensHub.sol";

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
        (uint256 rewardPerMirror, uint256 minFollowers, uint256 bufferPeriod) = abi
            .decode(data, (uint256, uint256, uint256));

        bloom.createPromotion(
            transactionExecutor,
            profileId,
            pubId,
            rewardPerMirror,
            minFollowers,
            bufferPeriod
        );

        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {
        Types.MirrorParams memory data = Types.MirrorParams({
            profileId: params.actorProfileId,
            metadataURI: "",
            pointedProfileId: params.publicationActedProfileId,
            pointedPubId: params.publicationActedId,
            referrerProfileIds: new uint256[](0),
            referrerPubIds: new uint256[](0),
            referenceModuleData: ""
        });
        uint256 mirrorId = lensHub.mirror(data);

        bloom.promote(
            params.publicationActedProfileId,
            params.publicationActedId,
            params.actorProfileId,
            mirrorId
        );
    }
}
