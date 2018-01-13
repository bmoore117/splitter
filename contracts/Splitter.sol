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
        uint amountB
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

        //do the division. In the case of even numbers, A and B will get the same amount.
        //In the case of odd numbers, B will receive 1 more wei than A (life isn't fair!)
        uint amountA = msg.value / 2;
        uint amountB = msg.value - amountA;

        recipA.transfer(amountA);
        recipB.transfer(amountB);

        LogSplitPayout(recipA, amountA, recipB, amountB);
    }
}