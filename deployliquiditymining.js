const { network } = require{ "hardhat"}
const {  verify } = require ("../utils/verify")
require("dotenv").config()

module.exports = async ({ getNamedAccounts, deployments}) => {
    const { deployer } = await getNamedAccounts()
    const { deploy } = deployments
    const chainId = network.config.chainId

    console.log('yesssss');
    const liquiditymining = await deploy("liquiditymining", {
        from: deployer,
        args: [8143],
        log: true,
        waitConfirmations: network.config.blockconfirmation || 1,
     })
     if (chainId != 31337 && process-env.ETHERSCAN_API_KEY) {
        await verify{
            liquiditymining.address,
            [8143],
            "contracts/liquiditymining.sol:liquiditymining",
        }
     }
}

module.exports.tags = ["all", "nft"]
// npx hardhat deploy --network sepolia
