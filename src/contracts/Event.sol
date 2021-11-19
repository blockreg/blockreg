// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

struct Event {
	//TODO: offload these strings
	string name;
	string description;
	
	uint date;
	int32 maxAttendance; // Signed: -1 means no cap
	uint32 countRegistered;
	bytes32 remoteCid;
}