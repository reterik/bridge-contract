
// File: contracts/upgradeability/EternalStorage.sol

pragma solidity 0.4.24;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/interfaces/IRewardableValidators.sol

pragma solidity 0.4.24;

interface IRewardableValidators {
    function isValidator(address _validator) external view returns (bool);
    function requiredSignatures() external view returns (uint256);
    function owner() external view returns (address);
    function validatorList() external view returns (address[]);
    function getValidatorRewardAddress(address _validator) external view returns (address);
    function validatorCount() external view returns (uint256);
    function getNextValidator(address _address) external view returns (address);
}

// File: contracts/upgradeable_contracts/FeeTypes.sol

pragma solidity 0.4.24;

contract FeeTypes {
    bytes32 internal constant HOME_FEE = 0x89d93e5e92f7e37e490c25f0e50f7f4aad7cc94b308a566553280967be38bcf1; // keccak256(abi.encodePacked("home-fee"))
    bytes32 internal constant FOREIGN_FEE = 0xdeb7f3adca07d6d1f708c1774389db532a2b2f18fd05a62b957e4089f4696ed5; // keccak256(abi.encodePacked("foreign-fee"))
}

// File: contracts/upgradeable_contracts/BaseFeeManager.sol

pragma solidity 0.4.24;





contract BaseFeeManager is EternalStorage, FeeTypes {
    using SafeMath for uint256;

    event HomeFeeUpdated(uint256 fee);
    event ForeignFeeUpdated(uint256 fee);

    // This is not a real fee value but a relative value used to calculate the fee percentage
    uint256 internal constant MAX_FEE = 1 ether;
    bytes32 internal constant HOME_FEE_STORAGE_KEY = 0xc3781f3cec62d28f56efe98358f59c2105504b194242dbcb2cc0806850c306e7; // keccak256(abi.encodePacked("homeFee"))
    bytes32 internal constant FOREIGN_FEE_STORAGE_KEY = 0x68c305f6c823f4d2fa4140f9cf28d32a1faccf9b8081ff1c2de11cf32c733efc; // keccak256(abi.encodePacked("foreignFee"))

    function calculateFee(uint256 _value, bool _recover, bytes32 _feeType) public view returns (uint256) {
        uint256 fee = _feeType == HOME_FEE ? getHomeFee() : getForeignFee();
        if (!_recover) {
            return _value.mul(fee).div(MAX_FEE);
        }
        return _value.mul(fee).div(MAX_FEE.sub(fee));
    }

    modifier validFee(uint256 _fee) {
        require(_fee < MAX_FEE);
        /* solcov ignore next */
        _;
    }

    function setHomeFee(uint256 _fee) external validFee(_fee) {
        uintStorage[HOME_FEE_STORAGE_KEY] = _fee;
        emit HomeFeeUpdated(_fee);
    }

    function getHomeFee() public view returns (uint256) {
        return uintStorage[HOME_FEE_STORAGE_KEY];
    }

    function setForeignFee(uint256 _fee) external validFee(_fee) {
        uintStorage[FOREIGN_FEE_STORAGE_KEY] = _fee;
        emit ForeignFeeUpdated(_fee);
    }

    function getForeignFee() public view returns (uint256) {
        return uintStorage[FOREIGN_FEE_STORAGE_KEY];
    }

    /* solcov ignore next */
    function distributeFeeFromAffirmation(uint256 _fee) external;

    /* solcov ignore next */
    function distributeFeeFromSignatures(uint256 _fee) external;

    /* solcov ignore next */
    function getFeeManagerMode() external pure returns (bytes4);

    function random(uint256 _count) internal view returns (uint256) {
        return uint256(blockhash(block.number.sub(1))) % _count;
    }
}

// File: contracts/interfaces/IBlockReward.sol

pragma solidity 0.4.24;

interface IBlockReward {
    function addExtraReceiver(uint256 _amount, address _receiver) external;
    function mintedTotally() external view returns (uint256);
    function mintedTotallyByBridge(address _bridge) external view returns (uint256);
    function bridgesAllowedLength() external view returns (uint256);
    function addBridgeTokenFeeReceivers(uint256 _amount) external;
    function addBridgeNativeFeeReceivers(uint256 _amount) external;
    function blockRewardContractId() external pure returns (bytes4);
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: contracts/upgradeable_contracts/BlockRewardBridge.sol

pragma solidity 0.4.24;




contract BlockRewardBridge is EternalStorage {
    bytes32 internal constant BLOCK_REWARD_CONTRACT = 0x20ae0b8a761b32f3124efb075f427dd6ca669e88ae7747fec9fd1ad688699f32; // keccak256(abi.encodePacked("blockRewardContract"))
    bytes4 internal constant BLOCK_REWARD_CONTRACT_ID = 0x2ee57f8d; // blockRewardContractId()
    bytes4 internal constant BRIDGES_ALLOWED_LENGTH = 0x10f2ee7c; // bridgesAllowedLength()

    function _blockRewardContract() internal view returns (IBlockReward) {
        return IBlockReward(addressStorage[BLOCK_REWARD_CONTRACT]);
    }

    function _setBlockRewardContract(address _blockReward) internal {
        require(AddressUtils.isContract(_blockReward));

        // Before store the contract we need to make sure that it is the block reward contract in actual fact,
        // call a specific method from the contract that should return a specific value
        bool isBlockRewardContract = false;
        if (_blockReward.call(BLOCK_REWARD_CONTRACT_ID)) {
            isBlockRewardContract =
                IBlockReward(_blockReward).blockRewardContractId() == bytes4(keccak256("blockReward"));
        } else if (_blockReward.call(BRIDGES_ALLOWED_LENGTH)) {
            isBlockRewardContract = IBlockReward(_blockReward).bridgesAllowedLength() != 0;
        }
        require(isBlockRewardContract);
        addressStorage[BLOCK_REWARD_CONTRACT] = _blockReward;
    }
}

// File: contracts/upgradeable_contracts/BlockRewardFeeManager.sol

pragma solidity 0.4.24;



contract BlockRewardFeeManager is BaseFeeManager, BlockRewardBridge {
    function distributeFeeFromAffirmation(uint256 _fee) external {
        distributeFeeFromBlockReward(_fee);
    }

    function distributeFeeFromSignatures(uint256 _fee) external {
        distributeFeeFromBlockReward(_fee);
    }

    /* solcov ignore next */
    function distributeFeeFromBlockReward(uint256 _fee) internal;
}

// File: contracts/upgradeable_contracts/erc20_to_erc20/FeeManagerErcToErcPOSDAO.sol

pragma solidity 0.4.24;


contract FeeManagerErcToErcPOSDAO is BlockRewardFeeManager {
    function getFeeManagerMode() external pure returns (bytes4) {
        return 0xd7de965f; // bytes4(keccak256(abi.encodePacked("manages-both-directions")))
    }

    function blockRewardContract() external view returns (address) {
        return _blockRewardContract();
    }

    function setBlockRewardContract(address _blockReward) external {
        _setBlockRewardContract(_blockReward);
    }

    function distributeFeeFromBlockReward(uint256 _fee) internal {
        IBlockReward blockReward = _blockRewardContract();
        blockReward.addBridgeTokenFeeReceivers(_fee);
    }
}
