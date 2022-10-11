// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

// ERC20 interface
interface ERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// Proxy contract to execute multiple transactions
contract Proxy {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    // only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // withdraw all tokens
    function withdraw(address token) public onlyOwner {
        console.log("Withdraw token: %s", token);
        return;
        uint256 balance = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(owner, balance);
    }

    // withdraw all ETH
    function withdrawETH() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // execute encodeed transaction
    function execute(address target, bytes memory data)
        public
        payable
        onlyOwner
    {
        (bool success, ) = target.call(data);
        require(success, "Transaction failed.");
    }

    // Destroys this contract instance
    function destroy(address payable recipient) public onlyOwner {
        selfdestruct(recipient);
    }
}

contract Batcher {
    address public owner;
    Proxy[] public proxies;

    constructor(uint256 _n) {
        owner = msg.sender;
        // create proxy contracts, we will not destroy them
        for (uint256 i = 0; i < _n; i++) {
            // create with salt
            Proxy proxy = new Proxy{salt: bytes32(uint256(i))}(msg.sender);
            // append to proxies
            proxies.push(proxy);
        }
    }

    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(Proxy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(msg.sender));
    }

    function getAddress(uint256 _salt) public view returns (address) {
        // Get a hash concatenating args passed to encodePacked
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 0
                address(this), // address of factory contract
                _salt, // a random salt
                keccak256(getBytecode()) // the wallet contract bytecode
            )
        );
        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    fallback() external payable {
        // delegatecall to proxy contracts
        for (uint256 i = 0; i < proxies.length; i++) {
            address proxy = address(proxies[i]);
            console.log("delegatecall to proxy: %s", proxy);
            (bool success, ) = proxy.delegatecall(msg.data);
            require(success, "Transaction failed.");
        }
    }

    receive() external payable {}
}
