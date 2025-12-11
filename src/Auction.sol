// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
/// @title Auction Smart Contract
/// @author tushar
/// @notice This contract allows  users to create auction and place bid on the particular auction in time-based manner or auction with a reserve price and bidding price.
contract Auction is Ownable{

enum GoodsNServices{
    SmartPhone,Car,Netflix,Haircut,MedicalConsultant
}
enum AuctionState{
    Active,
    Ended
}

struct AuctionInfo{
GoodsNServices goodsNservices;
address payable sellerAddress;
uint256 reservePrice;
address currentBidderAddress;
uint256 highestBid;
AuctionState state;
uint256 endTime;

}
struct AuctionWinner {
    address winner;
    uint256 finalWinningBid;
    bool finalized;
}


uint256 public constant CREATION_FEE = 0.01 ether;

mapping(address=>uint256) withdrawBidderRefunds;
mapping(uint256 => AuctionInfo) public auctions;
mapping(uint256 => mapping(address => uint256)) public bids;
mapping(uint256 => AuctionWinner) public auctionWinners;


uint256 public auctionId;
/// this constructor sets the owner of the contract by using Ownable base constructor and sets the initial auctionId
/// @param _initialOwner The onwer of the contract 
constructor(address _initialOwner)Ownable(_initialOwner){
auctionId=1;

}/**
/// @notice this function creates a new auction by taking item to auction on, the reserve price , and maximum time window the auction should exists
* and increament auctionId by 1 
/// @param _item its a a variant of enum GoodsNServices
/// @param _reservePrice its is a price that auctioner what to set the minimum price to place bid on his auction
/// @param _duration its a  maximum time the auctioner want  his contract to exists and a maximum time window in which bidder can place a bid
*/
function createAuction(GoodsNServices _item,uint256 _reservePrice,uint256 _duration) public payable{
    require(msg.value==CREATION_FEE,"Entry Fee Must match to Create Auction");
    require(msg.sender!=address(0),"seller Address cannot be zero");
    require(_reservePrice>0,"Enter valid reserve price 0 ");
    require(_duration > 0, "Duration must be greater than zero");
    
 auctions[auctionId]=AuctionInfo({
     goodsNservices:_item,
    sellerAddress:payable(msg.sender),
    reservePrice:_reservePrice,
    currentBidderAddress: address(0),
    highestBid:0,
    state:AuctionState.Active,
    endTime:block.timestamp+_duration
    });
    auctionId++;

}
/**
 * @notice this function allows bidder to place a bid owner and the auctioner can be bidder to a auctionId 
 * if highest bid is equal to zero than the bid is placed for the first time only at that time we check the 
 * the highest bid must be greater than reservePrice because after that if bidder bids again its bid should 
 * increase or gets added to the previous bid amount and after that bidder can bid any amount but it should 
 * be greater than zero now if another bidder comes and his bid is higher than the current highest amount 
 * he will be set as new currentbidder and highestbid amount and refund mappinhg will be populated by the
 * bidder who lost the bid and also the mapping of bids to auctionid and bidder address and to his bid amount
 * 
 * @param _auctionId auctionId to place bid on the auction id must exist to place bid successfully
 */


function placeBid(uint256 _auctionId) public payable{

AuctionInfo storage auction=auctions[_auctionId];

require(_auctionId>=1 && _auctionId < auctionId, "Invalid Auction ID");
require(auction.state == AuctionState.Active, "Auction is not active");
require(msg.value>0,"Bid amount must be greater than zero");
require(msg.sender!=auction.sellerAddress, "Seller cannot bid on their own auction");
require(block.timestamp < auction.endTime, "Auction has ended");
require(msg.sender!=owner(), "Owner cannot bid on auctions");
uint256 oldBid=bids[_auctionId][msg.sender];
uint256 newTotalBid=oldBid + msg.value;
// here if new bidder comes its oldbid will be zero because it does not exist in that mapping  
// and newtotalbid will be the value which will get compared with current highest bid amount

if (auction.highestBid == 0) {
    require(msg.value >= auction.reservePrice, "First bid must meet reserve price");
}else {
        
        require(newTotalBid > auction.highestBid, "Bid must exceed current highest");
    }

    
    // if control reaches here then the new total bid is greater than the highest bid and 
    //now withdrawing the old bidder mapping should be done
    // if comes here then new bidder is decided and now we will refund the old bidder amount

    
    if (auction.currentBidderAddress != address(0) && auction.currentBidderAddress != msg.sender) {
        withdrawBidderRefunds[auction.currentBidderAddress] += auction.highestBid;
    }
// populates the bids mapping because now the new bidder is decided
    bids[_auctionId][msg.sender] = newTotalBid;    
    auction.highestBid = newTotalBid;
    auction.currentBidderAddress = msg.sender;



}

/**
 * @notice this function is specially created to end auction if the time has elapsed or max time window of the 
 * particular auction is passed this function can only be called when auction state is active
 * if highest bid is greater than zeros than there will be a bidder who won the auction 
 * we set auction state to ended and transfer the bid amount of the bidder to seller adddress and bidder win the auction 
 * and auctionwinner struct is populed and auction state is updated to ended
 * @param _auctionId the auctionId to endAuction
 */
function endAuction(uint256 _auctionId) public{
    AuctionInfo storage auction=auctions[_auctionId];
require(block.timestamp>=auction.endTime);
require(_auctionId>=1 && _auctionId < auctionId, "Invalid Auction ID");
require(!auctionWinners[_auctionId].finalized, "Auction already ended");
require(auction.state == AuctionState.Active, "Auction is not active");

if(auction.highestBid>0){
    auction.state=AuctionState.Ended;
    auction.sellerAddress.transfer(auction.highestBid);
auctionWinners[_auctionId] = AuctionWinner({
        winner: auction.currentBidderAddress,
        finalWinningBid: auction.highestBid,
        finalized: true
    });
    
}

if(auction.highestBid==0){
    uint256 refundAmount = 0.005 ether;
(bool refunded,) = auction.sellerAddress.call{value: refundAmount}("");
require(refunded, "Refund failed");
}
auction.state = AuctionState.Ended;


}

/**
 * @notice this function allows any bidder that exists to in withdraw refund the amount of it will
 * be refunded to him
 */
function withdrawRefunds() public{
    
    uint256 amount=withdrawBidderRefunds[msg.sender];
    require(amount>0,"No funds To withdraw");
    withdrawBidderRefunds[msg.sender]=0;
    (bool refunded,)=payable(msg.sender).call{value:amount}("");
    require(refunded,"Refund failed");

}
/**
 * @notice this function takes bidder address and retunrs its refund amount 
 * @param _bidderAddress bidder addres to get amount of withdraw refund
 * @return uint256 this function returns the aomunt of bidder refund
 */
function getWithdrawBidderRefundsInfo(address _bidderAddress)external view returns(uint256){
    return withdrawBidderRefunds[_bidderAddress];
}
/**
 * @notice this function takes in auctionid and returns auctionwinner struct
 * @param _auctionId auction id to get auction winner struct
 * @return  AuctionWinner returns AuctionWinner struct
 */
function getAuctionWinner(uint256 _auctionId)external view returns(AuctionWinner memory) {
    return auctionWinners[_auctionId];
}

/**
 * @notice this function takes the auctionid and return auctioninfo struct against auctionid
 * @param _auctionId auctionid to get AuctionInfo of
 * @return AuctionInfo returns struct of this AuctionInfo Type
 */
function getAuctionInfo(uint256 _auctionId) external view returns (AuctionInfo memory) {
        
        return auctions[_auctionId];
    }
    
}