// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.5;

interface Government {
	function registerOrganization(string memory _name, string memory _symbol, string memory _ipfs_hash) external;
	function checkUserRegistration(address user) external view;
  function vaccinate(address to, address vaccine_address, uint256 batch_id) external;
}

interface Vaccine {
  function approve(address to, uint256 batchId, uint256 quantity) external;
  function transferFrom(address from, address to, uint256 batchId) external;
  function name() external view returns(string memory);
}

contract Organization {
  Government gov;
  address public owner;
  uint256 public partially_vaccinated;
  uint256 public fully_vaccinated;

	string private name_;
	string private symbol_;
	string private ipfs_hash_;
  string public location_;

  address[] public healthPersons;
	mapping(address => bool) healthPersonApprovalStatus;


  event HealthPersonAdded(address indexed account);
  event Vaccinate(address indexed user, address indexed healthPerson);

  // Constructor
  constructor(address government, string memory _name, string memory _symbol, string memory _ipfs_hash) {
    gov = Government(government);
    gov.registerOrganization(_name, _symbol, _ipfs_hash);
    name_ = _name;
    symbol_ = _symbol;
    ipfs_hash_ = _ipfs_hash;
  }


	function name() public view returns(string memory){
		return name_;
	}

	function symbol() public view returns(string memory){
		return symbol_;
	}

	function ipfs_hash() public view returns(string memory){
		return ipfs_hash_;
	}

  function approveHealthPerson(address person) public {
    healthPersons.push(person);
  }

    function vaccinate(
        address to,
        address vaccine_address,
        uint256 batch_id
    ) public onlyHealthPerson {
        Vaccine vaccine = Vaccine(vaccine_address);
        vaccine.transferFrom(address(this), to, batch_id);
        partially_vaccinated+=1;
        fully_vaccinated+=1;
        gov.vaccinate(to, vaccine_address, batch_id);
        emit Vaccinate(to, msg.sender);
    }

    modifier onlyHealthPerson() {
        require(healthPersonApprovalStatus[msg.sender], "HealthPerson not approved.");
        _;
    }


}
