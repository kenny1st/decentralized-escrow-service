
---

### **Example Solidity Contract (`contracts/Escrow.sol`)**  
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_CONFIRMATION, COMPLETE, DISPUTED }

    struct Transaction {
        address payable buyer;
        address payable seller;
        uint256 amount;
        State state;
    }

    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    event TransactionCreated(uint256 transactionId, address indexed buyer, address indexed seller, uint256 amount);
    event PaymentDeposited(uint256 transactionId);
    event TransactionConfirmed(uint256 transactionId);
    event TransactionDisputed(uint256 transactionId);

    function createTransaction(address payable _seller) public payable {
        require(msg.value > 0, "Amount must be greater than zero");

        transactions[transactionCount] = Transaction(payable(msg.sender), _seller, msg.value, State.AWAITING_PAYMENT);
        emit TransactionCreated(transactionCount, msg.sender, _seller, msg.value);
        transactionCount++;
    }

    function depositPayment(uint256 _transactionId) public payable {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.state == State.AWAITING_PAYMENT, "Transaction not awaiting payment");
        require(msg.value == transaction.amount, "Incorrect payment amount");

        transaction.state = State.AWAITING_CONFIRMATION;
        emit PaymentDeposited(_transactionId);
    }

    function confirmTransaction(uint256 _transactionId) public {
        Transaction storage transaction = transactions[_transactionId];
        require(msg.sender == transaction.buyer, "Only buyer can confirm");
        require(transaction.state == State.AWAITING_CONFIRMATION, "Transaction not awaiting confirmation");

        transaction.seller.transfer(transaction.amount);
        transaction.state = State.COMPLETE;
        emit TransactionConfirmed(_transactionId);
    }

    function disputeTransaction(uint256 _transactionId) public {
        Transaction storage transaction = transactions[_transactionId];
        require(msg.sender == transaction.buyer || msg.sender == transaction.seller, "Only buyer or seller can dispute");
        require(transaction.state == State.AWAITING_CONFIRMATION, "Transaction not in confirmation state");

        transaction.state = State.DISPUTED;
        emit TransactionDisputed(_transactionId);
    }
}
