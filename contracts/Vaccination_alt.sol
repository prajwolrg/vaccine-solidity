// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

uint256 constant REGISTRATION_COST = 10;

contract Vaccination {
    // uint256 public registered;
    uint256 public partiallyVaccinated;
    uint256 public fullyVaccinated;

    event Vaccinate(address indexed user, address indexed vaccine, string indexed batch);

    constructor() {
        superAdmin = msg.sender;
    }

    //Check Methods
    function checkUserRegistration(address user) private view {
        require(users[user].registered == true, "Unregistered user");
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

}
