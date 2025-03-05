pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for USD for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event RentPaid(address tenant, uint256 month, uint256 amount);
    event LeaseTerminated(address tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Caller is not the landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Caller is not the tenant");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Pay rent for a specific month
     * @param month The month for which rent is being paid
     */
    function payRent(uint256 month) external payable onlyTenant {
        require(leaseActive, "Lease is not active");
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(msg.value == rentAmount, "Incorrect rent amount");
        require(!rentPaid[month], "Rent already paid for this month");
        
        rentPaid[month] = true;
        emit RentPaid(msg.sender, month, msg.value);
    }

    /**
     * @dev Terminate the lease agreement
     */
    function terminateLease() external onlyLandlord {
        require(leaseActive, "Lease is already terminated");
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Return security deposit to tenant
     */
    function returnSecurityDeposit(uint256 amount) external onlyLandlord {
        require(!leaseActive, "Lease is still active");
        require(amount <= securityDeposit, "Amount exceeds security deposit");
        
        payable(tenant).transfer(amount);
    }

    /**
     * @dev Charge late fee
     */
    function chargeLateFee() external onlyLandlord {
        require(leaseActive, "Lease is not active");
        
        payable(landlord).transfer(lateFee);
    }

    /**
     * @dev Get the status of rent payment for a specific month
     * @param month The month to check
     * @return bool Status of rent payment for the month
     */
    function isRentPaid(uint256 month) external view returns (bool) {
        return rentPaid[month];
    }
}