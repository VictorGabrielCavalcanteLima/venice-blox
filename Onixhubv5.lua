--=====================================================================
--  ONIXHUB v5  •  BLOX FRUITS  •  MOBILE (Delta / Wave / Fluxus)
--  Arquivo: Onixhubv5.lua
--  Place: 2753915549  |  Use na Third Sea (1500+)
--=====================================================================

if getgenv().ONIX_GUI then pcall(function() getgenv().ONIX_GUI:Destroy() end) end

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local TS        = game:GetService("TweenService")
local UIS       = game:GetService("UserInputService")
local VIM       = game:GetService("VirtualInputManager")
local VU        = game:GetService("VirtualUser")
local HS        = game:GetService("HttpService")
local LP        = Players.LocalPlayer

local Remotes = RS:WaitForChild("Remotes")
local CommF   = Remotes:WaitForChild("CommF_")
local CommE   = Remotes:WaitForChild("CommE")

local PLACE_ID = 2753915549
local MAX_ATTEMPTS = 30
local LOAD_DELAY = 5

--=========================  TEMA  ===================================
local C = {
    bg      = Color3.fromRGB(10,10,14),
    panel   = Color3.fromRGB(18,18,24),
    card    = Color3.fromRGB(27,27,36),
    accent  = Color3.fromRGB(124,92,255),
    accent2 = Color3.fromRGB(84,58,190),
    txt     = Color3.fromRGB(234,234,242),
    dim     = Color3.fromRGB(140,140,158),
    green   = Color3.fromRGB(46,160,92),
    red     = Color3.fromRGB(190,60,70),
    bossC   = Color3.fromRGB(40,34,52),
    islC    = Color3.fromRGB(30,46,38),
    swdC    = Color3.fromRGB(52,38,30),
}

local State = {
    autoFarm=false, bring=false, takeQuest=false, questMob=nil,
    nearest=1500, farmDist=15, bringRadius=400, tweenSpeed=200,
    posMethod="Orbit", attackMethod="Fast Attack", fastAttack=true,
    fastDelay=0.05, weapon=nil, boss="Stone", autoBoss=false,
    autoChest=false, chestHop=false, chestCount=10, autoMaterial=false,
    tyrant=false, antiAfk=true, walkWater=false, autoLoad=false,
    hopping=false,
}

--=========================  UTIL  ===================================
local function notify(txt, cor)
    local g = getgenv().ONIX_NOTIFY
    if g then g(txt, cor) end
    print("[ONIX] " .. tostring(txt))
end

local function getChar()
    local c = LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then
        return c
    end
end

local function alive()
    local c = getChar()
    return c and c.Humanoid.Health > 0
end

local function hrp()
    local c = getChar()
    return c and c.HumanoidRootPart
end

local function moveTo(pos)
    local c = getChar()
    if not c then return end
    local r = c.HumanoidRootPart
    local d = (r.Position - pos).Magnitude
    if d < 4 then return end
    local t = TS:Create(r, TweenInfo.new(d / math.max(State.tweenSpeed, 20), Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))})
    t:Play()
    t.Completed:Wait()
end

local function orbit(mob)
    local c = getChar()
    local t = mob:FindFirstChild("HumanoidRootPart")
    if not c or not t then return end
    local a = tick() % (math.pi * 2)
    c.HumanoidRootPart.CFrame = CFrame.new(t.Position + Vector3.new(math.cos(a) * 6, 3, math.sin(a) * 6))
end

local function mobAlive(m)
    local h = m:FindFirstChildOfClass("Humanoid")
    local r = m:FindFirstChild("HumanoidRootPart")
    return h and r and h.Health > 0
end

local function nearestMob(maxDist, filter)
    local root = hrp()
    if not root then return end
    local folder = workspace:FindFirstChild("Enemies")
    if not folder then return end
    local best, bestD, any, anyD
    for _, m in ipairs(folder:GetChildren()) do
        if mobAlive(m) then
            local d = (m.HumanoidRootPart.Position - root.Position).Magnitude
            if d <= (maxDist or State.nearest) then
                if not anyD or d < anyD then any, anyD = m, d end
                if filter and m.Name:find(filter, 1, true) then
                    if not bestD or d < bestD then best, bestD = m, d end
                end
            end
        end
    end
    return best or any
end

local function findBoss(name)
    for _, m in ipairs(workspace:GetChildren()) do
        if m.Name == name and mobAlive(m) then return m end
    end
    local f = workspace:FindFirstChild("Bosses")
    if f then
        for _, m in ipairs(f:GetChildren()) do
            if m.Name == name and mobAlive(m) then return m end
        end
    end
end

local function findModel(name)
    return workspace:FindFirstChild(name, true)
end

local function ensureWeapon()
    local c = getChar()
    if not c or not State.weapon then return end
    if c:FindFirstChild(State.weapon) then return end
    local bp = LP:FindFirstChild("Backpack")
    local t = bp and bp:FindFirstChild(State.weapon)
    if t then pcall(function() c.Humanoid:EquipTool(t) end) end
end

local function doAttack(mob)
    local c = getChar()
    local t = mob and mob:FindFirstChild("HumanoidRootPart")
    if not c or not t then return end
    c.HumanoidRootPart.CFrame = CFrame.new(c.HumanoidRootPart.Position, t.Position)
    pcall(function() CommE:FireServer("UpdateMousePos", t.Position) end)
    local tool = c:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    if State.attackMethod == "Normal" then
        pcall(function()
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

--=========================  QUESTS  =================================
local QUESTS = {
    {lvl=1,    mob="Bandit",                id="BanditQuest1",        num=1},
    {lvl=10,   mob="Monkey",                id="JungleQuest",         num=1},
    {lvl=15,   mob="Gorilla",               id="JungleQuest",         num=2},
    {lvl=30,   mob="Pirate",                id="BuggyQuest1",         num=1},
    {lvl=40,   mob="Brute",                 id="BuggyQuest1",         num=2},
    {lvl=60,   mob="Desert Bandit",         id="DesertQuest",         num=1},
    {lvl=75,   mob="Desert Officer",        id="DesertQuest",         num=2},
    {lvl=90,   mob="Snow Bandit",           id="SnowQuest",           num=1},
    {lvl=100,  mob="Snowman",               id="SnowQuest",           num=2},
    {lvl=120,  mob="Chief Petty Officer",   id="MarineQuest2",        num=1},
    {lvl=150,  mob="Sky Bandit",            id="SkyQuest",            num=1},
    {lvl=175,  mob="Dark Master",           id="SkyQuest",            num=2},
    {lvl=250,  mob="Toga Warrior",          id="ColosseumQuest",      num=1},
    {lvl=275,  mob="Gladiator",             id="ColosseumQuest",      num=2},
    {lvl=300,  mob="Military Soldier",      id="MagmaQuest",          num=1},
    {lvl=325,  mob="Military Spy",          id="MagmaQuest",          num=2},
    {lvl=375,  mob="Fishman Warrior",       id="FishmanQuest",        num=1},
    {lvl=400,  mob="Fishman Commando",      id="FishmanQuest",        num=2},
    {lvl=450,  mob="God's Guard",           id="SkyExp1Quest",        num=1},
    {lvl=475,  mob="Shanda",                id="SkyExp1Quest",        num=2},
    {lvl=525,  mob="Royal Squad",           id="SkyExp2Quest",        num=1},
    {lvl=550,  mob="Royal Soldier",         id="SkyExp2Quest",        num=2},
    {lvl=625,  mob="Galley Pirate",         id="FountainQuest",       num=1},
    {lvl=650,  mob="Galley Captain",        id="FountainQuest",       num=2},
    {lvl=700,  mob="Raider",                id="Area1Quest",          num=1},
    {lvl=725,  mob="Mercenary",             id="Area1Quest",          num=2},
    {lvl=775,  mob="Swan Pirate",           id="Area2Quest",          num=1},
    {lvl=875,  mob="Marine Lieutenant",     id="MarineQuest3",        num=1},
    {lvl=900,  mob="Marine Captain",        id="MarineQuest3",        num=2},
    {lvl=950,  mob="Zombie",                id="ZombieQuest",         num=1},
    {lvl=975,  mob="Vampire",               id="ZombieQuest",         num=2},
    {lvl=1000, mob="Snow Trooper",          id="SnowMountainQuest",   num=1},
    {lvl=1050, mob="Winter Warrior",        id="SnowMountainQuest",   num=2},
    {lvl=1100, mob="Lab Subordinate",       id="IceSideQuest",        num=1},
    {lvl=1125, mob="Horned Warrior",        id="IceSideQuest",        num=2},
    {lvl=1175, mob="Magma Ninja",           id="FireSideQuest",       num=1},
    {lvl=1200, mob="Lava Pirate",           id="FireSideQuest",       num=2},
    {lvl=1350, mob="Arctic Warrior",        id="FrostQuest",          num=1},
    {lvl=1375, mob="Snow Lurker",           id="FrostQuest",          num=2},
    {lvl=1425, mob="Sea Soldier",           id="ForgottenQuest",      num=1},
    {lvl=1450, mob="Water Fighter",         id="ForgottenQuest",      num=2},
    {lvl=1500, mob="Pirate Millionaire",    id="PiratePortQuest",     num=1},
    {lvl=1525, mob="Pistol Billionaire",    id="PiratePortQuest",     num=2},
    {lvl=1575, mob="Dragon Crew Warrior",   id="AmazonQuest",         num=1},
    {lvl=1600, mob="Dragon Crew Archer",    id="AmazonQuest",         num=2},
    {lvl=1625, mob="Female Islander",       id="AmazonQuest2",        num=1},
    {lvl=1650, mob="Giant Islander",        id="AmazonQuest2",        num=2},
    {lvl=1700, mob="Marine Commodore",      id="MarineTreeIsland",    num=1},
    {lvl=1725, mob="Marine Rear Admiral",   id="MarineTreeIsland",    num=2},
    {lvl=1775, mob="Fishman Raider",        id="DeepForestIsland3",   num=1},
    {lvl=1800, mob="Fishman Captain",       id="DeepForestIsland3",   num=2},
    {lvl=1825, mob="Forest Pirate",         id="DeepForestIsland",    num=1},
    {lvl=1850, mob="Mythological Pirate",   id="DeepForestIsland",    num=2},
    {lvl=1900, mob="Jungle Pirate",         id="DeepForestIsland2",   num=1},
    {lvl=1925, mob="Musketeer Pirate",      id="DeepForestIsland2",   num=2},
    {lvl=1975, mob="Reborn Skeleton",       id="HauntedQuest1",       num=1},
    {lvl=2000, mob="Living Zombie",         id="HauntedQuest1",       num=2},
    {lvl=2025, mob="Demonic Soul",          id="HauntedQuest2",       num=1},
    {lvl=2050, mob="Posessed Mummy",        id="HauntedQuest2",       num=2},
    {lvl=2075, mob="Peanut Scout",          id="NutsIslandQuest",     num=1},
    {lvl=2100, mob="Peanut President",      id="NutsIslandQuest",     num=2},
    {lvl=2125, mob="Ice Cream Chef",        id="IceCreamIslandQuest", num=1},
    {lvl=2150, mob="Ice Cream Commander",   id="IceCreamIslandQuest", num=2},
    {lvl=2200, mob="Cookie Crafter",        id="CakeQuest1",          num=1},
    {lvl=2225, mob="Cake Guard",            id="CakeQuest1",          num=2},
    {lvl=2250, mob="Baking Staff",          id="CakeQuest2",          num=1},
    {lvl=2275, mob="Head Baker",            id="CakeQuest2",          num=2},
    {lvl=2300, mob="Cocoa Warrior",         id="ChocolateQuest1",     num=1},
    {lvl=2325, mob="Chocolate Bar Battler", id="ChocolateQuest1",     num=2},
    {lvl=2350, mob="Sweet Thief",           id="ChocolateQuest2",     num=1},
    {lvl=2375, mob="Candy Rebel",           id="ChocolateQuest2",     num=2},
    {lvl=2400, mob="Candy Pirate",          id="CandyQuest",          num=1},
    {lvl=2425, mob="Snow Demon",            id="CandyQuest",          num=2},
    {lvl=2450, mob="Isle Outlaw",           id="TikiQuest1",          num=1},
    {lvl=2475, mob="Island Boy",            id="TikiQuest1",          num=2},
    {lvl=2500, mob="Sun-kissed Warrior",    id="TikiQuest2",          num=1},
    {lvl=2525, mob="Isle Champion",         id="TikiQuest2",          num=2},
    {lvl=2550, mob="Serpent Hunter",        id="TikiQuest3",          num=1},
    {lvl=2575, mob="Skull Slayer",          id="TikiQuest3",          num=2},
    {lvl=2600, mob="Reef Bandit",           id="SubmergedQuest1",     num=1},
    {lvl=2625, mob="Coral Pirate",          id="SubmergedQuest1",     num=2},
    {lvl=2650, mob="Sea Chanter",           id="SubmergedQuest2",     num=1},
    {lvl=2675, mob="Ocean Prophet",         id="SubmergedQuest2",     num=2},
    {lvl=2700, mob="High Disciple",         id="SubmergedQuest3",     num=1},
    {lvl=2725, mob="Grand Devotee",         id="SubmergedQuest3",     num=2},
    {lvl=2750, mob="Abyssal Brute",         id="SubmergedQuest4",     num=1},
    {lvl=2800, mob="Deep Chantress",        id="SubmergedQuest4",     num=2},
    {lvl=2850, mob="Trench Duelist",        id="SecretQuest1",        num=1},
    {lvl=2900, mob="Cursed Devotee",        id="SecretQuest2",        num=1},
    {lvl=2950, mob="Secret Master Guard",   id="SecretQuest3",        num=1},
    {lvl=3000, mob="Secret Master",         id="SecretQuest3",        num=2},
}

local function questVisible()
    local pg = LP:FindFirstChild("PlayerGui")
    local mn = pg and pg:FindFirstChild("Main")
    local q  = mn and mn:FindFirstChild("Quest")
    return q and q.Visible
end

local function takeQuest()
    local d = LP:FindFirstChild("Data")
    local lvl = d and d:FindFirstChild("Level") and d.Level.Value or 0
    local idx = #QUESTS
    while idx >= 1 and QUESTS[idx].lvl > lvl do idx = idx - 1 end
    if idx < 1 then return end
    for i = idx, math.max(1, idx - 8), -1 do
        local q = QUESTS[i]
        pcall(function() CommF:InvokeServer("StartQuest", q.id, q.num) end)
        task.wait(0.45)
        if questVisible() then
            State.questMob = q.mob
            return
        end
    end
end

--=========================  HOP  ====================================
local function httpGet(url)
    local req = (syn and syn.request) or http_request or request or httprequest
    if not req then return nil end
    local ok, res = pcall(req, {Url = url, Method = "GET"})
    return ok and res and res.Body or nil
end

local function fetchServers()
    local body = httpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID))
    if not body then return {} end
    local ok, data = pcall(function() return HS:JSONDecode(body) end)
    if not ok or not data or not data.data then return {} end
    local list = {}
    for _, s in ipairs(data.data) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then table.insert(list, s.id) end
    end
    return list
end

local function queueOnTeleport(src)
    local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if q then pcall(q, src) end
end

local WATCHER = [==[
local ATTEMPT, MAX = __ATTEMPT__, 30
local CANDS = __CANDS__
local PLACE = 2753915549
local DELAY = 5

local Players = game:GetService("Players")
local TS      = game:GetService("TeleportService")
local HS      = game:GetService("HttpService")

local function notify(m)
    if getgenv().ONIX_NOTIFY then pcall(getgenv().ONIX_NOTIFY, m) end
    print("[ONIX-HOP] " .. tostring(m))
end

repeat task.wait(0.5) until Players.LocalPlayer and Players.LocalPlayer.Parent
task.wait(DELAY)

local function find()
    for _, n in ipairs(CANDS) do
        if workspace:FindFirstChild(n, true) then return n end
    end
end

local hit = find()
if hit then
    notify("ACHEI: " .. hit .. " (tentativa " .. ATTEMPT .. ")")
    if getgenv().ONIX_URL then
        pcall(function() loadstring(game:HttpGet(getgenv().ONIX_URL))() end)
    end
    return
end

if ATTEMPT >= MAX then notify("Limite de " .. MAX .. " tentativas.") return end

local req = (syn and syn.request) or http_request or request or httprequest
if not req then notify("Executor sem HTTP.") return end

local ok, res = pcall(req, {Url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE), Method = "GET"})
if not ok or not res or not res.Body then notify("Falha ao listar servidores.") return end
local ok2, data = pcall(function() return HS:JSONDecode(res.Body) end)
if not ok2 or not data or not data.data then notify("Resposta inválida.") return end

local list = {}
for _, s in ipairs(data.data) do
    if s.id ~= game.JobId and s.playing < s.maxPlayers then table.insert(list, s.id) end
end
if #list == 0 then notify("Nenhum servidor livre.") return end

local tpl = getgenv().ONIX_WATCHER
if tpl then
    local src = tpl:gsub("__ATTEMPT__", tostring(ATTEMPT + 1))
    local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if q then pcall(q, src) end
end

notify("Nada aqui. Tentando " .. (ATTEMPT + 1) .. "/" .. MAX)
pcall(function() TS:TeleportToPlaceInstance(PLACE, list[math.random(1, #list)], Players.LocalPlayer) end)
]==]

local function buildWatcher(cands, attempt)
    local ser = "{"
    for _, v in ipairs(cands) do ser = ser .. string.format("%q,", v) end
    ser = ser .. "}"
    local tpl = WATCHER:gsub("__CANDS__", function() return ser end)
    getgenv().ONIX_WATCHER = tpl
    return tpl:gsub("__ATTEMPT__", tostring(attempt))
end

local function startTargetHop(label, cands)
    if State.hopping then
        notify("Já está hopando.", C.red)
        return
    end
    local list = fetchServers()
    if #list == 0 then
        notify("Nenhum servidor disponível (HTTP ok?).", C.red)
        return
    end
    State.hopping = true
    queueOnTeleport(buildWatcher(cands, 1))
    notify("Hopando por: " .. label .. " (1/" .. MAX_ATTEMPTS .. ")", C.accent)
    task.wait(0.4)
    pcall(function() TS:TeleportToPlaceInstance(PLACE_ID, list[math.random(1, #list)], LP) end)
end

--=========================  GUI BASE  ===============================
local Registry = {}
local gui = Instance.new("ScreenGui")
gui.Name = "OnixHubV5"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")
getgenv().ONIX_GUI = gui

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end

local toastHolder = new("Frame", {
    Size = UDim2.new(0, 230, 0, 0), Position = UDim2.new(1, -245, 0, 60),
    BackgroundTransparency = 1, Parent = gui,
})
new("UIListLayout", {Padding = UDim.new(0, 6)}, toastHolder)

getgenv().ONIX_NOTIFY = function(txt, cor)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.card,
        BackgroundTransparency = 0.05, Parent = toastHolder,
    })
    corner(f, 8)
    new("UIStroke", {Color = cor or C.accent, Transparency = 0.4}, f)
    new("TextLabel", {
        Text = txt, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.txt,
        TextWrapped = true, BackgroundTransparency = 1, Size = UDim2.new(1, -14, 1, 0),
        Position = UDim2.new(0, 7, 0, 0), Parent = f,
    })
    task.delay(3, function()
        if f then
            TS:Create(f, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            f:Destroy()
        end
    end)
end

local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(400, 700)
local W = math.min(372, vp.X - 14)
local H = math.min(560, vp.Y - 40)

local main = new("Frame", {
    Size = UDim2.fromOffset(W, H), Position = UDim2.new(0.5, -W/2, 0.5, -H/2),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = gui,
})
corner(main, 12)
new("UIStroke", {Color = C.accent, Transparency = 0.45}, main)

local floatBtn = new("TextButton", {
    Text = "OX", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.txt,
    BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromOffset(46, 46),
    Position = UDim2.new(0, 12, 0.3, 0), Parent = gui,
})
corner(floatBtn, 23)
floatBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
    floatBtn.Visible = not main.Visible
end)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.panel,
    BorderSizePixel = 0, Parent = main,
})
corner(header, 12)
ne