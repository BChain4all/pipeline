pragma solidity ^0.5.1;

contract LeaseAgreement {
    //Struct to store Tenant Info
    struct Tenant {
        address tenantAddress;
        bool isTenant;
    }
    //Declaration of variables
    address public landlord;
    uint256 public leaseTermEndDate;
    uint256 public rent;
    uint256 public securityDeposit;

    // Mapping to save the tenants
    mapping(address => Tenant) tenants;
    
    // Function to set landlord details
    constructor(uint256 _leaseTermEndDate, uint256 _rent, uint256 _securityDeposit) public{
        landlord = msg.sender;
        leaseTermEndDate=now+_leaseTermEndDate;
        rent=_rent;
        securityDeposit=_securityDeposit;
    }
   
    // Landlord adds a tenant & deposits received here
    function addTenant(address _tenantAddress) public payable {
        require(msg.sender == landlord, "Only landlord can add a tenant");
        require(msg.value == securityDeposit + rent, "Rent and Security Deposit required");
        
        Tenant storage tenant = tenants[_tenantAddress];
        tenant.tenantAddress = _tenantAddress;
        tenant.isTenant = true;
    }

    // Tenant pays rent
    function payRent() public payable {
        require(msg.sender == tenants[msg.sender].tenantAddress, "Only tenants can pay rent");
        require(msg.value == rent ,"Rent amount required");
        landlord.transfer(msg.value); 
    }

    // Refund of security deposit after lease end
    function refundSecurityDeposit(address _tenantAddress) public {
        require(msg.sender == landlord, "Only landlord can refund deposit");
        require(now > leaseTermEndDate, "Lease term not ended");
        _tenantAddress.transfer(securityDeposit);
    }
}
