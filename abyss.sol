// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract abyss is ERC721, ERC721Enumerable, Ownable {
    string public baseURI = "https://www.abyssfnf.com/api/nft/";
    uint256 public constant ogTokenEnd = 10;
    uint256 public maxSupply = 100;
    uint256 public price = 0.08 ether;
    uint256 public renewPrice = 0.08 ether;
    uint256 public maxRenewMonths = 3;

    mapping(uint256 => uint256) public expireTime;
    mapping(address => bool) public hasMinted;

    bool public privateSale = false;
    bool public canRenew = true;

    bytes32 public merkleRoot;

    event passMinted(uint256 tokenId, uint256 _expireTime);
    event passRenewed(uint256 tokenId, uint256 _expireTime);

    constructor() ERC721("The Abyss", "ABYSS") {
    }

    function mint(bytes32[] calldata _merkleProof) external payable {
        uint256 nextToMint = totalSupply() + 1;
        require(privateSale, "Private sale not active");
        require(maxSupply >= totalSupply() + 1, "Exceeds max supply");
        require(tx.origin == msg.sender, "No contracts");
        require(!hasMinted[msg.sender], "Already minted");
        require(price == msg.value, "Invalid funds provided");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        hasMinted[msg.sender] = true;
        expireTime[nextToMint] = block.timestamp + 30 days;
        _mint(msg.sender, nextToMint);
        emit passMinted(nextToMint, expireTime[nextToMint]);
    }

    function renewPass(uint256 _tokenId, uint256 _months) external payable {
        require(canRenew);
        require(tx.origin == msg.sender, "No contracts");
        uint256 cost = renewPrice * _months;
        require(msg.value == cost, "Invalid funds provided");
        require(_exists(_tokenId), "Token does not exist.");
        require(_months <= maxRenewMonths, "Too many months");
        require(_months > 0, "Cannot renew 0 months");
        require(msg.sender == ownerOf(_tokenId), "Cannot renew a pass you do not own.");

        uint256 _currentexpireTime = expireTime[_tokenId];

        if (_tokenId <= ogTokenEnd) {
            // og renew
            if (block.timestamp > _currentexpireTime) {
                // if pass is already expired
                expireTime[_tokenId] = block.timestamp + (_months * 45 days);
            } else {
                // if pass is not already expired
                require(expireTime[_tokenId] + (_months * 45 days) <= block.timestamp + (maxRenewMonths * 45 days), "Surpasses renew limit");
                expireTime[_tokenId] += (_months * 45 days);
            }
        } else {
            // regular renew
            if (block.timestamp > _currentexpireTime) {
                // if pass is already expired
                expireTime[_tokenId] = block.timestamp + (_months * 30 days);
            } else {
                // if pass is not already expired
                require(expireTime[_tokenId] + (_months * 30 days) <= block.timestamp + (maxRenewMonths * 30 days), "Surpasses renew limit");
                expireTime[_tokenId] += (_months * 30 days);
            }
        }
        emit passRenewed(_tokenId, expireTime[_tokenId]);
    }



    // only owner
    function setPrivateSale(bool _state) external onlyOwner {
        privateSale = _state;
    }

    function setCanRenew(bool _state) external onlyOwner {
        canRenew = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setRenewPrice(uint256 _renewPrice) external onlyOwner {
        renewPrice = _renewPrice;
    }

    function setMaxRenewMonths(uint256 _maxRenewMonths) external onlyOwner {
        maxRenewMonths = _maxRenewMonths;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function ownerMint(address _receiver) external onlyOwner {
        uint256 nextToMint = totalSupply() + 1;
        require(maxSupply >= totalSupply() + 1, "Exceeds max supply");
        require(tx.origin == msg.sender, "No contracts");

        hasMinted[_receiver] = true;
        expireTime[nextToMint] = block.timestamp + 30 days;
        _mint(_receiver, nextToMint);
        emit passMinted(nextToMint, expireTime[nextToMint]);
    }

    function ownerBatchMint(address[] memory _receivers) external onlyOwner {
        for (uint256 i = 0; i < _receivers.length; i++) {
            uint256 nextToMint = totalSupply() + 1;
            require(maxSupply >= totalSupply() + 1, "Exceeds max supply");
            require(tx.origin == msg.sender, "No contracts");
            
            hasMinted[_receivers[i]] = true;
            expireTime[nextToMint] = block.timestamp + 30 days;
            _mint(_receivers[i], nextToMint);
            emit passMinted(nextToMint, expireTime[nextToMint]);
        }
    }

    function ownerRenew(uint256 _tokenId, uint256 _days) external onlyOwner {
        require(tx.origin == msg.sender, "No contracts");
        require(_exists(_tokenId), "Token does not exist.");
        uint256 _currentexpiryTime = expireTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            // if pass is expired
            expireTime[_tokenId] = block.timestamp + (_days * 1 days);
        } else {
            // if pass isn't expired
            expireTime[_tokenId] += (_days * 1 days);
        }
        emit passRenewed(_tokenId, expireTime[_tokenId]);
    }

    function ownerBatchRenew(uint256[] memory _tokenIds, uint256 _days) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(tx.origin == msg.sender, "No contracts");
            require(_exists(_tokenIds[i]), "Token does not exist.");
            uint256 _currentexpiryTime = expireTime[_tokenIds[i]];
            
            if (block.timestamp > _currentexpiryTime) {
                // if pass is expired
                expireTime[_tokenIds[i]] = block.timestamp + (_days * 1 days);
            } else {
                // if pass isn't expired
                expireTime[_tokenIds[i]] += (_days * 1 days);
            }
            emit passRenewed(_tokenIds[i], expireTime[_tokenIds[i]]);
        }
    }

    function inactivePassScrub(uint256 _tokenId, address _receiver) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist.");
        uint256 _currentexpiryTime = expireTime[_tokenId];
        require(_currentexpiryTime + 7 days < block.timestamp, "Pass needs to be inactive for 7+ days");
        address person = ownerOf(_tokenId);

        _safeTransfer(person, _receiver, _tokenId, "");
    }

    function inactivePassScrubBatch(uint256[] memory _tokenIds, address _receiver) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "Token does not exist.");
            uint256 _currentexpiryTime = expireTime[_tokenIds[i]];
            require(_currentexpiryTime + 7 days < block.timestamp, "Pass needs to be inactive for 7+ days");
            address person = ownerOf(_tokenIds[i]);

            _safeTransfer(person, _receiver, _tokenIds[i], "");
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }



    // misc    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function checkPass(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expireTime[_tokenId] > block.timestamp, "Pass is expired.");

        return msg.sender == ownerOf(_tokenId) ? true : false;
    }

    function checkUserWithPass(address _user, uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expireTime[_tokenId] > block.timestamp, "Pass is expired");

        return _user == ownerOf(_tokenId) ? true : false;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId)
            )
        ) : "";
    }
}