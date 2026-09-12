-- ==========================================
-- 👑 RAJA HUB — CORE
-- Services, remotes, constants, state, helpers, log system.
-- ==========================================

local H = shared.RajaHub
if not H then error("[RajaHub] Core: shared.RajaHub missing. Load Main.lua first.") end

-- ==========================================
-- SERVICES
-- ==========================================
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

local localPlayer = playersService.LocalPlayer
local currentCamera = workspace.CurrentCamera

H.playersService = playersService
H.replicatedStorage = replicatedStorage
H.httpService = httpService
H.runService = runService
H.userInputService = userInputService
H.tweenService = tweenService
H.localPlayer = localPlayer
H.currentCamera = currentCamera

-- ==========================================
-- REMOTES
-- ==========================================
local remotes = replicatedStorage:WaitForChild("Remotes")
local sellAll = remotes:WaitForChild("Shop"):WaitForChild("SellAll")
local invRemotes = remotes:WaitForChild("Inventory")
local equipPan = invRemotes:WaitForChild("EquipPan")
local getStorageData = invRemotes:WaitForChild("GetStorageData")
local toggleLock = invRemotes:WaitForChild("ToggleLock")
local unlockAll = invRemotes:WaitForChild("UnlockAll")

H.sellAll = sellAll
H.equipPan = equipPan
H.getStorageData = getStorageData
H.toggleLock = toggleLock
H.unlockAll = unlockAll

-- ==========================================
-- CONSTANTS
-- ==========================================
H.DEFAULT_SELL_PAN = "0"
H.DEFAULT_FARM_PAN = "153"
H.EQUIP_WAIT = 0.5
H.SELL_WAIT = 0.5
H.AFTER_TP_WAIT = 0.5
H.LOCK_DELAY = 0.05
H.UNLOCK_WAIT = 1
H.TELEPORT_OFFSET = Vector3.new(0, 3, 0)

-- Pan constants.
H.FILL_MAX_LOOPS = 60
H.FILL_ATTEMPT_DELAY = 0.1
H.FILL_SCORE = 1.0
H.SHAKE_DELAY = 0.01
H.SHAKE_CHECK_INTERVAL = 5
H.SHAKE_MAX_CLICKS = 500
H.PAN_TRIGGER_WAIT = 0.1
H.PAN_TRIGGER_MAX_ATTEMPTS = 10
H.PAN_TRIGGER_RETRY_DELAY = 0.2
H.TELEPORT_SYNC_WAIT = 0.3
H.TP_SAND_WAIT = 0.1
H.LOOP_CYCLE_DELAY = 0.5

-- Files.
H.SELECTION_SAVE_FILE = "RajaHub_Selection.json"
H.PAN_SETTINGS_FILE = "RajaHub_PanSettings.json"
H.MOD_SETTINGS_FILE = "RajaHub_ModSettings.json"

-- ==========================================
-- RARITY CATALOG
-- ==========================================
H.RARITY = {
	Common = { "Amethyst", "Blue Ice", "Copper", "Gold", "Obsidian", "Pearl", "Platinum", "Pyrite", "Seashell", "Silver" },
	Uncommon = { "Coral", "Electrum", "Glowberry", "Malachite", "Neodymium", "Nickel", "Rock Candy", "Sapphire", "Smoky Quartz", "Titanium", "Topaz", "Zircon" },
	Rare = { "Amber", "Azuralite", "Candy Cane", "Diopside", "Glacial Quartz", "Gloomberry", "Jade", "Lapis Lazuli", "Meteoric Iron", "Onyx", "Peridot", "Pyrelith", "Ruby", "Sandsteel", "Silver Clamshell" },
	Epic = { "Ammonite Fossil", "Ashvein", "Aurorite", "Bone", "Borealite", "Cobalt", "Emerald", "Glowmoss", "Golden Pearl", "Iridium", "Lightshard", "Mercury", "Meteoric Gold", "Moonstone", "Opal", "Osmium", "Pyronium", "Selenite" },
	Legendary = { "Aetherite", "Aquamarine", "Bismuth", "Catseye", "Cinnabar", "Depleted Shard", "Diamond", "Dragon Bone", "Fire Opal", "Firefly Stone", "Gloomcap", "Jasper", "Lost Soul", "Luminum", "Nautilus Shell", "Palladium", "Peppermint Prism", "Radium", "Rose Gold", "Specterite", "Starshine", "Tourmaline", "Uranium", "Volcanic Key" },
	Mythic = { "Aetherium", "Agate", "Chrysoberyl", "Flarebloom", "Frostshard", "Inferlume", "Mythril", "Painite", "Pink Diamond", "Prismara", "Radiant Gold", "Red Beryl", "Star Garnet", "Sunstone", "Vortessence", "Volcanic Core" },
	Exotic = { "Adamantine", "Astral Spore", "Bloodstone", "Celestium", "Cryonic Artifact", "Dinosaur Skull", "Eternium", "Eye of the Sands", "Forgotten Totem", "Key of Life", "North Star", "Pumpkin Soul", "Singularium", "Solarium", "Starpiercer", "Umbrite", "Vineheart", "Voidstone" },
}

H.ITEM_RARITY = {}
H.ALL_ITEMS = {}
for rarity, list in pairs(H.RARITY) do
	for _, name in ipairs(list) do
		H.ITEM_RARITY[name] = rarity
		table.insert(H.ALL_ITEMS, name)
	end
end
table.sort(H.ALL_ITEMS)

-- ==========================================
-- MERCHANTS
-- ==========================================
H.MERCHANTS = {
	{ name = "StarterTown", pos = Vector3.new(-4.61, 25.13, 61.16) },
	{ name = "RiverTown 1", pos = Vector3.new(-267.64, 25.31, 88.93) },
	{ name = "RiverTown 2", pos = Vector3.new(35.35, 13.00, -394.48) },
	{ name = "Cavern", pos = Vector3.new(-194.53, -7.00, 372.69) },
	{ name = "Volcano 1", pos = Vector3.new(803.99, 26.18, -1721.50) },
	{ name = "Volcano 2", pos = Vector3.new(-1015.00, 17.39, -689.50) },
	{ name = "Volcano 3", pos = Vector3.new(-1153.05, -91.08, -113.56) },
	{ name = "Swamp", pos = Vector3.new(-2052.58, 22.17, 1270.69) },
	{ name = "North Pole", pos = Vector3.new(3778.50, 14.00, 3527.50) },
	{ name = "Grotto 1", pos = Vector3.new(383.62, -192.94, 1156.63) },
	{ name = "Grotto 2", pos = Vector3.new(278.68, -114.12, 778.48) },
	{ name = "Grotto 3", pos = Vector3.new(123.21, -133.52, 918.59) },
	{ name = "Desert 1", pos = Vector3.new(-6529.50, 156.77, -327.50) },
	{ name = "Desert 2", pos = Vector3.new(-5917.50, 156.02, -183.50) },
	{ name = "Desert 3", pos = Vector3.new(-6058.50, 170.71, -694.50) },
	{ name = "MeteorValley 1", pos = Vector3.new(-4825.67, 111.15, 1474.86) },
	{ name = "MeteorValley 2", pos = Vector3.new(-5593.00, 106.84, 1521.50) },
	{ name = "MeteorValley 3", pos = Vector3.new(-5297.39, 106.66, 1610.46) },
	{ name = "Halloween", pos = Vector3.new(4272.84, 17.48, 4996.95) },
}

-- ==========================================
-- STATE
-- ==========================================
H.S = {
	-- Sell.
	sellAutoRunning = false,
	sellTesting = false,
	sellPanIndex = H.DEFAULT_SELL_PAN,
	farmPanIndex = H.DEFAULT_FARM_PAN,
	sellInterval = 10,

	-- Farm.
	farmLoopRunning = false,
	farmTesting = false,
	sandPos = nil,
	waterPos = nil,
	farmCycleCount = 0,
	claimAutoRunning = false,

	-- Mod.
	totemEspEnabled = true,
	walkSpeedEnabled = false,
	walkSpeedValue = 16,
	noclipEnabled = false,

	-- Lock.
	selectedItems = {},
	searchFilter = "",
	autoLockEnabled = false,
	descendantConn = nil,

	-- Data.
	cachedInventory = {},
	totems = {},
	espObjects = {},
	running = true,

	-- UI (diisi sama UI.lua).
	ui = {},
}

-- ==========================================
-- LOG SYSTEM (silent, ke log window)
-- ==========================================
H.logLines = {}
H.MAX_LOG = 20

H.log = function(text)
	local ts = os.date("[%H:%M:%S] ")
	table.insert(H.logLines, ts .. tostring(text))
	if #H.logLines > H.MAX_LOG then
		table.remove(H.logLines, 1)
	end
	if H.refreshLogUI then
		pcall(H.refreshLogUI)
	end
end

-- ==========================================
-- HELPERS
-- ==========================================
H.getHrp = function()
	local char = H.localPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

H.setCollide = function(state)
	local char = H.localPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = state end
	end
end

H.teleportLocal = function(position)
	local hrp = H.getHrp()
	if not hrp then return false end
	H.setCollide(false)
	hrp.CFrame = CFrame.new(position + H.TELEPORT_OFFSET)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	H.setCollide(true)
	return true
end

H.getCurrentPan = function()
	local char = H.localPlayer.Character
	if not char then return nil end
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Tool") and c.Name:lower():find("pan", 1, true) then
			return c
		end
	end
	return nil
end

H.getInventory = function()
	local ok, data = pcall(function() return H.getStorageData:InvokeServer() end)
	if ok and type(data) == "table" then
		H.S.cachedInventory = data
		return data
	end
	return nil
end

H.findNearestMerchant = function(fromPos)
	local best, bestDist = nil, math.huge
	for _, m in ipairs(H.MERCHANTS) do
		local d = (m.pos - fromPos).Magnitude
		if d < bestDist then bestDist = d best = m end
	end
	return best, bestDist
end

H.findAllToolsByName = function(name)
	local result = {}
	local function scan(container)
		if not container then return end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and child.Name == name then
				table.insert(result, child)
			end
		end
	end
	scan(H.localPlayer:FindFirstChild("BackpackTwo"))
	scan(H.localPlayer:FindFirstChild("Backpack"))
	scan(H.localPlayer.Character)
	return result
end

-- ==========================================
-- SAVE / LOAD
-- ==========================================
H.saveSelection = function()
	local arr = {}
	for name in pairs(H.S.selectedItems) do table.insert(arr, name) end
	local ok, encoded = pcall(function() return H.httpService:JSONEncode(arr) end)
	if ok then pcall(function() writefile(H.SELECTION_SAVE_FILE, encoded) end) end
end

H.loadSelection = function()
	if not isfile or not isfile(H.SELECTION_SAVE_FILE) then return end
	local ok, content = pcall(function() return readfile(H.SELECTION_SAVE_FILE) end)
	if not ok or not content then return end
	local ok2, decoded = pcall(function() return H.httpService:JSONDecode(content) end)
	if ok2 and type(decoded) == "table" then
		for _, name in ipairs(decoded) do H.S.selectedItems[name] = true end
	end
end

H.savePanSettings = function()
	local data = { sellPan = H.S.sellPanIndex, farmPan = H.S.farmPanIndex }
	local ok, encoded = pcall(function() return H.httpService:JSONEncode(data) end)
	if ok then pcall(function() writefile(H.PAN_SETTINGS_FILE, encoded) end) end
end

H.loadPanSettings = function()
	if not isfile or not isfile(H.PAN_SETTINGS_FILE) then return end
	local ok, content = pcall(function() return readfile(H.PAN_SETTINGS_FILE) end)
	if not ok or not content then return end
	local ok2, decoded = pcall(function() return H.httpService:JSONDecode(content) end)
	if ok2 and type(decoded) == "table" then
		if decoded.sellPan then H.S.sellPanIndex = decoded.sellPan end
		if decoded.farmPan then H.S.farmPanIndex = decoded.farmPan end
	end
end

H.saveModSettings = function()
	local data = { ws = H.S.walkSpeedValue, wsEnabled = H.S.walkSpeedEnabled }
	local ok, encoded = pcall(function() return H.httpService:JSONEncode(data) end)
	if ok then pcall(function() writefile(H.MOD_SETTINGS_FILE, encoded) end) end
end

H.loadModSettings = function()
	if not isfile or not isfile(H.MOD_SETTINGS_FILE) then return end
	local ok, content = pcall(function() return readfile(H.MOD_SETTINGS_FILE) end)
	if not ok or not content then return end
	local ok2, decoded = pcall(function() return H.httpService:JSONDecode(content) end)
	if ok2 and type(decoded) == "table" then
		if decoded.ws then H.S.walkSpeedValue = decoded.ws end
		if decoded.wsEnabled ~= nil then H.S.walkSpeedEnabled = decoded.wsEnabled end
	end
end

-- ==========================================
-- SILENT MODE
-- ==========================================
-- Suppress print & warn di scope file ini (biar nggak muncul di Developer Console).
local print = function() end
local warn = function() end
