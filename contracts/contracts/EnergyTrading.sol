// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergyTrading {
    struct EnergyCredit {
        uint256 id;
        address producer;
        uint256 quantity; // in kWh
        uint256 price; // in wei per kWh
        bool isAvailable;
    }

    uint256 public creditCount = 0;
    uint256[] public availableCreditIds;
    address public owner;

    mapping(uint256 => EnergyCredit) public energyCredits;
    mapping(address => bool) public registeredProducers;

    event CreditListed(uint256 id, address producer, uint256 quantity, uint256 price);
    event CreditPurchased(uint256 id, address buyer, uint256 quantity, uint256 totalCost);
    event RoleAssigned(address indexed user, Role role);


    modifier onlyProducer() {
        require(registeredProducers[msg.sender], "Not a registered producer");
        _;
    }


    enum Role { Buyer, Producer, Admin }

    mapping(address => Role) public roles;

    constructor() {
        owner = msg.sender;
        roles[owner] = Role.Admin;  
    }

    modifier onlyOwner {
       require(msg.sender == owner, "Not owner.");
       _;
   }

    function applyForProducer() external {
        roles[msg.sender] = Role.Producer;
        registeredProducers[msg.sender] = true;
        emit RoleAssigned(msg.sender, Role.Producer);
    }

    function registerProducer(address producer) public onlyOwner {
        registeredProducers[producer] = true;
    }

    function listEnergyCredit(uint256 quantity, uint256 price) public onlyProducer {
        require(quantity > 0, "Quantity must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        energyCredits[creditCount] = EnergyCredit({
            id: creditCount,
            producer: msg.sender,
            quantity: quantity,
            price: price,
            isAvailable: true
        });
        availableCreditIds.push(creditCount);
        emit CreditListed(creditCount, msg.sender, quantity, price);
        creditCount++;
    }

    function purchaseEnergyCredit(uint256 creditId, uint256 quantity) public payable {
        EnergyCredit storage credit = energyCredits[creditId];
        require(credit.isAvailable, "Energy credit is not available");
        require(quantity <= credit.quantity, "Not enough credits available");
        uint256 totalCost = quantity * credit.price;
        require(msg.value == totalCost, "Incorrect payment amount");

        credit.quantity -= quantity;
        if (credit.quantity == 0) {
            credit.isAvailable = false;
        }

        payable(credit.producer).transfer(totalCost);

        emit CreditPurchased(creditId, msg.sender, quantity, totalCost);
    }

   function getAvailableCredits() external view returns (uint256[] memory) {
        return availableCreditIds; 
    }

    function getEnergyCredit(uint256 creditId) external view returns (EnergyCredit memory) {
        return energyCredits[creditId];
    }

    function getDetailedAvailableCredits() external view returns (EnergyCredit[] memory) {
    uint256 count = availableCreditIds.length;
    EnergyCredit[] memory availableCredits = new EnergyCredit[](count);

    for (uint256 i = 0; i < count; i++) {
        availableCredits[i] = energyCredits[availableCreditIds[i]];
    }

    return availableCredits;
}

    modifier onlyBuyer() {
        require(roles[msg.sender] == Role.Buyer, "Not a buyer");
        _;
    }

    function assignRole(address user, Role role) external onlyOwner {
        roles[user] = role;
        emit RoleAssigned(user, role);
    }

    function getRole(address user) external view returns (Role) {
        return roles[user];
    }
}
