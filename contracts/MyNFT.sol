// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MyNFT is ERC1155, Ownable, ReentrancyGuard, Pausable, ERC1155Supply {
    using SafeMath for uint256;
    using Strings for uint256;

    AggregatorV3Interface internal priceFeed;

    string public name    = "My NFT";
    string public symbol  = "MNFT";
    uint256 public maxSupply = 100;

    string public notRevealedURI;
    string public baseURI1;
    string public baseURI2;

    bool public revealed         = false;
    bool public publicSaleActive = false;
    bool public preSaleActive    = false;

    uint256 public maxPreSaleSupply;
    uint256 public preSalePrice;
    uint256 public publicSalePrice;

    uint256 public deviationThreshold = 1;

    constructor() ERC1155(baseURI1) ReentrancyGuard(){
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // mainnet
        pause();
    }

    function airDrop(address[] memory _address) external onlyOwner {
        uint mintIndex = totalSupply(0).add(1);
        require(mintIndex.add(_address.length) <= maxSupply, 'NFT: airdrop would exceed total supply');
        for(uint index = 0; index < _address.length; index++) {
            _mint(_address[index], 0, 1, "0x0");
        }
    }

    function preSaleMint(uint256 _amount)external payable whenNotPaused {
        require(preSaleActive, "NFT:Pre-sale is not active");
        require(totalSupply(0).add(_amount) <= maxPreSaleSupply, 'NFT: Mint would exceed PreSaleLimit');
        mint(_amount, true);
    }

    function publicSaleMint(uint256 _amount) external payable whenNotPaused {
        require(totalSupply(0).add(_amount) <= maxSupply, 'NFT: Ether would exceed total supply');
        mint(_amount, false);
    }

    function mint(uint256 _amount, bool _state) internal {
        if(_state) {
            require(preSalePrice.mul(_amount) <= msg.value, "NFT: Ether value sent for presale mint is not correct");
        }
        else {
            require(publicSalePrice.mul(_amount) <= msg.value, "NFT: Ether value sent for public mint is not correct");
        }

        _mint(address(msg.sender), 0, _amount, "0x0");
    }

    function setDeviationThreshold(uint256 _deviationThreshold) external onlyOwner {
        deviationThreshold = _deviationThreshold;
    }

    function setURI(string memory _baseURI1, string memory _baseURI2) external onlyOwner {
        baseURI1  = _baseURI1;
        baseURI2 = _baseURI2;
    }

    function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function togglePublicSale()external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function togglePreSale() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC1155 uri: NONEXISTENT_TOKEN"); 
        bool flag = checkDeviation();
        if(flag == true) {
            return bytes(baseURI1).length > 0 ? string(abi.encodePacked(baseURI1, (_id).toString(), ".json")) : "";
        }
        else {
            return bytes(baseURI2).length > 0 ? string(abi.encodePacked(baseURI2, (_id).toString(), ".json")) : "";
        }
    }

    function checkDeviation() internal view returns(bool) {
        uint80 roundId;
        int price;
        int priceOld;
        uint timeStamp;
        uint256 deviation;
        uint256 priceDifference;

        (roundId, price,, timeStamp,) = priceFeed.latestRoundData();

        uint timeStampOld = timeStamp;
        timeStamp -= 86400; // 1 day = 86400

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

        if(deviation > deviationThreshold) {
            return true;
        }
        return false;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}
