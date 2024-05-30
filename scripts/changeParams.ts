import * as dotenv from "dotenv";
import { ethers } from "hardhat";
import { Lottery__factory } from "../typechain-types";
dotenv.config();

enum PARAMETER {
    NUMBER_REWARDS_OF_ROUND,
    TOTAL_ROUNDS,
    REWARDS,
    CURRENT_ROUND,
    ROLL_TICKET_TIME,
    CLAIM_TICKET_TIME,
    ROUND_DURATION,
    CLAIM_DURATION
}

async function main() {
    const lottery: Lottery__factory = await ethers.getContractFactory("Lottery");
    const rd = lottery.attach(process.env.LOTTERY!)

    // const lotto = await rd.getLottery()
    // console.log(lotto)

    // const luckyTIcket = await rd.roundTimestamp(0)
    // console.log(luckyTIcket)

    // const luckyTIcket = await rd.getTotalTicketsByRound(2)
    // console.log(luckyTIcket)

    // const claimDuration = 17 * 3600 + 15 * 60
    // const rollTicketTime = 17 * 3600 + 15 * 60

    // const changeClaimDuration = await (await rd.setLottery(PARAMETER.CLAIM_DURATION, claimDuration)).wait()
    // console.log(changeClaimDuration.transactionHash)

    // const changeRollTicketTime = await (await rd.setLottery(PARAMETER.ROLL_TICKET_TIME, rollTicketTime)).wait()
    // console.log(changeRollTicketTime.transactionHash)

    // const rollLuckyTickets = await (await rd.rollLuckyTickets()).wait()
    // console.log(rollLuckyTickets.transactionHash)

    // const admin = await (await rd.setAdmin("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43")).wait()
    // console.log(admin.transactionHash)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

