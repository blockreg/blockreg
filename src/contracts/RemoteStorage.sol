//SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract RemoteStorage is ChainlinkClient {
  using Chainlink for Chainlink.Request;
  uint256 constant private ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY;

  // multiple params returned in a single oracle response
  bytes32 public lastRequestId;
  string public cid;
  bytes public data;

  //TODO: These are temporary until I refactor this 
  uint256 eventId;
  uint256 registrationID;
  
  event EventDataStored (
    bytes32 indexed requestId,
    uint eventId
  );

  event RegistrationDataStored(
    bytes32 indexed requestId,
    uint registrationId
  );

  /**
   * @notice Initialize the link token and target oracle
   * @dev The oracle address must be an Operator contract for multiword response
   */
  constructor(
  ) {
    setChainlinkToken(0xa36085F69e2889c224210F603D836748e7dC0088);
    setChainlinkOracle(0x43B26Ac199FA7c8fef86e716FA70e29ed11977Bb); // kovan deployment of operator.sol
  }

  /**
   * @notice Set big expensive string data remotely on IPFS
   * @param _jobId bytes32 representation of the jobId in the Oracle
   * @param _name string name of event
   * @param _description string description of event
   */
  function setEventData(
    string memory _jobId,
    uint256 eventId,
    string memory _name,
    string memory _description
  )
    public
  {
    Chainlink.Request memory req = buildChainlinkRequest(_stringToBytes32(_jobId), address(this), this.fulfillSetEventData.selector);
    req.addUint("eventId", eventId);
    req.add("name", _name);
    req.add("description", _description);
    requestOracleData(req, ORACLE_PAYMENT);
  }
  
  
  /**
   * @notice Set big expensive registration data on IPFS
   * @param _jobId bytes32 representation of the jobId in the Oracle
   * @param _name string name of person 
   * @param _company string company they represent
   * @param _email string ENCRYPT BEFORE SAVING
   */
  function setRegistrationData(
    string memory _jobId,
    uint256 registrationId,
    string memory _name,
    string memory _company,
    string memory _email
  )
    public
  {
    Chainlink.Request memory req = buildChainlinkRequest(_stringToBytes32(_jobId), address(this), this.fulfillSetRegistrationData.selector);
    req.addUint("registrationId", registrationId);
    req.add("name", _name);
    req.add("company", _company);
    req.add("email", _email);
    requestOracleData(req, ORACLE_PAYMENT);
  }
  
  /**
   * @notice Get an entity from IPFS
   * @param _jobId bytes32 representation of the jobId in the Oracle
   * @param _cid string CID of the entity
   */
  function getEventData(
    string memory _jobId,
    string memory _cid
  )
    public
  {
    Chainlink.Request memory req = buildChainlinkRequest(_stringToBytes32(_jobId), address(this), this.fulfillGetData.selector);
    req.add("cid", _cid);
    requestOracleData(req, ORACLE_PAYMENT);
  }

  /**
   * @notice Returns the IPFS CID of the remote data
   * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
   */
  function fulfillSetEventData(
    bytes32 _requestId,
    uint256 _eventId,
    bytes calldata _cid
  )
    public
    recordChainlinkFulfillment(_requestId)
  {
    lastRequestId = _requestId;
    cid = string(abi.encodePacked(_cid));
    eventId = _eventId;
  } 

  /**
   * @notice Returns the IPFS CID of the remote data
   * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
   */
  function fulfillSetRegistrationData(
    bytes32 _requestId,
    uint256 _registrationId,
    bytes calldata _cid
  )
    public
    recordChainlinkFulfillment(_requestId)
  {
    lastRequestId = _requestId;
    cid = string(abi.encodePacked(_cid));
    registrationId = _registrationId;
  }
  
  /**
   * @notice Returns the remote data stored by the IPFS CID
   * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
   */
  function fulfillGetEventData(
    bytes32 _requestId,
    bytes32 calldata _name,
    bytes32 calldata _description,
  )
    public
    recordChainlinkFulfillment(_requestId)
  {
      lastRequestId = _requestId;
      data = _data;
  } 
  
  function _stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }
}