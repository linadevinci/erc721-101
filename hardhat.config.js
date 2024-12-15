require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
    },
    holesky: {
      url: "https://eth.holesky.g.alchemy.com/v2/" + process.env.infura,
      accounts: [process.env.privateKey]
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/" + process.env.infura,
      accounts: [process.env.privateKey],
      gasMultiplier: 3.6
    }
  },
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  etherscan: {
    apiKey: process.env.etherscan,
    customChains: [
      {
        network: "holesky",
        chainId: 17000,
        urls: {
          apiURL: "https://api-holesky.etherscan.io/api",
          browserURL: "https://holesky.etherscan.io"
        }
      }
    ]
  }
};
