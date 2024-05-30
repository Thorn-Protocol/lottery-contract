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
    const rd = lottery.attach(process.env.LOTTERY_TEST!)

    const lotto = await rd.roundTimestamp(0)
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

    // const admin = await (await rd.setAdmin("0x595622cBd0Fc4727DF476a1172AdA30A9dDf8F43")).wait()
    // console.log(admin.transactionHash)

    const a = {
        "address": "0x72e03B6E7AB9DdFe1699B65B8A46A3Cf30092020",
        "timestamp": 1717074573,
        "signature": "0x80d0cbe79e692c1f6bdde5aa0a4f53fb101c9520b8c9ffb13e709aca8a1400e13f6a31ce75032fb4ab0b83f23e919eee5577d903deee728511ad6da9ad4c57001c",
        "data": [
          "0x72e03B6E7AB9DdFe1699B65B8A46A3Cf30092020",
          1717074573
        ],
        "dataHash": "0x564a6ee5f6dc9a296be81a76dd49a74a3da9724c938511667c619ad6ac865e7c"
      }
    const admin = await (await rd.claimDailyTicket(
        a.address,
        a.timestamp,
        a.signature
    )).wait()
    console.log(admin.transactionHash)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

