local P=game:GetService("Players")
local AS=game:GetService("AssetService")
local MS=game:GetService("MarketplaceService")

local LP=P.LocalPlayer
local C=LP.Character or LP.CharacterAdded:Wait()
local H=C:WaitForChild("Humanoid")

if H.RigType==Enum.HumanoidRigType.R15 then
	C:WaitForChild("Head")
	C:WaitForChild("UpperTorso")
	C:WaitForChild("LowerTorso")
else
	C:WaitForChild("Head")
	C:WaitForChild("Torso")
end

local function V(x,y,z)return Vector3.new(x,y,z)end
local function F(...)return CFrame.new(...)end

-- name, body, relative, size, mesh, texture, scale, mesh-name, attachment, attachment-cframe
local O={
{"Accessory (Astray AVSPouches AOR1)","UpperTorso",
F(-.0050201416,.171539307,-.296020508,-1,-1.86264515e-9,1.49011612e-8,1.86264515e-9,1,6.51925802e-9,1.49011612e-8,-6.51925802e-9,-1.00000012),
V(4,1,2),"15892898774","16064071317",V(1,1,1),"SpecialMesh","BodyFrontAttachment",
F(-.00499999989,-.371499985,.203999996,-1,0,0,0,1,0,0,0,-1)},

{"Accessory (Warrior)","LowerTorso",
F(-.0122070312,-.291381836,.108032227,-1,0,0,0,1,7.10542736e-15,0,-7.10542736e-15,-1),
V(1,1,1),"18801967820","18802049125",V(1,1,1),"SpecialMesh","WaistCenterAttachment",
F(-.0122375488,.0913989544,.107852235,-1,0,0,0,1,0,0,0,-1)},

{"Accessory (Astray AVSVest AOR1)","UpperTorso",
F(-.0000152587891,.0865478516,-.0169677734,-1,-1.86264515e-9,1.49011612e-8,1.86264515e-9,1,6.51925802e-9,1.49011612e-8,-6.51925802e-9,-1.00000012),
V(4,1,2),"15892810096","16064073758",V(1,1,1),"SpecialMesh","BodyFrontAttachment",
F(0,-.286500007,.48300001,-1,0,0,0,1,0,0,0,-1)},

{"Accessory (Astray AVSBag AOR1)","UpperTorso",
F(-.0000152587891,-.00994873047,.826904297,-1,-1.86264515e-9,1.49011612e-8,1.86264515e-9,1,6.51925802e-9,1.49011612e-8,-6.51925802e-9,-1.00000012),
V(4,1,2),"15892813229","16064070309",V(1,1,1),"SpecialMesh","BodyBackAttachment",
F(0,-.189999998,.326880008,-1,0,0,0,1,0,0,0,-1)},

{"Accessory (MeshPartAccessory)","Head",
F(0,-.0219726562,.126586914,1.00000012,3.7252903e-9,-7.4505806e-9,3.7252903e-9,1.00000012,-5.96046448e-8,-7.4505806e-9,-5.96046448e-8,1.00000024),
V(1,1,1),"17430683489","17430701737",V(1,1,1),"SpecialMesh","HatAttachment",
F(0,.621938229,-.126529887,1,0,0,0,1,0,0,0,1)},

{"Accessory (lightyear)","Head",
F(0,.255004883,.0100097656,1.00000012,3.7252903e-9,-7.4505806e-9,3.7252903e-9,1.00000012,-5.96046448e-8,-7.4505806e-9,-5.96046448e-8,1.00000024),
V(2.01999998,1.00999999,1.00999999),"18156701514","18182544494",V(1.00999999,1.00999999,1.00999999),"Mesh","HairAttachment",
F(0,.344999313,-.00999999978,1,0,0,0,1,0,0,0,1)},

{"SleekTacticalShades","Head",
F(-.000183105469,.239990234,-.252075195,1.00000012,3.7252903e-9,-7.4505806e-9,3.7252903e-9,1.00000012,-5.96046448e-8,-7.4505806e-9,-5.96046448e-8,1.00000024),
V(1,1,1),"4082773106","4503278984",V(1,1,1),"SpecialMesh","FaceFrontAttachment",
F(.000186920166,-.239979744,-.347869873,1,0,0,0,1,0,0,0,1)},

{"Desert Shemagh","UpperTorso",
F(-.0323944092,.590606689,-.0604248047,-1,-1.86264515e-9,1.49011612e-8,1.86264515e-9,1,6.51925802e-9,1.49011612e-8,-6.51925802e-9,-1.00000012),
V(1,1,1),"8083432163","8083442602",V(1,1,1),"SpecialMesh","NeckAttachment",
F(-.0324092582,.209451914,-.0604430027,-1,0,0,0,1,0,0,0,-1)},

{"Accessory (AOR1)","Head",
F(-.0128936768,.514862061,.226074219,-1.00000012,3.7252903e-9,7.4505806e-9,-3.7252903e-9,1.00000012,5.96046448e-8,7.4505806e-9,-5.96046448e-8,-1.00000024),
V(1,1,1),"97073140332698","104575487804734",V(1,1,1),"SpecialMesh","HatAttachment",
F(-.0128860474,.0851502419,.226051331,-1,0,0,0,1,0,0,0,-1)},

{"Accessory (FTHSAccessory)","Head",
F(-.0000152587891,.236297607,.041015625,1.00000012,3.7252903e-9,-7.4505806e-9,3.7252903e-9,1.00000012,-5.96046448e-8,-7.4505806e-9,-5.96046448e-8,1.00000024),
V(4,1,2),"17172666849","17172687364",V(1,1,1),"Mesh","HatAttachment",
F(0,.363691807,-.0410003662,1,0,0,0,1,0,0,0,1)}
}

local function body(n)
	local x=C:FindFirstChild(n) or C:WaitForChild(n,2)
	if x and x:IsA("BasePart")then return x end
	if n=="UpperTorso" or n=="LowerTorso" then
		x=C:FindFirstChild("Torso")
		if x and x:IsA("BasePart")then return x end
	end
end

local function clearWelds(a)
	for _,x in ipairs(a:GetDescendants())do
		if (x:IsA("JointInstance") or x:IsA("WeldConstraint"))
		and (x.Name=="AccessoryWeld" or x.Name=="HeadWeld") then x:Destroy() end
	end
end

local function addDump(d)
	local b=body(d[2])
	if not b then return end

	local a=Instance.new("Accessory")
	a.Name=d[1]

	local h=Instance.new("Part")
	h.Name="Handle"
	h.Size=d[4]
	h.Anchored=false
	h.CanCollide=false
	h.CanTouch=false
	h.Massless=true
	h.Parent=a

	local m=Instance.new("SpecialMesh")
	m.Name=d[8]
	m.MeshType=Enum.MeshType.FileMesh
	m.MeshId="rbxassetid://"..d[5]
	m.TextureId="rbxassetid://"..d[6]
	m.Scale=d[7]
	m.Parent=h

	local at=Instance.new("Attachment")
	at.Name=d[9]
	at.CFrame=d[10]
	at.Parent=h

	a.Parent=C
	h.CFrame=b.CFrame*d[3]

	local w=Instance.new("Weld")
	w.Name="AccessoryWeld"
	w.Part0=h
	w.Part1=b
	w.C0=CFrame.identity
	w.C1=d[3]
	w.Parent=h
end

-- layered MeshPart item from dump
local function addLayered()
	local mesh="https://assetdelivery.roblox.com/v1/asset/?id=13684480556"
	local h

	pcall(function()
		h=AS:CreateMeshPartAsync(mesh,Enum.CollisionFidelity.Default,Enum.RenderFidelity.Precise)
	end)

	if not h then
		pcall(function()
			local t=game:GetObjects(mesh)
			for _,x in ipairs(t)do
				if x:IsA("MeshPart")then h=x break end
				h=h or x:FindFirstChildWhichIsA("MeshPart",true)
			end
		end)
	end

	if not h then return end

	local a=Instance.new("Accessory")
	a.Name="Accessory"

	h.Name="Handle"
	h.Size=V(.460280716,.0617623329,.0514787436)
	h.Anchored=false
	h.CanCollide=false
	h.CanTouch=false
	h.Massless=true
	h.Parent=a

	local at=Instance.new("Attachment")
	at.Name="FaceFront"
	at.CFrame=F(3.08952779e-16,-.0143091679,-.594028473,1,0,0,0,1,0,0,0,1)
	at.Parent=h

	pcall(function()
		local s=Instance.new("SurfaceAppearance")
		s.ColorMap="rbxassetid://13682617707"
		s.MetalnessMap="rbxassetid://13036533281"
		s.RoughnessMap="rbxassetid://13036535605"
		s.AlphaMode=Enum.AlphaMode.Overlay
		s.Parent=h
	end)

	pcall(function()
		local w=Instance.new("WrapLayer")
		w.CageMeshId="https://assetdelivery.roblox.com/v1/asset/?id=13684480557"
		w.ReferenceMeshId="https://assetdelivery.roblox.com/v1/asset/?id=13684480561"
		w.CageOrigin=F(-.00121644884,-.321609735,.541555643,1,0,0,0,1,0,0,0,1)
		w.ReferenceOrigin=F(-.00121644884,-.321609735,.543825269,1,0,0,0,1,0,0,0,1)
		w.Order=1
		w.Puffiness=1
		w.Enabled=true
		w.Parent=h
	end)

	local b=body("Head")
	if not b then a:Destroy() return end

	local r=F(.000900268555,.309844971,-.572998047,1.00000012,3.7252903e-9,-7.4505806e-9,3.7252903e-9,1.00000012,-5.96046448e-8,-7.4505806e-9,-5.96046448e-8,1.00000024)

	a.Parent=C
	h.CFrame=b.CFrame*r

	local w=Instance.new("Weld")
	w.Name="AccessoryWeld"
	w.Part0=h
	w.Part1=b
	w.C1=r
	w.Parent=h
end

--------------------------------------------------
-- CLEAR OLD OUTFIT
--------------------------------------------------

for _,x in ipairs(C:GetChildren())do
	if x:IsA("Accessory") or x:IsA("Shirt") or x:IsA("Pants") or x:IsA("ShirtGraphic") then
		x:Destroy()
	end
end

local s=Instance.new("Shirt")
s.Name="Shirt"
s.ShirtTemplate="rbxassetid://123545248115256"
s.Parent=C

local p=Instance.new("Pants")
p.Name="Pants"
p.PantsTemplate="rbxassetid://100446879220446"
p.Parent=C

for _,d in ipairs(O)do addDump(d) end
addLayered()

--------------------------------------------------
-- EXTRA IDS - TEMP RIG METHOD
--------------------------------------------------

local function charAttachment(n)
	for _,x in ipairs(C:GetDescendants())do
		if x:IsA("Attachment") and x.Name==n
		and x.Parent and x.Parent:IsA("BasePart") then
			return x
		end
	end
end

local function properName(id,a)
	local n
	pcall(function()
		local i=MS:GetProductInfo(id,Enum.InfoType.Asset)
		n=i and i.Name
	end)
	a.Name=n and ("Accessory ("..n..")") or a.Name
end

local function addID(id,t)
	local d=Instance.new("HumanoidDescription")

	local ok=pcall(function()
		d:SetAccessories({{AssetId=id,AccessoryType=t}},true)
	end)

	if not ok then d:Destroy() return end

	local rig
	ok=pcall(function()
		rig=P:CreateHumanoidModelFromDescriptionAsync(d,Enum.HumanoidRigType.R15)
	end)

	d:Destroy()
	if not ok or not rig then return end

	local src=rig:FindFirstChildWhichIsA("Accessory",true)
	if not src then rig:Destroy() return end

	local a=src:Clone()
	properName(id,a)
	clearWelds(a)

	local h=a:FindFirstChild("Handle")
	if not h or not h:IsA("BasePart") then
		a:Destroy()
		rig:Destroy()
		return
	end

	local aa,ta

	for _,x in ipairs(h:GetDescendants())do
		if x:IsA("Attachment") then
			local y=charAttachment(x.Name)
			if y then aa,ta=x,y break end
		end
	end

	if not aa then
		a:Destroy()
		rig:Destroy()
		return
	end

	h.Anchored=false
	h.CanCollide=false
	h.CanTouch=false
	h.Massless=true

	a.Parent=C
	h.CFrame=ta.WorldCFrame*aa.CFrame:Inverse()

	local w=Instance.new("Weld")
	w.Name="AccessoryWeld"
	w.Part0=h
	w.Part1=ta.Parent
	w.C0=aa.CFrame
	w.C1=ta.CFrame
	w.Parent=h

	rig:Destroy()
end

addID(17182483146,Enum.AccessoryType.Shoulder)
addID(74406183510198,Enum.AccessoryType.Back)
