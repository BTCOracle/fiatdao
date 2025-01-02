// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC1155} from "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ERC1155, ERC1155Supply} from "openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721Receiver} from "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC165} from "openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "../interfaces/ICodex.sol";
import {ICollybus} from "../interfaces/ICollybus.sol";
import {IVault} from "../interfaces/IVault.sol";
import {Guarded} from "../core/utils/Guarded.sol";
import {WAD, toInt256, add, sub, wmul, wdiv, mul, div} from "../core/utils/Math.sol";

interface ISmartYield {
    struct SeniorBond {
        uint256 principal;
        uint256 gain;
        uint256 issuedAt;
        uint256 maturesAt;
        bool liquidated;
    }

    function controller() external view returns (address);

    function pool() external view returns (address);

    function seniorBond() external view returns (address);

    function seniorBonds(uint256 bondId_) external view returns (SeniorBond memory);

    function seniorBondId() external view returns (uint256);

    function bondGain(uint256 principalAmount_, uint16 forDays_) external returns (uint256);

    function buyBond(
        uint256 principalAmount_,
        uint256 minGain_,
        uint256 deadline_,
        uint16 forDays_
    ) external returns (uint256);

    function redeemBond(uint256 bondId_) external;
}

interface ISmartYieldController {
    function EXP_SCALE() external view returns (uint256);

    function FEE_REDEEM_SENIOR_BOND() external view returns (uint256);

    function underlyingDecimals() external view returns (uint256);
}

interface ISmartYieldProvider {
    function uToken() external view returns (address);
}

/// @title VaultSY (BarnBridge Smart Yield Senior Bond Vault)
/// @notice Collateral adapter for BarnBridge Smart Yield senior bonds
/// @dev To be instantiated by Smart Yield market
contract VaultSY is Guarded, IVault, ERC165, ERC1155Supply, ERC721Holder {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error VaultSY__setParam_notLive();
    error VaultSY__setParam_unrecognizedParam();
    error VaultSY__enter_notLive();
    error VaultSY__enter_overflow();
    error VaultSY__exit_overflow();
    error VaultSY__wrap_maturedBond();
    error VaultSY__unwrap_bondNotMatured();
    error VaultSY__unwrap_notOwnerOfBond();
    error VaultSY__updateBond_redeemedBond();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Price Feed
    ICollybus public override collybus;

    // Bond Cache
    struct Bond {
        uint256 principal; // Cached value of (principal + gain) of the bond [underlierScale]
        uint256 conversion; // Cached value of principal / totalSupply(bondId) [wad]
        uint128 maturity; // Cached maturity of bond [seconds]
        uint64 owned; // True if the bond is owned by this contract [0, 1]
        uint64 redeemed; // True after when updateBond is initially called after maturity [0, 1]
    }

    /// @notice Keeps track of deposited bonds because `ownerOf` reverts after bond is burned during redemption
    /// BondId => Bond
    mapping(uint256 => Bond) public bonds;

    /// @notice Smart Yield Market (e.g. SY Compound USDC)
    ISmartYield public immutable market;
    /// @notice Smart Yield Senior Bond ERC721 token
    IERC721 public immutable seniorBond;

    /// @notice Maximum amount of principal that can remain after a user redeems a partial amount
    /// of tokens [underlierScale]
    uint256 public principalFloor;

    /// @notice Collateral token
    address public immutable override token;
    /// @notice Scale of collateral token
    uint256 public immutable override tokenScale; // == WAD for this implementation
    /// @notice Underlier of collateral token (corresponds to a SY market)
    address public immutable override underlierToken;
    /// @notice Scale of underlier of collateral token
    uint256 public immutable override underlierScale;

