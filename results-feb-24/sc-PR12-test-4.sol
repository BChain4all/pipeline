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
     * @dev Sign the agreement. Both landlord and tenant must call this function to sign.
     */
    function signAgreement() external {
        require(msg.sender == landlord || msg.sender == tenant, "Only the landlord or tenant can sign the agreement.");
        require(!agreementSigned, "The agreement is already signed.");

        if (msg.sender == landlord && tenant != address(0)) {
            agreementSigned = true;
            emit AgreementSigned(landlord, tenant);
        } else if (msg.sender == tenant && landlord != address(0)) {
            agreementSigned = true;
            emit AgreementSigned(landlord, tenant);
        }
    }

    /**
     * @dev Pay rent. Only the tenant can call this function.
     */
    function payRent() external payable onlyTenant isSigned {
        require(block.timestamp >= leaseStart && block.timestamp <= leaseEnd, "The lease term is not active.");
        require(msg.value == rent, "Incorrect rent amount.");

        payable(landlord).transfer(msg.value);
        emit RentPaid(tenant, msg.value);
    }

    /**
     * @dev Pay security deposit. Only the tenant can call this function.
     */
    function paySecurityDeposit() external payable onlyTenant {
        require(msg.value == securityDeposit, "Incorrect security deposit amount.");
        require(!agreementSigned, "The agreement is already signed.");

        payable(landlord).transfer(msg.value);
        emit SecurityDepositPaid(tenant, msg.value);
    }

    /**
     * @dev Refund security deposit. Only the landlord can call this function.
     */
    function refundSecurityDeposit(uint256 _amount) external onlyLandlord isSigned {
        require(_amount <= securityDeposit, "Amount exceeds the security deposit.");

        payable(tenant).transfer(_amount);
        emit SecurityDepositRefunded(tenant, _amount);
    }

    /**
     * @dev Terminate the agreement early. Can be called by either the landlord or the tenant.
     */
    function terminateAgreement() external isSigned {
        require(msg.sender == landlord || msg.sender == tenant, "Only the landlord or tenant can terminate the agreement.");
        agreementSigned = false;
    }
}