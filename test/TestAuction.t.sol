// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import "../script/DeployScript.s.sol";
import {Test,console} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";
import {DeployScript} from "../script/DeployScript.s.sol";
contract TestAuction is Test{
    DeployScript deployScript;
    Auction auction;
    address seller=vm.addr(0x1);
    address bidder1=vm.addr(0x2);
    address bidder2=vm.addr(0x3);
    address bidder3=vm.addr(0x4);

    function setUp() public
    {

        deployScript=new DeployScript();
        auction=deployScript.run();
        vm.deal(seller,1 ether);
        vm.deal(bidder1,10 ether);
        vm.deal(bidder2,10 ether);
        vm.deal(bidder3,10 ether);
    }



    function test_Auction() external{
        vm.deal(address(this), 1 ether);
    auction.createAuction{value: 0.01 ether}(Auction.GoodsNServices.Netflix,1 ether, 1000);


    Auction.AuctionInfo memory auctionInfo = auction.getAuctionInfo(1);

    console.log("Goods:", uint256(auctionInfo.goodsNservices));
    console.log("Seller:", auctionInfo.sellerAddress);
    console.log("Reserve Price:", auctionInfo.reservePrice);
    console.log("End Time:", auctionInfo.endTime);

    assertEq(auctionInfo.reservePrice, 1 ether);
    }
    
    function test_firstBid()external{
        vm.prank(seller);
        auction.createAuction{value:0.01 ether}(Auction.GoodsNServices.Haircut,2 ether,2 minutes);
        Auction.AuctionInfo memory auctionInfo=auction.getAuctionInfo(1);
        console.log("Goods and service: ", uint256(auctionInfo.goodsNservices));
    console.log("Seller: ", auctionInfo.sellerAddress);
    console.log("Reserve Price: " , auctionInfo.reservePrice);
    console.log("End Time: ", auctionInfo.endTime);
    
    vm.prank(bidder1);
    vm.expectRevert();
    auction.placeBid{value:1 ether}(1);
    auctionInfo=auction.getAuctionInfo(1);
    


    vm.prank(bidder1);
    auction.placeBid{value:2 ether}(1);
    uint256 oldHighestBid=auctionInfo.highestBid;
    
    vm.prank(bidder1); //testing recurring bids
    auction.placeBid{value:0.01 ether}(1);
    auctionInfo=auction.getAuctionInfo(1);
    uint256 currentHighestBid=auctionInfo.highestBid;
    address bidder1Address=auctionInfo.currentBidderAddress;
    assert(oldHighestBid<currentHighestBid);
    console.log("Bidder1 bid again",currentHighestBid);
    uint256 endtime=auctionInfo.endTime;
    console.log("endtime: ",endtime);

    vm.prank(bidder2);
    auction.placeBid{value :2.2 ether}(1);

    auctionInfo=auction.getAuctionInfo(1);
    
     currentHighestBid=auctionInfo.highestBid;
     console.log("current highest bid: ",currentHighestBid);
    
    vm.prank(bidder2);
    vm.warp(block.timestamp+(2*60));// cant bid after time elapsed
    vm.expectRevert();
    auction.placeBid{value:3 ether}(1);

//bidder1 address should go in the withdraw refunds mapping
    uint256 bidder1WithdrawAmount=auction.getWithdrawBidderRefundsInfo(bidder1Address);
    console.log(bidder1WithdrawAmount);




    }
    function test_endAuctionAandWithdrawRefunds() external{
        
        vm.prank(seller);
        auction.createAuction{value:0.01 ether}(Auction.GoodsNServices.Haircut,2 ether,2 minutes);
        Auction.AuctionInfo memory auctionInfo=auction.getAuctionInfo(1);
        console.log("Goods and service: ", uint256(auctionInfo.goodsNservices));
    console.log("Seller: ", auctionInfo.sellerAddress);
    console.log("Reserve Price: " , auctionInfo.reservePrice);
    console.log("End Time: ", auctionInfo.endTime);
    
    vm.prank(bidder1);
    vm.expectRevert();
    auction.placeBid{value:1 ether}(1);
    auctionInfo=auction.getAuctionInfo(1);
    


    vm.prank(bidder1);
    auction.placeBid{value:2 ether}(1);
    uint256 oldHighestBid=auctionInfo.highestBid;
    console.log("AuctionId after first auction",auction.auctionId());
    
    vm.prank(bidder1); //testing recurring bids
    auction.placeBid{value:0.01 ether}(1);
    auctionInfo=auction.getAuctionInfo(1);
    uint256 currentHighestBid=auctionInfo.highestBid;
    address bidder1Address=auctionInfo.currentBidderAddress;
    assert(oldHighestBid<currentHighestBid);
    console.log("Bidder1 bid again",currentHighestBid);
    uint256 endtime=auctionInfo.endTime;
    console.log("endtime: ",endtime);

    vm.prank(bidder2);
    auction.placeBid{value :2.2 ether}(1);

    auctionInfo=auction.getAuctionInfo(1);
    address bidder2Address=auctionInfo.currentBidderAddress;
    
     currentHighestBid=auctionInfo.highestBid;
     console.log("current highest bid: ",currentHighestBid);
    
    vm.prank(bidder3);

    auction.placeBid{value:3 ether}(1);

    uint256 bidder1WithdrawAmount=auction.getWithdrawBidderRefundsInfo(bidder1Address);
    console.log(bidder1WithdrawAmount);
uint256 bidder2WithdrawAmount=auction.getWithdrawBidderRefundsInfo(bidder2Address);
    console.log(bidder2WithdrawAmount);
    vm.expectRevert();
    auction.endAuction(1);
    
    uint256 currentAuctionContractBalance=address(auction).balance;
    console.log("current contract balance",currentAuctionContractBalance);
    vm.warp(block.timestamp+(2*60));
    auction.endAuction(1);
    uint256 endingAuctionContractBalance=address(auction).balance;
    console.log("current contract balance",endingAuctionContractBalance);

    auctionInfo=auction.getAuctionInfo(1);
assert(auctionInfo.state == Auction.AuctionState.Ended);

assert(auctionInfo.currentBidderAddress == bidder3);

assert(auctionInfo.highestBid == 3 ether);

assert(auction.getWithdrawBidderRefundsInfo(bidder1) == 2.01 ether);

assert(auction.getWithdrawBidderRefundsInfo(bidder2) == 2.2 ether);

assert(auction.getWithdrawBidderRefundsInfo(bidder3) == 0);
    
    
    vm.prank(bidder1);
    auction.withdrawRefunds();

    vm.prank(bidder2);
    auction.withdrawRefunds();
    
uint256 auctionContractBalanceAfterWithdrawRefunds=address(auction).balance;
    console.log("current contract balance after withdraw refunds: ",auctionContractBalanceAfterWithdrawRefunds);

    assertEq(auction.getWithdrawBidderRefundsInfo(bidder1), 0);
assertEq(auction.getWithdrawBidderRefundsInfo(bidder2), 0);
Auction.AuctionWinner memory auctionWinner=auction.getAuctionWinner(1);
console.log("Auction winner is: ",auctionWinner.winner);
console.log("Auction final winning bid: ",auctionWinner.finalWinningBid);
console.log("auction is finalised: ",auctionWinner.finalized);
}

    

}