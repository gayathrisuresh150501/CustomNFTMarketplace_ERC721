//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//equivalent to console.log and helps to debugg smart contract
import "hardhat/console.sol"; 

//to track the  umber of items sold in the NFT marketplace
import "@openzeppelin/contracts/utils/Counters.sol";

//to manage token URI
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//openzeppelin implementation of ERC721 token standard
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract NFTMarketplace is ERC721URIStorage
{
    address payable public owner;

    //using Counters.sol contract to custom create data of Counters.Counter type
    using Counters for Counters.Counter;

    //to store NFT IDs
    Counters.Counter private _tokenIds;

    //to store no. of NFTs sold
    Counters.Counter private _itemsSold;

    //the default fee charged for NFT listing in the marketplace
    uint256 public listPrice = 1;

    // ERC721(classname, acronym)
    constructor() ERC721("NFTMarketplace", "NFTM") {
        //owner who deployed the current contract and also to bget the listing fee from the marketplace
        owner = payable(msg.sender);
    }

    //stores info about a listed token
    struct ListedToken 
    {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    //maps tokenId to token info and is helpful when retrieving metadata about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;

    //updates the listing price only by the owner of the smart contract
    function updateListPrice(uint256 _listPrice) public payable 
    {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    //displays the listing fee
    function getListPrice() public view returns (uint256) 
    {
        return listPrice;
    }

    //gets the latest listed NFT information using tokenID
    function getLatestIdToListedToken() public view returns (ListedToken memory) 
    {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    //retrieves the NFT information of the passed tokenID
    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) 
    {
        return idToListedToken[tokenId];
    }

    //retrieves current token based on current tokenID
    function getCurrentToken() public view returns (uint256) 
    {
        return _tokenIds.current();
    }

    //first time a token is created, it is listed here
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) 
    {
        //increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        //mint the NFT with tokenId newTokenId to the address who called createToken
        _safeMint(msg.sender, newTokenId);

        //map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newTokenId, tokenURI);

        //helper function to update Global variables and emit an event
        createListedToken(newTokenId, price);

        return newTokenId;
    }


    function createListedToken(uint256 tokenId, uint256 price) private 
    {
        //make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Hopefully sending the correct price");

        //just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //update the mapping of tokenId's to Token details, useful for retrieval functions
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );
    }

    //returns all the NFTs currently listed to be sold on the marketplace
    function getAllNFTs() public view returns (ListedToken[] memory) 
    {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        uint currentId;

        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=0;i<nftCount;i++)
        {
            currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }

    //returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (ListedToken[] memory) 
    {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;
        //important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender)
            {
                itemCount += 1;
            }
        }

        //once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i=0; i < totalItemCount; i++) 
        {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) 
            {
                currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable 
    {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();

        //actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);

        //approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        //transfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);

        //transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
    }
}