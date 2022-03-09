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

    enum Role {
        GOVERNMENT,
        ORGANIZATION,
        HEALTHPERSON,
        USER
    }

    struct Vaccine {
        string name;
        uint256 batch_no;
        uint256 vaccination_datetime;
        // uint256 serialNo;
    }

    struct BatchDetails {
        uint256 batch_id;
        uint256 defrost_date;
        uint256 manufacture_expiry;
        uint256 use_by_date;
        string ipfs_hash;
    }

    struct VaccineDetails {
        string name;
        // string platform;
        // string route;
        string ipfs_hash;
        uint256[] schedule;
        uint256[] batches;
        bool approved;
    }

    struct User {
        uint256 year_of_birth;
        Gender gender;
        string namehash;
        string imagehash;
        string vaccine_name;
        uint256[] batches;
        uint256[] datetime;
        uint256 vaccine_count;
        bool registered;
    }

    struct Organization {
        string name;
        string location;
        string ipfs_hash;
        address[] healthPersons;
        bool approved;
        bool registration;
        uint256 vaccined;
    }

    struct HealthPerson {
        address org;
        bool approved;
    }

    mapping (address => Role) public roles;

    mapping(string => VaccineDetails) public approvedVaccines;
    mapping(string => mapping(uint256 => BatchDetails)) public approvedBatches;
    mapping(string => mapping(uint256 => mapping(address => uint256)))
        public approvedOperators;

    string[] public approvedVaccineNames;

    mapping(address => User) public users;
    mapping(address => Organization) public organizations;
    mapping(address => HealthPerson) public healthPersons;

    address public superAdmin;

    address[] public organizationsList;

    // uint256 public registered;
    uint256 public partiallyVaccinated;
    uint256 public fullyVaccinated;

    //uint256 public total_vaccines;
    event ApproveVaccine(string indexed vaccine_name);
    event AddBatch(string indexed vaccine_name, uint256 indexed batch_no);
    event ApproveOrganization(string indexed org_name);
    event TransferVaccine(
        address indexed to,
        string indexed vaccine_name,
        uint256 batch_no
    );

    event RegisterOrganization(string indexed org_name);
    event ApproveHealthPerson(address indexed org, address indexed hp);

    event RegisterHealthPerson(address indexed _from);

    event RegisterIndividual(address indexed _from);

    constructor() {
        superAdmin = msg.sender;
        roles[msg.sender] = Role.GOVERNMENT;
    }

    function approveVaccine(string memory name, uint256[] memory schedule)
        public
        onlySuperAdmin
    {
        approvedVaccines[name].name = name;
        approvedVaccines[name].schedule = schedule;
        approvedVaccineNames.push(name);
        approvedVaccines[name].approved = true;
        emit ApproveVaccine(name);
    }

    function addBatch(
        string memory name,
        uint256 batch_id,
        uint256 defrost_date,
        uint256 manufacture_expiry,
        uint256 use_by_date,
        uint256 units
    ) public onlySuperAdmin {
        require(batch_id > 0, "Invalid batch");
        require(approvedVaccines[name].approved, "Vaccine is not approved.");

        //Check dates
        require(defrost_date < block.timestamp, "Must be previously defrosted");
        require(manufacture_expiry > block.timestamp, "Expired");
        require(
            use_by_date > block.timestamp,
            "Must be used prior to use by date."
        );

        approvedBatches[name][batch_id].batch_id = batch_id;
        approvedBatches[name][batch_id].defrost_date = defrost_date;
        approvedBatches[name][batch_id].manufacture_expiry = manufacture_expiry;
        approvedBatches[name][batch_id].use_by_date = use_by_date;
        approvedVaccines[name].batches.push(batch_id);
        approvedOperators[name][batch_id][msg.sender] = units;
        users[msg.sender].vaccine_count = units;
        emit AddBatch(name, batch_id);
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
        organizationsList.push(msg.sender);
        roles[msg.sender] = Role.ORGANIZATION;
        emit RegisterOrganization(name);
    }

    function approveOrganization(address org) public onlySuperAdmin {
        if (!organizations[org].registration) {
            revert("Organization must first register to approve.");
        }
        if (organizations[org].approved) {
            revert("Organization is already approved.");
        }
        organizations[org].approved = true;
    }

    function transfer(
        address to,
        string memory name,
        uint256 batch_id,
        uint256 units
    ) public onlySuperAdmin {
        checkOrganization(to);
        checkVaccine(name);
        checkBatch(name, batch_id);

        if (approvedOperators[name][batch_id][msg.sender] < units) {
            revert("Insufficient vaccines.");
        }
        approvedOperators[name][batch_id][msg.sender] -= units;
        approvedOperators[name][batch_id][to] += units;
        emit TransferVaccine(to, name, batch_id);
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
        roles[msg.sender] = Role.USER;
        emit RegisterIndividual(msg.sender);
    }

    function approveHealthPerson(address person) public onlyOrganization {
        healthPersons[person].org = msg.sender;
        healthPersons[person].approved = true;
        roles[person] = Role.HEALTHPERSON;
        organizations[msg.sender].healthPersons.push(person);
        emit ApproveHealthPerson(msg.sender, person);
    }

    function vaccinate(
        address to,
        string memory name,
        uint256 batch_id
    ) public onlyHealthPerson {
        checkUserRegistration(to);
        checkAvailability(name, batch_id, msg.sender);
        checkUserVaccineCompatibility(to, name);
        users[to].vaccine_name = name;
        users[to].batches.push(batch_id);
        users[to].datetime.push(block.timestamp);
        users[to].vaccine_count += 1;
        approvedOperators[name][batch_id][healthPersons[msg.sender].org] -= 1;
        changeStatus(to);
    }

    //Check Methods
    function checkUserRegistration(address user) private view {
        require(users[user].registered == true, "Unregistered user");
    }

    function checkBatch(string memory name, uint256 batch_id) public view {
        require(approvedBatches[name][batch_id].batch_id > 0, "Invalid batch");
        require(
            approvedBatches[name][batch_id].defrost_date < block.timestamp,
            "Must be previously defrosted"
        );
        require(
            approvedBatches[name][batch_id].manufacture_expiry >
                block.timestamp,
            "Expired"
        );
        require(
            approvedBatches[name][batch_id].use_by_date > block.timestamp,
            "Must be used prior to use by date."
        );
    }

    function checkOrganization(address org) public view {
        if (!organizations[org].registration) {
            revert("Invalid organization.");
        }
        if (!organizations[org].approved) {
            revert("Organization is not approved.");
        }
    }

    function checkVaccine(string memory name) public view {
        if (!approvedVaccines[name].approved) {
            revert("Vaccine not approved");
        }
    }

    function checkUserVaccineCompatibility(address user, string memory name)
        private
        view
    {
        require(
            approvedVaccines[name].approved == true,
            "Vaccine is not approved."
        );
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

    //Read Only Methods
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

    function getAllOrganizations() public view returns (address[] memory) {
        return organizationsList;
    }

    function getAllHealthPersons(address org)
        public
        view
        returns (address[] memory)
    {
        return organizations[org].healthPersons;
    }

    function getVaccineStatusOf(address user)
        public
        view
        returns (VaccineStatus status)
    {
        uint256 user_vaccineCount = users[user].vaccine_count;
        uint256 required_vaccineCount = approvedVaccines[
            users[user].vaccine_name
        ].schedule.length;

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

    function changeStatus(address user) private {
        VaccineStatus status = getVaccineStatusOf(user);
        if (status == VaccineStatus.FULLY_VACCINATED) {
            fullyVaccinated += 1;
        }
        if (status == VaccineStatus.PARTIALLY_VACCINATED) {
            partiallyVaccinated += 1;
        }
    }

    //Modifiers
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
        require(
            approvedVaccines[name].approved == true,
            "Vaccine not approved."
        );
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

    function now() public view returns (uint256) {
        return block.timestamp;
    }

    function getRole(address user) public returns (Role) {
        return roles[user];
    }
}
