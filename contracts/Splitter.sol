pragma solidity ^0.4.17;

contract Splitter {

    //ownership
    address public owner;
    bool public isServiceEnabled;
    event LogServiceStateChanged(
        bool newState
    );

    //model
    struct RecipientPair {
        address recipA;
        address recipB;
        uint index;
    }
    event LogRecipientPairAdded(
        address sender,
        address recipA,
        address recipB
    );
    event LogSplitPayout(
        address recipA,
        uint amountA,
        address recipB,
        uint amountB
    );

    mapping(address => RecipientPair) private recipients;
    address[] private recipientIndex;

    /************** Init & Modifiers **************/
    modifier requireEnabled {
        require(isServiceEnabled);
        _;
    }

    function Splitter(bool initialServiceState) public {
        owner = msg.sender;
        isServiceEnabled = initialServiceState;
    }

    function setServiceEnabled(bool newState) public {
        require(msg.sender == owner);
        isServiceEnabled = newState;
        LogServiceStateChanged(isServiceEnabled);
    }
    /************** End Init & Modifiers **************/

    /************** Model Crud **************/
    function isPair(address sender) public view returns(bool pairExists) {
        if (recipientIndex.length == 0) 
            return false;

        address value = recipientIndex[recipients[sender].index];
        
        return (sender == value);
    }

    function addRecipientPair(address recipA, address recipB) requireEnabled public returns (uint index) {
        require(!isPair(msg.sender));

        uint idx = recipientIndex.push(msg.sender) - 1;
        recipients[msg.sender].index = idx;
        recipients[msg.sender].recipA = recipA;
        recipients[msg.sender].recipB = recipB;
        
        LogRecipientPairAdded(msg.sender, recipA, recipB);
        return idx;
    }

    function getRecipientPairSenderByIndex(uint index) public view returns (address sender) {
        return recipientIndex[index];
    }

    function getRecipientPairBySender(address sender) public view returns (address recipA, address recipB) {
        require(isPair(sender));
        RecipientPair memory p = recipients[sender];

        return (p.recipA, p.recipB);
    }
    /************** End Model Crud **************/

    /************** Business Logic **************/
    function splitValue() public payable {
        require(isPair(msg.sender));
        require(msg.value > 1);

        //do the division. In the case of even numbers, A and B will get the same amount.
        //In the case of odd numbers, B will receive 1 more wei than A (life isn't fair!)
        uint amountA = msg.value / 2;
        uint amountB = msg.value - amountA;

        RecipientPair memory pair = recipients[msg.sender];

        pair.recipA.transfer(amountA);
        pair.recipB.transfer(amountB);

        LogSplitPayout(pair.recipA, amountA, pair.recipB, amountB);
    }
}