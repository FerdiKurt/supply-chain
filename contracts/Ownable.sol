// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ownable {
    address private _owner; 
    
    modifier onlyOwner() {
        require(isOwner(), 'Only owner!');    
        _;
    }

    constructor() {
        _owner = msg.sender;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}
