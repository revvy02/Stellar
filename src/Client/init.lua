local Promise = require(script.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Cleaner)
local Slick = require(script.Parent.Parent.Slick)

local constructors = {
    ClientSignals = require(script.ClientSignal),
    ClientCallbacks = require(script.ClientCallback),
    ClientDynamicStores = require(script.ClientDynamicStore),
    ClientDynamicStreams = require(script.ClientDynamicStream),
    ClientStaticStores = require(script.ClientStaticStore),
    ClientStaticStreams = require(script.ClientStaticStream),
}

local Client = {}
Client.__index = Client

function Client.new(folder)
    local self = setmetatable({}, Client)

    self._cleaner = Cleaner.new()

    self._elements = self._cleaner:give(Slick.Store.new())
    
    for _, directory in pairs(folder:GetChildren()) do
        self:_directoryAdded(directory)
    end

    self._cleaner:give(folder.ChildAdded:Connect(function(directory)
        self:_directoryAdded(directory)
    end))

    self._cleaner:give(folder.ChildRemoved:Connect(function(directory)
        self:_directoryRemoved(directory)
    end))

    return self
end

function Client:_directoryAdded(directory)
    local cleaner = self._cleaner:set(directory, Cleaner.new())

    self._elements:rawset(directory, {})

    local function remotesAdded(remotes)
        self._elements:dispatch(directory, "setIndex", remotes.Name, cleaner:set(remotes.Name, constructors[directory].new({
            remoteEvent = remotes:FindFirstChild("RemoteEvent"),
            remoteFunction = remotes:FindFirstChild("RemoteFunction"),
        })))
    end

    local function remotesRemoved(remotes)
        cleaner:finalize(remotes.Name)
    end

    for _, remotes in pairs(directory:GetChildren()) do
        remotesAdded(remotes)
    end

    cleaner:give(directory.ChildAdded:Connect(remotesAdded))
    cleaner:give(directory.ChildRemoved:Connect(remotesRemoved))
end

function Client:_directoryRemoved(directory)
    self._cleaner:finalize(directory)
end

function Client:_getElementAsync(directory, name)
    if self._elements:get(directory)[name] then
        return self._elements:get(directory)[name]
    end

    return Promise.fromEvent(self._elements:getReducedSignal(directory), function(reducer, elementName)
        return reducer == "setIndex" and elementName == name
    end):andThen(function()
        return self._elements:get(directory)[name]
    end)
end

function Client:getClientSignalAsync(name)
    return self:_getElementAsync("ClientSignals", name)
end

function Client:getClientCallbackAsync(name)
    return self:_getElementAsync("ClientCallback", name)
end

function Client:getClientDynamicStreamAsync(name)
    return self:_getElementAsync("ClientDynamicStream", name)
end

function Client:getClientStaticStreamAsync(name)
    return self:_getElementAsync("ClientStaticStream", name)
end

function Client:destroy()
    self._cleaner:destroy()
end

return Client