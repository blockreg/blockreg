// SPDX-License-Identifier: CC-BY-NC-2.0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Storable.sol";

address constant ORACLE = 0x43B26Ac199FA7c8fef86e716FA70e29ed11977Bb; //Deployment of Operator.sol
string constant JOB_ID = "b719bfa40c264277a898ea1f6dcf3a31";

interface EventsInterface {
	struct Event {
		uint id;
		uint date;
		uint fee; //In ether
		int32 maxAttendance; // Signed: -1 means no cap
		string dataCid;
	}
	function getEvent(uint256 eventId) external view returns (Event memory);
	function isEventOwner(uint eventId, address account) external view returns(bool);
}

contract Registrations is Ownable, Storable {
	constructor()
	Storable(ORACLE, JOB_ID) {
		// zero is a special case, so burn it
		_registrations.push(Registration(0,msg.sender,0,0,"",0,0,0,0));
	}

	struct Registration {
		uint id;
		address account;
		uint eventFee;
		uint serviceFee;
		string dataCid;

		// TODO: Make a linked list utility to manage these more formally
		//Linked list entries for events
		uint _previousEventRegId;
		uint _nextEventRegId;

		//Linked list entries for 
		uint _previousAccountRegId;
		uint _nextAccountRegId;
	}

	uint SERVICE_FEE = 0.002 ether;
	uint private _serviceFeeBalance = 0; 

	Registration[] private _registrations;

	mapping(uint => uint) private _registrationIdToEventId;
	mapping(uint => uint) private _eventIdToCountOfRegistrations;
	mapping(address => uint) private _accountToCountOfRegistrations;
	mapping(uint => uint) private _eventAccountBalance;
	mapping(bytes32 => uint) private _cidToRegistrationId;

	//Linked list entry points to make moving through the array fast and efficient
	mapping(uint => uint) private _eventIdToLastRegistrationId; 
	mapping(address => uint) private _accountToLastRegistrationId; 

	EventsInterface private _events;

	modifier eventOwnedBy(uint eventId) {
		require(_events.isEventOwner(eventId, msg.sender));
		_;
	}

	/**
	* @notice Add an entry to the registrations array and register it with the event
	* @param eventId uint the event, will be retrieved with the EventsInterface
	* @param name string to be stored on IPFS
	* @param company string to be stored on IPFS
	* @param email string to be stored on IPFS
	*/
	function register(
		uint eventId, 
		string memory name, 
		string memory company, 
		string memory email
	) payable public
	{
		EventsInterface.Event memory _event = _events.getEvent(eventId);

		// Validation
		require(msg.value == _event.fee + SERVICE_FEE, "Incorrect fee.");
		require(_eventIdToCountOfRegistrations[eventId] < uint32(_event.maxAttendance) || _event.maxAttendance < 0, "Event full");
		require(_event.date > block.timestamp, "Event date has passed");
		require(!hasAccountRegisteredForEvent(eventId), "Account already registered for this event.");

		// Create the entry
		_registrations.push(Registration(0,msg.sender,0,0,"",0,0,0,0));
		uint id = _registrations.length - 1;
		
		// Set the on chain values
		_registrations[id].id = id;
		_registrations[id].eventFee = _event.fee;
		_registrations[id].serviceFee = SERVICE_FEE;

		// Set the remote values
		addStorableString("name", name);
		addStorableString("company", company);
		addStorableString("email", email);
		addStorableUint("registrationId", id);
		storeData(this.onDataIsSet.selector);

		// Maps
		_registrationIdToEventId[id] = eventId;
		_eventIdToCountOfRegistrations[eventId]++;
		_accountToCountOfRegistrations[msg.sender]++;

		// Set up the event linked list
		uint lastEventRegistrationId = _eventIdToLastRegistrationId[eventId];
		if (  lastEventRegistrationId > 0 ) {
			// Previous links to the new reg
			_registrations[lastEventRegistrationId]._nextEventRegId = id;
			//New reg links to the previous
			_registrations[id]._previousEventRegId = lastEventRegistrationId;
		}

		// Set up the account's linked list
		uint lastAcctRegistrationId = _accountToLastRegistrationId[msg.sender];
		if (  lastAcctRegistrationId > 0 ) {
			// Previous links to the new reg
			_registrations[lastAcctRegistrationId]._nextAccountRegId = id;
			//New reg links to the previous
			_registrations[id]._previousAccountRegId = lastAcctRegistrationId;
		}

		// Move the linked list entry points
		_eventIdToLastRegistrationId[eventId] = id;
		_accountToLastRegistrationId[msg.sender] = id;

		// Accounting
		_serviceFeeBalance += SERVICE_FEE;
		_eventAccountBalance[_event.id] += _event.fee;
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
		_registrations[registrationId].dataCid = _bytes32ToString(bytes32(cid));
		_cidToRegistrationId[bytes32(cid)] = registrationId;
	}

	/**
	* @notice Verifies the registration using CID to keep people from simply requesting the next ID in the array 
	* @notice In the future, we could definitely use a neutral identifier to separate concerns.
	* @param cid string the IPFS CID used to store remote data
	* @return registrationId uint
	* @return eventId uint
	*/
	function verifyRegistration(string calldata cid) public view returns (uint registrationId, uint eventId) {
		uint id = _cidToRegistrationId[_stringToBytes32(cid)];
		require(id > 0, "No registration found.");

		return (id, _registrationIdToEventId[id]);
	}

	/**
	* @notice Gets the all registrations for a the requesting account.
	*/
	function getAccountRegistrations() public view returns (Registration[] memory){
		Registration[] memory _response = new Registration[](_accountToCountOfRegistrations[msg.sender]);

		uint id = _accountToLastRegistrationId[msg.sender];
		uint index = 0;
		do {
			_response[index] = _registrations[id];
			id = _registrations[id]._previousAccountRegId;
			index++;
		} while ( id > 0 );

		return _response;
	}

	/**
	* @notice Gets the full list of registrations for an event. Restricted to event owner
	* @param eventId uint
	*/
	function getEventRegistrations(uint eventId) public view eventOwnedBy(eventId) returns(Registration[] memory) {
		Registration[] memory _response = new Registration[](_eventIdToCountOfRegistrations[eventId]);

		uint id = _eventIdToLastRegistrationId[eventId];
		uint index = 0;
		do {
			_response[index] = _registrations[id];
			id = _registrations[id]._previousEventRegId;
			index++;
		} while ( id > 0 );

		return _response;
	}

	/**
	* @notice Allows event owners to withdraw the registration fees. Sets a flag on the registration to keep from double-withdrawing.
	* @param eventId uint
	*/
	function withdrawEventRegistrationFees(uint eventId) public eventOwnedBy(eventId) {
		require(_eventAccountBalance[eventId] > 0, "Nothing to withdraw");

		uint toPay = _eventAccountBalance[eventId];
		_eventAccountBalance[eventId] = 0;

		// Must happen at the end to protect against re-entry attacks
		(bool sent,) = msg.sender.call{value: toPay}("");
		require(sent, "Transfer failed.");
	}

	/**
	* @notice Allows blockreg to withdraw service fees.
	*/
	function withdrawServiceFees() public onlyOwner() {
		require(_serviceFeeBalance > 0, "Nothing to withdraw");

		uint toPay = _serviceFeeBalance;
		_serviceFeeBalance = 0;

		// Must happen at the end to protect against re-entry attacks
		(bool sent,) = msg.sender.call{value: toPay}("");
		require(sent, "Transfer failed.");
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
	* @notice Get the total cost required for registration
	* @return uint
	*/
	function getRegistrationFee(uint eventId) external view returns(uint) {
		EventsInterface.Event memory _event = _events.getEvent(eventId);
		return _event.fee + SERVICE_FEE;
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
			id = _registrations[id]._previousEventRegId;
		} while( id > 0 );

		return false;
	}

}