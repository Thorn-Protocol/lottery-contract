// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

// import ecdsa library
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import {SignatureRSV, EthereumUtils} from "@oasisprotocol/sapphire-contracts/contracts/EthereumUtils.sol";

import "hardhat/console.sol";

contract Lottery is Ownable {
    struct LotteryInformation {
        uint epochTime;
        uint numberRewardsOfRound;
        uint totalRounds;
        uint rewards;
    }

    struct LuckyTicket {
        uint luckyNumber;
        uint round;
        address userAddress;
        uint timestamp;
    }
    mapping(address => LuckyTicket[]) public dailyTicketsByUser;
    // map to lucky number to retrieve winner, replaces luckynumber of previous round
    mapping(uint => LuckyTicket) public dailyTickets;
    mapping(uint => LuckyTicket[]) public roundReward;
    mapping(address => uint[]) public winnings;
    uint public ticketCounter;
    uint epochTime;
    uint currentRound;
    uint[] ticketCountByRound;
    address public adminAddress;
    uint totalRounds;
    uint numberRewardsOfRound;
    uint rewards;
    uint randNonce = 0;
    LotteryInformation lotteryInformation;

    event eventClaimDailyTicket(
        address userAddress,
        uint256 timestamp,
        bytes32 dataHash,
        bytes signature
    );
    event rollLuckyTicketsEvent(uint256[] luckyNumbers);

    using ECDSA for bytes32;
    using Sapphire for bytes;

    constructor() Ownable() {
        epochTime =
            block.timestamp -
            (block.timestamp % 86400) +
            18 *
            3600 +
            30 *
            60 -
            7 *
            3600;
        ticketCounter = 0;
        currentRound = 0;
        totalRounds = 10;
        ticketCountByRound = new uint[](totalRounds);
        adminAddress = msg.sender;
        numberRewardsOfRound = 5;
        rewards = 50;
        lotteryInformation = LotteryInformation(epochTime, numberRewardsOfRound, totalRounds, rewards);
    }

    modifier onlyAdmin() {
        console.log("Adminn: %s", adminAddress);
        console.log("Sender: %s", msg.sender);
        require(
            msg.sender == adminAddress,
            "Only admin can call this function"
        );
        _;
    }

    function randMod() internal returns (uint) {
        randNonce++;
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            );
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        adminAddress = _newAdmin;
    }

    function getHash(
        address userAddress,
        uint256 timestamp
    ) public pure returns (bytes32) {
        bytes32 msgHash = keccak256(abi.encode(userAddress, timestamp));
        return msgHash;
    }

    // user function
    /// @notice user claim ticket to get lucky number
    /// @param userAddress address of user
    /// @param timestamp timestamp of user claim ticket
    /// @param dataHash hash of user address and timestamp
    /// @param signature a string of ecdsa signature of user address and timestamp, signed by admin's public key
    function claimDailyTicket(
        address userAddress,
        uint256 timestamp,
        bytes32 dataHash,
        bytes memory signature
    ) public returns (uint) {
        // bytes32 dataHash = getHash(userAddress, timestamp);

        require (checkUserClaimDailyTicket(userAddress) == false, "User already claimed ticket today");

        address recovered = (dataHash.toEthSignedMessageHash()).recover(
            signature
        );
        bool verified = false;
        if (adminAddress == recovered) {
            verified = true;
        }
        recovered = dataHash.recover(signature);
        if (adminAddress == recovered) {
            verified = true;
        }
        console.log("(Contract) Signer: %s", recovered);
        console.log("(Contract) Admin: %s", adminAddress);
        require(verified == true, "Invalid ticket: signer is not admin");

        // check timestamp on ticket
        console.log(timestamp);
        uint rollTimeOfToday = getRollLuckyTicketsTime();
        require(
            timestamp > rollTimeOfToday - 86400,
            "Invalid ticket: timestamp is from previous round"
        );
        require(
            timestamp <= rollTimeOfToday,
            "Invalid ticket: timestamp is from next round"
        );

        uint round = getRound();

        ticketCounter++;
        ticketCountByRound[round]++;
        uint luckyNumber = ticketCountByRound[round];
        LuckyTicket memory ticket = LuckyTicket(
            luckyNumber,
            round,
            userAddress,
            timestamp
        );
        dailyTicketsByUser[userAddress].push(ticket);
        dailyTickets[luckyNumber] = ticket;
        console.log("Ticket counter: %s", luckyNumber);
        return luckyNumber;
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        console.log("Length: %s", b.length);
        for (uint i = 0; i < b.length; i++) {
            console.log("Byte: %s", uint8(b[i]));
            number |= uint256(uint8(b[i])) << (8 * (b.length - (i + 1)));
        }
        return number;
    }

    // admin function
    function rollLuckyTickets() public onlyAdmin returns (uint[] memory) {
        uint round = getRound();
        require(
            ticketCountByRound[round] > numberRewardsOfRound,
            "Not enough tickets to roll"
        );
        // use oasis sapphire random bytes function
        uint[] memory luckyNumbers = new uint[](numberRewardsOfRound);
        uint8 count = 0;
        uint8 iteration = 0;
        uint mod = ticketCountByRound[round];
        while (count < numberRewardsOfRound && iteration < 20) {
            // // get random bytes
            // bytes memory rand = Sapphire.randomBytes(32, "");
            // uint luckyNumber = bytesToUint(rand);

            // mock random generator
            uint luckyNumber = randMod();

            luckyNumber = luckyNumber % mod;
            bool skip = false;
            // if number already exists, skip
            for (uint i = 0; i < count; i++) {
                if (luckyNumbers[i] == luckyNumber) {
                    skip = true;
                    break;
                }
            }
            if (skip) {
                continue;
            }

            // find winner
            address winner = dailyTickets[luckyNumber].userAddress;
            if (winner == address(0)) {
                continue;
            }

            luckyNumbers[count] = luckyNumber;
            count++;
            iteration++;

            roundReward[round].push(dailyTickets[luckyNumber]);
            winnings[winner].push(luckyNumber);

            console.log("Lucky number %s", luckyNumber);
            console.log("Winner %s", winner);
        }
        emit rollLuckyTicketsEvent(luckyNumbers);
        return luckyNumbers;
    }

    enum PARAMETER {
        EPOCH_TIME,
        NUMBER_REWARDS_OF_ROUND,
        TOTAL_ROUNDS,
        REWARDS
    }

    function setLottery(PARAMETER _parameter, uint _input) public onlyAdmin
 {
        if (_parameter == PARAMETER.EPOCH_TIME) {
            lotteryInformation.epochTime = _input;
        } else if (_parameter == PARAMETER.NUMBER_REWARDS_OF_ROUND) {
            lotteryInformation.numberRewardsOfRound = _input;
        } else if (_parameter == PARAMETER.TOTAL_ROUNDS) {
            lotteryInformation.totalRounds = _input;
            // assign new array
            uint[] memory newTicketCountByRound = new uint[](totalRounds);
            if (totalRounds > ticketCountByRound.length) {
                for (uint i = 0; i < ticketCountByRound.length; i++) {
                    newTicketCountByRound[i] = ticketCountByRound[i];
                }
            } else {
                for (uint i = 0; i < totalRounds; i++) {
                    newTicketCountByRound[i] = ticketCountByRound[i];
                }
            }
            ticketCountByRound = newTicketCountByRound;
            for (uint i = 0; i < ticketCountByRound.length; i++) {
                console.log("Ticket count by round: %s", ticketCountByRound[i]);
            }
        } else if (_parameter == PARAMETER.REWARDS) {
            rewards = _input;
        }
        console.log("New lottery");
        console.log("Epoch time: %s", lotteryInformation.epochTime);
        console.log("Number rewards of round: %s", lotteryInformation.numberRewardsOfRound);
        console.log("Total rounds: %s", lotteryInformation.totalRounds);
        console.log("Rewards: %s", lotteryInformation.rewards);

    }

    function getLottery() public view returns (LotteryInformation memory) {
        return LotteryInformation(epochTime, numberRewardsOfRound, totalRounds, rewards);
    }

    function getRollLuckyTicketsTime() public view returns (uint) {
        // 18h30 utc of that day
        return
            block.timestamp - (block.timestamp % 86400) + 18 * 3600 + 30 * 60;
    }

    function getRound() public returns (uint round) {
        console.log("Block time: %s", block.timestamp);
        console.log("Epoch time: %s", epochTime);
        if (block.timestamp < epochTime) {
            round = 0;
        } else {
            uint rollTimeOfToday = getRollLuckyTicketsTime();
            round = (rollTimeOfToday - epochTime) / 86400;
            if (block.timestamp < rollTimeOfToday) round--;
        }
        currentRound = round;
        console.log("Current round: %s", currentRound);
    }

    function getLuckyTicketsByUser(
        address userAddress
    ) public view returns (LuckyTicket[] memory) {
        return dailyTicketsByUser[userAddress];
    }

    function getTotalLuckyNumbersByRound(
        uint round
    ) public view returns (LuckyTicket[] memory) {
        if (roundReward[round].length > 0) return roundReward[round];
        return new LuckyTicket[](0);
    }

    function checkUserClaimDailyTicket(
        address userAddress
    ) public returns (bool) {
        uint round = getRound();
        uint numberTicket = dailyTicketsByUser[userAddress].length;
        console.log("Number ticket: %s", numberTicket);
        if (numberTicket == 0) {
            console.log("User not claimed ticket");
            return false;
        }
        LuckyTicket memory ticket = dailyTicketsByUser[userAddress][
            numberTicket - 1
        ];
        if (ticket.round == round) {
            console.log("User claimed ticket");
            return true;
        }
        console.log("User not claimed ticket");
        return false;
    }

    function getTotalAttendeeByRound(uint round) public view returns (uint) {
        return ticketCountByRound[round];
    }

    function getUserInfo(
        address userAddress
    )
        public
        view
        returns (
            uint numberTicketClaimed,
            uint numberWinnings,
            uint latestTicketClaimTime
        )
    {
        numberTicketClaimed = dailyTicketsByUser[userAddress].length;
        numberWinnings = winnings[userAddress].length;
        // latest ticket claimed
        latestTicketClaimTime = dailyTicketsByUser[userAddress][
            numberTicketClaimed - 1
        ].timestamp;

        console.log("Number ticket claimed: %s", numberTicketClaimed);
        console.log("Number winnings: %s", numberWinnings);
        console.log("Latest ticket claimed: %s", latestTicketClaimTime);
    }
}
