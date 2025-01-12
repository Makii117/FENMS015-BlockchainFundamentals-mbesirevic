const hre = require("hardhat");

async function main() {
  const EnergyTrading = await hre.ethers.getContractFactory("EnergyTrading");
  const energyTrading = await EnergyTrading.deploy();

  console.log("Deploying contract...");
  await energyTrading.waitForDeployment();

  // Use getAddress() to retrieve the deployed address
  const address = await energyTrading.getAddress();
  console.log("EnergyTrading contract deployed to:", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
