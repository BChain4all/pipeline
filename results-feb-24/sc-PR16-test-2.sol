pragma solidity ^0.8.0;

/**
 * @title Standard Lease Agreement Smart Contract
 * @dev This contract represents a standard lease agreement between a landlord and a tenant.
 *      It includes functionalities for rent payments, security deposit handling, and lease termination.
 *      This contract is designed for deployment on the Ethereum blockchain.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as the currency
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public securityDepositPaid = false;
    bool public leaseActive = false;

    // Events
    event RentPaid(address tenant, uint256 amount);
    event SecurityDepositPaid(address tenant, uint256 amount);
    event SecurityDepositRefunded(address tenant, uint256 amount);
    event LeaseTerminated(address tenant);

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
        landlord = payable(msg.sender);
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
    }

    /**
     * @dev Allows the tenant to pay the security deposit. This function can only be called once.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(!securityDepositPaid, "Security deposit has already been paid.");
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        securityDepositPaid = true;
        leaseActive = true;
        emit SecurityDepositPaid(msg.sender, msg.value);
    }

    /**
     * @dev Allows the tenant to pay the rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(msg.value == rentAmount, "Incorrect rent amount.");
        landlord.transfer(msg.value);
        emit RentPaid(msg.sender, msg.value);
    }

    /**
     * @dev Allows the landlord to refund the security deposit to the tenant.
     * @param deduction The amount to be deducted from the security deposit for any damages or unpaid rent.
     */
    function refundSecurityDeposit(uint256 deduction) external onlyLandlord {
        require(securityDepositPaid, "Security deposit was not paid.");
        require(deduction <= securityDeposit, "Deduction exceeds security deposit.");
        uint256 refundAmount = securityDeposit - deduction;
        payable(tenant).transfer(refundAmount);
        securityDepositPaid = false;
        leaseActive = false;
        emit SecurityDepositRefunded(tenant, refundAmount);
    }

    /**
     * @dev Terminates the lease agreement. Can be called by either the landlord or the tenant.
     */
    function terminateLease() external {
        require(msg.sender == landlord || msg.sender == tenant, "Only the landlord or tenant can terminate the lease.");
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Fallback function to prevent direct sending of ether to the contract.
     */
    fallback() external {
        revert("Direct sending of ether is not allowed.");
    }
}