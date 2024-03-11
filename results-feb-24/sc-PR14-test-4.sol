pragma solidity ^0.8.0;

/**
 * @title Standard Lease Agreement Smart Contract
 * @dev This contract represents a standard lease agreement between a landlord and a tenant.
 *      It encapsulates terms and conditions of the lease agreement as per the provided legal agreement.
 *      This contract is designed for deployment on the Ethereum blockchain.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming rent is paid in Ether for simplicity
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(uint256 => bool) public rentPaid;

    event LeaseSigned(address indexed landlord, address indexed tenant, uint256 leaseStart, uint256 leaseEnd);
    event RentPaid(address indexed tenant, uint256 month, uint256 amount);
    event LeaseTerminated(address indexed tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier isLeaseActive() {
        require(leaseActive, "The lease is not active.");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        require(_leaseStart < _leaseEnd, "Lease start date must be before lease end date.");
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
        emit LeaseSigned(landlord, tenant, leaseStart, leaseEnd);
    }

    /**
     * @dev Allows the tenant to pay rent for a specific month.
     * @param _month The month for which rent is being paid.
     */
    function payRent(uint256 _month) external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Outside of lease term.");
        require(!rentPaid[_month], "Rent for this month has already been paid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");

        rentPaid[_month] = true;
        emit RentPaid(tenant, _month, msg.value);
    }

    /**
     * @dev Allows the landlord to terminate the lease agreement early under specific conditions.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     * Note: In a real-world scenario, additional logic to handle the security deposit (e.g., refunding) would be necessary.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        // In a real-world scenario, the security deposit would be stored in the contract or otherwise managed according to local laws.
    }

    /**
     * @dev Allows the landlord to withdraw accumulated rent.
     * Note: This simplistic approach does not account for expenses, taxes, or other real-world considerations.
     */
    function withdrawRent() external onlyLandlord {
        uint256 amount = address(this).balance;
        (bool success, ) = landlord.call{value: amount}("");
        require(success, "Failed to withdraw rent.");
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfers to the contract.
     */
    fallback() external {
        revert("Cannot send ETH directly to this contract.");
    }

    /**
     * @dev Receive function to accept ETH from specific functions only.
     */
    receive() external payable {
        revert("Please use the designated functions to send ETH to this contract.");
    }
}