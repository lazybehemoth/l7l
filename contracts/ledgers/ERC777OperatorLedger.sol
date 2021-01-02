// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/introspection/ERC1820Implementer.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

/** 
 * @title IOU ledger for players with balances in ERC777 tokens.
 * @dev Inspired by openzeppelin's ConditionalEscrow contract.
 */
contract ERC777OperatorLedger is Ownable, IERC777Sender, IERC777Recipient, ERC1820Implementer {
    using SafeMath for uint256;

    IERC777 public TrustedToken;

    mapping(address => uint256) private _deposits;
    bool internal initialized;

    event Deposited(address indexed payee, uint256 amount);
    event Withdrawn(address indexed payee, uint256 amount);

    // ERC777 implementation stuff
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    // keccak256("ERC777TokensSender")
    bytes32 constant private _TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;
    // keccak256("ERC777TokensRecipient")
    bytes32 constant private _TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    event TokensToSendCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    event TokensReceivedCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    /** 
     * @dev L7L DAO should be in charge of Ledger.
     */
    constructor() public {
        address self = address(this);
        _registerInterfaceForAddress(_TOKENS_SENDER_INTERFACE_HASH, self);
        _registerInterfaceForAddress(_TOKENS_RECIPIENT_INTERFACE_HASH, self);

        _erc1820.setInterfaceImplementer(self, _TOKENS_SENDER_INTERFACE_HASH, self);
        _erc1820.setInterfaceImplementer(self, _TOKENS_RECIPIENT_INTERFACE_HASH, self);
    }

    /** 
     * @dev Called once to bind abstract ledger to a specific ERC777 token.
     *
     * @param _token The ERC777 token address.
     */
    function initialize(address _token) public virtual {
        require(!initialized, "Not ready");

        TrustedToken = IERC777(_token);
        initialized = true;
    }

    /** 
     * @dev Check link balance for address.
     *
     * @param payee The creditor's address.
     */
    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     *
     * @param credit The destination address of the funds.
     * @param amount Amount of ERC777 tokens to transfer.
     */
    function depositFor(address credit, uint256 amount) public virtual onlyOwner {
        _deposits[credit] = _deposits[credit].add(amount);
        emit Deposited(credit, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];
        TrustedToken.operatorSend(address(this), payee, payment, "", "");

        _deposits[payee] = 0;

        emit Withdrawn(payee, payment);
    }


    /********************************/
    /* ERC777 callbacks and helpers */ 
    /********************************/

    /** 
     * @dev ERC777Sender implementation.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        address tokenAddress = address(TrustedToken);
        require(msg.sender == tokenAddress, "Invalid token");

        uint256 fromBalance = TrustedToken.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = TrustedToken.balanceOf(to);

        emit TokensToSendCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            tokenAddress,
            fromBalance,
            toBalance
        );
    }

    /** 
     * @dev ERC777Reciever implementation.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        address tokenAddress = address(TrustedToken);
        require(msg.sender == tokenAddress, "Invalid token");

        uint256 fromBalance = TrustedToken.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = TrustedToken.balanceOf(to);

        emit TokensReceivedCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            tokenAddress,
            fromBalance,
            toBalance
        );
    }

    /** 
     * @dev ERC777Sender implementation.
     * @param account Transfer sender address
     */
    function senderFor(address account) public {
        _registerInterfaceForAddress(_TOKENS_SENDER_INTERFACE_HASH, account);
    }

    /** 
     * @dev ERC777Sender implementation.
     * @param sender Transfer sender address
     */
    function registerSender(address sender) public {
        _erc1820.setInterfaceImplementer(address(this), _TOKENS_SENDER_INTERFACE_HASH, sender);
    }

    /** 
     * @dev ERC777Recipient implementation.
     * @param account Transfer reciever address
     */
    function recipientFor(address account) public {
        _registerInterfaceForAddress(_TOKENS_RECIPIENT_INTERFACE_HASH, account);
    }
}
