// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Event.sol";

contract Events is Ownable {
	Event[] private _events;

	event NewEvent(string name, uint id);

	mapping(uint256 => address) internal _eventToOwner;
	mapping(address => uint256) internal _eventsOwnedCount;

	modifier eventOwnedBy(uint eventId_) {
		require(_eventToOwner[eventId_] == msg.sender);
		_;
	}

	function createEvent(string memory name_, int maxAttendance_) public {
		//Create the event
		_events.push(Event(name_, maxAttendance_, 0));
		uint id = _events.length - 1;

		_eventToOwner[id] = msg.sender;
		_eventsOwnedCount[msg.sender]++;
		emit NewEvent(name_, id);
	}

	function getEvent(uint eventId_) external view returns(Event memory) {
		require(eventId_ < _events.length);

		return _events[eventId_];
	}

	function updateEvent(uint eventId_, string memory name_, int maxAttendance_) external eventOwnedBy(eventId_) {
		Event storage _event = _events[eventId_];
		require(maxAttendance_ == -1 || uint256(maxAttendance_) >= _event.countRegistered);
		_event.name = name_;
		_event.maxAttendance = maxAttendance_;
	}
}