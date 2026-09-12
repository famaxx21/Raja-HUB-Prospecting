-- ==========================================
-- 👑 RAJA HUB — MOD
-- Totem ESP + WalkSpeed + Noclip.
-- ==========================================

local H = shared.RajaHub
if not H then error("[RajaHub] Mod: shared.RajaHub missing.") end

-- Suppress print / warn lokal.
local print = function() end
local warn = function() end

local THEME = H.THEME
local S = H.S
local runService = H.runService
local currentCamera = H.currentCamera

-- ==========================================
-- TOTEM ESP — CORE
-- ==========================================
H.getTotemsFolder = function()
	return workspace:FindFirstChild("ActiveTotems")
end

H.getTotemPos = function(totem)
	if totem:IsA("BasePart") then return totem.Position end
	local mp = totem:FindFirstChild("MainPart")
	if mp and mp:IsA("BasePart") then return mp.Position end
	if totem.PrimaryPart then return totem.PrimaryPart.Position end
	local ok, pivot = pcall(function() return totem:GetPivot().Position end)
	if ok and pivot then return pivot end
	local part = totem:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position or nil
end

H.getTotemColor = function(name)
	local l = name:lower()
	if l:find("luck", 1, true) then return Color3.fromRGB(120, 255, 140) end
	if l:find("strength", 1, true) then return Color3.fromRGB(255, 100, 100) end
	return Color3.fromRGB(200, 200, 200)
end

H.getTotemLabel = function(name)
	local l = name:lower()
	if l:find("luck", 1, true) then return "🍀 Luck Totem" end
	if l:find("strength", 1, true) then return "💪 Strength Totem" end
	return "Totem"
end

H.createEsp = function(color)
	local text = Drawing.new("Text")
	text.Size = 14
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.new(0, 0, 0)
	text.Color = color
	text.Font = Drawing.Fonts.UI
	text.Visible = false
	return text
end

H.scanTotems = function()
	S.totems = {}
	local folder = H.getTotemsFolder()
	if not folder then return end
	for _, child in ipairs(folder:GetChildren()) do
		local l = child.Name:lower()
		if (l:find("luck", 1, true) or l:find("strength", 1, true)) and H.getTotemPos(child) then
			table.insert(S.totems, child)
			if not S.espObjects[child] then
				S.espObjects[child] = H.createEsp(H.getTotemColor(child.Name))
			end
		end
	end
	-- Cleanup.
	for totem, obj in pairs(S.espObjects) do
		if not totem.Parent or not table.find(S.totems, totem) then
			pcall(function() obj:Remove() end)
			S.espObjects[totem] = nil
		end
	end
end

-- ==========================================
-- UI — ESP CARD
-- ==========================================
local espCard = H.makeCard(H.ui.modContent, "🔮 Totem ESP", 80)
espCard.LayoutOrder = 1

local espToggleBtn = H.makeBtn(espCard, "ESP: ON", 10, 34, 460, 32, THEME.ok, THEME.bg)

-- ==========================================
-- UI — WALKSPEED CARD
-- ==========================================
local wsCard = H.makeCard(H.ui.modContent, "🏃 WalkSpeed", 140)
wsCard.LayoutOrder = 2

local wsToggleBtn = H.makeBtn(wsCard, "WALKSPEED: OFF", 10, 32, 220, 30, THEME.accentDark)

local wsValueLbl = Instance.new("TextLabel")
wsValueLbl.Size = UDim2.new(0, 230, 0, 30)
wsValueLbl.Position = UDim2.new(0, 240, 0, 32)
wsValueLbl.BackgroundColor3 = THEME.bg
wsValueLbl.BorderSizePixel = 0
wsValueLbl.Text = "Speed: " .. S.walkSpeedValue
wsValueLbl.TextColor3 = THEME.text
wsValueLbl.Font = Enum.Font.Code
wsValueLbl.TextSize = 12
wsValueLbl.Parent = wsCard

local wvc = Instance.new("UICorner")
wvc.CornerRadius = UDim.new(0, 5)
wvc.Parent = wsValueLbl

local wsMinusBtn = H.makeBtn(wsCard, "−", 10, 72, 80, 28, THEME.accentDark)
local wsPlusBtn = H.makeBtn(wsCard, "+", 410, 72, 80, 28, THEME.accentDark)

-- Preset row.
local presetRow = Instance.new("Frame")
presetRow.Size = UDim2.new(1, -20, 0, 26)
presetRow.Position = UDim2.new(0, 10, 0, 106)
presetRow.BackgroundTransparency = 1
presetRow.Parent = wsCard

local presetLayout = Instance.new("UIListLayout")
presetLayout.FillDirection = Enum.FillDirection.Horizontal
presetLayout.Padding = UDim.new(0, 4)
presetLayout.Parent = presetRow

local presets = { 50, 100, 150, 200, 300, 500 }
for _, val in ipairs(presets) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 73, 1, 0)
	btn.BackgroundColor3 = THEME.card
	btn.BorderSizePixel = 0
	btn.Text = tostring(val)
	btn.TextColor3 = THEME.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = presetRow

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = btn

	btn.MouseButton1Click:Connect(function()
		S.walkSpeedValue = val
		wsValueLbl.Text = "Speed: " .. S.walkSpeedValue
		pcall(H.saveModSettings)
	end)
end

-- ==========================================
-- UI — NOCLIP CARD
-- ==========================================
local ncCard = H.makeCard(H.ui.modContent, "👻 Noclip", 70)
ncCard.LayoutOrder = 3

local ncToggleBtn = H.makeBtn(ncCard, "NOCLIP: OFF", 10, 32, 460, 30, THEME.accentDark)

-- Store UI refs.
H.ui.espToggleBtn = espToggleBtn
H.ui.wsToggleBtn = wsToggleBtn
H.ui.wsValueLbl = wsValueLbl
H.ui.ncToggleBtn = ncToggleBtn

-- ==========================================
-- HANDLERS
-- ==========================================
espToggleBtn.MouseButton1Click:Connect(function()
	S.totemEspEnabled = not S.totemEspEnabled
	if S.totemEspEnabled then
		espToggleBtn.Text = "ESP: ON"
		espToggleBtn.BackgroundColor3 = THEME.ok
		espToggleBtn.TextColor3 = THEME.bg
		H.log("Totem ESP ON")
	else
		espToggleBtn.Text = "ESP: OFF"
		espToggleBtn.BackgroundColor3 = THEME.accentDark
		espToggleBtn.TextColor3 = THEME.text
		for _, obj in pairs(S.espObjects) do
			pcall(function() obj.Visible = false end)
		end
		H.log("Totem ESP OFF")
	end
end)

wsToggleBtn.MouseButton1Click:Connect(function()
	S.walkSpeedEnabled = not S.walkSpeedEnabled
	if S.walkSpeedEnabled then
		wsToggleBtn.Text = "WALKSPEED: ON"
		wsToggleBtn.BackgroundColor3 = THEME.ok
		wsToggleBtn.TextColor3 = THEME.bg
		H.log("WalkSpeed ON (" .. S.walkSpeedValue .. ")")
	else
		wsToggleBtn.Text = "WALKSPEED: OFF"
		wsToggleBtn.BackgroundColor3 = THEME.accentDark
		wsToggleBtn.TextColor3 = THEME.text
		local char = H.localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 16 end
		H.log("WalkSpeed OFF")
	end
	pcall(H.saveModSettings)
end)

wsMinusBtn.MouseButton1Click:Connect(function()
	S.walkSpeedValue = math.max(16, S.walkSpeedValue - 10)
	wsValueLbl.Text = "Speed: " .. S.walkSpeedValue
	pcall(H.saveModSettings)
end)

wsPlusBtn.MouseButton1Click:Connect(function()
	S.walkSpeedValue = math.min(500, S.walkSpeedValue + 10)
	wsValueLbl.Text = "Speed: " .. S.walkSpeedValue
	pcall(H.saveModSettings)
end)

ncToggleBtn.MouseButton1Click:Connect(function()
	S.noclipEnabled = not S.noclipEnabled
	if S.noclipEnabled then
		ncToggleBtn.Text = "NOCLIP: ON"
		ncToggleBtn.BackgroundColor3 = THEME.ok
		ncToggleBtn.TextColor3 = THEME.bg
		H.log("Noclip ON")
	else
		ncToggleBtn.Text = "NOCLIP: OFF"
		ncToggleBtn.BackgroundColor3 = THEME.accentDark
		ncToggleBtn.TextColor3 = THEME.text
		H.log("Noclip OFF")
	end
end)

-- ==========================================
-- LOOPS
-- ==========================================
-- WalkSpeed loop.
task.spawn(function()
	while S.running do
		if S.walkSpeedEnabled then
			local char = H.localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = S.walkSpeedValue end
		end
		task.wait(0.2)
	end
end)

-- Noclip loop.
task.spawn(function()
	while S.running do
		if S.noclipEnabled then
			local char = H.localPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end
		task.wait(0.2)
	end
end)

-- Totem ESP render.
local renderConn = runService.RenderStepped:Connect(function()
	if not S.totemEspEnabled then return end
	local hrp = H.getHrp()
	local playerPos = hrp and hrp.Position or Vector3.zero
	for _, totem in ipairs(S.totems) do
		local obj = S.espObjects[totem]
		if not obj then continue end
		local pos = H.getTotemPos(totem)
		if not pos then
			obj.Visible = false
			continue
		end
		local screenPos, onScreen = currentCamera:WorldToViewportPoint(pos + Vector3.new(0, 4, 0))
		local dist = (pos - playerPos).Magnitude
		if onScreen then
			obj.Text = string.format("%s\n%.0f studs", H.getTotemLabel(totem.Name), dist)
			obj.Position = Vector2.new(screenPos.X, screenPos.Y)
			obj.Visible = true
		else
			obj.Visible = false
		end
	end
end)

-- Totem rescan loop.
H.scanTotems()
task.spawn(function()
	while S.running do
		task.wait(3)
		H.scanTotems()
	end
end)

-- Init UI state (kalau load setting sebelumnya).
if S.totemEspEnabled then
	espToggleBtn.Text = "ESP: ON"
	espToggleBtn.BackgroundColor3 = THEME.ok
	espToggleBtn.TextColor3 = THEME.bg
else
	espToggleBtn.Text = "ESP: OFF"
	espToggleBtn.BackgroundColor3 = THEME.accentDark
	espToggleBtn.TextColor3 = THEME.text
end

if S.walkSpeedEnabled then
	wsToggleBtn.Text = "WALKSPEED: ON"
	wsToggleBtn.BackgroundColor3 = THEME.ok
	wsToggleBtn.TextColor3 = THEME.bg
end

wsValueLbl.Text = "Speed: " .. S.walkSpeedValue

H.log("Mod loaded.")
