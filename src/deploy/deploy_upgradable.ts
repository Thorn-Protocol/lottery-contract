import { ethers, upgrades } from "hardhat";

require("dotenv").config();

async function main () {
    const Lottery = await ethers.getContractFactory("Lottery");
    const lottery = await upgrades.deployProxy(Lottery, [
        8 * 3600
    ]);
    
    await lottery.deployed();
    console.log("Lottery deployed at: ", lottery.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  