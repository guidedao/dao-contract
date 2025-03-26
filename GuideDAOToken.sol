/**
 *Submitted for verification at optimistic.etherscan.io on 2024-04-15
 */

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: GuideDaoToken.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

error TokenDoesNotExist(uint256 tokenId);
error NotAnAdminOrOwner(address sender);
error NotAnOwner(address sender);
error AddressAlreadyHasToken(address recipient);
error NotInWhiteList(address student);
error AlreadyInWhiteList(address student);
error GradeTooSmall(uint256 newGrade);
error GradeTooBig(uint256 grade);
error OwnerIsZero();
error InsufficientPayment(uint256 requiredAmount, uint256 providedAmount);
error BurnNotTransfer();
error SendingToContract(address recipient);
error NotTokenOwner(address from, uint256 tokenId);
error AlreadyTokenOwner(address to, uint256 tokenId);

contract GuideDAONewToken is IERC721Metadata, Pausable {
    address public OWNER = 0xBF34eb509daAB7900491aEAc4d98d26F93dD165f;
    string private constant BASE_URI = "ipfs://";
    string private constant _name = "GuideDAO Access Token";
    string private constant _symbol = "GDAT";

    uint256 public currentIdToMint = 1;
    uint256 public MAX_GRADE = 2;
    uint256 public price;
    mapping(address => uint256) private _ids;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => uint256) private _grades;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public admins;

    modifier isMinted(uint256 tokenId) {
        if (_owners[tokenId] == address(0)) {
            revert TokenDoesNotExist(tokenId);
        }
        _;
    }

    modifier isAdmin() {
        if (!admins[msg.sender] && msg.sender != OWNER) {
            revert NotAnAdminOrOwner(msg.sender);
        }
        _;
    }

    modifier isFirstToken(address to) {
        if (balanceOf(to) != 0) {
            revert AddressAlreadyHasToken(to);
        }
        _;
    }

    modifier isOwner() {
        if (msg.sender != OWNER) {
            revert NotAnOwner(msg.sender);
        }
        _;
    }

    constructor() payable {
        admins[msg.sender] = true;
    }

    function setIsInWhiteList(
        address student,
        bool isInWhiteList
    ) public whenNotPaused isAdmin isFirstToken(student) {
        whiteList[student] = isInWhiteList;
    }

    function mint() public whenNotPaused {
        if (!whiteList[msg.sender]) {
            revert NotInWhiteList(msg.sender);
        }
        whiteList[msg.sender] = false;
        _mintTo(msg.sender);
    }

    function mintTo(address to) public whenNotPaused isAdmin {
        _mintTo(to);
    }

    function setPrice(uint256 _price) public whenNotPaused isAdmin {
        price = _price;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused isAdmin {
        _safeTransferFrom(from, to, tokenId);
    }

    function burn(address from) public whenNotPaused isAdmin {
        _transferFrom(from, address(0), getAddressNFTId(from));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused isAdmin isFirstToken(to) {
        _transferFrom(from, to, tokenId);
    }

    function setMaxGrade(uint256 _max_grade) public whenNotPaused isAdmin {
        if (_max_grade <= MAX_GRADE) {
            revert GradeTooSmall(_max_grade);
        }
        MAX_GRADE = _max_grade;
    }

    function setGradeURI(
        uint256 grade,
        string memory uri
    ) public whenNotPaused isAdmin {
        if (grade > MAX_GRADE) {
            revert GradeTooBig(grade);
        }
        //_tokenURIs[grade] = uri;
        _tokenURIs[grade] = string(abi.encodePacked(BASE_URI, uri));
    }

    function setGrade(
        uint256 tokenId,
        uint256 grade
    ) public whenNotPaused isAdmin isMinted(tokenId) {
        if (grade > MAX_GRADE) {
            revert GradeTooBig(grade);
        }

        if (grade <= _grades[tokenId]) {
            revert GradeTooSmall(grade);
        }
        _grades[tokenId] = grade;
    }

    function balanceOf(
        address owner
    ) public view override returns (uint256 balance) {
        if (owner == address(0)) {
            revert OwnerIsZero();
        }
        return _ids[owner] == 0 ? 0 : 1;
    }

    function ownerOf(
        uint256 tokenId
    ) public view override isMinted(tokenId) returns (address owner) {
        return _owners[tokenId];
    }

    function getAddressNFTId(address user) public view returns (uint256) {
        return _ids[user];
    }

    function getGrade(uint256 tokenId) public view returns (uint256) {
        return _grades[tokenId];
    }

    function setIsAdmin(
        address admin,
        bool _isAdmin
    ) external whenNotPaused isAdmin {
        admins[admin] = _isAdmin;
    }

    function updateStudentWhiteList(
        address oldAddress,
        address newAddress
    ) external whenNotPaused isAdmin {
        if (!whiteList[oldAddress]) {
            revert NotInWhiteList(oldAddress);
        }
        if (whiteList[newAddress]) {
            revert AlreadyInWhiteList(newAddress);
        }
        whiteList[oldAddress] = false;
        whiteList[newAddress] = true;
    }

    function setIsInWhiteListBatch(
        address[] calldata students,
        bool isInWhiteList
    ) external whenNotPaused isAdmin {
        uint256 studentsLength = students.length;
        for (uint256 i; i < studentsLength; ) {
            setIsInWhiteList(students[i], isInWhiteList);
            unchecked {
                ++i;
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {}

    function buy() external payable whenNotPaused {
        if (msg.value < price) {
            revert InsufficientPayment(price, msg.value);
        }
        _mintTo(msg.sender);
    }

    function withdraw() external whenNotPaused isAdmin {
        payable(OWNER).transfer(address(this).balance);
    }

    function pause() external isOwner {
        _pause();
    }

    function unpause() external isOwner {
        _unpause();
    }

    function transferOwnership(
        address newOwner
    ) external whenNotPaused isOwner {
        if (newOwner == address(0)) {
            revert OwnerIsZero();
        }
        OWNER = newOwner;
    }

    function approve(address to, uint256 tokenId) external override {}

    function setApprovalForAll(
        address operator,
        bool _approved
    ) external override {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function tokenURI(
        uint256 tokenId
    ) external view override isMinted(tokenId) returns (string memory) {
        return _tokenURIs[getGrade(tokenId)];
    }

    function getApproved(
        uint256 tokenId
    ) external view override returns (address operator) {}

    function isApprovedForAll(
        address owner,
        address operator
    ) external view override returns (bool) {}

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) private {
        if (to == address(0)) {
            revert BurnNotTransfer();
        }
        if (to.code.length != 0) {
            revert SendingToContract(to);
        }
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) private {
        if (_owners[tokenId] != from) {
            revert NotTokenOwner(from, tokenId);
        }

        if (_owners[tokenId] == to) {
            revert AlreadyTokenOwner(to, tokenId);
        }

        //если это не mint
        if (from != address(0)) {
            delete _ids[from];
        }

        //если это не burn
        if (to != address(0)) {
            _ids[to] = tokenId;
        }
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _mintTo(address to) private isFirstToken(to) {
        _safeTransferFrom(address(0), to, currentIdToMint);
        ++currentIdToMint;
    }
}
