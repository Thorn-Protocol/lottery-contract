// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

// import ecdsa library
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Lottery is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSA for bytes32;
    using Sapphire for bytes;
    using Math for uint;

    struct LotteryInformation {
        uint numberRewardsOfRound;
        uint totalRounds;
        uint rewards;
        uint currentRound;
        uint rollTicketTime;
        uint claimTicketTime;
        uint roundDuration;
        uint claimDuration;
    }

    struct LuckyTicket {
        uint luckyNumber;
        uint round;
        address userAddress;
        uint timestamp;
    }

    struct RoundTimestamp {
        uint roundStart;
        uint roundEnd;
        uint claimStart;
        uint claimEnd;
        uint rollTicketTime;
        uint actualRollTime;
    }

    mapping(uint => RoundTimestamp) public roundTimestamp;
    mapping(address => uint[]) public userLuckyNumber;
    mapping(uint => LuckyTicket) public dailyTickets;
    mapping(uint => uint) ticketCountByRound;
    mapping(uint => LuckyTicket[]) public roundReward;
    mapping(address => uint[]) public winnings;
    mapping(address => bool) public isAdmin;
    LotteryInformation lotto;
    uint randNonce;

    event eventClaimDailyTicket(
        address userAddress,
        uint256 timestamp,
        bytes signature,
        uint luckyNumber
    );
    event rollLuckyTicketsEvent(uint256[] luckyNumbers, uint round);
    event setLotteryEvent(
        LotteryInformation lotteryInformation,
        address sender
    );

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }

    function initialize(uint startTime) public initializer  {
        isAdmin[msg.sender] = true;
        lotto = LotteryInformation(
            5,
            20,
            50 * 10 ** 18,
            0,
            5 * 3600,
            4 * 3600,
            1 * 3600,
            1 * 3600
        );
        uint dayStart = block.timestamp - (block.timestamp % 86400);
        dayStart += startTime;
        roundTimestamp[0] = RoundTimestamp(
            dayStart,
            dayStart + lotto.roundDuration,
            dayStart + lotto.claimTicketTime,
            dayStart + lotto.claimTicketTime + lotto.claimDuration,
            dayStart + lotto.rollTicketTime,
            0
        );

        randNonce = 0;

        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    function setAdmin(address _newAdmin) public onlyOwner {
        isAdmin[_newAdmin] = true;
    }

    function toggleAdmin(address _admin) public onlyOwner {
        bool status = isAdmin[_admin];
        isAdmin[_admin] = !status;
    }

    function getRound() public returns (uint) {
        uint round = lotto.currentRound;
        uint roundEnd = roundTimestamp[round].roundEnd;

        if (roundEnd < block.timestamp){
            round += Math.ceilDiv(
                block.timestamp - roundEnd,
                lotto.roundDuration
            );
            startRound(round, false);
        }
        return round;
    }

    function startRound(uint round, bool force) internal returns (uint) {
        uint prevRound = lotto.currentRound;
        if (force) {
            roundTimestamp[round].roundStart = block.timestamp;
        }
        else {
            roundTimestamp[round].roundStart = roundTimestamp[prevRound].roundEnd;
        }
        roundTimestamp[round].roundEnd =
            roundTimestamp[round].roundStart +
            lotto.roundDuration;
        roundTimestamp[round].claimStart =
            roundTimestamp[round].roundStart +
            lotto.claimTicketTime;
        roundTimestamp[round].claimEnd =
            roundTimestamp[round].claimStart +
            lotto.claimDuration;
        roundTimestamp[round].rollTicketTime =
            roundTimestamp[round].roundStart +
            lotto.rollTicketTime;
        roundTimestamp[round].actualRollTime = 0;
        lotto.currentRound = round;
        return round;
    }

    
    function randNumber() internal returns (uint) {
        randNonce++;
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            );
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for (uint i = 0; i < b.length; i++) {
            number |= uint256(uint8(b[i])) << (8 * (b.length - (i + 1)));
        }
        return number;
    }


    function rollLuckyTickets() public onlyAdmin returns (uint[] memory) {
        uint round = getRound();
        uint currentTime = block.timestamp;

        require(currentTime >= roundTimestamp[round].rollTicketTime, "Not roll time yet");
        require(roundReward[round].length == 0, "Round already rolled");
        require(roundTimestamp[round].actualRollTime == 0, "Round already rolled");

        uint mod = ticketCountByRound[round];
        uint numberRewardsOfRound = lotto.numberRewardsOfRound;

        if (ticketCountByRound[round] < lotto.numberRewardsOfRound) {
            numberRewardsOfRound = ticketCountByRound[round];
        }

        uint[] memory luckyNumbers = new uint[](numberRewardsOfRound);
        uint8 count = 0;
        uint8 iteration = 0;
        while (count < numberRewardsOfRound && iteration < 20) {
            // // get random bytes
            // bytes memory rand = Sapphire.randomBytes(32, "");
            // uint luckyNumber = bytesToUint(rand);

            // mock random generator
            uint luckyNumber = randNumber();

            luckyNumber = luckyNumber % (mod + 1);
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
        }

        roundTimestamp[round].actualRollTime = currentTime;
        emit rollLuckyTicketsEvent(luckyNumbers, round);
        return luckyNumbers;
    }

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

    function setLottery(PARAMETER _parameter, uint _input) public onlyAdmin {
        if (_parameter == PARAMETER.NUMBER_REWARDS_OF_ROUND) {
            lotto.numberRewardsOfRound = _input;
        } else if (_parameter == PARAMETER.TOTAL_ROUNDS) {
            lotto.totalRounds = _input;
        } else if (_parameter == PARAMETER.REWARDS) {
            lotto.rewards = _input;
        } else if (_parameter == PARAMETER.CURRENT_ROUND) {
            startRound(_input, true);
            lotto.currentRound = _input;
        } else if (_parameter == PARAMETER.ROLL_TICKET_TIME) {
            lotto.rollTicketTime = _input;
        } else if (_parameter == PARAMETER.CLAIM_TICKET_TIME) {
            lotto.claimTicketTime = _input;
        } else if (_parameter == PARAMETER.ROUND_DURATION) {
            lotto.roundDuration = _input;
        } else if (_parameter == PARAMETER.CLAIM_DURATION) {
            lotto.claimDuration = _input;
        }
        emit setLotteryEvent(lotto, msg.sender);
    }

    function changeRoundTimestamp(uint round, RoundTimestamp memory _info) public onlyAdmin {
        roundTimestamp[round] = _info;
    }


    function getHash(
        address userAddress,
        uint256 timestamp
    ) public pure returns (bytes32) {
        bytes32 msgHash = keccak256(abi.encode(userAddress, timestamp));
        return msgHash;
    }

    function checkUserClaimDailyTicket(
        address userAddress
    ) public view returns (bool) {
        uint round = lotto.currentRound;
        uint numberTicket = userLuckyNumber[userAddress].length;
        if (numberTicket == 0) {
            return false;
        }
        LuckyTicket memory ticket = dailyTickets[numberTicket];
        if (ticket.round == round) {
            return true;
        }
        return false;
    }

    function claimDailyTicket(
        address userAddress,
        uint256 timestamp,
        bytes memory signature
    ) public nonReentrant returns (uint) {
        require(
            checkUserClaimDailyTicket(userAddress) == false,
            "User already claimed ticket today"
        );

        uint currentTime = block.timestamp;
        uint round = getRound();
        require(roundTimestamp[round].actualRollTime == 0, "Invalid ticket: Round already rolled");
        require(currentTime >= roundTimestamp[round].claimStart, "Invalid ticket: Claim ticket time has not started for this round" );
        require(currentTime < roundTimestamp[round].claimEnd, "Invalid ticket: Claim ticket time ended for this round");

        bytes32 dataHash = getHash(userAddress, timestamp);

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
        require(verified == true, "Invalid ticket: signer is not admin");

        // count from 1
        ticketCountByRound[round]++;
        uint luckyNumber = ticketCountByRound[round];
        LuckyTicket memory ticket = LuckyTicket(
            luckyNumber,
            round,
            userAddress,
            timestamp
        );
        dailyTickets[luckyNumber] = ticket;
        userLuckyNumber[userAddress].push(luckyNumber);

        emit eventClaimDailyTicket(
            userAddress,
            timestamp,
            signature,
            luckyNumber
        );
        return luckyNumber;

    }

    function getLottery() public view returns (LotteryInformation memory) {
        return lotto;
    }

    function getRollLuckyTicketsTime(uint round) public view returns (uint) {
        if (roundTimestamp[round].rollTicketTime != 0)
            return roundTimestamp[round].rollTicketTime;
        else {
            uint prevRound = lotto.currentRound;
            return roundTimestamp[prevRound].roundStart + lotto.roundDuration * (round - prevRound) + lotto.rollTicketTime;
        } 
    }

    function getTotalAttendeeByRound(uint round) public view returns (uint) {
        return ticketCountByRound[round];
    }

    function getTotalLuckyNumbersByRound(
        uint round
    ) public view returns (LuckyTicket[] memory) {
        if (roundReward[round].length > 0) return roundReward[round];
        return new LuckyTicket[](0);
    }

    function getLuckyTicketsByUser(
        address userAddress
    ) public view returns (LuckyTicket[] memory) {
        LuckyTicket[] memory result = new LuckyTicket[](
            userLuckyNumber[userAddress].length
        );
        for (uint i = 0; i < userLuckyNumber[userAddress].length; i++) {
            result[i] = dailyTickets[
                userLuckyNumber[userAddress][i]
            ];
        }
        return result;
    }

    function getCurrentRoundTicket(address userAddress) public view returns (uint) {
        uint round = lotto.currentRound;
        uint numberTicketClaimed = userLuckyNumber[userAddress].length;
        // latest ticket claimed
        if (numberTicketClaimed == 0) {
            return 0;
        }
        LuckyTicket memory luckyTicket = dailyTickets[
            userLuckyNumber[userAddress][numberTicketClaimed - 1]
        ];
        if (luckyTicket.round == round) return luckyTicket.luckyNumber;
        return 0;
    } 

    function getTotalTicketsByRound(
        uint round
    ) public view returns (LuckyTicket[] memory) {
        LuckyTicket[] memory tickets = new LuckyTicket[](
            ticketCountByRound[round]
        );
        for (uint i = 0; i < ticketCountByRound[round]; i++) {
            tickets[i] = dailyTickets[i + 1];
        }
        return tickets;
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
        latestTicketClaimTime = dailyTickets[
            userLuckyNumber[userAddress][numberTicketClaimed - 1]
        ].timestamp;
    }

}
