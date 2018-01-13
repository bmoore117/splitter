var p = require("bluebird");
const getBalancePromise = p.promisify(web3.eth.getBalance);
const getTransactionPromise = p.promisify(web3.eth.getTransaction);

const Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
    var instance;

    before("deploy new instance", function() {
        var hashedPassword = web3.sha3("password");
        return Splitter.new(hashedPassword, {from: accounts[0]})
        .then(function(_instance) {
            instance = _instance;
        });
    });

    it("should perform perfect splits if the amount sent is greater than 1 wei, and an even number", function() {
        var startingBalance2;
        var startingBalance3;
        var endingBalance2;
        var endingBalance3;
        var paidToA;
        var paidToB;

        return getBalancePromise(accounts[2])
        .then(balance => {
            startingBalance2 = balance;
            return getBalancePromise(accounts[3]);
        }).then(balance => {
            startingBalance3 = balance;
            return instance.splitValue(accounts[2], accounts[3], {from: accounts[1], value: 2})
        }).then(txInfo => {
            var logs = txInfo.logs[0];
            paidToA = logs.args.amountA;
            paidToB = logs.args.amountB;
            return getBalancePromise(accounts[2]);
        }).then(balance => {
            endingBalance2 = balance;
            return getBalancePromise(accounts[3]);
        }).then(balance => {
            endingBalance3 = balance;

            var amtA = startingBalance2.plus(paidToA);
            assert.strictEqual(amtA.toString(10), endingBalance2.toString(10), "Split not properly performed for recipA");

            var amtB = startingBalance3.plus(paidToB);
            assert.strictEqual(amtB.toString(10), endingBalance3.toString(10), "Split not properly performed for recipB");
        });
    });

    it("should perform splits in which the second recipient receives the remainder if the amount sent is greater than 1 wei, and an odd number", function() {

        var startingBalance2;
        var startingBalance3;
        var endingBalance2;
        var endingBalance3;
        var paidToA;
        var paidToB;

        return getBalancePromise(accounts[2])
        .then(balance => {
            startingBalance2 = balance;
            return getBalancePromise(accounts[3]);
        }).then(balance => {
            startingBalance3 = balance;
            return instance.splitValue(accounts[2], accounts[3], {from: accounts[1], value: 3})
        }).then(txInfo => {
            var logs = txInfo.logs[0];
            paidToA = logs.args.amountA;
            paidToB = logs.args.amountB;
            return getBalancePromise(accounts[2]);
        }).then(balance => {
            endingBalance2 = balance;
            return getBalancePromise(accounts[3]);
        }).then(balance => {
            endingBalance3 = balance;

            var difference = paidToB.minus(paidToA);
            assert.strictEqual(difference.toString(10), "1", "Split not properly calculated");

            var amtA = startingBalance2.plus(paidToA);
            assert.strictEqual(amtA.toString(10), endingBalance2.toString(10), "Split not properly performed for recipA");

            var amtB = startingBalance3.plus(paidToB);
            assert.strictEqual(amtB.toString(10), endingBalance3.toString(10), "Split not properly performed for recipB");
        });
    });
});