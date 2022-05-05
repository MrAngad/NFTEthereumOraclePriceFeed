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
    string public baseURI1; // -ve deviation
    string public baseURI2; // not enough deviation
    string public baseURI3; // +ve deviation 
    string public notRevealedUri;
    
    bool public revealed         = false;
    bool public publicSaleActive = false;
    bool public preSaleActive    = false;

    uint256 public preSalePrice  = 0.1 ether;
    uint256 public publicSalePrice = 0.15 ether;
    uint256 public maxPreSale = 1;
    uint256 public maxPublicSale = 1;

    uint256 public deviationThreshold = 5;

    mapping(address => bool) public isWhiteListed;
    mapping(address => uint256) public preSaleCounter;
    mapping(address => uint256) public publicSaleCounter;

    constructor() ERC1155(baseURI2) ReentrancyGuard(){
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

    function addToWhitelist(address[] memory _address) external onlyOwner {
        for (uint256 index = 0; index < _address.length; index++) {
            isWhiteListed[_address[index]] = true;
        }
    }

    function preSaleMint(uint256 _amount) external payable whenNotPaused {
        require(preSaleActive, "NFT:Pre-sale is not active");
        require(isWhiteListed[msg.sender], "NFT:Sender is not whitelisted");
        require(preSaleCounter[msg.sender].add(_amount) <= maxPreSale, 'NFT: Mint would exceed total supply');
        require(totalSupply(0).add(_amount) <= maxSupply, "NFT: You Cannot Mint so many tokens in the public sale");
        mint(_amount, true);
        preSaleCounter[msg.sender] += _amount;
    }

    function publicSaleMint(uint256 _amount) external payable whenNotPaused {
        require(publicSaleActive, "NFT:Public-sale is not active");
        require(totalSupply(0).add(_amount) <= maxSupply, 'NFT: Ether would exceed total supply');
        require(publicSaleCounter[msg.sender].add(_amount) <= maxPublicSale, 'NFT: Mint would exceed total supply');
        mint(_amount, false);
        publicSaleCounter[msg.sender] += _amount;
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

    function setURI(string memory _baseURI1, string memory _baseURI2, string memory _baseURI3) external onlyOwner {
        baseURI1 = _baseURI1;
        baseURI2 = _baseURI2;
        baseURI3 = _baseURI3;
    }

    function setNotRevealedURI(string memory _notRevealedUri) external onlyOwner {
        notRevealedUri = _notRevealedUri;
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

        if(!revealed){
            return notRevealedUri;
        }
        
        uint256 check = checkDeviation();
        if(check == 1) {
            return baseURI1;
        }
        if (check == 2) {
            return baseURI2;
        }
        return baseURI3;
    }

    function checkDeviation() internal view returns(uint256) {
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
            return 2; // no deviation
        }

        if(price > priceOld) {
            priceDifference = uint256(price - priceOld);
            deviation = priceDifference.mul(100).div(uint256(priceOld));
            if(deviation > deviationThreshold) {
                return 3; // +ve deviation
            }
            return 2;     // not enough deviation 
        }

        priceDifference = uint256(priceOld - price);
        deviation = priceDifference.mul(100).div(uint256(priceOld));

        if(deviation > deviationThreshold) {
            return 1; // -ve deviation
        }
        return 2;     // not enough deviation 
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdrawTotal() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}
