require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/MJzVejGcvxPk3Ne1FYJFkpbXHEnGP6c_",
        blockNumber: 15704872,
      }
    }
  }
};
