const Events = artifacts.require("Events");

contract("Events", accounts => {
    let [alice, bob] = accounts;
    let contractInstance;

    let eventNames = ["Mike's Birthday", "Dubai Trip"]
    let eventAttendance = 500;
    //Create new contract instance
    beforeEach (async () => {
        contractInstance = await Events.new();
    });
    it("should create a new event", async () => {
        const result = await contractInstance
            .createEvent(eventNames[0], eventAttendance);
        // Confirm that the event was created
        assert.equal(result.receipt.status, true);

        // Confirm that event with name, and max attendance values was created
        assert.equal(result.logs[0].args.name,eventNames[0]);
        assert.equal(result.logs[0].args.maxAttendance.toNumber()
            ,eventAttendance); 
    });
    it("should get an event", async () => {
        const result = await contractInstance
            .createEvent(eventNames[0], eventAttendance);
        test_event = await contractInstance.getEvent.call(0);
        // Confirm that the contract gets the correct event
        assert.equal(test_event.name,eventNames[0]);
        assert.equal(test_event.maxAttendance,eventAttendance); 

    });
    it("should update an event", async () => {
        const result = await contractInstance
            .createEvent(eventNames[0], eventAttendance);
        id = result.logs[0].args.id.toNumber();
        update_event = await contractInstance
            .updateEvent(id, eventNames[1], 600);
        // Confirm that event is updated with new name and max attendance values
        assert.equal(update_event.logs[0].args.name,eventNames[1]);
        assert.equal(update_event.logs[0].args.maxAttendance.toNumber()
            ,600); 
    });
});



