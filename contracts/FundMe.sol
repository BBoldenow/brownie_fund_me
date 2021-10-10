// SPDX-License-Identifier: MIT

// Always have to name the solidity version
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // No longer needed for verion 0.8 and above
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public PriceFeed;

    constructor(address priceFeed) public {
        PriceFeed = AggregatorV3Interface(priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // double multiply raises x^y
        uint256 minimumUSD = 50 * 10**18;

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        // msg.sender and msg.value are keywords for every contract call & every transaction
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        // This transfer can send ETH from one address to another
        // 'this' keyword refers to the contract
        msg.sender.transfer(address(this).balance);

        for (uint256 i = 0; i < funders.length; ++i) {
            addressToAmountFunded[funders[i]] = 0;
        }

        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        return PriceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // We can ignore some of the multiple returns by just leaving them blank with commas
        (, int256 answer, , , ) = PriceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);

        // wherever your underscore is is where the rest of the code will run
        _;
    }
}
