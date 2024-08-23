pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address payable public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is used as a unit for simplicity
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public constant lateFee = 200 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive;
    mapping(address => uint256) public balances;

    event RentPaid(address tenant, uint256 amount);
    event LeaseTerminated(address tenant);
    event SecurityDepositRefunded(address tenant, uint256 amount);
    event LateFeeAssessed(address tenant, uint256 amount);

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
        leaseActive = true;
    }

    /**
     * @dev Allows the tenant to pay rent.
     */
    function payRent() external payable onlyTenant isLeaseActive {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "Lease term is not valid.");
        require(msg.value == rentAmount, "Incorrect rent amount.");
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Allows the landlord to assess a late fee.
     */
    function assessLateFee() external onlyLandlord isLeaseActive {
        require(block.timestamp > leaseStart + 10 days, "Late fee cannot be assessed yet.");
        balances[tenant] += lateFee;
        emit LateFeeAssessed(tenant, lateFee);
    }

    /**
     * @dev Allows the tenant to pay the security deposit.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        balances[landlord] += msg.value;
    }

    /**
     * @dev Terminates the lease agreement.
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Refunds the security deposit to the tenant, minus any deductions.
     * @param _amount The amount to refund.
     */
    function refundSecurityDeposit(uint256 _amount) external onlyLandlord {
        require(_amount <= balances[landlord], "Insufficient funds to refund.");
        require(!leaseActive, "Lease must be terminated to refund the security deposit.");
        balances[landlord] -= _amount;
        payable(tenant).transfer(_amount);
        emit SecurityDepositRefunded(tenant, _amount);
    }

    /**
     * @dev Fallback function to prevent ether from being sent to the contract inadvertently.
     */
    fallback() external {
        revert("Cannot send ETH directly to this contract.");
    }
}