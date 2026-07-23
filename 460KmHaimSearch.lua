local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = PlayerService.LocalPlayer

-- 실시간 설정 변수
local Settings = {
    FOV = 55,
    MULTIPLIER = 12,
    Enabled = true,
    ESPEnabled = true, -- [신규] ESP 켜기/끄기 설정
    AimKey = Enum.KeyCode.P,
    ToggleKey = Enum.KeyCode.Insert,
    TargetPart = "Head"
}

local UiVisible = true -- 초기 UI 상태

----------------------------------------------------------------                
-- 1. FOV 시각화 원(Drawing) 설정
----------------------------------------------------------------
local FovCircle = Drawing.new("Circle")
FovCircle.Color = Color3.fromRGB(105, 12, 12)
FovCircle.Thickness = 3
FovCircle.NumSides = 64
FovCircle.Filled = false
FovCircle.Transparency = 0.5
FovCircle.Visible = UiVisible

----------------------------------------------------------------                
-- 2. GUI 생성 (Cookick Hub)
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimSettingsUI"
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 235) -- ESP 버튼 추가로 세로 크기 확장 (195 -> 235)
Frame.AnchorPoint = Vector2.new(0.5, 0.5) 
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true 
Frame.Visible = UiVisible
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = " Cookick Hub "
Title.TextColor3 = Color3.fromRGB(105, 12, 12)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

-- 공통 슬라이더 생성 함수
local function createSlider(text, min, max, default, posY, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, posY)
    label.Text = text .. " : " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(105, 12, 12)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.Parent = Frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    sliderBg.Position = UDim2.new(0, 10, 0, posY + 22)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = Frame

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 16, 0, 16)
    sliderBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(105, 12, 12)
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderBg

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = sliderBtn

    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging and UiVisible then
            local mouseX = UserInputService:GetMouseLocation().X
            local relativeX = mouseX - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            sliderBtn.Position = UDim2.new(percent, 0, 0.5, 0)
            
            local value = math.floor(min + (percent * (max - min)))
            label.Text = text .. " : " .. tostring(value)
            callback(value)
        end
    end)
end

-- 1. FOV 슬라이더
createSlider("FOV SIZE", 10, 300, Settings.FOV, 35, function(val)
    Settings.FOV = val
end)

-- 2. AIMLOCK 슬라이더
createSlider("AIMLOCK POWER", 1, 20, Settings.MULTIPLIER, 85, function(val)
    Settings.MULTIPLIER = val
end)

-- 3. AIM PART 선택 버튼 (Y: 135)
local PartLabel = Instance.new("TextLabel")
PartLabel.Size = UDim2.new(1, -20, 0, 20)
PartLabel.Position = UDim2.new(0, 10, 0, 135)
PartLabel.Text = "AIM PART : " .. tostring(Settings.TargetPart)
PartLabel.TextColor3 = Color3.fromRGB(105, 12, 12)
PartLabel.BackgroundTransparency = 1
PartLabel.TextXAlignment = Enum.TextXAlignment.Left
PartLabel.Font = Enum.Font.SourceSans
PartLabel.TextSize = 16
PartLabel.Parent = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, -20, 0, 22)
ToggleButton.Position = UDim2.new(0, 10, 0, 157)
ToggleButton.BackgroundColor3 = Color3.fromRGB(105, 12, 12)
ToggleButton.Text = "SWITCH TO BODY"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 13
ToggleButton.Parent = Frame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 5)
ButtonCorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    if Settings.TargetPart == "Head" then
        Settings.TargetPart = "Body"
        PartLabel.Text = "AIM PART : BODY"
        ToggleButton.Text = "SWITCH TO HEAD"
    else
        Settings.TargetPart = "Head"
        PartLabel.Text = "AIM PART : HEAD"
        ToggleButton.Text = "SWITCH TO BODY"
    end
end)

-- 4. [신규] ESP ON/OFF 토글 버튼 (Y: 188)
local EspBtn = Instance.new("TextButton")
EspBtn.Size = UDim2.new(1, -20, 0, 28)
EspBtn.Position = UDim2.new(0, 10, 0, 192)
EspBtn.BackgroundColor3 = Color3.fromRGB(105, 12, 12)
EspBtn.Text = "ESP : ON"
EspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspBtn.Font = Enum.Font.SourceSansBold
EspBtn.TextSize = 14
EspBtn.Parent = Frame

local EspCorner = Instance.new("UICorner")
EspCorner.CornerRadius = UDim.new(0, 5)
EspCorner.Parent = EspBtn

EspBtn.MouseButton1Click:Connect(function()
    Settings.ESPEnabled = not Settings.ESPEnabled
    if Settings.ESPEnabled then
        EspBtn.Text = "ESP : ON"
        EspBtn.BackgroundColor3 = Color3.fromRGB(105, 12, 12)
    else
        EspBtn.Text = "ESP : OFF"
        EspBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

----------------------------------------------------------------                
-- 3. Insert 키 토글 (UI & FOV 원)
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Settings.ToggleKey then
        UiVisible = not UiVisible
        Frame.Visible = UiVisible       
        FovCircle.Visible = UiVisible   
    end
end)

----------------------------------------------------------------                
-- 4. ESP 로직 (통합)
----------------------------------------------------------------
local function ESP(player)
    local DrawObject = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text")
    }

    RunService.RenderStepped:Connect(function()
        local Character = player.Character

        -- ESP 스위치가 ON 상태이고 대상 캐릭터가 존재할 때만 표시
        if Settings.ESPEnabled and Character then
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            
            if HumanoidRootPart and Humanoid and Humanoid.Health > 0 then
                local Position, OnScreen = Camera:WorldToViewportPoint(HumanoidRootPart.Position)
                if OnScreen then
                    local scale = 1 / (Position.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
                    local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
                    local x, y = math.floor(Position.X), math.floor(Position.Y)
                    local xPosition, yPosition = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))

                    -- Box 설정
                    DrawObject.Box.Size = Vector2.new(width, height)
                    DrawObject.Box.Position = Vector2.new(xPosition, yPosition)
                    DrawObject.Box.Visible = true
                    DrawObject.Box.Color = Color3.fromRGB(255, 255, 255)
                    DrawObject.Box.Thickness = 1

                    -- Box Outline 설정
                    DrawObject.BoxOutline.Size = Vector2.new(width, height)
                    DrawObject.BoxOutline.Position = Vector2.new(xPosition, yPosition)
                    DrawObject.BoxOutline.Visible = true
                    DrawObject.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
                    DrawObject.BoxOutline.Thickness = 2
                    DrawObject.BoxOutline.ZIndex = 1
                    DrawObject.Box.ZIndex = 2

                    -- Name 설정
                    DrawObject.Name.Text = player.Name
                    DrawObject.Name.Size = 14
                    DrawObject.Name.Center = true
                    DrawObject.Name.Outline = true
                    DrawObject.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
                    DrawObject.Name.Color = Color3.fromRGB(255, 255, 255)
                    DrawObject.Name.Position = Vector2.new(xPosition + (width / 2), yPosition - 16)
                    DrawObject.Name.Visible = true
                    DrawObject.Name.ZIndex = 3
                    return
                end
            end
        end

        -- 조건을 만족하지 못하면 일괄 숨김
        DrawObject.Box.Visible = false
        DrawObject.BoxOutline.Visible = false
        DrawObject.Name.Visible = false
    end)
end

-- 서버의 모든 플레이어 및 새로 들어오는 유저에게 ESP 연동
for _, v in pairs(PlayerService:GetPlayers()) do
    if v ~= LocalPlayer then
        ESP(v)
    end
end

PlayerService.PlayerAdded:Connect(function(v)
    if v ~= LocalPlayer then
        ESP(v)
    end
end)

----------------------------------------------------------------                
-- 5. 에임봇 로직
----------------------------------------------------------------
local function getClosest()
    local target = nil
    local shortestDist = Settings.FOV 
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(PlayerService:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            
            local aimPart = nil
            if Settings.TargetPart == "Head" then
                aimPart = p.Character:FindFirstChild("Head")
            else
                aimPart = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            end
            
            if aimPart and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = pos
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    FovCircle.Position = mousePos
    FovCircle.Radius = Settings.FOV
    
    if UserInputService:IsKeyDown(Settings.AimKey) then
        local targetPos = getClosest()
        if targetPos then
            local diffX = (targetPos.X - mousePos.X) * Settings.MULTIPLIER
            local diffY = (targetPos.Y - mousePos.Y) * Settings.MULTIPLIER
            
            mousemoverel(diffX, diffY)
        end
    end
end)
