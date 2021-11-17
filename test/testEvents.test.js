const Events = artifacts.require("Events");

contract("Events", accounts => {
    let [alice, bob] = accounts;
    let contractInstance;
    let eventNames = ["Mike's Birthday"]
    let eventAttendance = 500;
    
    //Create new contract instance
    beforeEach (async () => {
        contractInstance = await Events.new();
    });
    //TODO Consider testing ownership
    it("should create a new event", async () => {
        const result = await contractInstance
            .createEvent(eventNames[0], eventAttendance);
        // Confirm that the event was created
        assert.equal(result.receipt.status, true);
        // Confirm that the Name, and Max Attendance was created
        assert.equal(result.logs[0].args.name,eventNames[0]);
        assert.equal(result.logs[0].args.maxAttendance.toNumber()
            ,eventAttendance); 
        // Check Id
        console.log(result.logs[0].args.id.toNumber());
    });
    xit("should get an event", async () => {
        //const result = await contractInstance.createEvent(eventNames[0], eventAttendance);
        const result2 = await contractInstance.getEvent.call(0);
        console.log(result2);

    });
    xit("should update an event", async () => {
        const result = await contractInstance
            .updateEvent(eventNames[0], 500);
        assert.equal(result.receipt.status, true);
        assert.equal(result.logs[0].args.name,eventNames[0]);
    });


    //TODO Add a tear down file

});



