pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    uint256 public constant rentAmount = 850 ether; // Assuming ether is the currency used
    uint256 public constant lateFee = 200 ether;
    uint256 public constant securityDeposit = 1700 ether;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public leaseActive = false;
    mapping(uint256 => bool) public rentPaid;

    event LeaseSigned(uint256 leaseStart, uint256 leaseEnd, address tenant);
    event RentPaid(uint256 month, address tenant);
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
        require(leaseActive, "Lease is not active.");
        _;
    }

    constructor(address _tenant, uint256 _leaseStart, uint256 _leaseEnd) {
        landlord = msg.sender;
        tenant = _tenant;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
    }

    /**
     * @dev Sign the lease agreement to activate it
     */
    function signLease() external onlyTenant {
        require(block.timestamp >= leaseStart, "Lease start date is in the future.");
        require(block.timestamp <= leaseEnd, "Lease end date has passed.");
        leaseActive = true;
        emit LeaseSigned(leaseStart, leaseEnd, tenant);
    }

    /**
     * @dev Pay rent for a specific month
     * @param month The month for which rent is being paid
     */
    function payRent(uint256 month) external payable onlyTenant isLeaseActive {
        require(msg.value == rentAmount, "Incorrect rent amount.");
        require(block.timestamp <= leaseEnd, "Lease has ended.");
        require(!rentPaid[month], "Rent for this month has already been paid.");
        rentPaid[month] = true;
        emit RentPaid(month, tenant);
    }

    /**
     * @dev Terminate the lease agreement
     */
    function terminateLease() external onlyLandlord isLeaseActive {
        leaseActive = false;
        emit LeaseTerminated(tenant);
    }

    /**
     * @dev Withdraw funds from the contract (rent, security deposit)
     */
    function withdrawFunds() external onlyLandlord {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal.");
        (bool success, ) = landlord.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev Return security deposit to tenant
     */
    function returnSecurityDeposit() external onlyLandlord {
        require(!leaseActive, "Lease is still active.");
        (bool success, ) = tenant.call{value: securityDeposit}("");
        require(success, "Security deposit return failed.");
    }

    /**
     * @dev Fallback function to handle receiving ether
     */
    receive() external payable {}

    /**
     * @dev Fallback function in case ether is sent to the contract by mistake
     */
    fallback() external payable {}
}