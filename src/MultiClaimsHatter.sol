// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { HatsModule } from "hats-module/HatsModule.sol";
import { HatsModuleFactory } from "hats-module/HatsModuleFactory.sol";

contract MultiClaimsHatter is HatsModule {
  /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
  //////////////////////////////////////////////////////////////*/

  /// @notice Thrown if the given array parameters are not of equal length
  error MultiClaimsHatter_ArrayLengthMismatch();
  /// @notice Thrown if the calling account is not an admin of the hat
  error MultiClaimsHatter_NotAdminOfHat(address acoount, uint256 hatId);
  /// @notice Thrown if the account is not explicitly eligible for the hat
  error MultiClaimsHatter_NotExplicitlyEligible(address acoount, uint256 hatId);
  /// @notice Thrown if the hat is not claimable
  error MultiClaimsHatter_HatNotClaimable(uint256 hatId);
  /// @notice Thrown if the hat is not claimable on behalf of accounts
  error MultiClaimsHatter_HatNotClaimableFor(uint256 hatId);

  /*//////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /// @notice Emitted when the claimability of multiple hats was edited
  event HatsEdited(uint256[] hatIds, ClaimInfo[] claimInfo);
  /// @notice Emitted when the calimability of a hat was edited
  event HatEdited(uint256 hatIds, ClaimInfo claimInfo);
  /// @notice Emitted when a hat was claimed
  event HatClaimed(uint256 hatId, address wearer);
  /// @notice Emitted when multiple hats were claimed by a single wearer
  event HatsClaimedByWearer(uint256[] hatIds, address wearer);
  /// @notice Emitted when multiple hats were claimed for wearers
  event HatsClaimedForWearers(uint256[] hatIds, address[] wearers);

  /*//////////////////////////////////////////////////////////////
                            DATA MODELS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Hats claimability information.
   * @param NotClaimable The hat is not claimable
   * @param Claimable The hat is only claimable by the account that will be the hat's wearer
   * @param ClaimableFor The hat is claimable on behalf of accounts (and also by the wearer)
   */
  enum ClaimInfo {
    NotClaimable,
    Claimable,
    ClaimableFor
  }

  /*//////////////////////////////////////////////////////////////
                            CONSTANTS 
  //////////////////////////////////////////////////////////////*/

  /**
   * This contract is a clone with immutable args, which means that it is deployed with a set of
   * immutable storage variables (ie constants). Accessing these constants is cheaper than accessing
   * regular storage variables (such as those set on initialization of a typical EIP-1167 clone),
   * but requires a slightly different approach since they are read from calldata instead of storage.
   *
   * Below is a table of constants and their location.
   *
   * For more, see here: https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args
   *
   * ----------------------------------------------------------------------+
   * CLONE IMMUTABLE "STORAGE"                                             |
   * ----------------------------------------------------------------------|
   * Offset  | Constant          | Type    | Length  | Source              |
   * ----------------------------------------------------------------------|
   * 0       | IMPLEMENTATION    | address | 20      | HatsModule          |
   * 20      | HATS              | address | 20      | HatsModule          |
   * 40      | hatId             | uint256 | 32      | HatsModule          |
   * ----------------------------------------------------------------------+
   */

  /*//////////////////////////////////////////////////////////////
                            MUTABLE STATE
  //////////////////////////////////////////////////////////////*/

  /// @notice Maps between hats and their claimability information
  mapping(uint256 hatId => ClaimInfo claimInfo) claimableHats;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploy the implementation contract and set its version
  /// @dev This is only used to deploy the implementation contract, and should not be used to deploy clones
  constructor(string memory _version) HatsModule(_version) { }

  /*//////////////////////////////////////////////////////////////
                            INITIALIZOR
  //////////////////////////////////////////////////////////////*/

  /// @inheritdoc HatsModule
  function _setUp(bytes calldata _initData) internal override {
    // if there are no initial accounts to add, only initialize the clone instance
    if (_initData.length == 0) return;

    // decode init data
    (uint256[] memory _hatIds, ClaimInfo[] memory _claimInfo) = abi.decode(_initData, (uint256[], ClaimInfo[]));
    _addOrRemoveHatsMemory(_hatIds, _claimInfo);
  }

  /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Change the claimability status of a hat. The caller should be an admin of the hat.
   * @param _hatId The ID of the hat to edit
   * @param _claimInfo New claimability information for the hat
   */
  function addOrRemoveHat(uint256 _hatId, ClaimInfo _claimInfo) public {
    if (!HATS().isAdminOfHat(msg.sender, _hatId)) revert MultiClaimsHatter_NotAdminOfHat(msg.sender, _hatId);

    claimableHats[_hatId] = _claimInfo;

    emit HatEdited(_hatId, _claimInfo);
  }

  /**
   * @notice Change the claimability status of a multiple hats. The caller should be an admin of the hats.
   * @param _hatIds The IDs of the hats to edit
   * @param _claimInfo New claimability information for each hat
   */
  function addOrRemoveHats(uint256[] calldata _hatIds, ClaimInfo[] calldata _claimInfo) public {
    uint256 length = _hatIds.length;
    if (_claimInfo.length != length) {
      revert MultiClaimsHatter_ArrayLengthMismatch();
    }

    for (uint256 i; i < length;) {
      uint256 hatId = _hatIds[i];
      if (!HATS().isAdminOfHat(msg.sender, hatId)) revert MultiClaimsHatter_NotAdminOfHat(msg.sender, hatId);
      claimableHats[hatId] = _claimInfo[i];
      unchecked {
        ++i;
      }
    }

    emit HatsEdited(_hatIds, _claimInfo);
  }

  /*//////////////////////////////////////////////////////////////
                        CLAIMING FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Claim a hat.
   * @param _hatId The ID of the hat to claim
   */
  function claimHat(uint256 _hatId) public {
    if (claimableHats[_hatId] == ClaimInfo.NotClaimable) {
      revert MultiClaimsHatter_HatNotClaimable(_hatId);
    }

    _mint(_hatId, msg.sender);
    emit HatClaimed(_hatId, msg.sender);
  }

  /**
   * @notice Claim multiple hats.
   * @param _hatIds The IDs of the hats to claim
   */
  function claimMultipleHats(uint256[] calldata _hatIds) public {
    for (uint256 i; i < _hatIds.length;) {
      uint256 hatId = _hatIds[i];
      if (claimableHats[hatId] == ClaimInfo.NotClaimable) {
        revert MultiClaimsHatter_HatNotClaimable(hatId);
      }

      _mint(hatId, msg.sender);
    }

    emit HatsClaimedByWearer(_hatIds, msg.sender);
  }

  /**
   * @notice Claim a hat on behalf of an account
   * @param _hatId The ID of the hat to claim for
   * @param _account The account for which to claim
   */
  function claimHatFor(uint256 _hatId, address _account) public {
    if (claimableHats[_hatId] != ClaimInfo.ClaimableFor) {
      revert MultiClaimsHatter_HatNotClaimableFor(_hatId);
    }

    _mint(_hatId, _account);
    emit HatClaimed(_hatId, _account);
  }

  /**
   * @notice Claim multiple hats on behalf of accounts
   * @param _hatIds The IDs of the hats to claim for
   * @param _accounts The accounts for which to claim
   */
  function claimMultipleHatsFor(uint256[] calldata _hatIds, address[] calldata _accounts) public {
    if (_hatIds.length != _accounts.length) {
      revert MultiClaimsHatter_ArrayLengthMismatch();
    }

    for (uint256 i; i < _hatIds.length;) {
      uint256 hatId = _hatIds[i];
      if (claimableHats[hatId] != ClaimInfo.ClaimableFor) {
        revert MultiClaimsHatter_HatNotClaimableFor(hatId);
      }

      _mint(hatId, _accounts[i]);
    }

    emit HatsClaimedForWearers(_hatIds, _accounts);
  }

  /*//////////////////////////////////////////////////////////////
                        MODULES CREATION FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Wrapper around a HatsModuleFactory. Deploys a new HatsModule instance for a given `_hatId` to a
   * deterministic address, if not already deployed, and sets up the new instance with initial operational values.
   * @dev Will revert *after* the instance is deployed if their initial values are invalid.
   * @param _factory The HatsModuleFactory instance that will deploy the module
   * @param _implementation The address of the implementation contract of which to deploy a clone
   * @param _hatId The hat for which to deploy a HatsModule.
   * @param _otherImmutableArgs Other immutable args to pass to the clone as immutable storage.
   * @param _initData The encoded data to pass to the `setUp` function of the new HatsModule instance. Leave empty if no
   * {setUp} is required.
   * @return _instance The address of the deployed HatsModule instance
   */
  function createHatsModule(
    HatsModuleFactory _factory,
    address _implementation,
    uint256 _hatId,
    bytes calldata _otherImmutableArgs,
    bytes calldata _initData
  ) public returns (address _instance) {
    _instance = _factory.createHatsModule(_implementation, _hatId, _otherImmutableArgs, _initData);
  }

  /**
   * @notice Wrapper around a HatsModuleFactory. Deploys new HatsModule instances in batch.
   * Every module is created for a given `_hatId` to a deterministic address, if not already deployed.
   * Sets up each new instance with initial operational values.
   * @dev Will revert *after* an instance is deployed if its initial values are invalid.
   * @param _factory The HatsModuleFactory instance that will deploy the modules
   * @param _implementations The addresses of the implementation contracts of which to deploy a clone
   * @param _hatIds The hats for which to deploy a HatsModule.
   * @param _otherImmutableArgsArray Other immutable args to pass to the clones as immutable storage.
   * @param _initDataArray The encoded data to pass to the `setUp` functions of the new HatsModule instances. Leave
   * empty if no {setUp} is required.
   * @return success True if all modules were successfully created
   */
  function batchCreateHatsModule(
    HatsModuleFactory _factory,
    address[] calldata _implementations,
    uint256[] calldata _hatIds,
    bytes[] calldata _otherImmutableArgsArray,
    bytes[] calldata _initDataArray
  ) public returns (bool success) {
    success = _factory.batchCreateHatsModule(_implementations, _hatIds, _otherImmutableArgsArray, _initDataArray);
  }

  /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Checks if a hat is claimable on behalf of an account
   * @param _account The account to claim for
   * @param _hatId The hat to claim
   */
  function canClaimForAccount(address _account, uint256 _hatId) public view returns (bool) {
    return (hatIsClaimableFor(_hatId) && _isExplicitlyEligible(_hatId, _account));
  }

  /**
   * @notice Checks if an account can claim a hat.
   * @param _account The claiming account
   * @param _hatId The hat to claim
   */
  function accountCanClaim(address _account, uint256 _hatId) public view returns (bool) {
    return (hatIsClaimableBy(_hatId) && _isExplicitlyEligible(_hatId, _account));
  }

  /**
   * @notice Checks if a hat is claimable
   * @param _hatId The ID of the hat
   */
  function hatIsClaimableBy(uint256 _hatId) public view returns (bool) {
    return (hatExists(_hatId) && wearsAdmin(_hatId) && claimableHats[_hatId] != ClaimInfo.NotClaimable);
  }

  /**
   * @notice Checks if a hat is claimable on behalf of accounts
   * @param _hatId The ID of the hat
   */
  function hatIsClaimableFor(uint256 _hatId) public view returns (bool) {
    return (hatExists(_hatId) && wearsAdmin(_hatId) && claimableHats[_hatId] == ClaimInfo.ClaimableFor);
  }

  /**
   * @notice Check if this contract is an admin of a hat.
   *   @param _hatId The ID of the hat
   */
  function wearsAdmin(uint256 _hatId) public view returns (bool) {
    return HATS().isAdminOfHat(address(this), _hatId);
  }

  /// @notice Checks if a hat exists
  function hatExists(uint256 _hatId) public view returns (bool) {
    return HATS().getHatMaxSupply(_hatId) > 0;
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function _mint(uint256 _hatId, address _account) internal {
    // revert if _wearer is not explicitly eligible
    if (!_isExplicitlyEligible(_hatId, _account)) revert MultiClaimsHatter_NotExplicitlyEligible(_account, _hatId);
    // mint the hat to _wearer if eligible. This contract can mint as long as its the hat's admin.
    HATS().mintHat(_hatId, _account);
  }

  function _isExplicitlyEligible(uint256 _hatId, address _account) internal view returns (bool eligible) {
    // get the hat's eligibility module address
    address eligibility = HATS().getHatEligibilityModule(hatId());
    // get _wearer's eligibility status from the eligibility module
    bool standing;
    (bool success, bytes memory returndata) =
      eligibility.staticcall(abi.encodeWithSignature("getWearerStatus(address,uint256)", _account, _hatId));

    /* 
    * if function call succeeds with data of length == 64, then we know the contract exists 
    * and has the getWearerStatus function (which returns two words).
    * But — since function selectors don't include return types — we still can't assume that the return data is two
    booleans, 
    * so we treat it as a uint so it will always safely decode without throwing.
    */
    if (success && returndata.length == 64) {
      // check the returndata manually
      (uint256 firstWord, uint256 secondWord) = abi.decode(returndata, (uint256, uint256));
      // returndata is valid
      if (firstWord < 2 && secondWord < 2) {
        standing = (secondWord == 1) ? true : false;
        // never eligible if in bad standing
        eligible = (standing && firstWord == 1) ? true : false;
      }
      // returndata is invalid
      else {
        // false since _wearer is not explicitly eligible
        eligible = false;
      }
    } else {
      // false since _wearer is not explicitly eligible
      eligible = false;
    }
  }

  function _addOrRemoveHatsMemory(uint256[] memory _hatIds, ClaimInfo[] memory _claimInfo) internal {
    uint256 length = _hatIds.length;
    if (_claimInfo.length != length) {
      revert MultiClaimsHatter_ArrayLengthMismatch();
    }

    for (uint256 i; i < length;) {
      uint256 hatId = _hatIds[i];
      if (!HATS().isAdminOfHat(msg.sender, hatId)) revert MultiClaimsHatter_NotAdminOfHat(msg.sender, hatId);
      claimableHats[hatId] = _claimInfo[i];
      unchecked {
        ++i;
      }
    }

    emit HatsEdited(_hatIds, _claimInfo);
  }

  /*//////////////////////////////////////////////////////////////
                            MODIFIERS
  //////////////////////////////////////////////////////////////*/
}
