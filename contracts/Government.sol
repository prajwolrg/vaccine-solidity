// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma experimental ABIEncoderV2;

uint256 constant ORG_REGISTRATION_COST = 10;

struct OrgDetails {
    string name;
    string url;
    string logo_hash;
    string document_hash;
    string location;
    string phone;
    string email;
}

interface IGOrganization {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function ipfs_hash() external view returns (string memory);
}

interface IGVaccine {
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

    function getVaccineSchedule() external view returns (uint256[] memory);

    function getVaccineScheduleLength() external view returns (uint256);
}

interface IGOrganizationFactory {
    function getSpeficiedOrganizationDetails(address[] memory orgAddrs)
        external
        view
        returns (OrgDetails[] memory);
}

contract Government {
    address public owner;

    string private name_;
    string private symbol_;
    string private ipfs_hash_;

    uint256 fully_vaccinated;
    uint256 partially_vaccinated;

    mapping(address => bool) public vaccineApprovalStatus;
    mapping(address => bool) public organizationApprovalStatus;

    mapping(string => bool) org_names;
    mapping(string => bool) org_symbols;
    mapping(string => bool) org_ipfs_hash;

    address[] registeredOrganizations;
    address[] approvedOrganizations;
    address[] rejectedOrganizations;

    enum Gender {
        MALE,
        FEMALE,
        UNSPECIFIED
    }

    enum VaccineStatus {
        UNVACCINATED,
        PARTIALLY_VACCINATED,
        FULLY_VACCINATED
    }

    struct Vaccine {
        address vaccine_address;
        // string vaccine_name;
        string batch;
        uint256 datetime;
    }

    struct User {
        uint256 year_of_birth;
        Gender gender;
        string namehash;
        string imagehash;
        Vaccine[] vaccines;
        bool registered;
    }
    mapping(address => User) public users;

    event OrganizationApproval(address indexed org);
    event OrganizationRegistration(address indexed org);
    event VaccineApproved(address indexed vaccine);
    event RegisterIndividual(address indexed user);
    event Vaccinate(
        address indexed user,
        address indexed vaccine_address,
        string indexed batch_id
    );

    address public superAdmin;
		address public vaccineFactoryAddress;
		address public orgFactoryAddress;

    // Constructor
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_hash,
				address vFactory,
				address oFactory
    ) {
        owner = msg.sender;
        name_ = _name;
        symbol_ = _symbol;
        ipfs_hash_ = _ipfs_hash;
				orgFactoryAddress = oFactory;
				vaccineFactoryAddress = vFactory;
        superAdmin = msg.sender;
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

    function getUser(address user_address) public view returns (User memory) {
        return users[user_address];
    }

    function approveVaccine(address vaccine) public {
        vaccineApprovalStatus[vaccine] = true;
        emit VaccineApproved(vaccine);
    }

    function registerIndividual(
        uint256 year_of_birth,
        Gender gender,
        string memory namehash,
        string memory imagehash
    ) public {
        require(users[msg.sender].registered == false, "Already registered.");
        users[msg.sender].year_of_birth = year_of_birth;
        users[msg.sender].gender = gender;
        users[msg.sender].namehash = namehash;
        users[msg.sender].imagehash = imagehash;
        users[msg.sender].registered = true;
        emit RegisterIndividual(msg.sender);
    }

    function registerOrganization() public {
        // if (msg.value < ORG_REGISTRATION_COST) {
        // 		revert("Insufficient amount.");
        // }
        // require(!org_ipfs_hash[_ipfs_hash], "Organization already registered.");
        // require(!org_names[_name], "Organization name already taken.");
        // require(!org_symbols[_symbol], "Organization symbol already taken.");
        // org_ipfs_hash[_ipfs_hash] = true;
        // org_names[_name] = true;
        // org_symbols[_symbol] = true;
        registeredOrganizations.push(msg.sender);
        emit OrganizationRegistration(msg.sender);
    }

    function approveOrganization(address org_address) public onlySuperAdmin {
        // IGOrganization org = IGOrganization(org_address);
        // require(org_ipfs_hash[org.ipfs_hash()], "Organization not registered.");
        // require(org_names[org.name()], "Organization not registered.");
        // require(org_symbols[org.symbol()], "Organization not registered.");
        organizationApprovalStatus[org_address] = true;
        // emit OrganizationApproval(org_address, org.name(), org.symbol());
    }

    function vaccinate(
        address to,
        address vaccine_address,
        string memory batch_id
    ) public onlyApprovedOrganization {
        checkUserRegistration(to);
        users[to].vaccines.push(
            Vaccine(vaccine_address, batch_id, block.timestamp)
        );
        // users[to].vaccine_address = vaccine_address;
        // users[to].batches.push(batch_id);
        // users[to].datetime.push(block.timestamp);
        // users[to].vaccine_count += 1;
        // changeStatus(to);
        emit Vaccinate(to, vaccine_address, batch_id);
    }

    modifier onlyApprovedOrganization() {
        require(
            organizationApprovalStatus[msg.sender],
            "Only approved organization can vaccinate."
        );
        _;
    }

    function checkUserRegistration(address user) private view {
        require(users[user].registered == true, "Unregistered user");
    }

    function getRequiredVaccineCount(address vaccine_address)
        public
        view
        returns (uint256)
    {
        IGVaccine vaccine = IGVaccine(vaccine_address);
        return vaccine.getVaccineScheduleLength();
    }

    // function changeStatus(address user) private {
    //     VaccineStatus status = getVaccineStatusOf(user);
    //     if (status == VaccineStatus.FULLY_VACCINATED) {
    //       fully_vaccinated += 1;
    //     }
    //     if (status == VaccineStatus.PARTIALLY_VACCINATED) {
    //       	partially_vaccinated += 1;
    //     }
    // }

    // function getVaccineStatusOf(address user)
    //     public
    //     view
    //     returns (VaccineStatus status)
    // {
    //     uint256 user_vaccineCount = users[user].vaccine_count;
    //     uint256 required_vaccineCount = getRequiredVaccineCount(users[user].vaccine_address);

    //     if (user_vaccineCount == 0) {
    //         return VaccineStatus.UNVACCINATED;
    //     }
    //     if (user_vaccineCount < required_vaccineCount) {
    //         return VaccineStatus.PARTIALLY_VACCINATED;
    //     }
    //     if (user_vaccineCount == required_vaccineCount) {
    //         return VaccineStatus.FULLY_VACCINATED;
    //     }
    // }

    modifier onlySuperAdmin() {
        require(
            msg.sender == superAdmin,
            "Only admin can perform the function."
        );
        _;
    }

    function getApprovedOrganizations()
        public
        view
        returns (OrgDetails[] memory)
    {
			IGOrganizationFactory oFactory = IGOrganizationFactory(orgFactoryAddress);
			return oFactory.getSpeficiedOrganizationDetails(approvedOrganizations);
		}

    function getRegisteredOrganizations()
        public
        view
        returns (OrgDetails[] memory)
    {
			IGOrganizationFactory oFactory = IGOrganizationFactory(orgFactoryAddress);
			return oFactory.getSpeficiedOrganizationDetails(registeredOrganizations);
		}
}
 