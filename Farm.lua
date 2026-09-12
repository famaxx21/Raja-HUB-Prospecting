-- ==========================================
-- 👑 RAJA HUB — FARM
-- Auto Pan + Forever Pack Claim.
-- Shake: trigger Pan → fill turun → unequip/equip (Humanoid) → spam shake.
-- ==========================================

local H = shared.RajaHub
if not H then error("[RajaHub] Farm: shared.RajaHub missing.") end

-- Suppress print / warn lokal.
local print = function() end
local warn = function() end

local THEME = H.THEME
local S = H.S

-- ==========================================
-- AUTO PAN CORE
-- ==========================================
H.equipPan = function()
	local char = H.localPlayer.Character
	if not char then return false end
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Tool") and c.Name:lower():find("pan", 1, true) then return true end
	end
	local target = nil
	local function findIn(container)
		if not container or target then return end
		for _, c in ipairs(container:GetChildren()) do
			if c:IsA("Tool") and c.Name:lower():find("pan", 1, true) then
				target = c
				return
			end
		end
	end
	findIn(H.localPlayer:FindFirstChild("BackpackTwo"))
	if not target then findIn(H.localPlayer:FindFirstChild("Backpack")) end
	if target then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum:EquipTool(target) return true end
	end
	return false
end

H.getEquippedPanTool = function()
	local char = H.localPlayer.Character
	if not char then return nil end
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Tool") and c.Name:lower():find("pan", 1, true) then return c end
	end
	return nil
end

H.findPanRemotes = function()
	local list = {}
	local char = H.localPlayer.Character
	if not char then return list end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("pan", 1, true) then
			local scripts = tool:FindFirstChild("Scripts")
			if scripts then
				for _, r in ipairs(scripts:GetChildren()) do
					if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
						list[r.Name] = r
					end
				end
			end
		end
	end
	return list
end

H.getFill = function()
	local pg = H.localPlayer:FindFirstChild("PlayerGui")
	if not pg then return nil, nil end
	local toolUI = pg:FindFirstChild("ToolUI")
	if not toolUI then return nil, nil end
	local fp = toolUI:FindFirstChild("FillingPan")
	if not fp then return nil, nil end
	local ft = fp:FindFirstChild("FillText")
	if not ft then return nil, nil end
	local c, m = ft.Text:match("(%d+)/(%d+)")
	if c and m then return tonumber(c), tonumber(m) end
	return nil, nil
end

H.doFillPan = function()
	H.equipPan()
	local remotes = H.findPanRemotes()
	if not remotes.ToggleShovelActive or not remotes.Collect then
		return false, "Pan remotes not found"
	end
	local loop = 0
	while S.running and loop < H.FILL_MAX_LOOPS do
		loop = loop + 1
		remotes.ToggleShovelActive:FireServer(true)
		pcall(function() remotes.Collect:InvokeServer() end)
		pcall(function() remotes.Collect:InvokeServer(H.FILL_SCORE, false) end)
		remotes.ToggleShovelActive:FireServer(false)
		task.wait(H.FILL_ATTEMPT_DELAY)
		local c, m = H.getFill()
		if c and m and c >= m then break end
	end
	if remotes.Collect then pcall(function() remotes.Collect:InvokeServer() end) end
	return true
end

-- ==========================================
-- SHAKE — TRIGGER PAN → FILL TURUN → UNEQUIP/EQUIP (Humanoid)
-- ==========================================
H.doShakePan = function()
	H.equipPan()
	task.wait(H.TELEPORT_SYNC_WAIT)

	local char = H.localPlayer.Character
	if not char then
		H.log("❌ No character")
		return false, "No char"
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		H.log("❌ No Humanoid")
		return false, "No humanoid"
	end

	local panTool = H.getEquippedPanTool()
	if not panTool then
		H.log("❌ No equipped pan")
		return false, "No pan"
	end

	local remotes = H.findPanRemotes()
	if not remotes.Shake or not remotes.Pan then
		H.log("❌ Shake/Pan not found")
		return false, "Shake/Pan not found"
	end

	-- 1. Trigger Pan sampai return true.
	local triggerOk = false
	local attempts = 0
	for i = 1, H.PAN_TRIGGER_MAX_ATTEMPTS do
		attempts = i
		local ok, res = pcall(function() return remotes.Pan:InvokeServer() end)
		if ok and res == true then triggerOk = true break end
		task.wait(H.PAN_TRIGGER_RETRY_DELAY)
	end
	if not triggerOk then
		H.log("❌ Pan trigger failed after " .. attempts .. " attempts")
		return false, "Pan trigger failed"
	end
	H.log("Pan trigger OK (" .. attempts .. " attempts)")
	task.wait(H.PAN_TRIGGER_WAIT)

	-- 2. Fire Shake 1x-1x sampai fill mulai turun.
	local fillBefore = select(1, H.getFill())
	H.log("Fill before: " .. tostring(fillBefore))

	local t0 = tick()
	local started = false
	for i = 1, 20 do
		pcall(function() remotes.Shake:FireServer() end)
		task.wait(0.03)
		local c = select(1, H.getFill())
		if c and fillBefore and c < fillBefore then
			started = true
			H.log("Fill dropping: " .. fillBefore .. " → " .. c .. " (after " .. i .. " fires)")
			break
		end
	end

	if not started then
		H.log("⚠️ Fill not dropping after 20 fires")
	end

	-- 3. Unequip + equip cepat pakai Humanoid.
	if started then
		H.log("→ Fast unequip → equip (Humanoid)")
		pcall(function() hum:UnequipTools() end)
		task.wait(0.01)
		pcall(function() hum:EquipTool(panTool) end)
		task.wait(0.01)
	end

	-- 4. Spam Shake tanpa batas sampai fill = 0.
	local lastCheck = tick()
	local clickCount = 0
	local batchSize = H.SHAKE_BATCH_SIZE or 50
	local delay = H.SHAKE_DELAY or 0

	while S.running do
		for _ = 1, batchSize do
			pcall(function() remotes.Shake:FireServer() end)
			clickCount = clickCount + 1
		end

		if delay > 0 then
			task.wait(delay)
		else
			task.wait()
		end

		if tick() - lastCheck >= H.SHAKE_CHECK_INTERVAL_SEC then
			lastCheck = tick()
			local c, _ = H.getFill()
			if c == 0 then break end
		end
	end

	local t1 = tick()
	H.log(string.format("Shake done: %d fires in %.2fs", clickCount, t1 - t0))

	-- 5. Equip pan balik (jaga-jaga).
	pcall(function() hum:EquipTool(panTool) end)
	task.wait(0.2)

	-- 6. Collect final.
	local remotesAfter = H.findPanRemotes()
	if remotesAfter.Collect then
		pcall(function() remotesAfter.Collect:InvokeServer() end)
	end
	task.wait(0.1)
	return true
end

-- ==========================================
-- FARM CYCLE
-- ==========================================
H.runFarmCycle = function()
	if not S.sandPos or not S.waterPos then
		H.log("❌ Sand/Water not set")
		return false
	end
	H.log("=== Farm cycle #" .. (S.farmCycleCount + 1) .. " ===")

	-- 1. Fill — di sand.
	H.equipPan()
	H.log("Fill start")
	H.teleportLocal(S.sandPos)
	task.wait(H.TP_SAND_WAIT)
	H.doFillPan()
	H.log("Fill done")

	-- 2. TP water, shake.
	H.log("Shake start")
	H.teleportLocal(S.waterPos)
	task.wait(H.TP_SAND_WAIT)
	H.doShakePan()
	H.log("Shake done")

	-- 3. TP balik ke sand.
	H.log("→ TP back to sand")
	H.teleportLocal(S.sandPos)
	task.wait(H.TP_SAND_WAIT)

	S.farmCycleCount = S.farmCycleCount + 1
	if H.ui.farmCycleLabel then
		H.ui.farmCycleLabel.Text = "Cycles: " .. S.farmCycleCount
	end
	return true
end

-- ==========================================
-- FOREVER PACK CLAIM
-- ==========================================
H.getForeverPackPanel = function()
	local pg = H.localPlayer:FindFirstChild("PlayerGui")
	if not pg then return nil end
	local mainUI = pg:FindFirstChild("MainUI")
	if not mainUI then return nil end
	local shop = mainUI:FindFirstChild("Shop")
	if not shop then return nil end
	local content = shop:FindFirstChild("Content")
	if not content then return nil end
	local shopList = content:FindFirstChild("ShopList")
	if not shopList then return nil end
	return shopList:FindFirstChild("ForeverPack")
end

H.parseCountdown = function(text)
	local h, m = text:match("(%d+)h%s*(%d+)m")
	if h and m then return tonumber(h) * 60 + tonumber(m) end
	return nil
end

H.getTimeLeftMinutes = function()
	local panel = H.getForeverPackPanel()
	if not panel then return nil end
	local tl = panel:FindFirstChild("TimeLeft")
	if not tl then return nil end
	return H.parseCountdown(tl.Text)
end

H.claimAllPack = function()
	local panel = H.getForeverPackPanel()
	if not panel then return false, "Panel not found" end
	local pc = panel:FindFirstChild("PackContents")
	if not pc then return false, "PackContents not found" end

	local claimed = 0
	for _, slot in ipairs(pc:GetChildren()) do
		if slot.Name == "PackSlot" then
			local buy = slot:FindFirstChild("Buy")
			if buy and buy:IsA("ImageButton") then
				local price = buy:FindFirstChild("Price")
				if price and price.Text == "Claim" then
					pcall(function() buy.MouseButton1Click:Fire() end)
					claimed = claimed + 1
					task.wait(0.3)
				end
			end
		end
	end
	return true, claimed
end

H.doClaim = function()
	local ok, res = H.claimAllPack()
	if not ok then
		H.log("❌ Claim: " .. tostring(res))
		return false
	end
	if res == 0 then
		H.log("Nothing to claim")
		return false
	end
	H.log("✅ Claimed " .. res .. " slots")
	return true
end

H.runClaimAuto = function()
	H.log("=== Claim Auto started ===")
	while S.running and S.claimAutoRunning do
		local mins = H.getTimeLeftMinutes()
		if not mins then
			H.log("Panel not available. Wait 60s...")
			task.wait(60)
			continue
		end
		local claimed = H.doClaim()
		if claimed then
			task.wait(300)
		else
			if mins > 5 then
				local waitSec = math.min((mins - 5) * 60, 600)
				task.wait(waitSec)
			else
				task.wait(60)
			end
		end
	end
	H.log("=== Claim Auto stopped ===")
end

-- ==========================================
-- UI — PAN CARD
-- ==========================================
local panCard = H.makeCard(H.ui.farmContent, "🔮 Auto Pan", 260)
panCard.LayoutOrder = 1

local sandLbl = Instance.new("TextLabel")
sandLbl.Size = UDim2.new(1, -20, 0, 16)
sandLbl.Position = UDim2.new(0, 10, 0, 28)
sandLbl.BackgroundTransparency = 1
sandLbl.Text = "Sand: Not set"
sandLbl.TextColor3 = THEME.textDim
sandLbl.TextXAlignment = Enum.TextXAlignment.Left
sandLbl.Font = Enum.Font.Code
sandLbl.TextSize = 10
sandLbl.Parent = panCard

local waterLbl = Instance.new("TextLabel")
waterLbl.Size = UDim2.new(1, -20, 0, 16)
waterLbl.Position = UDim2.new(0, 10, 0, 44)
waterLbl.BackgroundTransparency = 1
waterLbl.Text = "Water: Not set"
waterLbl.TextColor3 = THEME.textDim
waterLbl.TextXAlignment = Enum.TextXAlignment.Left
waterLbl.Font = Enum.Font.Code
waterLbl.TextSize = 10
waterLbl.Parent = panCard

local setSandBtn = H.makeBtn(panCard, "Set Sand", 10, 66, 110, 28)
local setWaterBtn = H.makeBtn(panCard, "Set Water", 125, 66, 110, 28)
local tpSandBtn = H.makeBtn(panCard, "TP Sand", 240, 66, 110, 28)
local tpWaterBtn = H.makeBtn(panCard, "TP Water", 355, 66, 110, 28)

local runFarmBtn = H.makeBtn(panCard, "▶ RUN ONE CYCLE", 10, 102, 225, 34, THEME.blue)
local loopFarmBtn = H.makeBtn(panCard, "🔁 FARM LOOP: OFF", 245, 102, 225, 34, THEME.accentDark)

local farmCycleLabel = Instance.new("TextLabel")
farmCycleLabel.Size = UDim2.new(1, -20, 0, 18)
farmCycleLabel.Position = UDim2.new(0, 10, 0, 144)
farmCycleLabel.BackgroundTransparency = 1
farmCycleLabel.Text = "Cycles: 0"
farmCycleLabel.TextColor3 = THEME.textDim
farmCycleLabel.TextXAlignment = Enum.TextXAlignment.Left
farmCycleLabel.Font = Enum.Font.Code
farmCycleLabel.TextSize = 10
farmCycleLabel.Parent = panCard

local fillLbl = Instance.new("TextLabel")
fillLbl.Size = UDim2.new(1, -20, 0, 18)
fillLbl.Position = UDim2.new(0, 10, 0, 162)
fillLbl.BackgroundTransparency = 1
fillLbl.Text = "Fill: -/-"
fillLbl.TextColor3 = THEME.text
fillLbl.TextXAlignment = Enum.TextXAlignment.Left
fillLbl.Font = Enum.Font.Code
fillLbl.TextSize = 10
fillLbl.Parent = panCard

local runFarmNote = Instance.new("TextLabel")
runFarmNote.Size = UDim2.new(1, -20, 0, 60)
runFarmNote.Position = UDim2.new(0, 10, 0, 188)
runFarmNote.BackgroundTransparency = 1
runFarmNote.Text = "Set Sand + Water dulu (TP ke lokasi, klik Set).\nKlik RUN ONE CYCLE atau LOOP."
runFarmNote.TextColor3 = THEME.textDim
runFarmNote.TextXAlignment = Enum.TextXAlignment.Left
runFarmNote.TextYAlignment = Enum.TextYAlignment.Top
runFarmNote.TextWrapped = true
runFarmNote.Font = Enum.Font.Code
runFarmNote.TextSize = 10
runFarmNote.Parent = panCard

H.ui.sandLbl = sandLbl
H.ui.waterLbl = waterLbl
H.ui.farmCycleLabel = farmCycleLabel
H.ui.loopFarmBtn = loopFarmBtn
H.ui.fillLbl = fillLbl

-- ==========================================
-- UI — CLAIM CARD
-- ==========================================
local claimCard = H.makeCard(H.ui.farmContent, "🎁 Forever Pack Claim", 130)
claimCard.LayoutOrder = 2

local claimCountdown = Instance.new("TextLabel")
claimCountdown.Size = UDim2.new(1, -20, 0, 18)
claimCountdown.Position = UDim2.new(0, 10, 0, 28)
claimCountdown.BackgroundTransparency = 1
claimCountdown.Text = "Countdown: -"
claimCountdown.TextColor3 = THEME.text
claimCountdown.TextXAlignment = Enum.TextXAlignment.Left
claimCountdown.Font = Enum.Font.Code
claimCountdown.TextSize = 10
claimCountdown.Parent = claimCard

local claimNowBtn = H.makeBtn(claimCard, "▶ CLAIM NOW", 10, 50, 225, 32, THEME.blue)
local claimAutoBtn = H.makeBtn(claimCard, "⏳ CLAIM AUTO: OFF", 245, 50, 225, 32, THEME.accentDark)

local claimNote = Instance.new("TextLabel")
claimNote.Size = UDim2.new(1, -20, 0, 32)
claimNote.Position = UDim2.new(0, 10, 0, 88)
claimNote.BackgroundTransparency = 1
claimNote.Text = "Buka Shop → tab Forever Pack dulu."
claimNote.TextColor3 = THEME.textDim
claimNote.TextXAlignment = Enum.TextXAlignment.Left
claimNote.TextWrapped = true
claimNote.Font = Enum.Font.Code
claimNote.TextSize = 10
claimNote.Parent = claimCard

H.ui.claimCountdown = claimCountdown
H.ui.claimAutoBtn = claimAutoBtn

-- ==========================================
-- HANDLERS — PAN
-- ==========================================
setSandBtn.MouseButton1Click:Connect(function()
	local hrp = H.getHrp()
	if hrp then
		S.sandPos = hrp.Position
		sandLbl.Text = string.format("Sand: (%.1f, %.1f, %.1f)", S.sandPos.X, S.sandPos.Y, S.sandPos.Z)
		sandLbl.TextColor3 = THEME.ok
		H.log("Sand set")
	end
end)

setWaterBtn.MouseButton1Click:Connect(function()
	local hrp = H.getHrp()
	if hrp then
		S.waterPos = hrp.Position
		waterLbl.Text = string.format("Water: (%.1f, %.1f, %.1f)", S.waterPos.X, S.waterPos.Y, S.waterPos.Z)
		waterLbl.TextColor3 = THEME.ok
		H.log("Water set")
	end
end)

tpSandBtn.MouseButton1Click:Connect(function()
	if S.sandPos then
		H.teleportLocal(S.sandPos)
		H.log("TP to sand")
	else
		H.log("❌ Sand not set")
	end
end)

tpWaterBtn.MouseButton1Click:Connect(function()
	if S.waterPos then
		H.teleportLocal(S.waterPos)
		H.log("TP to water")
	else
		H.log("❌ Water not set")
	end
end)

runFarmBtn.MouseButton1Click:Connect(function()
	if S.farmTesting or S.farmLoopRunning then return end
	S.farmTesting = true
	runFarmBtn.Text = "⏳..."
	task.spawn(function()
		H.runFarmCycle()
		runFarmBtn.Text = "▶ RUN ONE CYCLE"
		S.farmTesting = false
	end)
end)

loopFarmBtn.MouseButton1Click:Connect(function()
	if S.farmLoopRunning then
		S.farmLoopRunning = false
		loopFarmBtn.Text = "🔁 FARM LOOP: OFF"
		loopFarmBtn.BackgroundColor3 = THEME.accentDark
		H.log("Farm loop OFF")
	else
		if not S.sandPos or not S.waterPos then
			H.log("❌ Set sand/water first")
			return
		end
		S.farmLoopRunning = true
		loopFarmBtn.Text = "🔁 FARM LOOP: ON"
		loopFarmBtn.BackgroundColor3 = THEME.ok
		H.log("Farm loop ON")
		task.spawn(function()
			while S.farmLoopRunning and S.running do
				H.runFarmCycle()
				task.wait(H.LOOP_CYCLE_DELAY)
			end
		end)
	end
end)

-- ==========================================
-- HANDLERS — CLAIM
-- ==========================================
claimNowBtn.MouseButton1Click:Connect(function()
	if S.claimAutoRunning then return end
	task.spawn(H.doClaim)
end)

claimAutoBtn.MouseButton1Click:Connect(function()
	if S.claimAutoRunning then
		S.claimAutoRunning = false
		claimAutoBtn.Text = "⏳ CLAIM AUTO: OFF"
		claimAutoBtn.BackgroundColor3 = THEME.accentDark
	else
		S.claimAutoRunning = true
		claimAutoBtn.Text = "⏳ CLAIM AUTO: ON"
		claimAutoBtn.BackgroundColor3 = THEME.ok
		task.spawn(H.runClaimAuto)
	end
end)

-- ==========================================
-- LIVE UPDATE — FILL + COUNTDOWN
-- ==========================================
task.spawn(function()
	while S.running do
		local c, m = H.getFill()
		if c and m then
			fillLbl.Text = "Fill: " .. c .. "/" .. m
		else
			fillLbl.Text = "Fill: -/-"
		end
		task.wait(0.3)
	end
end)

task.spawn(function()
	while S.running do
		local mins = H.getTimeLeftMinutes()
		if mins then
			claimCountdown.Text = string.format("Countdown: %dh %dm", math.floor(mins / 60), mins % 60)
		else
			claimCountdown.Text = "Countdown: - (open Forever Pack)"
		end
		task.wait(2)
	end
end)

H.log("Farm loaded.")
