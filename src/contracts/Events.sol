// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Event.sol";
import "./Storable.sol";

address constant ORACLE = 0x43B26Ac199FA7c8fef86e716FA70e29ed11977Bb; //Deployment of Operator.sol
string constant JOB_ID = "8957883b425d45ada064c7f4fbb54690";

contract Events is Ownable, Storable {
	constructor()
	Storable(ORACLE, JOB_ID) {}

	Event[] private _events;

	event NewEvent(string name, uint id);
	event UpdateEvent(uint id, string name, int maxAttendance);

	mapping(uint256 => address) internal _eventToOwner;
	mapping(address => uint256) internal _eventsOwnedCount;

	modifier eventOwnedBy(uint eventId_) {
		require(_eventToOwner[eventId_] == msg.sender);
		_;
	}

	function createEvent(string memory name, string memory description, uint date, int32 maxAttendance) public {
		//Create the event
		_events.push(Event(0, date, maxAttendance, 0, ""));
		
		uint id = _events.length - 1;
		_events[id].id = id;

		addStorableString("name", name);
		addStorableString("description", description);
		addStorableUint("eventId", id);
		storeData(this.onDataIsSet.selector);

		_eventToOwner[id] = msg.sender;
		_eventsOwnedCount[msg.sender]++;
		emit NewEvent(name, id);
	}

	function getEvent(uint eventId) external view returns(Event memory) {
		require(eventId < _events.length);
		
		return _events[eventId];
	}

	function updateEvent(uint eventId, string memory name, string memory description, uint date, int maxAttendance) external eventOwnedBy(eventId) {
		Event storage _event = _events[eventId];
		require(maxAttendance == -1 || uint256(maxAttendance) >= _event.countRegistered);

		_event.maxAttendance = int32(maxAttendance);
		_event.date = date;

		addStorableString("name", name);
		addStorableString("description", description);
		addStorableUint("eventId", eventId);
		storeData(this.onDataIsSet.selector);
		
		// emit UpdateEvent(eventId_, name_, maxAttendance_);
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