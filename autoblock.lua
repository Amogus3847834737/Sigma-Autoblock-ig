local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // 1. SAFETY & CONFIG //
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local STATE = {
    AutoBlockEnabled = true, 
    JoystickEnabled = true,
    AimlockEnabled = false 
}

local SETTINGS = {
    Radius = 10,             
    AimRadius = 200,         
    DebounceTime = 0.1, 
    VisualColor = Color3.new(1, 0, 0),
    
    TargetAnimations = {
        "83315617640528", "124853830813308", "109073770803138",
        "117991143485398", "105018679651616", "72036716319034"
    }
}

-- // 2. GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CombatAssist_Mobile_CharLock"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- > Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.5, -100, 0.3, 0) 
MainFrame.Size = UDim2.new(0, 200, 0, 200) 
MainFrame.Active = true

-- > Drag Logic
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

-- > Title 
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "  COMBAT ASSIST"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

-- > Minimize/Open Buttons
local MiniBtn = Instance.new("TextButton")
MiniBtn.Parent = MainFrame
MiniBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
MiniBtn.Position = UDim2.new(1, -30, 0, 0)
MiniBtn.Size = UDim2.new(0, 30, 0, 30)
MiniBtn.Font = Enum.Font.SourceSansBold
MiniBtn.Text = "-"
MiniBtn.TextColor3 = Color3.new(1, 1, 1)
MiniBtn.TextSize = 20

local OpenBtn = Instance.new("TextButton")
OpenBtn.Parent = ScreenGui
OpenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
OpenBtn.Position = UDim2.new(0, 10, 0.5, 0)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.Text = "MENU"
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.Visible = false

-- // BUTTONS //
local function createBtn(text, order)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80) 
    btn.Position = UDim2.new(0.05, 0, 0.2 + (order * 0.22), 0)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 18
    return btn
end

local BlockBtn = createBtn("Auto Block: ON", 0.2)
local JoyBtn = createBtn("Joystick: ON", 1.2)
local AimBtn = createBtn("Char Lock: OFF", 2.2)
AimBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) 

-- // 3. BUTTON LOGIC //
MiniBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenBtn.Visible = true end)
OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true; OpenBtn.Visible = false end)

BlockBtn.MouseButton1Click:Connect(function()
    STATE.AutoBlockEnabled = not STATE.AutoBlockEnabled
    BlockBtn.Text = STATE.AutoBlockEnabled and "Auto Block: ON" or "Auto Block: OFF"
    BlockBtn.BackgroundColor3 = STATE.AutoBlockEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)
end)

JoyBtn.MouseButton1Click:Connect(function()
    STATE.JoystickEnabled = not STATE.JoystickEnabled
    JoyBtn.Text = STATE.JoystickEnabled and "Joystick: ON" or "Joystick: OFF"
    JoyBtn.BackgroundColor3 = STATE.JoystickEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)
end)

AimBtn.MouseButton1Click:Connect(function()
    STATE.AimlockEnabled = not STATE.AimlockEnabled
    AimBtn.Text = STATE.AimlockEnabled and "Char Lock: ON" or "Char Lock: OFF"
    AimBtn.BackgroundColor3 = STATE.AimlockEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)
end)

-- // 4. JOYSTICK SETUP //
local JoyFrame = Instance.new("Frame")
JoyFrame.Parent = ScreenGui
JoyFrame.BackgroundTransparency = 1
JoyFrame.Size = UDim2.new(1, 0, 1, 0)

local JoyBack = Instance.new("ImageLabel")
JoyBack.Parent = JoyFrame
JoyBack.BackgroundColor3 = Color3.new(0, 0, 0)
JoyBack.BackgroundTransparency = 0.5
JoyBack.Size = UDim2.new(0, 150, 0, 150)
JoyBack.Position = UDim2.new(0, 50, 1, -100) -- Lowered position
JoyBack.Image = "rbxassetid://8004055268"
JoyBack.ImageTransparency = 1 

local JoyKnob = Instance.new("ImageLabel")
JoyKnob.Parent = JoyBack
JoyKnob.BackgroundColor3 = Color3.new(1, 1, 1)
JoyKnob.BackgroundTransparency = 0.2
JoyKnob.Size = UDim2.new(0, 60, 0, 60)
JoyKnob.Position = UDim2.new(0.5, -30, 0.5, -30) 
JoyKnob.BorderSizePixel = 0

local moveInput = Vector2.new(0,0) -- Holds X/Y strength
local isDragging = false
local touchId = nil
local origin = nil
local maxDist = 75

local function updateOrigin()
    if JoyBack and JoyBack.Parent then origin = JoyBack.AbsolutePosition + (JoyBack.AbsoluteSize / 2) end
end
updateOrigin()

JoyKnob.InputBegan:Connect(function(input)
    if not STATE.JoystickEnabled then return end
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
        
        -- Clamp logic
        if dist > maxDist then delta = delta.Unit * maxDist end
        
        JoyKnob.Position = UDim2.new(0.5, delta.X - 30, 0.5, delta.Y - 30)
        
        -- Normalize input (-1 to 1)
        moveInput = delta / maxDist
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == touchId or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        touchId = nil
        JoyKnob.Position = UDim2.new(0.5, -30, 0.5, -30)
        moveInput = Vector2.new(0,0)
    end
end)

-- // 5. TARGETING SYSTEM (RootPart Only) //
local function getClosestTarget()
    local closestDist = SETTINGS.AimRadius
    local targetRootPart = nil
    
    local entities = {}
    for _, p in pairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer and p.Character then table.insert(entities, p.Character) end 
    end
    if workspace:FindFirstChild("LobbyMap") then
        for _, o in pairs(workspace.LobbyMap:GetChildren()) do if o:IsA("Model") then table.insert(entities, o) end end
    end
    
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    for _, char in pairs(entities) do
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if root and hum and hum.Health > 0 then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                targetRootPart = root 
            end
        end
    end
    return targetRootPart
end

-- // MAIN RUN LOOP //
RunService.RenderStepped:Connect(function()
    -- 1. Joystick Movement (RE-FIXED)
    JoyFrame.Visible = STATE.JoystickEnabled
    
    -- Check Character Existence
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if hum and root then
        
        -- JOYSTICK MOVEMENT
        if STATE.JoystickEnabled and isDragging and moveInput.Magnitude > 0 then
            local cam = workspace.CurrentCamera
            -- Get flat camera vectors
            local camLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
            local camRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
            
            -- LOGIC: 
            -- Drag UP (Negative Y) = Forward. 
            -- Drag DOWN (Positive Y) = Backward.
            -- Drag RIGHT (Positive X) = Right.
            
            local forwardStrength = -moveInput.Y -- Invert Y so Up is positive
            local rightStrength = moveInput.X
            
            local moveDir = (camLook * forwardStrength) + (camRight * rightStrength)
            hum:Move(moveDir, true)
        end

        -- CHARACTER AIMLOCK (Turns Body)
        if STATE.AimlockEnabled then
            local target = getClosestTarget()
            if target then
                -- Look at target, but keep Y level (Don't tilt into ground)
                local lookPos = Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)
                root.CFrame = CFrame.lookAt(root.Position, lookPos)
            end
        end
    end
end)

-- // AUTO BLOCK LOGIC //
local VisualPart = Instance.new("Part")
VisualPart.Name = "RadiusVisual"
VisualPart.Shape = Enum.PartType.Cylinder
VisualPart.Color = SETTINGS.VisualColor
VisualPart.Material = Enum.Material.Neon
VisualPart.Transparency = 0.7
VisualPart.Anchored = true
VisualPart.CanCollide = false
VisualPart.CastShadow = false
VisualPart.Size = Vector3.new(0.2, SETTINGS.Radius * 2, SETTINGS.Radius * 2) 
VisualPart.Parent = workspace

local lastPress = 0
local function checkAnimations(humanoid)
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        for _, targetId in pairs(SETTINGS.TargetAnimations) do
            if string.find(tostring(track.Animation.AnimationId), targetId) then return true end
        end
    end
    return false
end

local function triggerAction()
    if tick() - lastPress > SETTINGS.DebounceTime then
        lastPress = tick()
        task.spawn(function()
            if keypress then
                keypress(0x51); task.wait(0.05); if keyrelease then keyrelease(0x51) end
            elseif VirtualInputManager then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                end)
            end
        end)
        return true
    end
    return false
end

RunService.Heartbeat:Connect(function()
    VisualPart.Transparency = STATE.AutoBlockEnabled and 0.7 or 1
    if not STATE.AutoBlockEnabled then VisualPart.CFrame = CFrame.new(0,-1000,0); return end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        VisualPart.CFrame = myRoot.CFrame * CFrame.Angles(0, 0, math.rad(90))
        
        local entitiesToScan = {}
        for _, plr in pairs(Players:GetPlayers()) do if plr ~= LocalPlayer and plr.Character then table.insert(entitiesToScan, plr.Character) end end
        if workspace:FindFirstChild("LobbyMap") then
            for _, obj in pairs(workspace.LobbyMap:GetChildren()) do if obj:IsA("Model") then table.insert(entitiesToScan, obj) end end
        end
        
        for _, char in pairs(entitiesToScan) do
            local hum, root = char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 and (root.Position - myRoot.Position).Magnitude <= SETTINGS.Radius then
                if checkAnimations(hum) then if triggerAction() then break end end
            end
        end
    end
end)

print("Character Lock & Fixed Joystick Loaded")
