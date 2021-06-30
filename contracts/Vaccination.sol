// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

uint256 constant REGISTRATION_COST = 10;

contract Vaccination {
    enum VaccineStatus {
        UNVACCINATED,
        PARTIALLY_VACCINATED,
        FULLY_VACCINATED
    }

    enum Gender {
        MALE,
        FEMALE,
        UNSPECIFIED
    }
    struct Vaccine {
        string name;
        uint256 batchNo;
        uint256 vaccination_datetime;
        // uint256 serialNo;
    }

    struct BatchDetails {
        uint256 batch_id;
        uint256 defrost_date;
        uint256 manufacture_expiry;
        uint256 use_by_date;
    }

    struct VaccineDetails {
        string name;
        // string platform;
        // string route;
        // string details;
        uint256[] schedule;
        uint256[] batches;
        bool approved;
    }

    struct User {
        // uint8 age;
        // Gender gender;
        string vaccine_name;
        uint256[] batches;
        uint256[] datetime;
        uint256 vaccine_count;
    }

    struct Organization {
        string name;
        string location;
        address[] healthPersons;
        bool approved;
        bool registration;
        uint256 vaccined;
    }

    struct HealthPerson {
        address org;
        bool approved;
    }

    mapping(string => VaccineDetails) public approvedVaccines;
    mapping(string => mapping(uint256 => BatchDetails)) public approvedBatches;
    mapping(string => mapping(uint256 => mapping(address => uint256)))
        public approvedOperators;

    string[] public approvedVaccineNames;

    mapping(address => User) public users;
    mapping(address => Organization) public organizations;
    mapping(address => HealthPerson) public healthPersons;

    mapping(address => bool) adminStatus;
    address[] public admins;

    address public superAdmin;

    address[] public organizationsList;

    // uint256 public registered;
    uint256 public partiallyVaccinated;
    uint256 public fullyVaccinated;

    //uint256 public total_vaccines;

    constructor() {
        superAdmin = msg.sender;
        adminStatus[superAdmin] = true;
    }

    function getApprovedVaccinesLength() public view returns (uint256) {
        return approvedVaccineNames.length;
    }

    function getVaccineApprovalStatus(string memory name)
        public
        view
        returns (bool)
    {
        return approvedVaccines[name].approved;
    }

    function approveVaccine(string memory name, uint256[] memory schedule)
        public
    {
        approvedVaccines[name].name = name;
        approvedVaccines[name].schedule = schedule;
        approvedVaccineNames.push(name);
        approvedVaccines[name].approved = true;
    }

    function addBatch(
        string memory name,
        uint256 batch_id,
        uint256 defrost_date,
        uint256 manufacture_expiry,
        uint256 use_by_date,
        uint256 units
    ) public {
        if (!approvedVaccines[name].approved) {
            revert("Vaccine is not yet approved.");
        }
        //Add checks for valid date
        approvedBatches[name][batch_id].batch_id = batch_id;
        approvedBatches[name][batch_id].defrost_date = defrost_date;
        approvedBatches[name][batch_id].manufacture_expiry = manufacture_expiry;
        approvedBatches[name][batch_id].use_by_date = use_by_date;
        approvedVaccines[name].batches.push(batch_id);
        approvedOperators[name][batch_id][msg.sender] = units;
        users[msg.sender].vaccine_count = units;
    }

    function transfer(
        address to,
        string memory name,
        uint256 batch_id,
        uint256 units
    ) public onlySuperAdmin {
        checkOrganization(to);
        checkVaccine(name);

        if (approvedOperators[name][batch_id][msg.sender] < units) {
            revert("Insufficient vaccines.");
        }
        approvedOperators[name][batch_id][msg.sender] -= units;
        approvedOperators[name][batch_id][to] += units;
    }

    function vaccinate(
        address to,
        string memory name,
        uint256 batch_id
    ) public onlyHealthPerson {
        checkAvailability(name, batch_id, msg.sender);
        checkUserVaccineCompatibility(to, name);
        users[to].vaccine_name = name;
        users[to].batches.push(batch_id);
        users[to].datetime.push(block.timestamp);
        users[to].vaccine_count += 1;
        approvedOperators[name][batch_id][healthPersons[msg.sender].org] -= 1;
        changeStatus(to);
    }

    function getUserVaccineCount(address user) public view returns (uint256) {
        uint256 count = users[user].vaccine_count;
        return count;
    }

    function getRequiredVaccineCount(string memory name)
        public
        view
        returns (uint256)
    {
        return approvedVaccines[name].schedule.length;
    }

    function getTotalOrganization() public view returns (uint256) {
        return organizationsList.length;
    }

    function getVaccineStatusOf(address user)
        public
        view
        returns (VaccineStatus status)
    {
        uint256 user_vaccineCount = users[user].vaccine_count;
        uint256 required_vaccineCount = approvedVaccines[
            users[user].vaccine_name
        ]
        .schedule
        .length;

        if (user_vaccineCount == 0) {
            return VaccineStatus.UNVACCINATED;
        }
        if (user_vaccineCount < required_vaccineCount) {
            return VaccineStatus.PARTIALLY_VACCINATED;
        }
        if (user_vaccineCount == required_vaccineCount) {
            return VaccineStatus.FULLY_VACCINATED;
        }
    }

    function checkVaccine(string memory name) private view {
        if (!approvedVaccines[name].approved) {
            revert("Vaccine is not approved.");
        }
    }

    function checkBatch(string memory name, uint256 batch_id) public view {
        require(approvedBatches[name][batch_id].batch_id > 0, "Invalid batch");
        // require(
        //     approvedBatches[name][batch_id].defrost_date < block.timestamp,
        //     "Must be previously defrosted"
        // );
        // require(
        //     approvedBatches[name][batch_id].manufacture_expiry >
        //         block.timestamp,
        //     "Expired"
        // );
        // require(
        //     approvedBatches[name][batch_id].use_by_date > block.timestamp,
        //     "Must be previously used."
        // );
    }

    function checkOrganization(address org) public view {
        if (!organizations[org].registration) {
            revert("Invalid organization.");
        }
        if (!organizations[org].approved) {
            revert("Organization is not approved.");
        }
    }

    function checkUserVaccineCompatibility(address user, string memory name)
        private
        view
    {
        checkVaccine(name);
        bytes memory _user_recieved_vaccine = bytes(users[user].vaccine_name);
        bytes memory _user_recieving_vaccine = bytes(name);

        if (_user_recieved_vaccine.length > 0) {
            if (
                _user_recieved_vaccine.length != _user_recieving_vaccine.length
            ) {
                revert("Vaccine not compatible.");
            }
            for (uint256 i = 0; i < _user_recieved_vaccine.length; i++) {
                if (_user_recieved_vaccine[i] != _user_recieving_vaccine[i]) {
                    revert("Vaccine not compatible.");
                }
            }
        }
        uint256 user_vaccineCount = getUserVaccineCount(user);
        uint256 required_vaccineCount = getRequiredVaccineCount(name);

        if (user_vaccineCount == required_vaccineCount) {
            revert("Fully vaccinated already.");
        }
    }

    function changeStatus(address user) private {
        VaccineStatus status = getVaccineStatusOf(user);
        if (status == VaccineStatus.FULLY_VACCINATED) {
            fullyVaccinated += 1;
        }
        if (status == VaccineStatus.PARTIALLY_VACCINATED) {
            partiallyVaccinated += 1;
        }
    }

    function registerOrganization(string memory name, string memory location)
        public
        payable
    {
        if (msg.value < REGISTRATION_COST) {
            revert("Insufficient amount.");
        }
        organizations[msg.sender].name = name;
        organizations[msg.sender].location = location;
        organizations[msg.sender].registration = true;
    }

    function approveOrganization(address org) public onlySuperAdmin {
        if (!organizations[org].registration) {
            revert("Organization must first register to approve.");
        }
        if (organizations[org].approved) {
            revert("Organization is already approved.");
        }
        organizations[org].approved = true;
        organizationsList.push(org);
    }

    function approveHealthPerson(address person) public onlyOrganization {
        if (healthPersons[person].org != msg.sender) {
            revert("Healthperson do not belong to the organization.");
        }
        healthPersons[person].approved = true;
        organizations[msg.sender].healthPersons.push(person);
    }

    function registerAsHealthPerson(address org) public payable {
        if (msg.value < REGISTRATION_COST) {
            revert("Insufficient amount.");
        }
        healthPersons[msg.sender].org = org;
        healthPersons[msg.sender].approved = false;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "superAdmin");
        _;
    }
    modifier onlyOrganization() {
        require(organizations[msg.sender].approved, "Organization");
        _;
    }
    modifier onlyHealthPerson() {
        require(healthPersons[msg.sender].approved, "HealthPerson");
        _;
    }

    function getHealthPersonOrganization(address healthPerson)
        public
        view
        returns (address)
    {
        return (healthPersons[healthPerson].org);
    }

    function checkAvailability(
        string memory name,
        uint256 batch_id,
        address healthPerson
    ) public view {
        checkVaccine(name);
        checkBatch(name, batch_id);
        require(
            approvedOperators[name][batch_id][healthPersons[healthPerson].org] >
                0,
            "Insufficient vaccine..."
        );
    }

    function getAvailableVaccines(
        string memory name,
        uint256 batch,
        address org
    ) public view returns (uint256) {
        return approvedOperators[name][batch][org];
    }
}
