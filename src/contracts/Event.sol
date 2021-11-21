// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

struct Event {
	uint id;
	uint date;
	uint fee; //In ether
	int32 maxAttendance; // Signed: -1 means no cap
	string dataCid;
}