// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

// import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 

library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

uint256 public constant MINIMIM_USD = 5e18;

address[] public funders;
mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

address public immutable i_owner;


    constructor() {
        i_owner = msg.sender;
    } 

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMIM_USD, "didn't send enough ETH"); //1e18 = 1 ETH = 18 = 1 * 10 **18
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
        return priceFeed.version();
        }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1) {
        address funder = funders[funderIndex];
        addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        //call
        (bool callSuccess, ) = payable (msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");

    }
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        

        if (msg.sender != i_owner) {revert NotOwner();}
        _;
 
}

receive() external payable { 
    fund();
}
fallback() external payable { 
    fund();
}

}