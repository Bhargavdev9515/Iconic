//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
contract uniChecker is EIP712 {

    string private constant SIGNING_DOMAIN = "Ikonic";
    string private constant SIGNATURE_VERSION = "1";

    struct Ikonic{
        address userAddress;
        address contractAddress;
        uint256 amount;
        uint256 saleType;
        uint256 timestamp;
        bytes signature;
    }
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){

    }

    function getSigner(Ikonic memory whitelist) public view returns(address){
        return _verify(whitelist);
    }

    /// @notice Returns a hash of the given whitelist, prepared using EIP712 typed data hashing rules.

    function _hash(Ikonic memory whitelist) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("Ikonic(address userAddress,address contractAddress,uint256 amount,uint256 saleType,uint256 timestamp)"),
                whitelist.userAddress,
                whitelist.contractAddress,
                whitelist.amount,
                whitelist.saleType,
                whitelist.timestamp
            )));
    }
    function _verify(Ikonic memory whitelist) internal view returns (address) {
        bytes32 digest = _hash(whitelist);
        return ECDSA.recover(digest, whitelist.signature);
    }

}
