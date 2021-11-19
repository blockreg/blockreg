// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

struct Event {
	uint id;
	uint date;
	int32 maxAttendance; // Signed: -1 means no cap
	uint32 countRegistered;
	string dataCid;
}