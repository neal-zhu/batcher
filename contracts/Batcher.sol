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
        uint256 balance = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(tx.origin, balance);
    }

    // withdraw all ETH
    function withdrawETH() public onlyOwner {
        payable(tx.origin).transfer(address(this).balance);
    }

    // execute encodeed transaction
    function execute(address target, bytes memory data)
        public
        payable
        onlyOwner
    {
        //(bool success, ) = target.call(data);
        //require(success, "Transaction failed.");
        _call(target, data);
    }

    // Destroys this contract instance
    function destroy(address payable recipient) public onlyOwner {
        selfdestruct(recipient);
    }

    function _call(address target, bytes memory data)
        internal 
        onlyOwner
        returns (bytes memory)
    {
        // implementation with assembly
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let succeeded := call(
                gas(),
                target,
                callvalue(),
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let size := returndatasize()

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
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
            Proxy proxy = new Proxy{salt: bytes32(uint256(i))}((address(this)));
            // append to proxies
            proxies.push(proxy);
        }
    }

    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(Proxy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(address(this)));
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
        require(owner == msg.sender, "Only owner can call this function.");
        // delegatecall to proxy contracts
        uint length = proxies.length;
        for (uint256 i = 0; i < length; i++) {
            address proxy = address(proxies[i]);
            //(bool success, ) = proxy.call(msg.data);
            //require(success, "Transaction failed.");
            _call(proxy, msg.data);
        }
    }

    receive() external payable {}

    function _call(address target, bytes memory data)
        internal 
    {
        // implementation with assembly
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let succeeded := call(
                gas(),
                target,
                callvalue(),
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let size := returndatasize()

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(ptr, size)
                }
        }
    }
}
