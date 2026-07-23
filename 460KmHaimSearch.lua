local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 실시간 설정 변수
local Settings = {
    FOV = 55,
    MULTIPLIER = 12, 
    Enabled = true,
    AimKey = Enum.KeyCode.P,
    ToggleKey = Enum.KeyCode.Insert,
    TargetPart = "Head" -- [기본값] 에임봇이 타겟팅할 기본 파트
}

local UiVisible = true -- 초기 UI 상태 (켜짐)

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
-- 2. GUI 생성 (FOV, 에임 강도 및 조준 부위 조절 UI)
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimSettingsUI"
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 195) -- [수정] 조준 부위 추가로 인해 세로 높이 확장 (140 -> 195)
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
Title.TextSize = 16
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
    sliderBtn.BackgroundColor3 = Color3.fromRGB(105, 12, 12) -- 버튼 색깔 통일
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

-- 1. FOV 슬라이더 생성 (위치 Y: 35)
createSlider("FOV SIZE", 10, 300, Settings.FOV, 35, function(val)
    Settings.FOV = val
end)

-- 2. MULTIPLIER 슬라이더 생성 (위치 Y: 85)
createSlider("AIMLOCK POWER", 1, 20, Settings.MULTIPLIER, 85, function(val)
    Settings.MULTIPLIER = val
end)

-- 3. [신규] 에임 부위 선택용 버튼 생성 (위치 Y: 140)
local PartLabel = Instance.new("TextLabel")
PartLabel.Size = UDim2.new(1, -20, 0, 20)
PartLabel.Position = UDim2.new(0, 10, 0, 140)
PartLabel.Text = "AIM PART : " .. tostring(Settings.TargetPart)
PartLabel.TextColor3 = Color3.fromRGB(105, 12, 12)
PartLabel.BackgroundTransparency = 1
PartLabel.TextXAlignment = Enum.TextXAlignment.Left
PartLabel.Font = Enum.Font.SourceSans
PartLabel.TextSize = 16
PartLabel.Parent = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, -20, 0, 25)
ToggleButton.Position = UDim2.new(0, 10, 0, 162)
ToggleButton.BackgroundColor3 = Color3.fromRGB(105, 12, 12) -- 어두운 레드 톤 배경
ToggleButton.Text = "SWITCH TO BODY" -- 기본 상태에서 누르면 몸으로 바꾼다는 예고
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 16
ToggleButton.Parent = Frame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 5)
ButtonCorner.Parent = ToggleButton

-- 버튼 클릭 시 머리 <-> 몸통 전환 토글
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

----------------------------------------------------------------                
-- 3. Insert 키 입력 감지 (UI & FOV 토글)
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Settings.ToggleKey then
        UiVisible = not UiVisible
        Frame.Visible = UiVisible       
        FovCircle.Visible = UiVisible   
    end
end)

----------------------------------------------------------------                
-- 4. 에임봇 로직 (조준 파트 유동화 적용)
----------------------------------------------------------------
local function getClosest()
    local target = nil
    local shortestDist = Settings.FOV 
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            
            -- [핵심 수정] UI 세팅에 따라 타겟 파트를 동적으로 선택합니다.
            local aimPart = nil
            if Settings.TargetPart == "Head" then
                aimPart = p.Character:FindFirstChild("Head")
            else
                -- BODY를 선택하면 R6 캐릭터와 R15 캐릭터의 몸통 파트를 유연하게 탐색합니다.
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
