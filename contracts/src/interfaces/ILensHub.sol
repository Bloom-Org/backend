// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title Types
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library Types {
    /**
     * @notice ERC721Timestamped storage. Contains the owner address and the mint timestamp for every NFT.
     *
     * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
     * _tokenData mapping, alongside the mint timestamp.
     *
     * @param owner The token owner.
     * @param mintTimestamp The mint timestamp.
     */
    struct TokenData {
        address owner;
        uint96 mintTimestamp;
    }

    /**
     * @notice A struct containing token follow-related data.
     *
     * @param followerProfileId The ID of the profile using the token to follow.
     * @param originalFollowTimestamp The timestamp of the first follow performed with the token.
     * @param followTimestamp The timestamp of the current follow, if a profile is using the token to follow.
     * @param profileIdAllowedToRecover The ID of the profile allowed to recover the follow ID, if any.
     */
    struct FollowData {
        uint160 followerProfileId;
        uint48 originalFollowTimestamp;
        uint48 followTimestamp;
        uint256 profileIdAllowedToRecover;
    }

    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param PublishingPaused The state where only publication creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        PublishingPaused,
        Paused
    }

    /**
     * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
     *
     * @param Nonexistent An indicator showing the queried publication does not exist.
     * @param Post A standard post, having an URI, action modules and no pointer to another publication.
     * @param Comment A comment, having an URI, action modules and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or action modules.
     * @param Quote A quote, having an URI, action modules, and a pointer to another publication.
     */
    enum PublicationType {
        Nonexistent,
        Post,
        Comment,
        Mirror,
        Quote
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param signer The address of the signer. Specially needed as a parameter to support EIP-1271.
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter.
     * @param deadline The signature's deadline.
     */
    struct EIP712Signature {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice A struct containing profile data.
     *
     * @param pubCount The number of publications made to this profile.
     * @param followModule The address of the current follow module in use by this profile, can be address(0) in none.
     * @param followNFT The address of the followNFT associated with this profile. It can be address(0) if the
     * profile has not been followed yet, as the collection is lazy-deployed upon the first follow.
     * @param __DEPRECATED__handle DEPRECATED in V2: handle slot, was replaced with LensHandles.
     * @param __DEPRECATED__imageURI DEPRECATED in V2: The URI to be used for the profile image.
     * @param __DEPRECATED__followNFTURI DEPRECATED in V2: The URI used for the follow NFT image.
     * @param metadataURI MetadataURI is used to store the profile's metadata, for example: displayed name, description,
     * interests, etc.
     */
    struct Profile {
        uint256 pubCount; // offset 0
        address followModule; // offset 1
        address followNFT; // offset 2
        string __DEPRECATED__handle; // offset 3
        string __DEPRECATED__imageURI; // offset 4
        string __DEPRECATED__followNFTURI; // Deprecated in V2 as we have a common tokenURI for all Follows, offset 5
        string metadataURI; // offset 6
    }

    /**
     * @notice A struct containing publication data.
     *
     * @param pointedProfileId The profile token ID to point the publication to.
     * @param pointedPubId The publication ID to point the publication to.
     * These are used to implement the "reference" feature of the platform and is used in:
     * - Mirrors
     * - Comments
     * - Quotes
     * There are (0,0) if the publication is not pointing to any other publication (i.e. the publication is a Post).
     * @param contentURI The URI to set for the content of publication (can be ipfs, arweave, http, etc).
     * @param referenceModule Reference module associated with this profile, if any.
     * @param __DEPRECATED__collectModule Collect module associated with this publication, if any. Deprecated in V2.
     * @param __DEPRECATED__collectNFT Collect NFT associated with this publication, if any. Deprecated in V2.
     * @param pubType The type of publication, can be Nonexistent, Post, Comment, Mirror or Quote.
     * @param rootProfileId The profile ID of the root post (to determine if comments/quotes and mirrors come from it).
     * Posts, V1 publications and publications rooted in V1 publications don't have it set.
     * @param rootPubId The publication ID of the root post (to determine if comments/quotes and mirrors come from it).
     * Posts, V1 publications and publications rooted in V1 publications don't have it set.
     * @param actionModuleEnabled The action modules enabled in a given publication.
     */
    struct Publication {
        uint256 pointedProfileId;
        uint256 pointedPubId;
        string contentURI;
        address referenceModule;
        address __DEPRECATED__collectModule; // Deprecated in V2
        address __DEPRECATED__collectNFT; // Deprecated in V2
        // Added in Lens V2, so these will be zero for old publications:
        PublicationType pubType;
        uint256 rootProfileId;
        uint256 rootPubId;
        mapping(address => bool) actionModuleEnabled;
    }

    struct PublicationMemory {
        uint256 pointedProfileId;
        uint256 pointedPubId;
        string contentURI;
        address referenceModule;
        address __DEPRECATED__collectModule; // Deprecated in V2
        address __DEPRECATED__collectNFT; // Deprecated in V2
        // Added in Lens V2, so these will be zero for old publications:
        PublicationType pubType;
        uint256 rootProfileId;
        uint256 rootPubId;
        // bytes32 __ACTION_MODULE_ENABLED_MAPPING; // Mappings are not supported in memory.
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param to The address receiving the profile.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     */
    struct CreateProfileParams {
        address to;
        address followModule;
        bytes followModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `post()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct PostParams {
        uint256 profileId;
        string contentURI;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `comment()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param pointedProfileId The profile token ID to point the comment to.
     * @param pointedPubId The publication ID to point the comment to.
     * @param referrerProfileId The profile token ID of the publication that referred to the publication being commented on/quoted.
     * @param referrerPubId The ID of the publication that referred to the publication being commented on/quoted.
     * @param referenceModuleData The data passed to the reference module.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct CommentParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `quote()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param pointedProfileId The profile token ID of the publication author that is quoted.
     * @param pointedPubId The publication ID that is quoted.
     * @param referrerProfileId The profile token ID of the publication that referred to the publication being commented on/quoted.
     * @param referrerPubId The ID of the publication that referred to the publication being commented on/quoted.
     * @param referenceModuleData The data passed to the reference module.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct QuoteParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `comment()` or `quote()` internal functions.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param pointedProfileId The profile token ID of the publication author that is commented on/quoted.
     * @param pointedPubId The publication ID that is commented on/quoted.
     * @param referrerProfileId The profile token ID of the publication that referred to the publication being commented on/quoted.
     * @param referrerPubId The ID of the publication that referred to the publication being commented on/quoted.
     * @param referenceModuleData The data passed to the reference module.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct ReferencePubParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `mirror()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param metadataURI the URI containing metadata attributes to attach to this mirror publication.
     * @param pointedProfileId The profile token ID to point the mirror to.
     * @param pointedPubId The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     */
    struct MirrorParams {
        uint256 profileId;
        string metadataURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
    }

    /**
     * Deprecated in V2: Will be removed after some time after upgrading to V2.
     * @notice A struct containing the parameters required for the legacy `collect()` function.
     * @dev The referrer can only be a mirror of the publication being collected.
     *
     * @param publicationCollectedProfileId The token ID of the profile that published the publication to collect.
     * @param publicationCollectedId The publication to collect's publication ID.
     * @param collectorProfileId The collector profile.
     * @param referrerProfileId The ID of a profile that authored a mirror that helped discovering the collected pub.
     * @param referrerPubId The ID of the mirror that helped discovering the collected pub.
     * @param collectModuleData The arbitrary data to pass to the collectModule if needed.
     */
    struct LegacyCollectParams {
        uint256 publicationCollectedProfileId;
        uint256 publicationCollectedId;
        uint256 collectorProfileId;
        uint256 referrerProfileId;
        uint256 referrerPubId;
        bytes collectModuleData;
    }

    /**
     * @notice A struct containing the parameters required for the `action()` function.
     *
     * @param publicationActedProfileId The token ID of the profile that published the publication to action.
     * @param publicationActedId The publication to action's publication ID.
     * @param actorProfileId The actor profile.
     * @param referrerProfileId
     * @param referrerPubId
     * @param actionModuleAddress
     * @param actionModuleData The arbitrary data to pass to the actionModule if needed.
     */
    struct PublicationActionParams {
        uint256 publicationActedProfileId;
        uint256 publicationActedId;
        uint256 actorProfileId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        address actionModuleAddress;
        bytes actionModuleData;
    }

    struct ProcessActionParams {
        uint256 publicationActedProfileId;
        uint256 publicationActedId;
        uint256 actorProfileId;
        address actorProfileOwner;
        address transactionExecutor;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes actionModuleData;
    }

    struct ProcessCommentParams {
        uint256 profileId;
        uint256 pubId;
        address transactionExecutor;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes data;
    }

    struct ProcessQuoteParams {
        uint256 profileId;
        uint256 pubId;
        address transactionExecutor;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes data;
    }

    struct ProcessMirrorParams {
        uint256 profileId;
        uint256 pubId;
        address transactionExecutor;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes data;
    }

    /**
     * @notice A struct containing a profile's delegated executors configuration.
     *
     * @param isApproved Tells when an address is approved as delegated executor in the given configuration number.
     * @param configNumber Current configuration number in use.
     * @param prevConfigNumber Previous configuration number set, before switching to the current one.
     * @param maxConfigNumberSet Maximum configuration number ever used.
     */
    struct DelegatedExecutorsConfig {
        mapping(uint256 => mapping(address => bool)) isApproved; // isApproved[configNumber][delegatedExecutor]
        uint64 configNumber;
        uint64 prevConfigNumber;
        uint64 maxConfigNumberSet;
    }

    struct TreasuryData {
        address treasury;
        uint16 treasuryFeeBPS;
    }

    struct MigrationParams {
        address lensHandlesAddress;
        address tokenHandleRegistryAddress;
        address legacyFeeFollowModule;
        address legacyProfileFollowModule;
        address newFeeFollowModule;
    }
}

/**
 * @title ILensProtocol
 * @author Lens Protocol
 *
 * @notice This is the interface for Lens Protocol's core functions. It contains all the entry points for performing
 * social operations.
 */
interface ILensProtocol {
    /**
     * @notice Creates a profile with the specified parameters, minting a Profile NFT to the given recipient.
     * @custom:permissions Any whitelisted profile creator.
     *
     * @param createProfileParams A CreateProfileParams struct containing the needed params.
     */
    function createProfile(
        Types.CreateProfileParams calldata createProfileParams
    ) external returns (uint256);

    /**
     * @notice Sets the metadata URI for the given profile.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param profileId The token ID of the profile to set the metadata URI for.
     * @param metadataURI The metadata URI to set for the given profile.
     */
    function setProfileMetadataURI(
        uint256 profileId,
        string calldata metadataURI
    ) external;

    /**
     * @custom:meta-tx setProfileMetadataURI.
     */
    function setProfileMetadataURIWithSig(
        uint256 profileId,
        string calldata metadataURI,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets the follow module for the given profile.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param profileId The token ID of the profile to set the follow module for.
     * @param followModule The follow module to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the follow module for initialization.
     */
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external;

    /**
     * @custom:meta-tx setFollowModule.
     */
    function setFollowModuleWithSig(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Changes the delegated executors configuration for the given profile. It allows setting the approvals for
     * delegated executors in the specified configuration, as well as switching to it.
     * @custom:permissions Profile Owner.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param delegatedExecutors The array of delegated executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor's new approval status.
     * @param configNumber The number of the configuration where the executor approval state is being set.
     * @param switchToGivenConfig A boolean indicating if the configuration must be switched to the one with the given
     * number.
     */
    function changeDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) external;

    /**
     * @notice Changes the delegated executors configuration for the given profile under the current configuration.
     * @custom:permissions Profile Owner.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param delegatedExecutors The array of delegated executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor's new approval status.
     */
    function changeDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals
    ) external;

    /**
     * @custom:meta-tx changeDelegatedExecutorsConfig.
     */
    function changeDelegatedExecutorsConfigWithSig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Publishes a post.
     * Post is the most basic publication type, and can be used to publish any kind of content.
     * Posts can have these types of modules initialized:
     *  - Action modules: any number of publication actions (e.g. collect, tip, etc.)
     *  - Reference module: a module handling the rules when referencing this post (e.g. token-gated comments)
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param postParams A PostParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the post's publication ID.
     */
    function post(
        Types.PostParams calldata postParams
    ) external returns (uint256);

    /**
     * @custom:meta-tx post.
     */
    function postWithSig(
        Types.PostParams calldata postParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a comment on the given publication.
     * Comment is a type of reference publication that points to another publication.
     * Comments can have these types of modules initialized:
     *  - Action modules: any number of publication actions (e.g. collect, tip, etc.)
     *  - Reference module: a module handling the rules when referencing this comment (e.g. token-gated mirrors)
     * Comments can have referrers (e.g. publications or profiles that helped to discover the pointed publication).
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param commentParams A CommentParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the comment's publication ID.
     */
    function comment(
        Types.CommentParams calldata commentParams
    ) external returns (uint256);

    /**
     * @custom:meta-tx comment.
     */
    function commentWithSig(
        Types.CommentParams calldata commentParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a mirror of the given publication.
     * Mirror is a type of reference publication that points to another publication but doesn't have content.
     * Mirrors don't have any modules initialized.
     * Mirrors can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * You cannot mirror a mirror, comment on a mirror, or quote a mirror.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param mirrorParams A MirrorParams struct containing the necessary parameters.
     *
     * @return uint256 An integer representing the mirror's publication ID.
     */
    function mirror(
        Types.MirrorParams calldata mirrorParams
    ) external returns (uint256);

    /**
     * @custom:meta-tx mirror.
     */
    function mirrorWithSig(
        Types.MirrorParams calldata mirrorParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a quote of the given publication.
     * Quote is a type of reference publication similar to mirror, but it has content and modules.
     * Quotes can have these types of modules initialized:
     *  - Action modules: any number of publication actions (e.g. collect, tip, etc.)
     *  - Reference module: a module handling the rules when referencing this quote (e.g. token-gated comments on quote)
     * Quotes can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * Unlike mirrors, you can mirror a quote, comment on a quote, or quote a quote.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param quoteParams A QuoteParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the quote's publication ID.
     */
    function quote(
        Types.QuoteParams calldata quoteParams
    ) external returns (uint256);

    /**
     * @custom:meta-tx quote.
     */
    function quoteWithSig(
        Types.QuoteParams calldata quoteParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Follows given profiles, executing each profile's follow module logic (if any).
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @dev Both the `idsOfProfilesToFollow`, `followTokenIds`, and `datas` arrays must be of the same length,
     * regardless if the profiles do not have a follow module set.
     *
     * @param followerProfileId The ID of the profile the follows are being executed for.
     * @param idsOfProfilesToFollow The array of IDs of profiles to follow.
     * @param followTokenIds The array of follow token IDs to use for each follow (0 if you don't own a follow token).
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     *
     * @return uint256[] An array of follow token IDs representing the follow tokens created for each follow.
     */
    function follow(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas
    ) external returns (uint256[] memory);

    /**
     * @custom:meta-tx follow.
     */
    function followWithSig(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas,
        Types.EIP712Signature calldata signature
    ) external returns (uint256[] memory);

    /**
     * @notice Unfollows given profiles.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param unfollowerProfileId The ID of the profile the unfollows are being executed for.
     * @param idsOfProfilesToUnfollow The array of IDs of profiles to unfollow.
     */
    function unfollow(
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow
    ) external;

    /**
     * @custom:meta-tx unfollow.
     */
    function unfollowWithSig(
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets the block status for the given profiles. Changing a profile's block status to `true` (i.e. blocked),
     * when will also force them to unfollow.
     * Blocked profiles cannot perform any actions with the profile that blocked them: they cannot comment or mirror
     * their publications, they cannot follow them, they cannot collect, tip them, etc.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @dev Both the `idsOfProfilesToSetBlockStatus` and `blockStatus` arrays must be of the same length.
     *
     * @param byProfileId The ID of the profile that is blocking/unblocking somebody.
     * @param idsOfProfilesToSetBlockStatus The array of IDs of profiles to set block status.
     * @param blockStatus The array of block statuses to use for each (true is blocked).
     */
    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external;

    /**
     * @custom:meta-tx setBlockStatus.
     */
    function setBlockStatusWithSig(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Collects a given publication via signature with the specified parameters.
     * Collect can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * @custom:permissions Collector Profile Owner or its Delegated Executor.
     * @custom:pending-deprecation Collect modules were replaced by PublicationAction Collect modules in V2. This method
     * is left here for backwards compatibility with posts made in V1 that had Collect modules.
     *
     * @param collectParams A CollectParams struct containing the parameters.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collectLegacy(
        Types.LegacyCollectParams calldata collectParams
    ) external returns (uint256);

    /**
     * @custom:meta-tx collect.
     * @custom:pending-deprecation
     */
    function collectLegacyWithSig(
        Types.LegacyCollectParams calldata collectParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Acts on a given publication with the specified parameters.
     * You can act on a publication except a mirror (if it has at least one action module initialized).
     * Actions can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * @custom:permissions Actor Profile Owner or its Delegated Executor.
     *
     * @param publicationActionParams A PublicationActionParams struct containing the parameters.
     *
     * @return bytes Arbitrary data the action module returns.
     */
    function act(
        Types.PublicationActionParams calldata publicationActionParams
    ) external returns (bytes memory);

    /**
     * @custom:meta-tx act.
     */
    function actWithSig(
        Types.PublicationActionParams calldata publicationActionParams,
        Types.EIP712Signature calldata signature
    ) external returns (bytes memory);

    /**
     * @dev This function is used to invalidate signatures by incrementing the nonce of the signer.
     * @param increment The amount to increment the nonce by (max 255).
     */
    function incrementNonce(uint8 increment) external;

    /////////////////////////////////
    ///       VIEW FUNCTIONS      ///
    /////////////////////////////////

    /**
     * @notice Returns whether or not `followerProfileId` is following `followedProfileId`.
     *
     * @param followerProfileId The ID of the profile whose following state should be queried.
     * @param followedProfileId The ID of the profile whose followed state should be queried.
     *
     * @return bool True if `followerProfileId` is following `followedProfileId`, false otherwise.
     */
    function isFollowing(
        uint256 followerProfileId,
        uint256 followedProfileId
    ) external view returns (bool);

    /**
     * @notice Returns whether the given address is approved as delegated executor, in the configuration with the given
     * number, to act on behalf of the given profile.
     *
     * @param delegatorProfileId The ID of the profile to check the delegated executor approval for.
     * @param delegatedExecutor The address to query the delegated executor approval for.
     * @param configNumber The number of the configuration where the executor approval state is being queried.
     *
     * @return bool True if the address is approved as a delegated executor to act on behalf of the profile in the
     * given configuration, false otherwise.
     */
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor,
        uint64 configNumber
    ) external view returns (bool);

    /**
     * @notice Returns whether the given address is approved as delegated executor, in the current configuration, to act
     * on behalf of the given profile.
     *
     * @param delegatorProfileId The ID of the profile to check the delegated executor approval for.
     * @param delegatedExecutor The address to query the delegated executor approval for.
     *
     * @return bool True if the address is approved as a delegated executor to act on behalf of the profile in the
     * current configuration, false otherwise.
     */
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor
    ) external view returns (bool);

    /**
     * @notice Returns the current delegated executor config number for the given profile.
     *
     * @param delegatorProfileId The ID of the profile from which the delegated executors config number is being queried
     *
     * @return uint256 The current delegated executor configuration number.
     */
    function getDelegatedExecutorsConfigNumber(
        uint256 delegatorProfileId
    ) external view returns (uint64);

    /**
     * @notice Returns the previous used delegated executor config number for the given profile.
     *
     * @param delegatorProfileId The ID of the profile from which the delegated executors' previous configuration number
     * set is being queried.
     *
     * @return uint256 The delegated executor configuration number previously set. It will coincide with the current
     * configuration set if it was never switched from the default one.
     */
    function getDelegatedExecutorsPrevConfigNumber(
        uint256 delegatorProfileId
    ) external view returns (uint64);

    /**
     * @notice Returns the maximum delegated executor config number for the given profile.
     * This is the maximum config number that was ever used by this profile.
     * When creating a new clean configuration, you can only use a number that is maxConfigNumber + 1.
     *
     * @param delegatorProfileId The ID of the profile from which the delegated executors' maximum configuration number
     * set is being queried.
     *
     * @return uint256 The delegated executor maximum configuration number set.
     */
    function getDelegatedExecutorsMaxConfigNumberSet(
        uint256 delegatorProfileId
    ) external view returns (uint64);

    /**
     * @notice Returns whether `profileId` is blocked by `byProfileId`.
     * See setBlockStatus() for more information on how blocking works on the platform.
     *
     * @param profileId The ID of the profile whose blocked status should be queried.
     * @param byProfileId The ID of the profile whose blocker status should be queried.
     *
     * @return bool True if `profileId` is blocked by `byProfileId`, false otherwise.
     */
    function isBlocked(
        uint256 profileId,
        uint256 byProfileId
    ) external view returns (bool);

    /**
     * @notice Returns the URI associated with a given publication.
     * This is used to store the publication's metadata, e.g.: content, images, etc.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return string The URI associated with a given publication.
     */
    function getContentURI(
        uint256 profileId,
        uint256 pubId
    ) external view returns (string memory);

    /**
     * @notice Returns the full profile struct associated with a given profile token ID.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return Profile The profile struct of the given profile.
     */
    function getProfile(
        uint256 profileId
    ) external view returns (Types.Profile memory);

    /**
     * @notice Returns the full publication struct for a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return Publication The publication struct associated with the queried publication.
     */
    function getPublication(
        uint256 profileId,
        uint256 pubId
    ) external view returns (Types.PublicationMemory memory);

    /**
     * @notice Returns the type of a given publication.
     * The type can be one of the following (see PublicationType enum):
     * - Nonexistent
     * - Post
     * - Comment
     * - Mirror
     * - Quote
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return PublicationType The publication type of the queried publication.
     */
    function getPublicationType(
        uint256 profileId,
        uint256 pubId
    ) external view returns (Types.PublicationType);

    /**
     * @notice Returns wether a given Action Module is enabled for a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     * @param module The address of the Action Module to query.
     *
     * @return bool True if the Action Module is enabled for the queried publication, false if not.
     */
    function isActionModuleEnabledInPublication(
        uint256 profileId,
        uint256 pubId,
        address module
    ) external view returns (bool);
}

/**
 * @title ILensGovernable
 * @author Lens Protocol
 *
 * @notice This is the interface for the Lens Protocol main governance functions.
 */
interface ILensGovernable {
    /**
     * @notice Sets the privileged governance role.
     * @custom:permissions Governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state.
     * @custom:permissions Governance.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external;

    /**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state.
     * @custom:permissions Governance or Emergency Admin. Emergency Admin can only restrict more.
     *
     * @param newState The state to set. It can be one of the following:
     *  - Unpaused: The protocol is fully operational.
     *  - PublishingPaused: The protocol is paused for publishing, but it is still operational for others operations.
     *  - Paused: The protocol is paused for all operations.
     */
    function setState(Types.ProtocolState newState) external;

    /**
     * @notice Adds or removes a profile creator from the whitelist.
     * @custom:permissions Governance.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(
        address profileCreator,
        bool whitelist
    ) external;

    /**
     * @notice Sets the treasury address.
     * @custom:permissions Governance
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Sets the treasury fee.
     * @custom:permissions Governance
     *
     * @param newTreasuryFee The new treasury fee to set.
     */
    function setTreasuryFee(uint16 newTreasuryFee) external;

    /**
     * @notice Returns the currently configured governance address.
     *
     * @return address The address of the currently configured governance.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Gets the state currently set in the protocol. It could be a global pause, a publishing pause or an
     * unpaused state.
     * @custom:permissions Anyone.
     *
     * @return Types.ProtocolState The state currently set in the protocol.
     */
    function getState() external view returns (Types.ProtocolState);

    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return bool True if the profile creator is whitelisted, false otherwise.
     */
    function isProfileCreatorWhitelisted(
        address profileCreator
    ) external view returns (bool);

    /**
     * @notice Returns the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Returns the treasury fee.
     *
     * @return uint16 The treasury fee.
     */
    function getTreasuryFee() external view returns (uint16);

    /**
     * @notice Returns the treasury address and treasury fee in a single call.
     *
     * @return tuple First, the treasury address, second, the treasury fee.
     */
    function getTreasuryData() external view returns (address, uint16);
}

/**
 * @title ILensHubEventHooks
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract's event hooks. As we want most of the core events to be
 * emitted by the LensHub contract, event hooks are needed for core events generated by pheripheral contracts.
 */
interface ILensHubEventHooks {
    /**
     * @dev Helper function to emit an `Unfollowed` event from the hub, to be consumed by indexers to track unfollows.
     * @custom:permissions FollowNFT of the Profile unfollowed.
     *
     * @param unfollowerProfileId The ID of the profile that executed the unfollow.
     * @param idOfProfileUnfollowed The ID of the profile that was unfollowed.
     * @param transactionExecutor The address of the account executing the unfollow operation.
     */
    function emitUnfollowedEvent(
        uint256 unfollowerProfileId,
        uint256 idOfProfileUnfollowed,
        address transactionExecutor
    ) external;
}

/**
 * @title ILensImplGetters
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract's implementation getters. These implementations will be used
 * for deploying each respective contract for each profile.
 */
interface ILensImplGetters {
    /**
     * @notice Returns the Follow NFT implementation address that is used for all deployed Follow NFTs.
     *
     * @return address The Follow NFT implementation address.
     */
    function getFollowNFTImpl() external view returns (address);

    /**
     * @notice Returns the Collect NFT implementation address that is used for each new deployed Collect NFT.
     * @custom:pending-deprecation
     *
     * @return address The Collect NFT implementation address.
     */
    function getLegacyCollectNFTImpl() external view returns (address);

    /**
     * @notice Returns the address of the registry that stores all modules that are used by the Lens Protocol.
     *
     * @return address The address of the Module Registry contract.
     */
    function getModuleRegistry() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

/**
 * @title IERC721Timestamped
 * @author Lens Protocol
 *
 * @notice Extension of ERC-721 including a struct for token data, which contains the owner and the mint timestamp, as
 * well as their associated getters.
 */
interface IERC721Timestamped {
    /**
     * @notice Returns the mint timestamp associated with a given NFT.
     *
     * @param tokenId The token ID of the NFT to query the mint timestamp for.
     *
     * @return uint256 Mint timestamp, this is stored as a uint96 but returned as a uint256 to reduce unnecessary
     * padding.
     */
    function mintTimestampOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the token data associated with a given NFT. This allows fetching the token owner and
     * mint timestamp in a single call.
     *
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return TokenData A struct containing both the owner address and the mint timestamp.
     */
    function tokenDataOf(
        uint256 tokenId
    ) external view returns (Types.TokenData memory);

    /**
     * @notice Returns whether a token with the given token ID exists.
     *
     * @param tokenId The token ID of the NFT to check existence for.
     *
     * @return bool True if the token exists.
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @notice Returns the amount of tokens in circulation.
     *
     * @return uint256 The current total supply of tokens.
     */
    function totalSupply() external view returns (uint256);
}

/**
 * @title IERC721Burnable
 * @author Lens Protocol
 *
 * @notice Extension of ERC-721 including a function that allows the token to be burned.
 */
interface IERC721Burnable {
    /**
     * @notice Burns an NFT, removing it from circulation and essentially destroying it.
     * @custom:permission Owner of the NFT.
     *
     * @param tokenId The token ID of the token to burn.
     */
    function burn(uint256 tokenId) external;
}

/**
 * @title IERC721MetaTx
 * @author Lens Protocol
 *
 * @notice Extension of ERC-721 including meta-tx signatures related functions.
 */
interface IERC721MetaTx {
    /**
     * @notice Returns the current signature nonce of the given signer.
     *
     * @param signer The address for which to query the nonce.
     *
     * @return uint256 The current nonce of the given signer.
     */
    function nonces(address signer) external view returns (uint256);

    /**
     * @notice Returns the EIP-712 domain separator for this contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ILensERC721 is
    IERC721,
    IERC721Timestamped,
    IERC721Burnable,
    IERC721MetaTx,
    IERC721Metadata
{}

interface ILensProfiles is ILensERC721 {
    /**
     * @notice DANGER: Triggers disabling the profile protection mechanism for the msg.sender, which will allow
     * transfers or approvals over profiles held by it.
     * Disabling the mechanism will have a timelock before it becomes effective, allowing the owner to re-enable
     * the protection back in case of being under attack.
     * The protection layer only applies to EOA wallets.
     */
    function DANGER__disableTokenGuardian() external;

    /**
     * @notice Enables back the profile protection mechanism for the msg.sender, preventing profile transfers or
     * approvals (except when revoking them).
     * The protection layer only applies to EOA wallets.
     */
    function enableTokenGuardian() external;

    /**
     * @notice Returns the timestamp at which the Token Guardian will become effectively disabled.
     *
     * @param wallet The address to check the timestamp for.
     *
     * @return uint256 The timestamp at which the Token Guardian will become effectively disabled. Zero if enabled.
     */
    function getTokenGuardianDisablingTimestamp(
        address wallet
    ) external view returns (uint256);
}

/**
 * @title ILensVersion
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub Version getters and emitter.
 * It allows to emit a LensHub version during an upgrade, and also to get the current version.
 */
interface ILensVersion {
    /**
     * @notice Returns the LensHub current Version.
     *
     * @return version The LensHub current Version.
     */
    function getVersion() external view returns (string memory);

    /**
     * @notice Returns the LensHub current Git Commit.
     *
     * @return gitCommit The LensHub current Git Commit.
     */
    function getGitCommit() external view returns (bytes20);

    /**
     * @notice Emits the LensHub current Version. Used in upgradeAndCall().
     */
    function emitVersion() external;
}

interface ILensHub is
    ILensProfiles,
    ILensProtocol,
    ILensGovernable,
    ILensHubEventHooks,
    ILensImplGetters,
    ILensVersion
{}
