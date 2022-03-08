// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Vaccine {
  using SafeMath for uint256;

  string public name;
  string public symbol;
  address public Owner;

  struct Batch {
    string batch_name;
    uint256 defrost_date;
    uint256 manufacture_expiry;
    uint256 use_by_date;
    uint256 units;
    string ipfs_hash;
  }

  uint256 public vaccineCount;
  uint256 currentClass;
  struct Transactor {
    address actor;
    uint256 amount;
  }

  mapping(uint256 => uint256) public batchIdToSupply;
  mapping(address => mapping(uint256 => uint256)) ownerToClassToBalance;
  mapping(address => mapping(uint256 => Transactor)) approvals;
  mapping(uint256 => Batch) public batches;

  event Transfer(address indexed from, address indexed to, uint256 indexed batchId, uint256 units);
  event Approval(address indexed from, address indexed to, uint256 indexed batchId, uint256 units);

  // Constructor
  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
    Owner = msg.sender;
  }

  function totalSupply() public view returns (uint256) {
    return vaccineCount;
  }

  function individualSupply(uint256 batchId) public view returns (uint256) {
    return batchIdToSupply[batchId];
  }

  function balanceOf(address owner, uint256 batchId) public view returns (uint256) {
    /* if (ownerToClassToBalance[owner] == 0) return 0; */
    return ownerToClassToBalance[owner][batchId];
  }

  // class of 0 is meaningless and should be ignored.
  function batchesOwned(address owner) public view returns (uint256[] memory){
    uint256[] memory tempBatches = new uint256[](currentClass - 1);
    uint256 count = 0;
    for (uint256 i = 1; i < currentClass; i++){
      if (ownerToClassToBalance[owner][i] != 0){
        if (ownerToClassToBalance[owner][i] != 0){
          tempBatches[count] = i;
        }
        count += 1;
      }
    }
    uint256[] memory batches_ = new uint256[](count);
    for (uint i = 0; i < count; i++){
      batches_[i] = tempBatches[i];
    }
    return batches_;
  }

  function transfer(address to, uint256 batchId, uint256 quantity) public {
    require(ownerToClassToBalance[msg.sender][batchId] >= quantity);
    ownerToClassToBalance[msg.sender][batchId] -= quantity;
    ownerToClassToBalance[to][batchId] += quantity;
    Transactor memory zeroApproval;
    zeroApproval = Transactor(address(0), 0);
    approvals[msg.sender][batchId] = zeroApproval;
  }

  function approve(address to, uint256 batchId, uint256 quantity) public {
    require(ownerToClassToBalance[msg.sender][batchId] >= quantity);
    Transactor memory takerApproval;
    takerApproval = Transactor(to, quantity);
    approvals[msg.sender][batchId] = takerApproval;
    emit Approval(msg.sender, to, batchId, quantity);
  }

  function transferFrom(address from, address to, uint256 batchId) public {
    Transactor storage takerApproval = approvals[from][batchId];
    uint256 quantity = takerApproval.amount;
    require(takerApproval.actor == to && quantity >= ownerToClassToBalance[from][batchId]);
    ownerToClassToBalance[from][batchId] -= quantity;
    ownerToClassToBalance[to][batchId] += quantity;
    Transactor memory zeroApproval;
    zeroApproval = Transactor(address(0), 0);
    approvals[from][batchId] = zeroApproval;
  }

  function addBatch(uint256 batchId, string memory batch_name, uint256 defrost_date, uint256 manufacture_expiry, uint256 use_by_date, uint256 units) public {
    require(msg.sender == Owner, "Only Pharmacy can add the batch.");
    require(defrost_date < block.timestamp, "Must be previously defrosted");
    require(manufacture_expiry > block.timestamp, "Expired");
    require(
        use_by_date > block.timestamp,
        "Must be used prior to use by date."
    );

    batches[batchId].batch_name = batch_name;
    batches[batchId].defrost_date = defrost_date;
    batches[batchId].manufacture_expiry = manufacture_expiry;
    batches[batchId].use_by_date = use_by_date;
    batches[batchId].units = units;

    vaccineCount += units;
  }

}

