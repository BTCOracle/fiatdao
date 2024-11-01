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
