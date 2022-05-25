return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
    local Promise = require(script.Parent.Parent.Parent.Promise)

    local DynamicStore = require(script.Parent.DynamicStore)
    local ClientDynamicStream = require(script.Parent.ClientDynamicStream)

    describe("ClientDynamicStream.new", function()
        it("should create a new ClientDynamicStream instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })
    
            expect(clientDynamicStream).to.be.ok()
            expect(ClientDynamicStream.is(clientDynamicStream)).to.equal(true)
    
            clientDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientDynamicStream.is", function()
        it("should return true if the passed argument is a ClientDynamicStream instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })
    
            expect(ClientDynamicStream.is(clientDynamicStream)).to.equal(true)
    
            clientDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return false if the passed argument is not a ClientDynamicStream instance", function()
            expect(ClientDynamicStream.is(true)).to.equal(false)
            expect(ClientDynamicStream.is(false)).to.equal(false)
            expect(ClientDynamicStream.is({})).to.equal(false)
            expect(ClientDynamicStream.is(0)).to.equal(false)
        end)
    end)

    describe("ClientDynamicStream:get", function()
        it("should return nil if no DynamicStore instance exists for the passed owner yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(clientDynamicStream:get("owner")).to.equal(nil)

            clientDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should get the DynamicStore instance owned by the passed owner", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            mockRemoteEvent:fireClient(nil, "stream", "owner")

            expect(clientDynamicStream:get("owner")).to.be.ok()
            expect(DynamicStore.is(clientDynamicStream:get("owner"))).to.equal(true)

            clientDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientDynamicStream:streamedAsync", function()
        it("should return a promise that resolves when a store with the passed owner is streamed in", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })
            
            local promise = clientDynamicStream:streamedAsync("owner")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal("Started")

            mockRemoteEvent:fireClient(nil, "stream", "owner")

            expect(promise:getStatus()).to.equal("Resolved")
            expect(clientDynamicStream:get("owner")).to.be.ok()

            clientDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientDynamicStream:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            }) 

            local function noop() end

            local connection0 = clientDynamicStream.streamed:connect(noop)
            local connection1 = clientDynamicStream.unstreaming:connect(noop)

            clientDynamicStream:destroy()
            mockRemoteEvent:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            clientDynamicStream:destroy()
            mockRemoteEvent:destroy()

            expect(clientDynamicStream.destroyed).to.equal(true)
        end)
    end)
end