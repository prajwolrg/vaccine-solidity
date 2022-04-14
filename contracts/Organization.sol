// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma experimental ABIEncoderV2;

interface IOGovernment {
    function registerOrganization(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_hash
    ) external;

    function checkUserRegistration(address user) external view;

    function vaccinate(
        address to,
        address vaccine_address,
        string memory batch_id
    ) external;
}

interface IOVaccine {
    function approve(
        address to,
        uint256 batchId,
        uint256 quantity
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 batchId
    ) external;

    function name() external view returns (string memory);

    function vaccinate(address to, string memory batchId) external;
}

contract Organization {
    IOGovernment gov;
    address public owner;
    uint256 public partially_vaccinated;
    uint256 public fully_vaccinated;

    string private name_;
    string private symbol_;
    string private ipfs_hash_;
    string public location_;

    address[] public healthPersons;
    mapping(address => bool) public healthPersonApprovalStatus;

    address superAdmin;

    event HealthPersonAdded(address indexed account);
    event Vaccined(
        address indexed user,
        address indexed healthPerson,
        address indexed vaccine
    );

    // Constructor
    constructor(
        address government,
        string memory _name,
        string memory _symbol,
        string memory _ipfs_hash
    ) {
        superAdmin = msg.sender;
        gov = IOGovernment(government);
        gov.registerOrganization(_name, _symbol, _ipfs_hash);
        name_ = _name;
        symbol_ = _symbol;
        ipfs_hash_ = _ipfs_hash;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function ipfs_hash() public view returns (string memory) {
        return ipfs_hash_;
    }

    function approveHealthPerson(address person) public {
        healthPersons.push(person);
        healthPersonApprovalStatus[person] = true;
    }

    function disapproveHealthPerson(address person) public {
      address[] memory hps = new address[](healthPersons.length - 1);

			uint j = 0;
      for (uint i = 0; i < healthPersons.length; i++) {
          if (healthPersons[i] == person) {
            healthPersonApprovalStatus[person] = false;
          } else {
            hps[j] = healthPersons[i];
            j++;
          }
      }
      healthPersons = hps;
    }

    function vaccinate(
        address to,
        address vaccine_address,
        string memory batch_id
    ) public onlyHealthPerson {
        IOVaccine vaccine = IOVaccine(vaccine_address);
        partially_vaccinated += 1;
        fully_vaccinated += 1;
        gov.vaccinate(to, vaccine_address, batch_id);
        vaccine.vaccinate(to, batch_id);
        emit Vaccined(to, msg.sender, vaccine_address);
    }

    modifier onlyHealthPerson() {
        require(
            healthPersonApprovalStatus[msg.sender],
            "HealthPerson not approved."
        );
        _;
    }

    function getApprovedHealthPersons() public view returns (address[] memory) {
        address[] memory hps = new address[](healthPersons.length);
        uint256 i = 0;
        uint256 j = 0;
        for (i = 0; i < healthPersons.length; i++) {
            if (healthPersonApprovalStatus[healthPersons[i]]) {
                hps[j] = (healthPersons[i]);
                j++;
            }
        }
        return hps;
    }
}
