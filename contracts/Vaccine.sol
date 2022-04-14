// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
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

interface IFVaccine {
    function name() external view returns (string memory);

    function schedule() external view returns (uint256[] memory);

    function platform() external view returns (string memory);

    function route() external view returns (string memory);

    function developers() external view returns (string memory);

    function ipfs_hash() external view returns (string memory);
}

contract Vaccine {
    using SafeMath for uint256;

    string private name_;
    uint256[] private schedule_;
    string private platform_;
    string private developers_;
    string private route_;
    string private ipfs_hash_;

    address public superAdmin;

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

    mapping(address => mapping(address => bool)) fullApprovals;

    mapping(string => uint256) public batchIdToSupply;
    mapping(address => mapping(string => uint256)) public ownerToBatchToBalance;
    mapping(address => mapping(string => Transactor)) approvals;
    mapping(string => Batch) public batchDetails;

    string[] batches;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed batchId,
        uint256 units
    );
    event Approval(
        address indexed from,
        address indexed to,
        string indexed batchId,
        uint256 units
    );
    event NewBatch(string indexed batch_name);
    event Vaccined(address indexed to, string indexed batchId);

    // Constructor
    constructor(
        string memory _name,
        uint256[] memory _schedule,
        string memory _platform,
        string memory _route,
        string memory _ipfs_hash
    ) {
        name_ = _name;
        schedule_ = _schedule;
        platform_ = _platform;
        route_ = _route;
        ipfs_hash_ = _ipfs_hash;
        superAdmin = tx.origin;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function schedule() public view returns(uint256[] memory) {
      return schedule_;
    }

    function platform() public view returns (string memory) {
        return platform_;
    }

    function developers() public view returns (string memory) {
        return developers_;
    }

    function route() public view returns (string memory) {
        return route_;
    }

    function ipfs_hash() public view returns (string memory) {
        return ipfs_hash_;
    }

    function totalSupply() public view returns (uint256) {
        return vaccineCount;
    }

    function individualSupply(string memory batchId)
        public
        view
        returns (uint256)
    {
        return batchIdToSupply[batchId];
    }

    function balanceOf(address owner, string memory batchId)
        public
        view
        returns (uint256)
    {
        /* if (ownerToBatchToBalance[owner] == 0) return 0; */
        return ownerToBatchToBalance[owner][batchId];
    }

    // class of 0 is meaningless and should be ignored.
    function batchesOwned(address owner)
        public
        view
        returns (OwnerBatch[] memory)
    {
        string[] memory tempBatches = new string[](batches.length);
        uint256 count = 0;
        for (uint256 i = 0; i < batches.length; i++) {
            if (ownerToBatchToBalance[owner][batches[i]] != 0) {
                tempBatches[count] = batches[i];
                count += 1;
            }
        }
        OwnerBatch[] memory batches_ = new OwnerBatch[](count);
        for (uint256 i = 0; i < count; i++) {
            batches_[i].batchId = tempBatches[i];
            batches_[i].units = ownerToBatchToBalance[owner][tempBatches[i]];
        }
        return batches_;
    }

    function transfer(
        address to,
        string memory batchId,
        uint256 quantity
    ) public {
        require(
            ownerToBatchToBalance[msg.sender][batchId] >= quantity,
            "Owner do not hold vaccine"
        );
        ownerToBatchToBalance[msg.sender][batchId] -= quantity;
        ownerToBatchToBalance[to][batchId] += quantity;
        Transactor memory zeroApproval;
        zeroApproval = Transactor(address(0), 0);
        approvals[msg.sender][batchId] = zeroApproval;
    }

    function approve(
        address to,
        string memory batchId,
        uint256 quantity
    ) public {
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
        require(
            ownerToBatchToBalance[msg.sender][batchId] > 0,
            "Not enough vaccine"
        );
        ownerToBatchToBalance[msg.sender][batchId] -= 1;
        ownerToBatchToBalance[to][batchId] += 1;
        emit Vaccined(to, batchId);
    }

    function transferFrom(
        address from,
        address to,
        string memory batchId
    ) public {
        Transactor storage takerApproval = approvals[from][batchId];
        uint256 quantity = takerApproval.amount;
        require(
            takerApproval.actor == to &&
                quantity >= ownerToBatchToBalance[from][batchId]
        );
        ownerToBatchToBalance[from][batchId] -= quantity;
        ownerToBatchToBalance[to][batchId] += quantity;
        Transactor memory zeroApproval;
        zeroApproval = Transactor(address(0), 0);
        approvals[from][batchId] = zeroApproval;
    }

    function addBatch(
        string memory batchId,
        uint256 defrost_date,
        uint256 manufacture_expiry,
        uint256 use_by_date,
        uint256 units
    ) public onlySuperAdmin {
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

    modifier onlySuperAdmin() {
        require(
            msg.sender == superAdmin,
            "Only admin can perform the function."
        );
        _;
    }
}

contract VaccineFactory {
    Vaccine[] public vaccines;
    struct VaccineDetails {
        string name;
        uint256[] schedule;
        string platform;
        string route;
        string ipfs_hash;
    }
    mapping(address => uint256) vaccineIndex;

    function createVaccine(
        string memory name,
        uint256[] memory schedule,
        string memory platform,
        string memory route,
        string memory ipfs_hash
    ) public {
        Vaccine v = new Vaccine(name, schedule, platform, route, ipfs_hash);
        vaccines.push(v);
    }

    function getVaccineAddresses() public view returns (Vaccine[] memory) {
        return vaccines;
    }

    function getVaccineDetails(address vaccineAddress)
        public
        view
        returns (VaccineDetails memory)
    {
        IFVaccine vaccine = IFVaccine(vaccineAddress);
        string memory name = vaccine.name();
        uint256[] memory schedule = vaccine.schedule();
        string memory platform = vaccine.platform();
        string memory route = vaccine.route();
        string memory ipfs_hash = vaccine.ipfs_hash();
        return VaccineDetails(name, schedule, platform, route, ipfs_hash);
    }

    function getAllVaccinesWithDetails()
        public
        view
        returns (VaccineDetails[] memory)
    {
        VaccineDetails[] memory vDetails = new VaccineDetails[](
            vaccines.length
        );
        for (uint256 i = 0; i < vaccines.length; i++) {
            vDetails[i] = getVaccineDetails(address(vaccines[i]));
        }
        return vDetails;
    }

    function getSpecifiedVaccinesDetails(address[] memory vaccineAddress)
        public
        view
        returns (VaccineDetails[] memory)
    {
        VaccineDetails[] memory vDetails = new VaccineDetails[](
            vaccineAddress.length
        );
        for (uint256 i = 0; i < vaccineAddress.length; i++) {
            vDetails[i] = getVaccineDetails(vaccineAddress[i]);
        }
        return vDetails;
    }
}
