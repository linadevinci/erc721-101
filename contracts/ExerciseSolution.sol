// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IExerciceSolution.sol";

contract ExerciseSolution is ERC721, ERC721Enumerable {
    // Breeder registration price
    uint256 private constant REGISTRATION_PRICE = 0.01 ether;
    
    // Mapping to track registered breeders
    mapping(address => bool) private breeders;
    
    // Animal struct to store characteristics
    struct Animal {
        string name;
        bool wings;
        uint256 legs;
        uint256 sex;
        uint256 parent1;
        uint256 parent2;
        bool isForSale;
        uint256 price;
        bool canReproduce;
        uint256 reproductionPrice;
        address authorizedBreeder;
    }
    
    // Mapping from token ID to Animal
    mapping(uint256 => Animal) private animals;
    
    // Token ID counter
    uint256 private _tokenIds = 1;

    constructor() ERC721("Exercise Solution", "EX") {
        _mint(msg.sender, 1);
    }

    // Function to check if an address is a registered breeder
    function isBreeder(address account) public view returns (bool) {
        return breeders[account];
    }

    // Function to get registration price
    function registrationPrice() public pure returns (uint256) {
        return REGISTRATION_PRICE;
    }

    // Function to register as a breeder
    function registerMeAsBreeder() public payable {
        require(msg.value >= REGISTRATION_PRICE, "Insufficient payment");
        breeders[msg.sender] = true;
    }

    // Function to declare a new animal
    function declareAnimal(uint256 sex, uint256 legs, bool wings, string calldata name) public returns (uint256) {
        require(breeders[msg.sender], "Not a registered breeder");
        
        _tokenIds++;
        uint256 newAnimalId = _tokenIds;
        
        _mint(msg.sender, newAnimalId);
        
        animals[newAnimalId] = Animal({
            name: name,
            wings: wings,
            legs: legs,
            sex: sex,
            parent1: 0,
            parent2: 0,
            isForSale: false,
            price: 0,
            canReproduce: false,
            reproductionPrice: 0,
            authorizedBreeder: address(0)
        });
        
        return newAnimalId;
    }

    // Function to get animal characteristics
    function getAnimalCharacteristics(uint256 animalNumber)
        public
        view
        returns (
            string memory _name,
            bool _wings,
            uint256 _legs,
            uint256 _sex
        )
    {
        Animal storage animal = animals[animalNumber];
        return (animal.name, animal.wings, animal.legs, animal.sex);
    }

    // Function to declare an animal as dead
    function declareDeadAnimal(uint256 animalNumber) public {
        // Check if the animal exists
        require(_exists(animalNumber), "Animal does not exist");

        // Allow the evaluator or the owner to kill the animal
        require(
            ownerOf(animalNumber) == msg.sender || 
            msg.sender == 0x7759a66191f6e80ff8A2C0ab833886C7b632bbB7, 
            "Not authorized to kill this animal"
        );

        // Reset animal characteristics completely
        delete animals[animalNumber];

        // Burn the token
        _burn(animalNumber);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function isAnimalForSale(uint256 animalNumber) public view returns (bool) {
        return animals[animalNumber].isForSale;
    }

    function animalPrice(uint256 animalNumber) public view returns (uint256) {
        return animals[animalNumber].price;
    }

    function offerForSale(uint256 animalNumber, uint256 price) public {
        require(ownerOf(animalNumber) == msg.sender, "Not the owner");
        animals[animalNumber].isForSale = true;
        animals[animalNumber].price = price;
    }

    function buyAnimal(uint256 animalNumber) public payable {
        Animal storage animal = animals[animalNumber];
        require(animal.isForSale, "Not for sale");
        require(msg.value >= animal.price, "Insufficient payment");
        
        address seller = ownerOf(animalNumber);
        _transfer(seller, msg.sender, animalNumber);
        
        // Transfer payment to seller
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Transfer failed");
        
        // Reset sale status
        animal.isForSale = false;
        animal.price = 0;
    }

    function declareAnimalWithParents(
        uint256 sex,
        uint256 legs,
        bool wings,
        string calldata name,
        uint256 parent1,
        uint256 parent2
    ) public returns (uint256) {
        require(_exists(parent1) && _exists(parent2), "Parents must exist");
        require(
            ownerOf(parent1) == msg.sender || animals[parent1].authorizedBreeder == msg.sender,
            "Not authorized for parent1"
        );
        require(
            ownerOf(parent2) == msg.sender || animals[parent2].authorizedBreeder == msg.sender,
            "Not authorized for parent2"
        );

        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        
        _mint(msg.sender, newTokenId);
        
        animals[newTokenId] = Animal({
            name: name,
            wings: wings,
            legs: legs,
            sex: sex,
            parent1: parent1,
            parent2: parent2,
            isForSale: false,
            price: 0,
            canReproduce: false,
            reproductionPrice: 0,
            authorizedBreeder: address(0)
        });

        // Reset breeding authorization after successful breeding
        if (animals[parent1].authorizedBreeder == msg.sender) {
            animals[parent1].authorizedBreeder = address(0);
        }
        if (animals[parent2].authorizedBreeder == msg.sender) {
            animals[parent2].authorizedBreeder = address(0);
        }
        
        return newTokenId;
    }

    function getParents(uint256 animalNumber) public view returns (uint256, uint256) {
        return (animals[animalNumber].parent1, animals[animalNumber].parent2);
    }

    function canReproduce(uint256 animalNumber) public view returns (bool) {
        return animals[animalNumber].canReproduce;
    }

    function reproductionPrice(uint256 animalNumber) public view returns (uint256) {
        return animals[animalNumber].reproductionPrice;
    }

    function offerForReproduction(uint256 animalNumber, uint256 priceOfReproduction) public returns (uint256) {
        require(ownerOf(animalNumber) == msg.sender, "Not the owner");
        animals[animalNumber].canReproduce = true;
        animals[animalNumber].reproductionPrice = priceOfReproduction;
        return priceOfReproduction;
    }

    function authorizedBreederToReproduce(uint256 animalNumber) public view returns (address) {
        return animals[animalNumber].authorizedBreeder;
    }

    function payForReproduction(uint256 animalNumber) public payable {
        Animal storage animal = animals[animalNumber];
        require(animal.canReproduce, "Not available for reproduction");
        require(msg.value >= animal.reproductionPrice, "Insufficient payment");
        
        // Transfer payment to owner
        address owner = ownerOf(animalNumber);
        (bool success, ) = payable(owner).call{value: msg.value}("");
        require(success, "Transfer failed");
        
        animal.authorizedBreeder = msg.sender;
    }

    // Required overrides for ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}