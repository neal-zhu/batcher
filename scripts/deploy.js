// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;

  const account =  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
  let signer = await hre.ethers.provider.getSigner(account);

  const Batcher = await hre.ethers.getContractFactory("Batcher", signer);
  const batcher = await Batcher.deploy(10);

  await batcher.deployed();
  // encode execute function call
  let abi = [
    "function execute(address, bytes) payable",
    "function withdraw(address)",
    "function test(address)",
  ];
  let iface = new hre.ethers.utils.Interface(abi);
  //let executeFunctionCall = iface.encodeFunctionData("execute", [batcher.address, iface.encodeFunctionData("test", [account])]);
  //await signer.sendTransaction({to: batcher.address, value: hre.ethers.utils.parseEther("1.0"), data: executeFunctionCall, gasLimit: 10000000});
  executeFunctionCall = iface.encodeFunctionData("withdraw", ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"]);
  //await signer.sendTransaction({to: batcher.address, data: executeFunctionCall, gasLimit: 10000000});
  await signer.sendTransaction({to: batcher.address, data: executeFunctionCall,});
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
