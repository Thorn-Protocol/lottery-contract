
import { ethers, run, upgrades } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function upgrade() {
    const lotteryFactory= await ethers.getContractFactory("Lottery");

    const lotteryContract = await upgrades.upgradeProxy(
        process.env.LOTTERY!,
        lotteryFactory
      );
    
    console.log("Lottery deploy at: ", lotteryContract.address);
        
    console.log("Success upgrade");
}

async function main() {
    await upgrade();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
