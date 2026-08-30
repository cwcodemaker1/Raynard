--!nonstrict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WarfareTycoon = {}

WarfareTycoon.Name = "WarfareTycoon"
WarfareTycoon.Version = "1.0.0"

local Config = {
    GroupId = 12266404,
    StaffMinimumRank = 1,
    StaffMaximumRank = 253,

    MaxTycoons = 16,
    TycoonPrefixes = {"Tycoon", "tycoon"},
    ConstructionsName = "Constructions",
    OwnerDoorName = "OwnerOnlyDoor",
    GateNames = {
        "GFOwnerGate",
        "GFOwnerGate2",
        "TFOwnerGate",
    },

    AutoWatchOwnerGates = true,
}

local State = {
    OwnerGateOverride = false,
    OriginalCanTouch = setmetatable({}, {__mode = "k"}),
    OwnerGateWatchConnection = nil,
    Destroyed = false,
}

local function copyArray(source)
    local result = {}
    for i, value in ipairs(source or {}) do
        result[i] = value
    end
    return result
end

local function copyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            result[key] = copyTable(value)
        else
            result[key] = value
        end
    end
    return result
end

local function arrayContains(source, wanted)
    for _, value in ipairs(source or {}) do
        if value == wanted then
            return true
        end
    end
    return false
end

local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function getTycoonIndexFromName(name)
    local lowered = string.lower(tostring(name or ""))
    local number = string.match(lowered, "^tycoon(%d+)$")
    return number and tonumber(number) or nil
end

local function isConfiguredGateName(name)
    return arrayContains(Config.GateNames, tostring(name or ""))
end

local function getTycoonByIndex(index)
    index = tonumber(index)
    if not index then
        return nil
    end

    index = math.floor(index)

    for _, prefix in ipairs(Config.TycoonPrefixes) do
        local tycoon = Workspace:FindFirstChild(prefix .. tostring(index))
        if tycoon then
            return tycoon
        end
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        if getTycoonIndexFromName(child.Name) == index then
            return child
        end
    end

    return nil
end

local function getConstructions(tycoon)
    if not tycoon then
        return nil
    end

    return tycoon:FindFirstChild(Config.ConstructionsName)
end

local function getDoorFromGate(gate)
    if not gate then
        return nil
    end

    local door = gate:FindFirstChild(Config.OwnerDoorName)
        or gate:FindFirstChild(Config.OwnerDoorName, true)

    if door and door:IsA("BasePart") then
        return door
    end

    return nil
end

local function isOwnerGateDoor(instance)
    if not instance or not instance:IsA("BasePart") then
        return false
    end

    if instance.Name ~= Config.OwnerDoorName then
        return false
    end

    local current = instance.Parent
    local foundGate = false
    local foundConstructions = false
    local foundTycoon = false

    while current and current ~= Workspace do
        if isConfiguredGateName(current.Name) then
            foundGate = true
        elseif current.Name == Config.ConstructionsName then
            foundConstructions = true
        elseif getTycoonIndexFromName(current.Name) then
            foundTycoon = true
        end

        current = current.Parent
    end

    return foundGate and foundConstructions and foundTycoon
end

local function rememberDoorState(door)
    if State.OriginalCanTouch[door] == nil then
        State.OriginalCanTouch[door] = door.CanTouch
    end
end

local function disableDoor(door)
    if not door or not door.Parent or not door:IsA("BasePart") then
        return false
    end

    rememberDoorState(door)
    door.CanTouch = false
    return true
end

local function restoreDoor(door)
    if not door or not door.Parent or not door:IsA("BasePart") then
        State.OriginalCanTouch[door] = nil
        return false
    end

    local original = State.OriginalCanTouch[door]
    if original ~= nil then
        door.CanTouch = original
        State.OriginalCanTouch[door] = nil
        return true
    end

    return false
end

local function collectOwnerGateEntries()
    local entries = {}
    local seenDoors = {}

    for index = 1, Config.MaxTycoons do
        local tycoon = getTycoonByIndex(index)
        local constructions = getConstructions(tycoon)

        if constructions then
            for _, gateName in ipairs(Config.GateNames) do
                local gate = constructions:FindFirstChild(gateName)
                local door = getDoorFromGate(gate)

                if door and not seenDoors[door] then
                    seenDoors[door] = true
                    table.insert(entries, {
                        TycoonIndex = index,
                        Tycoon = tycoon,
                        Constructions = constructions,
                        GateName = gateName,
                        Gate = gate,
                        Door = door,
                    })
                end
            end
        end
    end

    -- Also discover matching tycoons outside the configured numeric range.
    -- This keeps the module useful if the experience adds more tycoons later.
    for _, child in ipairs(Workspace:GetChildren()) do
        local index = getTycoonIndexFromName(child.Name)
        if index then
            local constructions = getConstructions(child)
            if constructions then
                for _, gateName in ipairs(Config.GateNames) do
                    local gate = constructions:FindFirstChild(gateName)
                    local door = getDoorFromGate(gate)

                    if door and not seenDoors[door] then
                        seenDoors[door] = true
                        table.insert(entries, {
                            TycoonIndex = index,
                            Tycoon = child,
                            Constructions = constructions,
                            GateName = gateName,
                            Gate = gate,
                            Door = door,
                        })
                    end
                end
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.TycoonIndex == b.TycoonIndex then
            return tostring(a.GateName) < tostring(b.GateName)
        end
        return (a.TycoonIndex or math.huge) < (b.TycoonIndex or math.huge)
    end)

    return entries
end

local function stopOwnerGateWatcher()
    safeDisconnect(State.OwnerGateWatchConnection)
    State.OwnerGateWatchConnection = nil
end

local function startOwnerGateWatcher()
    stopOwnerGateWatcher()

    if not Config.AutoWatchOwnerGates or not State.OwnerGateOverride then
        return
    end

    State.OwnerGateWatchConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if not State.OwnerGateOverride then
            return
        end

        if descendant.Name ~= Config.OwnerDoorName then
            return
        end

        task.defer(function()
            if State.OwnerGateOverride and isOwnerGateDoor(descendant) then
                pcall(function()
                    disableDoor(descendant)
                end)
            end
        end)
    end)
end

local function resolvePlayer(playerOrUsername)
    if typeof(playerOrUsername) == "Instance" and playerOrUsername:IsA("Player") then
        return playerOrUsername
    end

    local username = tostring(playerOrUsername or "")
    if username == "" then
        return nil
    end

    local exact = Players:FindFirstChild(username)
    if exact and exact:IsA("Player") then
        return exact
    end

    local lowered = string.lower(username)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == lowered then
            return player
        end
    end

    return nil
end

local function getRank(player)
    if not player then
        return 0
    end

    local ok, rank = pcall(function()
        return player:GetRankInGroup(Config.GroupId)
    end)

    if not ok then
        return 0
    end

    return tonumber(rank) or 0
end

local function getRole(player)
    if not player then
        return ""
    end

    local ok, role = pcall(function()
        return player:GetRoleInGroup(Config.GroupId)
    end)

    if not ok then
        return ""
    end

    return tostring(role or "")
end

-- Configuration --------------------------------------------------------------

function WarfareTycoon.GetConfig()
    return copyTable(Config)
end

function WarfareTycoon.Configure(configuration)
    if type(configuration) ~= "table" then
        return false
    end

    if tonumber(configuration.GroupId) then
        Config.GroupId = math.floor(tonumber(configuration.GroupId))
    end

    if tonumber(configuration.StaffMinimumRank) then
        Config.StaffMinimumRank = math.floor(tonumber(configuration.StaffMinimumRank))
    end

    if tonumber(configuration.StaffMaximumRank) then
        Config.StaffMaximumRank = math.floor(tonumber(configuration.StaffMaximumRank))
    end

    if tonumber(configuration.MaxTycoons) then
        Config.MaxTycoons = math.max(1, math.floor(tonumber(configuration.MaxTycoons)))
    end

    if type(configuration.TycoonPrefixes) == "table" then
        Config.TycoonPrefixes = copyArray(configuration.TycoonPrefixes)
    end

    if type(configuration.ConstructionsName) == "string" and configuration.ConstructionsName ~= "" then
        Config.ConstructionsName = configuration.ConstructionsName
    end

    if type(configuration.OwnerDoorName) == "string" and configuration.OwnerDoorName ~= "" then
        Config.OwnerDoorName = configuration.OwnerDoorName
    end

    if type(configuration.GateNames) == "table" then
        Config.GateNames = copyArray(configuration.GateNames)
    end

    if configuration.AutoWatchOwnerGates ~= nil then
        Config.AutoWatchOwnerGates = configuration.AutoWatchOwnerGates == true
    end

    if State.OwnerGateOverride then
        startOwnerGateWatcher()
        WarfareTycoon.RefreshOwnerGates()
    end

    return true
end

-- Tycoon discovery ------------------------------------------------------------

function WarfareTycoon.GetTycoon(index)
    return getTycoonByIndex(index)
end

function WarfareTycoon.GetTycoons()
    local tycoons = {}
    local seen = {}

    for index = 1, Config.MaxTycoons do
        local tycoon = getTycoonByIndex(index)
        if tycoon and not seen[tycoon] then
            seen[tycoon] = true
            table.insert(tycoons, tycoon)
        end
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        if getTycoonIndexFromName(child.Name) and not seen[child] then
            seen[child] = true
            table.insert(tycoons, child)
        end
    end

    table.sort(tycoons, function(a, b)
        return (getTycoonIndexFromName(a.Name) or math.huge) < (getTycoonIndexFromName(b.Name) or math.huge)
    end)

    return tycoons
end

function WarfareTycoon.GetOwnerGates()
    return collectOwnerGateEntries()
end

function WarfareTycoon.GetOwnerGateCount()
    return #collectOwnerGateEntries()
end

-- Owner gate override ---------------------------------------------------------

function WarfareTycoon.GetOwnerGateOverride()
    return State.OwnerGateOverride
end

function WarfareTycoon.RefreshOwnerGates()
    local entries = collectOwnerGateEntries()
    local changed = 0

    if State.OwnerGateOverride then
        for _, entry in ipairs(entries) do
            local ok, didChange = pcall(disableDoor, entry.Door)
            if ok and didChange then
                changed = changed + 1
            end
        end
    end

    return changed, entries
end

function WarfareTycoon.SetOwnerGateOverride(enabled)
    if State.Destroyed then
        return false, 0
    end

    enabled = enabled == true

    if enabled == State.OwnerGateOverride then
        if enabled then
            local changed = WarfareTycoon.RefreshOwnerGates()
            return true, changed
        end
        return true, 0
    end

    State.OwnerGateOverride = enabled

    local changed = 0

    if enabled then
        local entries = collectOwnerGateEntries()
        for _, entry in ipairs(entries) do
            local ok, didChange = pcall(disableDoor, entry.Door)
            if ok and didChange then
                changed = changed + 1
            end
        end
        startOwnerGateWatcher()
    else
        stopOwnerGateWatcher()

        local toRestore = {}
        for door in pairs(State.OriginalCanTouch) do
            table.insert(toRestore, door)
        end

        for _, door in ipairs(toRestore) do
            local ok, didChange = pcall(restoreDoor, door)
            if ok and didChange then
                changed = changed + 1
            end
        end
    end

    return State.OwnerGateOverride, changed
end

-- Backward-compatible function used by the Rayward client.
-- No argument: toggle.
-- Boolean argument: explicitly set the desired state.
function WarfareTycoon.OwnerGate(enabled)
    if enabled == nil then
        enabled = not State.OwnerGateOverride
    end

    local state = WarfareTycoon.SetOwnerGateOverride(enabled == true)
    return state
end

function WarfareTycoon.EnableOwnerGateOverride()
    return WarfareTycoon.SetOwnerGateOverride(true)
end

function WarfareTycoon.DisableOwnerGateOverride()
    return WarfareTycoon.SetOwnerGateOverride(false)
end

-- Staff checking --------------------------------------------------------------

function WarfareTycoon.GetGroupRank(playerOrUsername)
    return getRank(resolvePlayer(playerOrUsername))
end

function WarfareTycoon.GetGroupRole(playerOrUsername)
    return getRole(resolvePlayer(playerOrUsername))
end

function WarfareTycoon.GetStaffInfo(playerOrUsername)
    local player = resolvePlayer(playerOrUsername)

    if not player then
        return {
            Found = false,
            Player = nil,
            Username = tostring(playerOrUsername or ""),
            DisplayName = "",
            UserId = 0,
            Rank = 0,
            Role = "",
            IsStaff = false,
            GroupId = Config.GroupId,
        }
    end

    local rank = getRank(player)
    local role = getRole(player)
    local isStaff = rank >= Config.StaffMinimumRank and rank <= Config.StaffMaximumRank

    return {
        Found = true,
        Player = player,
        Username = player.Name,
        DisplayName = player.DisplayName,
        UserId = player.UserId,
        Rank = rank,
        Role = role,
        IsStaff = isStaff,
        GroupId = Config.GroupId,
    }
end

-- Backward-compatible function used by the Rayward client.
function WarfareTycoon.CheckStaff(username)
    return WarfareTycoon.GetStaffInfo(username).IsStaff == true
end

function WarfareTycoon.GetStaffPlayers()
    local result = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local info = WarfareTycoon.GetStaffInfo(player)
        if info.IsStaff then
            table.insert(result, info)
        end
    end

    table.sort(result, function(a, b)
        if a.Rank == b.Rank then
            return string.lower(a.Username) < string.lower(b.Username)
        end
        return a.Rank > b.Rank
    end)

    return result
end

function WarfareTycoon.CheckAllPlayers()
    local result = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(result, WarfareTycoon.GetStaffInfo(player))
    end

    table.sort(result, function(a, b)
        return string.lower(a.Username) < string.lower(b.Username)
    end)

    return result
end

-- State / cleanup -------------------------------------------------------------

function WarfareTycoon.GetState()
    return {
        OwnerGateOverride = State.OwnerGateOverride,
        OwnerGateCount = #collectOwnerGateEntries(),
        GroupId = Config.GroupId,
        StaffMinimumRank = Config.StaffMinimumRank,
        StaffMaximumRank = Config.StaffMaximumRank,
        MaxTycoons = Config.MaxTycoons,
        AutoWatchOwnerGates = Config.AutoWatchOwnerGates,
        Destroyed = State.Destroyed,
    }
end

function WarfareTycoon.Reset()
    if State.Destroyed then
        return false
    end

    WarfareTycoon.SetOwnerGateOverride(false)
    return true
end

function WarfareTycoon.Destroy()
    if State.Destroyed then
        return
    end

    WarfareTycoon.SetOwnerGateOverride(false)
    stopOwnerGateWatcher()
    State.Destroyed = true
end

WarfareTycoon.Cleanup = WarfareTycoon.Destroy

return WarfareTycoon
