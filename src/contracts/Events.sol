// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storable.sol";

address constant ORACLE = 0x43B26Ac199FA7c8fef86e716FA70e29ed11977Bb; //Deployment of Operator.sol
string constant JOB_ID = "8957883b425d45ada064c7f4fbb54690";

interface RegistrationsInterface {
	function countEventRegistrations(uint eventId) external view returns(uint);
}

contract Events is Ownable, Storable {
	constructor()
	Storable(ORACLE, JOB_ID) {
		// Burn the first entry to avoid 0 index
		_events.push(Event(0, 0, 0, 0, ""));
	}

	struct Event {
		uint id;
		uint date;
		uint fee; //In wei
		int32 maxAttendance; // Signed: -1 means no cap
		string dataCid;
	}

	Event[] private _events;
	RegistrationsInterface _registrations;

	event EventSaved(
		uint eventId, 
		string name, 
		string description, 
		string badgeColor,
		string logoCid,
		uint date, 
		uint fee,
		int maxAttendance
	);

	mapping(uint256 => address) internal _eventToOwner;
	mapping(address => uint256) internal _eventsOwnedCount;
	
	//Linked list style traversal
	mapping(address => uint) internal _ownerToFirstEventCreated;
	mapping(uint => uint) internal _ownersNextEvent;

	modifier eventOwnedBy(uint eventId_) {
		require(_eventToOwner[eventId_] == msg.sender);
		_;
	}

	/**
	* @notice Link our registrations contract 
	* @param _address the address where the registrations contract is deployed
	*/
	function setRegistrationsContractAddress(address _address) public onlyOwner() {
		_registrations = RegistrationsInterface(_address);
	}

	/**
	* @notice Create a new event
	* @param name string offloaded to IPFS
	* @param description string offloaded to IPFS
	* @param date uint date of the event in epoch seconds
	* @param fee uint fee in ether
	* @param maxAttendance int -- value of -1 means unlimited
	*/
	function createEvent(
		string memory name, 
		string memory description, 
		string memory badgeColor,
		string memory logoCid,
		uint date,
		uint fee, // IMPORTANT: In ether
		int32 maxAttendance
	) public {
		//Create the event
		_events.push(Event(0, date, fee, maxAttendance, ""));
		uint id = _events.length -1;

		_setEventData(
			id,
			name, 
			description,
			badgeColor,
			logoCid,
			date,
			fee, 
			maxAttendance
		);

		_eventToOwner[id] = msg.sender;
		_eventsOwnedCount[msg.sender]++;
	}
	
	/**
	* @notice Retrieves an event
	* @notice This is also called by the Registrations contract to get event info
	* @param eventId uint the index of the event to retrieve
	*/
	function getEvent(uint eventId) external view returns(Event memory) {
		require(eventId < _events.length);
		
		return _events[eventId];
	}

	/**
	* @notice Update an existing event
	* @param eventId the index of the event to update
	* @param name string offloaded to IPFS
	* @param description string offloaded to IPFS
	* @param date uint date of the event in epoch seconds
	* @param fee uint fee in ether
	* @param maxAttendance int -- value of -1 means unlimited
	*/
	function updateEvent(
		uint eventId, 
		string memory name, 
		string memory description,
		string memory badgeColor,
		string memory logoCid,
		uint date, 
		uint fee,
		int maxAttendance
	) external eventOwnedBy(eventId) {
		require(maxAttendance == -1 || uint256(maxAttendance) >= _registrations.countEventRegistrations(eventId));

		_setEventData(
			eventId,
			name, 
			description,
			badgeColor,
			logoCid,
			date,
			fee, 
			int32(maxAttendance)
		);
	}

	/**
	* @notice Sets the event data on the internal array. Used by both create and update functions
	* @param eventId the index of the event to update
	* @param name string offloaded to IPFS
	* @param description string offloaded to IPFS
	* @param date uint date of the event in epoch seconds
	* @param fee uint fee in ether
	* @param maxAttendance int -- value of -1 means unlimited
	*/
	function _setEventData(
		uint eventId,
		string memory name, 
		string memory description, 
		string memory badgeColor,
		string memory logoCid,
		uint date,
		uint fee,  
		int32 maxAttendance
	) private {
		addStorableString("name", name);
		addStorableString("description", description);
		addStorableString("badgeColor", badgeColor);
		addStorableString("logoCid", logoCid);
		addStorableUint("eventId", eventId);
		storeData(this.onDataIsSet.selector);

		_events[eventId].id = eventId;
		_events[eventId].date = date;
		_events[eventId].fee = fee;
		_events[eventId].maxAttendance = maxAttendance;

		// Track their first event...
		if ( _ownerToFirstEventCreated[msg.sender] == 0 ) {
			_ownerToFirstEventCreated[msg.sender] = eventId;
		} else {
			// Step through the map to see what their last event without a next event is...
			uint index = _ownerToFirstEventCreated[msg.sender];
			while (_ownersNextEvent[index] > 0) {
				index = _ownersNextEvent[index];
			}
			// Index is now their most recently created event
			_ownersNextEvent[index] = eventId;
		}
		// Add an entry to the map to signify that eventId is their most recent event
		_ownersNextEvent[eventId] = 0;

		emit EventSaved(
			eventId, 
			name, 
			description, 
			badgeColor,
			logoCid,
			date, 
			fee, 
			maxAttendance
		);
	}

	/**
	* @notice Retrieves all the events hosted by the account making the request
	* @return Event array
	*/
	function getHostedEvents() external view returns(Event[] memory) {
		Event[] memory ownedEvents = new Event[](_eventsOwnedCount[msg.sender]);

		uint id = _ownerToFirstEventCreated[msg.sender];
		uint count = 0;
		do {
			ownedEvents[count] = _events[id];
			id = _ownersNextEvent[id];
			count++;
		} while(id > 0);

		return ownedEvents;
	}

	/**
	* @notice An external utility function for other contracts to ensure that someone is the event owner
	* @param eventId the index of the event 
	* @param account address test
	*/
	function isEventOwner(
		uint eventId, 
		address account
	) external view returns(bool){
		return _eventToOwner[eventId] == account;
	}

	/**
	* @notice Returns the IPFS CID of the remote data
	* @dev This is called by the oracle. recordChainlinkFulfillment must be used.
	*/
	function onDataIsSet(
		bytes32 requestId,
		uint eventId,
		bytes calldata cid
	)
	public
	recordChainlinkFulfillment(requestId)
	{
		_events[eventId].dataCid = string(abi.encodePacked(cid));
	}
}