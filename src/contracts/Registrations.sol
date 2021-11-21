// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storable.sol";
import "./Registration.sol";
import "./Event.sol";

address constant ORACLE = 0x43B26Ac199FA7c8fef86e716FA70e29ed11977Bb; //Deployment of Operator.sol
string constant JOB_ID = "b719bfa40c264277a898ea1f6dcf3a31";

interface EventsInterface {
	function getEvent(uint256 eventId) external view returns (
		Event memory
	);
}

contract Registrations is Ownable, Storable {
	constructor()
	Storable(ORACLE, JOB_ID) {
		// zero is a special case, so burn it
		_registrations.push(Registration(0,msg.sender,0,0,"",0,0));
	}

	uint SERVICE_FEE = 0.002 ether;

	Registration[] private _registrations;

	mapping(uint => uint) private _registrationIdToEventId;
	mapping(uint => uint) private _eventIdToCountOfRegistrations;
	mapping(uint => uint) private _eventIdToLastRegistrationId; 

	EventsInterface private _events;

	/**
	* @notice Add an entry to the registrations array and register it with the event
	* @param eventId uint the event, will be retrieved with the EventsInterface
	* @param name string to be stored on IPFS
	* @param company string to be stored on IPFS
	* @param email string to be stored on IPFS
	*/
	function createRegistration(
		uint eventId, 
		string memory name, 
		string memory company, 
		string memory email
	) payable public
	{
		Event memory _event = _events.getEvent(eventId);

		// Validation
		require(msg.value == _event.fee + SERVICE_FEE);
		require(_eventIdToCountOfRegistrations[eventId] < uint32(_event.maxAttendance));
		require(_event.date > block.timestamp);
		require(!hasAccountRegisteredForEvent(eventId));

		// Create the entry
		_registrations.push(Registration(0,msg.sender,0,0,"",0,0));
		uint id = _registrations.length - 1;
		
		// Set the onchain values
		_registrations[id].id = id;
		_registrations[id].eventFeePaid = _event.fee;
		_registrations[id].serviceFeePaid = SERVICE_FEE;

		// Set the remote values
		addStorableString("name", name);
		addStorableString("company", company);
		addStorableString("email", email);
		addStorableUint("registrationId", id);
		storeData(this.onDataIsSet.selector);

		// Maps
		_registrationIdToEventId[id] = eventId;
		_eventIdToCountOfRegistrations[eventId]++;

		//Set up the linked list
		uint lastRegistrationId = _eventIdToLastRegistrationId[eventId];
		if (  lastRegistrationId > 0 ) {
			// Previous links to the new reg
			_registrations[lastRegistrationId]._nextRegId = id;
			//New reg linkst to the previous
			_registrations[id]._previousRegId = lastRegistrationId;
		}

		// Move the linked list entry point for this event
		_eventIdToLastRegistrationId[eventId] = id;
	} 

	/**
	* @notice Returns the IPFS CID of the remote data
	* @param requestId bytes32 required for the oracle to work
	* @param registrationId uint the ID of the reg that was offloaded
	* @param cid bytes encoded string of the IPFS CID.
	* @dev This is called by the oracle. recordChainlinkFulfillment must be used.
	*/
	function onDataIsSet(
		bytes32 requestId,
		uint registrationId,
		bytes calldata cid
	) public recordChainlinkFulfillment(requestId)
	{
		_registrations[registrationId].dataCid = string(abi.encodePacked(cid));
	}

	/**
	* @notice Set the events contract address
	* @param eventAddress address 
	*/
	function setEventsContractAddress(address eventAddress) public onlyOwner() {
		_events = EventsInterface(eventAddress);
	}

	/**
	* @notice Set the service fee required for registration
	* @param newFee uint 
	*/
	function setServiceFee(uint newFee) public onlyOwner() {
		SERVICE_FEE = newFee;
	}

	/**
	* @notice Get the current service fee required for registration
	* @return uint
	*/
	function getServiceFee() external view returns(uint) {
		return SERVICE_FEE;
	}

	/**
	* @notice Get the nubmer of registrations for an event
	* @return uint
	*/
	function countEventRegistrations(uint eventId) external view returns(uint) {
		return _eventIdToCountOfRegistrations[eventId];
	}

	/**
	* @notice Check if the account has registered for this event
	* @param eventId uint 
	* @return bool
	*/
	function hasAccountRegisteredForEvent(uint eventId) public view returns(bool) {
		if ( _eventIdToLastRegistrationId[eventId] == 0 ) return false;
		uint id = _eventIdToLastRegistrationId[eventId];
		
		// Step through the linked list to check if the user has registered.
		do {
			if(_registrations[id].account == msg.sender) return true;
			id = _registrations[id]._previousRegId;
		} while( id > 0 );

		return false;
	}

}