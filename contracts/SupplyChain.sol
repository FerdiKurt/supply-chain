// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import './Ownable.sol';

contract SupplyChain is Ownable {
    mapping (bytes32 => Item) public items;
    mapping (address => mapping(bytes32 => Delivery)) public deliveries;
    
    event ItemAdded(string description, uint amount, uint price);
    event ItemOrderedBy(address indexed buyer, bytes32 itemId, uint orderedAmount, State state);
    event ItemDelivered(address indexed recipient, bytes32 itemId, uint timestamp, State state);
    event ItemAvailable(bool available, uint soldedAmount, uint availableAmount);
    
    enum State {
        PENDING,
        ORDERED,
        DELIVERED
    }
    
    struct Delivery {
        uint numOfItems;
        uint fulfilledPayment;
        State state;
    }

    struct Item {
        bytes32 id;
        uint availableAmount;
        uint soldAmount;
        uint itemPrice;
    }

    function addItem(
        bytes32 _id,
        string memory _description,
        uint _availableAmount,
        uint _price
    ) public onlyOwner() {
        items[_id].id = _id;
        items[_id].availableAmount += _availableAmount;
        items[_id].itemPrice = _price;
        
        emit ItemAdded (_description, items[_id].availableAmount, _price);
    }
    
    function orderItem(bytes32 _id, uint _amount) public payable{
        require(_amount <= items[_id].availableAmount, 'Not enough items left!');
        require(msg.value == items[_id].itemPrice * _amount, 'Only full payment accepted!');
        
        items[_id].availableAmount -= _amount;
        items[_id].soldAmount += _amount;

        deliveries[msg.sender][_id].numOfItems += _amount;
        deliveries[msg.sender][_id].fulfilledPayment += msg.value;
        deliveries[msg.sender][_id].state = State.ORDERED;
        
        if (items[_id].availableAmount < 5) {
            emit ItemAvailable(false, items[_id].soldAmount, items[_id].availableAmount);
            emit ItemOrderedBy(msg.sender, _id, _amount, State.ORDERED);
            
            return;
        }
        
        emit ItemAvailable(true, items[_id].soldAmount, items[_id].availableAmount);
        emit ItemOrderedBy(msg.sender, _id, _amount, State.ORDERED);
    }
    
    function deliverItem(bytes32 _id, address _to) public onlyOwner() {
        require(deliveries[_to][_id].state ==  State.ORDERED, 'Only ORDERED txs!');
        
        emit ItemDelivered(_to, _id, block.timestamp, State.DELIVERED);
        
        deliveries[_to][_id].state = State.DELIVERED;
    }
    
    function randomId(string memory str) public view onlyOwner() returns(bytes32) {
        return (keccak256(abi.encode(block.timestamp, block.difficulty, str)));
    }
    
    function balanceOf() public view returns (uint) {
        return address(this).balance;
    }
}