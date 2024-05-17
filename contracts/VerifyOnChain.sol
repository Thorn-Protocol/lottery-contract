// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VerifyOnChain {
    using ECDSA for bytes32;

    function verify(
        address publicAddress,
        bytes32 dataHash,
        bytes memory signature
    ) public pure returns (bool) {
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
