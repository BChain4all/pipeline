pragma solidity ^0.8.0;

/**
 * @title Standard Lease Agreement Smart Contract
 * @dev This contract represents a standard lease agreement between a landlord and a tenant.
 *      It includes functionalities to handle payments, conditions, constraints, and termination
 *      of the lease agreement as per the provided legal agreement details.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as the currency unit for simplicity
    uint256 public constant securityDepositAmount = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(address => uint256) public balances;

    event RentPaid(address indexed tenant, uint256 amount);
    event LeaseTerminated(address indexed tenant);
    event SecurityDepositRefunded(address indexed tenant, uint256 amount);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Caller is not the landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Caller is not the tenant");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "Lease is not active");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
    }

    /**
     * @dev Allows the tenant to pay rent. Rent must be paid in full.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term");
        require(msg.value == rentAmount, "Rent amount is incorrect");
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Allows the tenant to pay the security deposit. Must be paid in full before the lease starts.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(block.timestamp < leaseStart, "Lease has already started");
        require(msg.value == securityDepositAmount, "Security deposit amount is incorrect");
        balances[tenant] += msg.value;
    }

    /**
     * @dev Allows the landlord to refund the security deposit to the tenant upon lease termination.
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active");
        uint256 amount = balances[tenant];
        require(amount > 0, "No security deposit to refund");
        balances[tenant] = 0;
        payable(tenant).transfer(amount);
        emit SecurityDepositRefunded(tenant, amount);
    }

    /**
     * @dev Allows the landlord to terminate the lease early under specific conditions.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Allows the tenant to terminate the lease under specific conditions such as being a victim of domestic violence.
     *      This is a placeholder for actual implementation based on legal requirements.
     */
    function terminateLeaseByTenant() external onlyTenant isLeaseActive {
        // Placeholder for condition checks based on legal requirements
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Utility function to check if the lease is currently active.
     */
    function isLeaseCurrentlyActive() external view returns (bool) {
        return leaseActive && block.timestamp >= leaseStart && block.timestamp <= leaseEnd;
    }
}