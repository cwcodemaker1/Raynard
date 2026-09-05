function Section:AddViewportModel(configuration)
    configuration = configuration or {}
    local app = self.App
    local source = configuration.Model
    local row = self:_Row(configuration.Height or 220)
    local viewport = create("ViewportFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.BackgroundColor or app.Config.Colors.Background2, BorderSizePixel = 0, Ambient = configuration.Ambient or Color3.fromRGB(180, 180, 180), LightColor = configuration.LightColor or Color3.new(1, 1, 1), LightDirection = configuration.LightDirection or Vector3.new(-1, -1, -1)})
    corner(viewport, app.Config.Radius.Control)
    local camera = Instance.new("Camera") camera.Parent = viewport viewport.CurrentCamera = camera
    local world = Instance.new("WorldModel") world.Parent = viewport
    local id = app:_MakeId("ViewportModel", configuration.Id)
    local control = self:_Control(id, "ViewportModel", configuration.Text or "Viewport", row, configuration)
    local clone
    local rotation = 0
    local autoRotate = configuration.AutoRotate == true
    local function clear() if clone then clone:Destroy() clone = nil end end
    local function frameModel()
        if not clone then return end
        local cf, size
        if clone:IsA("Model") then cf, size = clone:GetBoundingBox() elseif clone:IsA("BasePart") then cf, size = clone.CFrame, clone.Size else return end
        local maxSize = math.max(size.X, size.Y, size.Z)
        local distance = math.max(3, maxSize * (configuration.Zoom or 1.8))
        camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y * 0.15, distance), cf.Position)
    end
    local function set(newSource, silent)
        clear() source = newSource
        if typeof(source) == "Instance" then
            local ok, result = pcall(function() return source:Clone() end)
            if ok and result then clone = result clone.Parent = world frameModel() end
        end
        if not silent then self:_Emit(control, "ViewportModelChanged", source, nil) app:_Callback(configuration.Callback, source, control) end
        return source
    end
    local connection = RunService.RenderStepped:Connect(function(dt)
        if autoRotate and clone then
            rotation += dt * (configuration.RotationSpeed or 35)
            if clone:IsA("Model") then local pivot = clone:GetPivot() clone:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.rad(rotation), 0)) elseif clone:IsA("BasePart") then clone.CFrame = CFrame.new(clone.Position) * CFrame.Angles(0, math.rad(rotation), 0) end
        end
    end)
    table.insert(control._connections, connection)
    control._getter = function() return source end control._setter = set
    function control:SetAutoRotate(state) autoRotate = state == true return self end
    function control:Frame() frameModel() return self end
    function control:GetClone() return clone end
    set(source, true)
    return app:_Register(control)
end

function Section:AddAvatarViewport(configuration)
    configuration = configuration or {}
    local app = self.App
    local player = configuration.Player or Players.LocalPlayer
    local row = self:_Row(configuration.Height or 240)
    local viewport = create("ViewportFrame", {
        Parent = row,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = configuration.BackgroundColor or app.Config.Colors.Background2,
        BorderSizePixel = 0,
        Ambient = configuration.Ambient or Color3.fromRGB(190, 190, 190),
        LightColor = configuration.LightColor or Color3.new(1, 1, 1),
        LightDirection = configuration.LightDirection or Vector3.new(-1, -1, -1),
    })
    corner(viewport, app.Config.Radius.Control)

    local world = Instance.new("WorldModel")
    world.Name = "RaynardAvatarWorld"
    world.Parent = viewport

    local camera = Instance.new("Camera")
    camera.Name = "RaynardAvatarCamera"
    camera.FieldOfView = clamp(tonumber(configuration.FieldOfView) or 70, 1, 120)
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local id = app:_MakeId("AvatarViewport", configuration.Id)
    local control = self:_Control(id, "AvatarViewport", configuration.Text or "Avatar", row, configuration)

    local model = nil
    local basePivot = nil
    local generation = 0
    local autoRotate = configuration.AutoRotate == true
    local rotationSpeed = tonumber(configuration.RotationSpeed) or 35
    local rotation = tonumber(configuration.Rotation) or 0
    local fixedRotation

    if typeof(configuration.FixedRotation) == "Vector3" then
        fixedRotation = configuration.FixedRotation
    else
        fixedRotation = Vector3.new(
            tonumber(configuration.FixedRotationX) or 0,
            tonumber(configuration.FixedRotation) or 0,
            tonumber(configuration.FixedRotationZ) or 0
        )
    end

    local function normalizeDegrees(value)
        value = tonumber(value) or 0
        value %= 360
        if value < 0 then value += 360 end
        return value
    end

    local function applyRotation()
        if not model or not model.Parent or not basePivot then return end
        model:PivotTo(basePivot * CFrame.Angles(
            math.rad(fixedRotation.X),
            math.rad(fixedRotation.Y + rotation),
            math.rad(fixedRotation.Z)
        ))
    end

    local function frameModel()
        if not model or not model.Parent then return end
        local cf, size = model:GetBoundingBox()
        local maxSize = math.max(size.X, size.Y, size.Z)
        local distance = math.max(4, maxSize * (tonumber(configuration.Zoom) or 1.8))
        local target = cf.Position + Vector3.new(0, size.Y * (tonumber(configuration.VerticalOffset) or 0.05), 0)
        camera.CFrame = CFrame.lookAt(target + Vector3.new(0, size.Y * 0.05, distance), target)
    end

    local function prepareRig(rig)
        local root = rig:FindFirstChild("HumanoidRootPart") or rig.PrimaryPart or rig:FindFirstChildWhichIsA("BasePart", true)
        local humanoid = rig:FindFirstChildOfClass("Humanoid")
        for _, object in ipairs(rig:GetDescendants()) do
            if object:IsA("BasePart") then
                object.CanCollide = false
                object.CanTouch = false
                object.CanQuery = false
                object.Anchored = object == root
            end
        end
        if root and not rig.PrimaryPart then pcall(function() rig.PrimaryPart = root end) end
        if humanoid then
            humanoid.AutoRotate = false
            humanoid.BreakJointsOnDeath = false
            pcall(function()
                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end)
        end
    end

    local function set(target, silent)
        if typeof(target) == "number" then
            for _, candidate in ipairs(Players:GetPlayers()) do
                if candidate.UserId == target then target = candidate break end
            end
        end
        if not (typeof(target) == "Instance" and target:IsA("Player")) then return player end
        player = target
        generation += 1
        local thisGeneration = generation
        local targetUserId = target.UserId
        if model then model:Destroy() model = nil end
        basePivot = nil

        task.spawn(function()
            local ok, created = pcall(function()
                local creator = Players.CreateHumanoidModelFromUserIdAsync or Players.CreateHumanoidModelFromUserId
                return creator(Players, targetUserId)
            end)
            if not ok or not created or thisGeneration ~= generation or not world.Parent then
                if created then created:Destroy() end
                return
            end
            model = created
            model.Name = "RaynardAvatar_" .. tostring(targetUserId)
            model.Parent = world
            prepareRig(model)
            basePivot = model:GetPivot()
            rotation = tonumber(configuration.Rotation) or 0
            applyRotation()
            RunService.Heartbeat:Wait()
            if model and model.Parent then frameModel() end
        end)

        if not silent then
            self:_Emit(control, "AvatarChanged", player, nil)
            app:_Callback(configuration.Callback, player, control)
        end
        return player
    end

    local connection = RunService.RenderStepped:Connect(function(dt)
        if autoRotate and model and model.Parent and basePivot then
            rotation = (rotation + dt * rotationSpeed) % 360
            applyRotation()
        end
    end)
    table.insert(control._connections, connection)

    control._getter = function() return player end
    control._setter = set

    function control:SetAutoRotate(state) autoRotate = state == true return self end
    function control:GetAutoRotate() return autoRotate end
    function control:SetRotationSpeed(speed) rotationSpeed = tonumber(speed) or rotationSpeed return self end
    function control:GetRotationSpeed() return rotationSpeed end
    function control:SetRotation(degrees) rotation = normalizeDegrees(degrees) applyRotation() return self end
    function control:GetRotation() return rotation end
    function control:SetFixedRotation(value)
        if typeof(value) == "Vector3" then
            fixedRotation = value
        else
            fixedRotation = Vector3.new(fixedRotation.X, tonumber(value) or fixedRotation.Y, fixedRotation.Z)
        end
        applyRotation()
        return self
    end
    function control:GetFixedRotation() return fixedRotation end
    function control:ResetRotation() rotation = 0 applyRotation() return self end
    function control:Frame() frameModel() return self end
    function control:GetModel() return model end
    function control:GetViewport() return viewport end
    function control:GetCamera() return camera end
    function control:GetWorldModel() return world end

    set(player, true)
    return app:_Register(control)
end
