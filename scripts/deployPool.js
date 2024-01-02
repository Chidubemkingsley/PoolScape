const hre = require("hardhat");

async function main() {
  console.log("deploying...");
  const BUNNPool = await hre.ethers.getContractFactory(
    "BUNNPool"
  );
  const BUNNPool = await BUNNPool.deploy(
    "0xc4dCB5126a3AfEd129BC3668Ea19285A9f56D15D"
  );

  await BUNNPool.deployed();

  console.log(
    "BUNNPool loan contract deployed: ",
    BUNNPool.address
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});