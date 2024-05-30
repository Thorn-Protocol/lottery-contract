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

interface RoundTimestamp {
    roundStart: number
    roundEnd: number
    claimStart: number
    claimEnd: number
    rollTicketTime: number
    actualRollTime: number
}


async function main() {
    const lottery: Lottery__factory = await ethers.getContractFactory("Lottery");
    const rd = lottery.attach(process.env.LOTTERY!)

    const lotto = await rd.getLottery()
    console.log(lotto)

    // let round0: RoundTimestamp = {
    //     roundStart: 1717088400 - 10 * 3600 + 600,
    //     roundEnd: 1717090200 - 10 * 3600 + 600,
    //     claimStart: 1717088400 - 10 * 3600 + 600,
    //     claimEnd: 1717054200,
    //     rollTicketTime: 1717088400 - 10 * 3600 + 1200 + 600,
    //     actualRollTime: 0
    // }

    // const admin = await (await rd.changeRoundTimestamp(0, round0)).wait()
    // console.log(admin.transactionHash)

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

    // const admin = await (await rd.setAdmin("0xdE2Ad170EA4b11e0c6BDEc63a3F212E377ef1dc4")).wait()
    // console.log(admin.transactionHash)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

