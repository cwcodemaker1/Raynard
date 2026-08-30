local Players = game:GetService("Players")

local OwnerGateOverride = false

local function OwnerGate()
	OwnerGateOverride = not OwnerGateOverride

	local gates = {
		"GFOwnerGate",
		"GFOwnerGate2",
		"TFOwnerGate"
	}

	for i = 1, 16 do
		local tycoon = workspace:FindFirstChild("Tycoon" .. i)

		if tycoon then
			local constructions = tycoon:FindFirstChild("Constructions")

			if constructions then
				for _, gateName in ipairs(gates) do
					local gate = constructions:FindFirstChild(gateName)

					if gate then
						local door = gate:FindFirstChild("OwnerOnlyDoor")

						if door and door:IsA("BasePart") then
							door.CanTouch = not OwnerGateOverride
						end
					end
				end
			end
		end
	end

	return OwnerGateOverride
end

local function CheckStaff(username)
	local player = Players:FindFirstChild(username)

	if not player then
		return false
	end

	local rank = player:GetRankInGroup(12266404)

	return rank > 0 and rank <= 253
end
