import { arrayify } from "ethers/lib/utils";
import { getLottery, getSignOnChain, getVerifynOnChain } from "../src/utils/helper";
// import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployments, ethers } from "hardhat";
import hre from "hardhat";

const main = async () => {
    await deployments.fixture();

    let deployer: SignerWithAddress;
    [deployer] = await ethers.getSigners();

    const contract = await getLottery();
    // const LotteryDeployment = await deployments.get("Lottery");
    // const Lottery = await hre.ethers.getContractFactory("Lottery");
    // const contract = Lottery.attach("0xd8d32D69456646889E10E6E068F45D04E890AdD7");


    const timestamp = Math.floor(Date.now() / 1000);
    const ticket = [deployer.address, timestamp];

    const data = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], ticket);
    const dataHash = ethers.utils.keccak256(data);
    const message = arrayify(dataHash);

    const signature = await deployer.signMessage(message);

    console.log("signature: ", signature);

    const expectSigner = ethers.utils.verifyMessage(message, signature);
    console.log(" expect address ", expectSigner);

    // TEST 1: claimDailyTicket
    const resultVerifyOnchain = await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    await contract.claimDailyTicket(deployer.address, timestamp, message, signature);
    // const result = await resultVerifyOnchain.wait();
    // // console.log("Result verify on chain: ", result);

    // TEST 2: rollLuckyTicket
    // contract owner
    const owner = await contract.owner();
    console.log("owner: ", owner);
    console.log(deployer.address)
    let resultRollLuckyTicket = await contract.connect(deployer).rollLuckyTickets();
    console.log("Result roll lucky ticket: ", resultRollLuckyTicket);

    // TEST 3: getTotalLuckyNumbersByRound
    const totalLuckyNumbers = await contract.getTotalLuckyNumbersByRound(0);
    console.log("Total lucky numbers by round 0: ", totalLuckyNumbers);

    // TEST 4: checkUserClaimDailyTicket
    const checkUserClaimDailyTicket = await contract.checkUserClaimDailyTicket(deployer.address);
    console.log("User claimed daily ticket: ", checkUserClaimDailyTicket);

    // TEST 5: getTotalAttendeeByRound
    const totalAttendee = await contract.getTotalAttendeeByRound(0);
    console.log("Total attendee by round 0: ", totalAttendee);

    // TEST 6: getUserInfo
    const userInfo = await contract.getUserInfo(deployer.address);
    console.log("User info: ", userInfo);

    // TEST 7: setNumberRewardsOfRound
    const resultSetNumberRewardsOfRound = await contract.setNumberRewardsOfRound(4);
    console.log("Result set number rewards of round: ", resultSetNumberRewardsOfRound);
    resultRollLuckyTicket = await contract.connect(deployer).rollLuckyTickets();
    console.log("Result roll lucky ticket: ", resultRollLuckyTicket);

    // TEST 8: setNumberOfRounds
    const resultSetNumberOfRounds = await contract.setNumberOfRounds(7);
    console.log("Result set number of rounds: ", resultSetNumberOfRounds);


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });