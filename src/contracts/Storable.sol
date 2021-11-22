//SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

address constant LINK_TOKEN_KOVAN = 0xa36085F69e2889c224210F603D836748e7dC0088;

abstract contract Storable is ChainlinkClient {
	using Chainlink for Chainlink.Request;
	uint256 constant private ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY;
	bytes32 internal jobId;

	struct StorableData {
		mapping(string => string) stringValues;
		mapping(string => uint) uintValues;
		string[] stringKeys;
		string[] uintKeys;
	}
	
	StorableData _data;
	bytes32 storageCid;

	constructor(address _oracle, string memory _jobId) {
		setChainlinkToken(LINK_TOKEN_KOVAN); 
		setChainlinkOracle(_oracle); 
		jobId = _stringToBytes32(_jobId);
	}

	/**
	* @notice Queue string data to be stored
	* @param _key string key to add
	* @param _value string value to add
	*/
	function addStorableString(string memory _key, string memory _value) internal {
		_data.stringKeys.push(_key);
		_data.stringValues[_key] = _value;
	}

	/**
	* @notice Queue uint data to be stored
	* @param _key string key to add
	* @param _value uint value to add
	*/
	function addStorableUint(string memory _key, uint _value) internal {
		_data.uintKeys.push(_key);
		_data.uintValues[_key] = _value;
	}

	/**
	* @notice Store the data on IPFS
	* @param _callbackFunctionSignature bytes3 the .selector of the function the oracle will call when it fulfills
	*/
	function storeData(bytes4 _callbackFunctionSignature) internal {
		Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), _callbackFunctionSignature);

		for(uint i=_data.stringKeys.length; i>0; i--){
			req.add(_data.stringKeys[i-1], _data.stringValues[_data.stringKeys[i-1]]);
			delete(_data.stringValues[_data.stringKeys[i-1]]);
			_data.stringKeys.pop();
		}

		for(uint j=_data.uintKeys.length; j>0; j--){
			req.addUint(_data.uintKeys[j-1], _data.uintValues[_data.uintKeys[j-1]]);
			delete(_data.uintValues[_data.uintKeys[j-1]]);
			_data.uintKeys.pop();
		}
		requestOracleData(req, ORACLE_PAYMENT);
	}

	/**
	* @notice Convert from bytes32 to string 
	* @param source bytes32 
	* @return string 
	*/
	function _bytes32ToString(bytes32 source) internal pure returns (string memory) {
		return string(abi.encodePacked(source));
	}

	/**
	* @notice Convert from string to bytes32
	* @param source string 
	* @return result bytes32
	*/
	function _stringToBytes32(string memory source) internal pure returns (bytes32 result) {
		bytes memory tempEmptyStringTest = bytes(source);
		if (tempEmptyStringTest.length == 0) {
			return 0x0;
		}

		assembly { // solhint-disable-line no-inline-assembly
			result := mload(add(source, 32))
		}
	}
}