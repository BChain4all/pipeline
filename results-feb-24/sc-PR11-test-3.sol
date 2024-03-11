pragma solidity ^0.8.0;

/**
 * @title StandardLeaseAgreement
 * @dev Implements a standard lease agreement as a smart contract.
 */
contract StandardLeaseAgreement {
    address public landlord;
    address public tenant;
    string public premises;
    uint256 public rent;
    uint256 public securityDeposit;
    uint256 public leaseStart;
    uint256 public leaseEnd;
    bool public agreementSigned = false;

    // Events
    event AgreementSigned(address landlord, address tenant);
    event RentPaid(address tenant, uint256 amount);
    event SecurityDepositPaid(address tenant, uint256 amount);
    event SecurityDepositRefunded(address tenant, uint256 amount);

    // Modifiers
    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action.");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action.");
        _;
    }

    modifier isSigned() {
        require(agreementSigned, "The agreement must be signed by both parties.");
        _;
    }

    /**
     * @dev Constructor to create a lease agreement.
     * @param _landlord address of the landlord.
     * @param _tenant address of the tenant.
     * @param _premises address of the leased premises.
     * @param _rent monthly rent amount in wei.
     * @param _securityDeposit security deposit amount in wei.
     * @param _leaseStart start date of the lease as a timestamp.
     * @param _leaseEnd end date of the lease as a timestamp.
     */
    constructor(
        address _landlord,
        address _tenant,
        string memory _premises,
        uint256 _rent,
        uint256 _securityDeposit,
        uint256 _leaseStart,
        uint256 _leaseEnd
    ) {
        landlord = _landlord;
        tenant = _tenant;
        premises = _premises;
        rent = _rent;
        securityDeposit = _securityDeposit;
        leaseStart = _leaseStart;
        leaseEnd = _leaseEnd;
    }

    /**
     * @dev Function for both parties to sign the agreement.
     */
    function signAgreement() public {
        require(msg.sender == landlord || msg.sender == tenant, "Only the landlord or tenant can sign the agreement.");
        require(!agreementSigned, "The agreement is already signed.");

        agreementSigned = true;
        emit AgreementSigned(landlord, tenant);
    }

    /**
     * @dev Function for the tenant to pay rent.
     */
    function payRent() public payable onlyTenant isSigned {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "The lease term is not active.");
        require(msg.value == rent, "Incorrect rent amount.");

        payable(landlord).transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Function for the tenant to pay the security deposit.
     */
    function paySecurityDeposit() public payable onlyTenant isSigned {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");

        payable(landlord).transfer(msg.value);
        emit SecurityDepositPaid(tenant, msg.value);
    }

    /**
     * @dev Function for the landlord to refund the security deposit.
     */
    function refundSecurityDeposit(uint256 _amount) public onlyLandlord isSigned {
        require(_amount <= securityDeposit, "Refund amount exceeds security deposit.");

        payable(tenant).transfer(_amount);
        emit SecurityDepositRefunded(tenant, _amount);
    }

    /**
     * @dev Function to check the balance of the contract (for demonstration purposes).
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}