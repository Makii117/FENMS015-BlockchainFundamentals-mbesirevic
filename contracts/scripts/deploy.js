const hre = require("hardhat");

async function main() {
  const energyTrading = await hre.ethers.getContractFactory("EnergyTrading");
  const EnergyTrading = await energyTrading.deploy();

  console.log("Deploying contract...");
  await EnergyTrading.waitForDeployment();

  // Use getAddress() to retrieve the deployed address
  const address = await EnergyTrading.getAddress();
  console.log("EnergyTrading contract deployed to:", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
