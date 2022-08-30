pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RandomWinnerGame is VRFConsumerBaseV2, Ownable {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
  uint64 s_subscriptionId;
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint256 public randomResult;
  address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
  address link = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
  bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
  uint32 callbackGasLimit = 300000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;

    mapping(uint => address) public resultsWinner;
    mapping(uint => uint256) public resultsAmount;
    address[] public players;
    uint8 maxPlayers;
    bool public gameStarted;
    uint256 entryFee;
    uint256 public gameId;
    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    event PlayerJoined(uint256 gameId, address player);
    event GameEnded(uint256 gameId, address winner,uint256 requestId);
    address s_owner;

    struct Result{
    uint result_id;
    address result_wallet;
    uint256 result_prize;
    uint256 result_date;
    uint result_number;
  }
  mapping (uint => Result) public results;
  uint public resultCount;

     constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    gameStarted = false;
  }

    function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
        require(!gameStarted, "Game is currently running");
        delete players;
        maxPlayers = _maxPlayers;
        gameStarted = true;
        entryFee = _entryFee;
        gameId += 1;
        emit GameStarted(gameId, maxPlayers, entryFee);
    }

    function requestRandomWords() private {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

    function joinGame() public payable {
        require(gameStarted, "Game has not been started yet");
        require(msg.value == entryFee, "Value sent is not equal to entryFee");
        require(players.length < maxPlayers, "Game is full");
        players.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);
        if(players.length == maxPlayers) {
            requestRandomWords();
        }
    }



    function fulfillRandomWords (
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    randomResult = randomWords[0] % players.length;
    address winner = players[randomResult];
    emit GameEnded(gameId, winner,requestId);
    gameStarted = false;
    sendPrize(winner,(maxPlayers*entryFee*90/100));
    uint256 toplam = maxPlayers*entryFee*90/100;
    uint256 zaman = block.timestamp;
    addResult(winner,toplam,zaman,randomResult);
  }

function addResult(address _result_wallet,uint256 _result_prize,uint256 _result_date,uint _result_number) public {
    results[resultCount] = Result(resultCount,_result_wallet,_result_prize,_result_date,_result_number);
    resultCount++;
}

function getResult(uint getirilcek) public view returns (uint[] memory, address[] memory,uint256[]
  memory,uint256[] memory,uint[] memory){
      uint[]    memory id_ = new uint[](1);
      address[]  memory wallet_ = new address[](1);
      uint256[]    memory prize_ = new uint256[](1);
      uint256[]    memory date_ = new uint256[](1);
      uint[]    memory number_ = new uint[](1);

         Result storage results_ = results[getirilcek];
          id_[getirilcek] = results_.result_id;
          wallet_[getirilcek] = results_.result_wallet;
          prize_[getirilcek] = results_.result_prize;
          date_[getirilcek] = results_.result_date;
          number_[getirilcek] = results_.result_number;

      return (id_, wallet_,prize_,date_,number_);
  }

function addWinnerResult(address theWinner,uint theGameId) private {
      resultsWinner[theGameId-1] = theWinner;
}
function addAmountResult(uint256 theAmount,uint theGameId) private {
      resultsAmount[theGameId-1] = theAmount;
}

function sendPrize(address adres,uint256 ucret) private {
      payable(adres).transfer(ucret);
}
function getBalance() public view returns (uint256) {
    return address(this).balance;
}

function getPlayers() public view returns (uint256) {
    return players.length;
}

function getMaxPlayers() public view returns (uint256) {
    return maxPlayers;
}

function getTicketFee() public view returns (uint256) {
    return entryFee;
}

function getGameStatus() public view returns (bool) {
    return gameStarted;
}

function getResultsWinner(uint theid) public view returns (address) {
    return resultsWinner[theid];
}

function getPlayerTickets(address thewallet) public view returns (string memory) {
    string memory numbers;
    for (uint i=0; i<players.length; i++) {
            if (players[i] == thewallet) {
              if (i==0) {
                numbers=Strings.toString(i);
              } else {
                numbers=string.concat(numbers,',',Strings.toString(i));
              }
            }
        }
        return numbers;
}

function withdraw() public onlyOwner {
  payable(msg.sender).transfer(address(this).balance);
}
    receive() external payable {}
    fallback() external payable {}
}
