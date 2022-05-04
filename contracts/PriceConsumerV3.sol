// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "hardhat/console.sol";

contract PriceConsumerV3 {
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;

    uint256 public deviationThreshold = 1;
    /**
     * Network:  mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    function data() external view returns(uint80, int, uint) {
        uint80 roundId;
        int price;
        uint timeStamp;
        (roundId, price,, timeStamp,) = priceFeed.latestRoundData();
        return (roundId, price, timeStamp);
    }

    function loop() public view returns(int, int, uint) {
        uint80 roundId;
        int price;
        uint timeStamp;
        bool flag = false;

        (roundId, price,, timeStamp,) = priceFeed.latestRoundData();

        timeStamp -= 86400; // 1 day = 86400

        while (flag == false) {
            int priceOld;
            uint timeStampOld;
            roundId -= 1;
            (,priceOld,, timeStampOld,) = priceFeed.getRoundData(roundId);

            if (timeStampOld < timeStamp) {
                flag = true;
                return (price, priceOld, timeStampOld);
            }
        }
        return (0, 0, 0);
    }

    function loop2() public view returns(uint256, int sign) {
        uint80 roundId;
        int price;
        int priceOld;
        uint timeStamp;
        uint256 deviation;
        uint256 priceDifference;

        (roundId, price,, timeStamp,) = priceFeed.latestRoundData();

        uint timeStampOld = timeStamp;
        timeStamp -= 86400; // 1 day = 86400

/*         while (flag == false) {
            uint timeStampOld;
            roundId -= 1;
            (,priceOld,, timeStampOld,) = priceFeed.getRoundData(roundId);

            if (timeStampOld < timeStamp) {
                flag = true;
                break;
            }
        } */

        while (timeStampOld > timeStamp) {
            roundId -= 1;
            (,priceOld,, timeStampOld,) = priceFeed.getRoundData(roundId);
        }

        if(price == priceOld) {
            return (0, 0);
        }

        if(price > priceOld) {
            priceDifference = uint256(price - priceOld);
            deviation = priceDifference.mul(100).div(uint256(priceOld));
            return (deviation, 0);
        }

        priceDifference = uint256(priceOld - price);
        deviation = priceDifference.mul(100).div(uint256(priceOld));
        return (deviation, 1);
    }

    function loop3() public view returns(bool) {
        uint80 roundId;
        int price;
        int priceOld;
        uint timeStamp;
        uint256 deviation;
        uint256 priceDifference;

        (roundId, price,, timeStamp,) = priceFeed.latestRoundData();

        uint timeStampOld = timeStamp;
        timeStamp -= 86400; // 1 day = 86400
        console.log("here");
        while (timeStampOld > timeStamp) {
            roundId -= 1;
            (,priceOld,, timeStampOld,) = priceFeed.getRoundData(roundId);
        }

        if(price == priceOld) {
            return false;
        }

        if(price > priceOld) {
            priceDifference = uint256(price - priceOld);
            deviation = priceDifference.mul(100).div(uint256(priceOld));
        }
        else {
            priceDifference = uint256(priceOld - price);
            deviation = priceDifference.mul(100).div(uint256(priceOld));
        }

        console.log("here");
        if(deviation > deviationThreshold) {
            return true;
        }
        return false;
    }
}