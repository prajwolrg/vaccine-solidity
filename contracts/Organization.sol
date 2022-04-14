// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma experimental ABIEncoderV2;

interface IOGovernment {
    function registerOrganization() external;

    function checkUserRegistration(address user) external view;

    function vaccinate( address to, address vaccine_address, string memory batch_id) external;
}

interface IOVaccine {
    function approve( address to, uint256 batchId, uint256 quantity) external;

    function transferFrom( address from, address to, uint256 batchId) external;

    function name() external view returns (string memory);

    function vaccinate(address to, string memory batchId) external;
}

interface IFOrganization {
    function name() external view returns(string memory);
    function url() external view returns(string memory);
    function logo_hash() external view returns(string memory);
    function document_hash() external view returns(string memory);
    function location() external view returns (string memory);
    function phone() external view returns (string memory);
    function email() external view returns(string memory);
}

contract Organization {
    IOGovernment gov;
    address public owner;
    uint256 public partially_vaccinated;
    uint256 public fully_vaccinated;

    string private name_;
    string private url_;
    string private logo_hash_;
    string private document_hash_;
    string private location_;
    string private phone_;
    string private email_;

    address[] public healthPersons;
    mapping(address => bool) public healthPersonApprovalStatus;

    address public superAdmin;

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
        string memory _url,
        string memory _logo_hash,
        string memory _document_hash,
        string memory _location,
        string memory _phone,
        string memory _email
    ) {
        superAdmin = tx.origin;

        name_ = _name;
        url_ = _url;
        logo_hash_ = _logo_hash;
        document_hash_ = _document_hash;
        location_ = _location;
        phone_ = _phone;
        email_ = _email;

        gov = IOGovernment(government);
        gov.registerOrganization();
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function url() public view returns (string memory) {
        return url_;
    }

    function logo_hash() public view returns (string memory) {
        return logo_hash_;
    }

    function document_hash() public view returns (string memory) {
        return document_hash_;
    }

    function location() public view returns (string memory) {
        return location_;
    }

    function phone() public view returns (string memory) {
        return phone_;
    }

    function email() public view returns (string memory) {
        return email_;
    }

    modifier onlySuperAdmin() {
        require(
            msg.sender == superAdmin,
            "Only admin can perform the function."
        );
        _;
    }

    function approveHealthPerson(address person) public onlySuperAdmin {
        healthPersons.push(person);
        healthPersonApprovalStatus[person] = true;
    }

    function disapproveHealthPerson(address person) public onlySuperAdmin{
        address[] memory hps = new address[](healthPersons.length - 1);

        uint256 j = 0;
        for (uint256 i = 0; i < healthPersons.length; i++) {
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

contract OrganizationFactory {
    Organization[] public orgs;
    address[] public orgAddresses;
    struct OrgDetails {
        string name;
        string url;
        string logo_hash;
        string document_hash;
        string location;
        string phone;
        string email;
    }
    mapping(address => uint256) orgIndex;

    function createOrganization(
        address gov,
        string memory name,
        string memory url,
        string memory logo_hash,
        string memory document_hash,
        string memory location,
        string memory phone,
        string memory email
    ) public {
        Organization org = new Organization(
            gov,
            name,
            url,
            logo_hash,
            document_hash,
            location,
            phone,
            email
        );
        orgs.push(org);
    }

    function getOrganizationAddresses() public view returns (Organization[] memory) {
        return orgs;
    }

    function getOrganizationDetails(address orgAddress)
        public
        view
        returns (OrgDetails memory)
    {
        IFOrganization org = IFOrganization(orgAddress);

        string memory name = org.name();
        string memory url = org.url();
        string memory logo_hash = org.logo_hash();
        string memory document_hash = org.document_hash();
        string memory location = org.location();
        string memory phone = org.phone();
        string memory email = org.email();
        return
            OrgDetails(
                name,
                url,
                logo_hash,
                document_hash,
                location,
                phone,
                email
            );
    }

    function getAllOrganizationsWithDetails() public view returns (OrgDetails[] memory) {
        OrgDetails[] memory organizations = new OrgDetails[](orgs.length);
        for (uint i=0; i<orgs.length; i++) {
            organizations[i] = getOrganizationDetails(address(orgs[i]));
        }
        return organizations;
    }

    function getSpeficiedOrganizationDetails(address[] memory orgAddrs) public view returns (OrgDetails[] memory) {
        OrgDetails[] memory organizations = new OrgDetails[](orgAddrs.length);
        for (uint i=0; i<orgs.length; i++) {
            organizations[i] = getOrganizationDetails(orgAddrs[i]);
        }
        return organizations;
    }
}
