// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

struct Registration {
	uint id;
	address account;
	uint eventFeePaid;
	uint serviceFeePaid;
	string dataCid;

	//Linked list entries
	uint _previousRegId;
	uint _nextRegId;
}