local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local OwnerGateOverride = false

local function OwnerGate()
    OwnerGateOverride = not OwnerGateOverride
    
    for i = 1, 16 do
        local constructions = workspace["Tycoon"..i]:FindFirstChild("Constructions")
        if constructions then
            local gates = {"GFOwnerGate", "GFOwnerGate2", "TFOwnerGate"}
            
            for _, gateName in ipairs(gates) do
                local d = constructions:FindFirstChild(gateName)
                if d and d:FindFirstChild("OwnerOnlyDoor") then
                    d.OwnerOnlyDoorDoor.CanTouch = not OwnerGateOverride
                end
            end
        end
    end
end

local function CheckStaff(username)
	local p = Players:FindFirstChild(username)
	local rank = p and p:GetRankInGroup(12266404) or 0
	return rank > 0 and rank <= 253
end
