require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("hardhat-deploy");

/** @type import ('hardhat/config').HardhatUserConfig */

const SEPOLIA_RPC = Process.env.SEPOLIA_RPC_URL;
const PRIV_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    Sepolia: {
      URL: SEPOLIA_RPC,
      accounts:[
        PRIV_KEY,
      ]
      ChainId: 11155111,
      blockConfirmations: 6,
    }
  },
  Solidity: "0.8.20",
  etherscan: {
apiKey: ETHERSCAN_API_KEY,
},
namedAccounts: {
  deployer: {
    default: 0,
    11155111:0, 
  }
}
}