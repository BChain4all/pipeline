pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether as a stand-in for US Dollars for simplicity
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    
    // Events
    event LeaseSigned(address indexed _landlord, address indexed _tenant, uint256 _leaseStart, uint256 _leaseEnd);
    event RentPaid(address indexed _tenant, uint256 _amount);
    event LeaseTerminated(address indexed _landlord, address indexed _tenant);
    event SecurityDepositRefunded(address indexed _tenant, uint256 _amount);
    
    // Modifiers
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
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
        leaseActive = true;
        emit LeaseSigned(landlord, tenant, leaseStart, leaseEnd);
    }
    
    /**
     * @dev Allows the tenant to pay rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Not within lease term.");
        emit RentPaid(tenant, msg.value);
    }
    
    /**
     * @dev Terminates the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(landlord, tenant);
    }
    
    /**
     * @dev Refunds the security deposit to the tenant.
     */
    function refundSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease must be terminated to refund the security deposit.");
        payable(tenant).transfer(securityDeposit);
        emit SecurityDepositRefunded(tenant, securityDeposit);
    }
    
    /**
     * @dev Fallback function to handle receiving ether.
     */
    receive() external payable {
        revert("Please use the payRent function to make payments.");
    }
}