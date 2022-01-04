// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@jbox/sol/contracts/abstract/JuiceboxProject.sol";

pragma solidity 0.8.6;

contract OGBANNY is ERC721Enumerable {
    using SafeMath for uint256;

    event Mint(address to, address OGBannyAddress);
    event SetBaseURI(string baseURI);

    bool public saleIsActive = false;

    // Limit the total number of reserve OGBANNY that can be minted by the owner
    uint256 public mintedReservesLimit = 5;
    uint256 public mintedReservesCount = 0;

    // Map OGBanny addresses to their token ID
    mapping(address => uint256) public idOfAddress;

    // Map token IDs to OGBanny addresses
    mapping(uint256 => address) public OGBannyAddressOf;

    // Base uri used to retrieve OGBanny token metadata
    string public baseURI;

    constructor(
        uint256 _projectID,
        ITerminalDirectory _terminalDirectory,
        string memory _baseURI
    ) JuiceboxProject(_projectID, _terminalDirectory) ERC721("OGBANNY", "OGBNY") {
        baseURI = _baseURI;
    // This is where ETH moves to during purchase.     
      contract.deploy(<wagmi-project-id>, <terminal-directory-address>) 
    }

    // Get URI used to retrieve metadata for OGBanny with ID `tokenID`
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        toAsciiString(OGBannyAddressOf[tokenId])
                    ) // Convert address to string before encoding
                )
                : "";
    }

    // Get IDs for all tokens owned by `_owner`
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Calculate the current OGBanny market price based on current supply
    function calculatePrice() public view returns (uint256) {
        require(saleIsActive == true, "Sale hasn't started");

        uint256 currentSupply = totalSupply();

            return 10000000000000000; // 1 - 50 : 0.5 ETH
        }
    }

    // Mint OGBanny for address `_OGBannyAddress` to `msg.sender`
    function mintOGBanny(address _OGBannyAddress) external payable returns (uint256) {
        require(
            msg.value >= calculatePrice(),
            "Ether value sent is below the price"
        );

        // Take fee into OGBannyDAO Juicebox treasury
        _takeFee(
            msg.value,
            msg.sender,
            string(
                abi.encodePacked(
                    "Minted OGBanny with address ",
                    toAsciiString(_OGBannyAddress)
                )
            ),
            false
        );

        return _mintOGBanny(msg.sender, _OGBannyAddress);
    }

    function _mintOGBanny(address to, address _OGBannyAddress)
        private
        returns (uint256)
    {
        require(
            idOfAddress[_OGBannyAddress] == 0,
            "OGBanny already minted for address"
        );

        // Start IDs at 1
        uint256 tokenId = totalSupply() + 1;

        _safeMint(to, tokenId);

        // Map OGBanny address to token ID
        idOfAddress[_OGBannyAddress] = tokenId;
        // Map token ID to OGBanny address
        OGBannyAddressOf[tokenId] = _OGBannyAddress;

        emit Mint(to, _OGBannyAddress);

        return tokenId;
    }

    //
    // Owner functions
    //

    function startSale() external onlyOwner {
        require(saleIsActive == false, "Sale is already active");
        saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "Sale is already inactive");
        saleIsActive = false;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    // Reserved for promotional giveaways, and rewards to those who helped inspire or enable OGBANNY.
    // Owner may mint OGBanny for `_OGBannyAddress` to `to`
    function mintReserveOGBanny(address to, address _OGBannyAddress)
        external
        onlyOwner
        returns (uint256)
    {
        require(
            mintedReservesCount < mintedReservesLimit,
            "Reserves limit exceeded"
        );

        mintedReservesCount = mintedReservesCount + 1;

        return _mintOGBanny(to, _OGBannyAddress);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}
