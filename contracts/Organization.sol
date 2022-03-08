// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.5;

contract Organization {
  address public owner;

	string public name;
	string public symbol;
	string public ipfs_hash;

  uint256 currentClass;
  mapping(uint256 => uint256) public classIdToSupply;
  mapping(address => mapping(uint256 => uint256)) ownerToClassToBalance;
  mapping(uint256 => string) public classNames;

  // Constructor
  constructor(string memory _name, string memory _symbol, string memory _ipfs_hash) {
    owner = msg.sender;
		name = _name;
		symbol = _symbol;
		ipfs_hash = _ipfs_hash;
  }

}
