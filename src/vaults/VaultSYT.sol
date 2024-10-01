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
