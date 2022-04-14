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
  string public ipfs_hash;

  address public Owner;

  uint256[] private schedule;

  struct Batch {
    uint256 defrost_date;
    uint256 manufacture_expiry;
    uint256 use_by_date;
    uint256 units;
    string ipfs_hash;
  }

  uint256 public vaccineCount;
  uint256 currentBatch;
  struct Transactor {
    address actor;
    uint256 amount;
  }

  struct OwnerBatch {
    string batchId;
    uint256 units;
  }

  mapping (address => mapping(address => bool)) fullApprovals;

  mapping(string => uint256) public batchIdToSupply;
  mapping(address => mapping(string => uint256)) public ownerToBatchToBalance;
  mapping(address => mapping(string => Transactor)) approvals;
  mapping(string => Batch) public batchDetails;

  string[] batches;

  event Transfer(address indexed from, address indexed to, uint256 indexed batchId, uint256 units);
  event Approval(address indexed from, address indexed to, string indexed batchId, uint256 units);
  event NewBatch(string indexed batch_name);
  event Vaccined(address indexed to, string indexed batchId);

  // Constructor
  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
    Owner = msg.sender;
  }

  function totalSupply() public view returns (uint256) {
    return vaccineCount;
  }

  function individualSupply(string memory batchId) public view returns (uint256) {
    return batchIdToSupply[batchId];
  }

  function balanceOf(address owner, string memory batchId) public view returns (uint256) {
    /* if (ownerToBatchToBalance[owner] == 0) return 0; */
    return ownerToBatchToBalance[owner][batchId];
  }

  // class of 0 is meaningless and should be ignored.
  function batchesOwned(address owner) public view returns (OwnerBatch[] memory){
    string[] memory tempBatches = new string[](batches.length);
    uint256 count = 0;
    for (uint256 i = 0; i < batches.length; i++){
      if (ownerToBatchToBalance[owner][batches[i]] != 0){
        tempBatches[count] = batches[i];
        count += 1;
      }
    }
    OwnerBatch[] memory batches_ = new OwnerBatch[](count);
    for (uint i = 0; i < count; i++){
      batches_[i].batchId = tempBatches[i];
      batches_[i].units = ownerToBatchToBalance[owner][tempBatches[i]];
    }
    return batches_;
  }

  function transfer(address to, string memory batchId, uint256 quantity) public {
    require(ownerToBatchToBalance[msg.sender][batchId] >= quantity, "Owner do not hold vaccine");
    ownerToBatchToBalance[msg.sender][batchId] -= quantity;
    ownerToBatchToBalance[to][batchId] += quantity;
    Transactor memory zeroApproval;
    zeroApproval = Transactor(address(0), 0);
    approvals[msg.sender][batchId] = zeroApproval;
  }

  function approve(address to, string memory batchId, uint256 quantity) public {
    require(ownerToBatchToBalance[msg.sender][batchId] >= quantity);
    Transactor memory takerApproval;
    takerApproval = Transactor(to, quantity);
    approvals[msg.sender][batchId] = takerApproval;
    emit Approval(msg.sender, to, batchId, quantity);
  }

  function approveAll(address to) public {
    fullApprovals[msg.sender][to] = true;
  }

  function vaccinate(address to, string memory batchId) public {
    require(ownerToBatchToBalance[msg.sender][batchId]>0, "Not enough vaccine");
    ownerToBatchToBalance[msg.sender][batchId] -= 1;
    ownerToBatchToBalance[to][batchId] += 1;
    emit Vaccined(to, batchId);
  }

  function transferFrom(address from, address to, string memory batchId) public {
    Transactor storage takerApproval = approvals[from][batchId];
    uint256 quantity = takerApproval.amount;
    require(takerApproval.actor == to && quantity >= ownerToBatchToBalance[from][batchId]);
    ownerToBatchToBalance[from][batchId] -= quantity;
    ownerToBatchToBalance[to][batchId] += quantity;
    Transactor memory zeroApproval;
    zeroApproval = Transactor(address(0), 0);
    approvals[from][batchId] = zeroApproval;
  }

  function addBatch(string memory batchId, uint256 defrost_date, uint256 manufacture_expiry, uint256 use_by_date, uint256 units) public {
    require(msg.sender == Owner, "Only Pharmacy can add the batch.");
    require(defrost_date < block.timestamp, "Must be previously defrosted");
    require(manufacture_expiry > block.timestamp, "Expired");
    require(
        use_by_date > block.timestamp,
        "Must be used prior to use by date."
    );

    batchDetails[batchId].defrost_date = defrost_date;
    batchDetails[batchId].manufacture_expiry = manufacture_expiry;
    batchDetails[batchId].use_by_date = use_by_date;
    batchDetails[batchId].units = units;
    ownerToBatchToBalance[msg.sender][batchId] = units;

    vaccineCount += units;
    currentBatch += 1;
    batches.push(batchId);
    emit NewBatch(batchId);
  }

  function getVaccineSchedule() public view returns(uint256[] memory){
    return schedule;
  }

  function getVaccineScheduleLength() public view returns(uint256){
    return schedule.length;
  }

}

contract VaccineFactory{
    Vaccine[] public vaccines;

    function createOrganization(string memory name, string memory symbol) public {
        Vaccine v = new Vaccine(name, symbol);
        vaccines.push(v);
    }
}