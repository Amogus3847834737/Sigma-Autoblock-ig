local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- // SAFETY CHECK: VirtualInputManager //
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

-- // 1. CONFIGURATION // --
local SETTINGS = {
    Radius = 10, 
    DebounceTime = 0.1, 
    -- We use a simpler color definition to prevent errors
    VisualColor = Color3.new(1, 0, 0), -- Red
    VisualTransparency = 0.7,
    
    TargetAnimations = {
        "83315617640528",
        "124853830813308",
        "109073770803138",
        "117991143485398",
        "105018679651616",
        "72036716319034"
    }
}

-- // 2. CUSTOM JOYSTICK SETUP // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomJoystickUI"
if LocalPlayer:FindFirstChild("PlayerGui") then
    ScreenGui.Parent = LocalPlayer.PlayerGui
else
    -- Fallback if PlayerGui isn't ready
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
ScreenGui.ResetOnSpawn = false 

-- Joystick Background
local JoyBack = Instance.new("ImageLabel")
JoyBack.Name = "Background"
JoyBack.Parent = ScreenGui
JoyBack.BackgroundColor3 = Color3.new(0, 0, 0)
JoyBack.BackgroundTransparency = 0.5
JoyBack.Size = UDim2.new(0, 150, 0, 150)
JoyBack.Position = UDim2.new(0, 50, 1, -180) 
JoyBack.AnchorPoint = Vector2.new(0, 1) 
JoyBack.Image = "rbxassetid://8004055268" 
JoyBack.ImageTransparency = 1 
JoyBack.BorderSizePixel = 0

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = JoyBack

-- Joystick Knob
local JoyKnob = Instance.new("ImageLabel")
JoyKnob.Name = "Knob"
JoyKnob.Parent = JoyBack
JoyKnob.BackgroundColor3 = Color3.new(1, 1, 1)
JoyKnob.BackgroundTransparency = 0.2
JoyKnob.Size = UDim2.new(0, 60, 0, 60)
JoyKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
JoyKnob.AnchorPoint = Vector2.new(0.5, 0.5)
JoyKnob.BorderSizePixel = 0

local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(1, 0)
KnobCorner.Parent = JoyKnob

-- // 3. JOYSTICK LOGIC // --
local moveVector = Vector3.new(0, 0, 0)
local isDragging = false
local touchId = nil
local origin = nil
local maxDist = 75 

local function updateOrigin()
    if JoyBack and JoyBack.Parent then
        origin = JoyBack.AbsolutePosition + (JoyBack.AbsoluteSize / 2)
    end
end
updateOrigin()
JoyBack:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateOrigin)

JoyKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        touchId = input
        updateOrigin()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input == touchId or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local inputPos = input.Position
        local delta = Vector2.new(inputPos.X, inputPos.Y) - origin
        local dist = delta.Magnitude
        
        if dist > maxDist then
            delta = delta.Unit * maxDist
        end
        
        JoyKnob.Position = UDim2.new(0.5, delta.X, 0.5, delta.Y)
        
        local controlV2 = delta / maxDist
        moveVector = Vector3.new(controlV2.X, 0, controlV2.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == touchId or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        touchId = nil
        JoyKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
        moveVector = Vector3.new(0, 0, 0)
    end
end)

-- // MOVEMENT LOOP // --
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        
        if isDragging and moveVector.Magnitude > 0 then
            local cam = workspace.CurrentCamera
            local camLook = cam.CFrame.LookVector
            local camRight = cam.CFrame.RightVector
            
            camLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
            camRight = Vector3.new(camRight.X, 0, camRight.Z).Unit
            
            -- Direction logic
            local forward = moveVector.Z 
            local right = moveVector.X
            
            local finalDir = (camLook * forward) + (camRight * right)
            
            humanoid:Move(finalDir, true)
        end
    end
end)

-- // 4. AUTO-BLOCK LOGIC // --
local VisualPart = Instance.new("Part")
VisualPart.Name = "RadiusVisual"
VisualPart.Shape = Enum.PartType.Cylinder
VisualPart.Color = SETTINGS.VisualColor
VisualPart.Material = Enum.Material.Neon
VisualPart.Transparency = SETTINGS.VisualTransparency
VisualPart.Anchored = true
VisualPart.CanCollide = false
VisualPart.CastShadow = false
VisualPart.Size = Vector3.new(0.2, SETTINGS.Radius * 2, SETTINGS.Radius * 2) 
VisualPart.Parent = workspace

local lastPress = 0

local function checkAnimations(humanoid)
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    local tracks = animator:GetPlayingAnimationTracks()
    for _, track in pairs(tracks) do
        local animId = track.Animation.AnimationId
        for _, targetId in pairs(SETTINGS.TargetAnimations) do
            if string.find(tostring(animId), targetId) then return true end
        end
    end
    return false
end

local function triggerAction()
    if tick() - lastPress > SETTINGS.DebounceTime then
        lastPress = tick()
        
        task.spawn(function()
            -- 1. Try generic keypress (Executor specific)
            if keypress then
                keypress(0x51)
                task.wait(0.05)
                if keyrelease then keyrelease(0x51) end
                
            -- 2. Try VirtualInputManager (Official Roblox Method)
            elseif VirtualInputManager then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                end)
            
            -- 3. Fallback: Print error if neither works
            else
                warn("Cannot press Q: keypress() and VirtualInputManager both failed.")
            end
        end)
        return true
    end
    return false
end

local function updateLoop()
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
        VisualPart.CFrame = CFrame.new(0, -1000, 0)
        return
    end

    local myRoot = LocalPlayer.Character.HumanoidRootPart
    VisualPart.CFrame = myRoot.CFrame * CFrame.Angles(0, 0, math.rad(90))

    local entitiesToScan = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then table.insert(entitiesToScan, plr.Character) end
    end
    local mapFolder = workspace:FindFirstChild("LobbyMap")
    if mapFolder then
        for _, obj in pairs(mapFolder:GetChildren()) do
            if obj:IsA("Model") then table.insert(entitiesToScan, obj) end
        end
    end

    for _, character in pairs(entitiesToScan) do
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart and humanoid.Health > 0 then
            if (rootPart.Position - myRoot.Position).Magnitude <= SETTINGS.Radius then
                if checkAnimations(humanoid) then
                    if triggerAction() then break end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(updateLoop)
print("Safe-Mode Script Loaded (No Crash)")
