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
        uint currentRound;
        uint rollTicketTime;
        uint claimTicketTime;
    }

    struct LuckyTicket {
        uint luckyNumber;
        uint round;
        address userAddress;
        uint timestamp;
    }
    mapping(address => mapping(uint => LuckyTicket)) public dailyTicketsByUser;
    mapping(address => uint[]) public userLuckyNumber;
    // map to lucky number to retrieve winner, replaces luckynumber of previous round
    mapping(uint => LuckyTicket) public dailyTickets;
    mapping(uint => LuckyTicket[]) public roundReward;
    mapping(address => uint[]) public winnings;
    mapping(uint => uint) ticketCountByRound;
    mapping(address => bool) public isAdmin;
    uint randNonce = 0;
    LotteryInformation public lotteryInformation;

    event eventClaimDailyTicket(
        address userAddress,
        uint256 timestamp,
        bytes32 dataHash,
        bytes signature,
        uint luckyNumber
    );
    event rollLuckyTicketsEvent(uint256[] luckyNumbers, uint round);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }

    constructor() Ownable() {
        isAdmin[msg.sender] = true;
        lotteryInformation = LotteryInformation(
            block.timestamp - (block.timestamp % 86400),
            5,
            10,
            50 * 10 ** 18,
            0,
            11 * 3600 + 30 * 60,
            0
        );
    }

    using ECDSA for bytes32;
    using Sapphire for bytes;

    function setAdmin(address _newAdmin) public onlyOwner {
        isAdmin[_newAdmin] = true;
    }

    function toggleAdmin(address _admin) public onlyOwner {
        bool status = isAdmin[_admin];
        isAdmin[_admin] = !status;
    }

    // admin function
    function rollLuckyTickets() public onlyAdmin returns (uint[] memory) {
        uint round = lotteryInformation.currentRound;
        require(roundReward[round].length == 0, "Round already rolled");
        require(
            block.timestamp >= getRollLuckyTicketsTime(),
            "Not roll time yet"
        );
        uint numberRewardsOfRound = lotteryInformation.numberRewardsOfRound;
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
            // get random bytes
            bytes memory rand = Sapphire.randomBytes(32, "");
            uint luckyNumber = bytesToUint(rand);

            // // mock random generator
            // uint luckyNumber = randMod();

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
        lotteryInformation.currentRound++;
        emit rollLuckyTicketsEvent(luckyNumbers, round);
        return luckyNumbers;
    }

    enum PARAMETER {
        NUMBER_REWARDS_OF_ROUND,
        TOTAL_ROUNDS,
        REWARDS,
        ROLL_TICKET_TIME,
        CLAIM_TICKET_TIME
    }

    function setLottery(PARAMETER _parameter, uint _input) public onlyAdmin {
        if (_parameter == PARAMETER.NUMBER_REWARDS_OF_ROUND) {
            lotteryInformation.numberRewardsOfRound = _input;
        } else if (_parameter == PARAMETER.REWARDS) {
            lotteryInformation.rewards = _input;
        } else if (_parameter == PARAMETER.TOTAL_ROUNDS) {
            lotteryInformation.totalRounds = _input;
        } else if (_parameter == PARAMETER.ROLL_TICKET_TIME) {
            lotteryInformation.rollTicketTime = _input;
        } else if (_parameter == PARAMETER.CLAIM_TICKET_TIME) {
            lotteryInformation.claimTicketTime = _input;
        }
        console.log("New lottery");
        console.log("Epoch time: %s", lotteryInformation.epochTime);
        console.log(
            "Number rewards of round: %s",
            lotteryInformation.numberRewardsOfRound
        );
        console.log("Total rounds: %s", lotteryInformation.totalRounds);
        console.log("Rewards: %s", lotteryInformation.rewards);
        console.log("Current round: %s", lotteryInformation.currentRound);
        console.log("Roll ticket time: %s", lotteryInformation.rollTicketTime);
        console.log(
            "Claim ticket time: %s",
            lotteryInformation.claimTicketTime
        );
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

        require(
            checkUserClaimDailyTicket(userAddress) == false,
            "User already claimed ticket today"
        );

        // require before roll ticket time of today and after claim time of today
        uint rollTimeOfToday = getRollLuckyTicketsTime();
        console.log(timestamp);
        console.log(rollTimeOfToday);
        require(
            timestamp < rollTimeOfToday,
            "Invalid ticket: current round is over"
        );
        require(
            (timestamp % 86400) >= lotteryInformation.claimTicketTime,
            "Invalid ticket: claim ticket time has not started"
        );

        address recovered = (dataHash.toEthSignedMessageHash()).recover(
            signature
        );
        bool verified = false;
        if (isAdmin[recovered]) {
            verified = true;
        }
        recovered = dataHash.recover(signature);
        if (isAdmin[recovered]) {
            verified = true;
        }
        console.log("(Contract) Signer: %s", recovered);
        require(verified == true, "Invalid ticket: signer is not admin");

        uint round = lotteryInformation.currentRound;

        ticketCountByRound[round]++;
        uint luckyNumber = ticketCountByRound[round];
        LuckyTicket memory ticket = LuckyTicket(
            luckyNumber,
            round,
            userAddress,
            timestamp
        );
        dailyTicketsByUser[userAddress][luckyNumber] = ticket;
        dailyTickets[luckyNumber] = ticket;
        userLuckyNumber[userAddress].push(luckyNumber);
        console.log("Ticket counter: %s", luckyNumber);

        emit eventClaimDailyTicket(
            userAddress,
            timestamp,
            dataHash,
            signature,
            luckyNumber
        );
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

    function getLottery() public view returns (LotteryInformation memory) {
        return lotteryInformation;
    }

    function getRollLuckyTicketsTime() public view returns (uint) {
        // 18h30 utc of that day
        return
            block.timestamp -
            (block.timestamp % 86400) +
            lotteryInformation.rollTicketTime;
    }

    function getLuckyTicketsByUser(
        address userAddress
    ) public view returns (LuckyTicket[] memory) {
        LuckyTicket[] memory result = new LuckyTicket[](
            userLuckyNumber[userAddress].length
        );
        for (uint i = 0; i < userLuckyNumber[userAddress].length; i++) {
            result[i] = dailyTicketsByUser[userAddress][
                userLuckyNumber[userAddress][i]
            ];
        }
        return result;
    }

    function getTotalLuckyNumbersByRound(
        uint round
    ) public view returns (LuckyTicket[] memory) {
        if (roundReward[round].length > 0) return roundReward[round];
        return new LuckyTicket[](0);
    }

    function checkUserClaimDailyTicket(
        address userAddress
    ) public view returns (bool) {
        uint round = lotteryInformation.currentRound;
        uint numberTicket = userLuckyNumber[userAddress].length;
        console.log("Number ticket: %s", numberTicket);
        if (numberTicket == 0) {
            console.log("User not claimed ticket");
            return false;
        }
        LuckyTicket memory ticket = dailyTicketsByUser[userAddress][
            userLuckyNumber[userAddress][numberTicket - 1]
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
        numberTicketClaimed = userLuckyNumber[userAddress].length;
        numberWinnings = winnings[userAddress].length;
        // latest ticket claimed
        if (numberTicketClaimed == 0) {
            return (0, 0, 0);
        }
        latestTicketClaimTime = dailyTicketsByUser[userAddress][
            userLuckyNumber[userAddress][numberTicketClaimed - 1]
        ].timestamp;

        console.log("Number ticket claimed: %s", numberTicketClaimed);
        console.log("Number winnings: %s", numberWinnings);
        console.log("Latest ticket claimed: %s", latestTicketClaimTime);
    }
}
