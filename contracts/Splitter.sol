pragma solidity ^0.4.17;

contract Splitter {

    address public owner;
    bytes32 private hashedPassword;

    event LogContractKilled(
        uint balanceTransferred
    );
    event LogSplitPayout(
        address recipA,
        uint amountA,
        address recipB,
        uint amountB,
        uint senderChange
    );

    /************** Init & Modifiers **************/
    function Splitter(bytes32 passwordHash) public {
        owner = msg.sender;
        hashedPassword = passwordHash;
    }

    function kill(string password) public {
        require(msg.sender == owner);
        if (keccak256(password) == hashedPassword) {
            LogContractKilled(this.balance);
            selfdestruct(owner);
        }
    }
    /************** End Init & Modifiers **************/

    /************** Business Logic **************/
    function splitValue(address recipA, address recipB) public payable {
        require(msg.value > 1); //can't split 1 wei!

        LogSplitPayout(recipA, amountA, recipB, amountB, senderChange);

        //do the division. In the case of even numbers, the sender will receive no change.
        //In the case of odd numbers, the sender will receive the 1 extra wei back
        uint amountA = msg.value / 2;
        uint amountB = amountA;
        uint senderChange = msg.value - amountA*2;

        if (senderChange > 0) {
            msg.sender.transfer(senderChange);
        }
        recipA.transfer(amountA);
        recipB.transfer(amountB);
    }
}