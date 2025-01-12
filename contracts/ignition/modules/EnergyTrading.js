// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const hre = require("hardhat");

async function main() {
  const EnergyTrading = await hre.ethers.getContractFactory("EnergyTrading");
  const energyTrading = await EnergyTrading.deploy();

  await energyTrading.deployed();

  console.log("EnergyTrading contract deployed to:", energyTrading.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});