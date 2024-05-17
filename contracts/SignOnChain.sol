// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureRSV, EthereumUtils} from "@oasisprotocol/sapphire-contracts/contracts/EthereumUtils.sol";
import {Sapphire} from "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

contract SignOnChain {
    using ECDSA for bytes32;

    address public publicAddress;
    bytes32 public privateSecret;

    constructor() {
        address keypairAddress;
        bytes32 keypairSecret;
        (keypairAddress, keypairSecret) = EthereumUtils.generateKeypair();
        publicAddress = keypairAddress;
        privateSecret = keypairSecret;
    }

    function sign(
        bytes32 messageHash
    ) public view returns (SignatureRSV memory) {
        return EthereumUtils.sign(publicAddress, privateSecret, messageHash);
    }

    function verify(
        bytes32 dataHash,
        bytes memory signature
    ) public view returns (bool) {
        address recovered = (dataHash.toEthSignedMessageHash()).recover(
            signature
        );
        if (publicAddress == recovered) {
            return true;
        }
        recovered = dataHash.recover(signature);
        if (publicAddress == recovered) {
            return true;
        }
        return false;
    }
}
