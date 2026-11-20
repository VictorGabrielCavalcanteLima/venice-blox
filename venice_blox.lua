--==================================================================
--  VENICE HUB  |  Blox Fruits
--  local SRC = "https://raw.githubusercontent.com/VictorGabrielCavalcanteLima/venice-blox/main/venice_blox.lua"
--  loadstring(game:HttpGet(SRC))()
--==================================================================

if _G.__VeniceHub then pcall(function() _G.__VeniceHub() end) end

local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local TS          = game:GetService("TweenService")
local UIS         = game:GetService("UserInputService")
local TeleportSvc = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP          = Players.LocalPlayer
local Remotes     = RS:FindFirstChild("Remotes")
local CommF       = Remotes and Remotes:FindFirstChild("CommF_")

if not CommF then warn("[VeniceHub] CommF_ nao encontrado.") end

local MAX_LEVEL = 3000

--------------------------------------------------------------------
-- ESTADO
--------------------------------------------------------------------
local S = {
    Farm = false, KillAura = false, Chests = false, Fruits = false,
    AutoQuest = true, AutoEquip = true, AntiAfk = true, SafeTp = true,
    AutoRejoin = true, Stealth = 1, Radius = 60, AtkDelay = 0.12,
    ManualMob = "", TargetLevel = MAX_LEVEL, TierOffset = 0, LastBase = 0,
    Status = "Ocioso"
}

local CONNS = {}
local function bind(sig, fn) local c = sig:Connect(fn); CONNS[#CONNS+1] = c; return c end
local function rnd(a, b) return a + math.random() * (b - a) end
local function jitter(mult) task.wait(rnd(0.04, 0.16) * (mult or S.Stealth)) end

local function char()
    local c = LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then
        if c:FindFirstChildOfClass("Humanoid").Health > 0 then return c end
    end
end

local function level()
    local ok, v = pcall(function() return LP.Data.Level.Value end)
    return ok and v or 1
end

local function touch(a, b)
    if not firetouchinterest then return end
    pcall(firetouchinterest, a, b, 0)
    pcall(firetouchinterest, a, b, 1)
end

local function tp(pos, force)
    local c = char(); if not c then return end
    local hrp = c.HumanoidRootPart
    if force or not S.SafeTp then hrp.CFrame = CFrame.new(pos) return end
    local goal = CFrame.new(pos + Vector3.new(rnd(-2, 2), 0, rnd(-2, 2)))
    TS:Create(hrp, TweenInfo.new(rnd(0.08, 0.22), Enum.EasingStyle.Linear), {CFrame = goal}):Play()
    task.wait(rnd(0.1, 0.18))
end

local function talk(model)
    local cd = model:FindFirstChildOfClass("ClickDetector")
    if cd and fireclickdetector then pcall(fireclickdetector, cd) return true end
    local pp = model:FindFirstChildOfClass("ProximityPrompt")
    if pp and fireproximityprompt then pcall(fireproximityprompt, pp) return true end
    return false
end

--------------------------------------------------------------------
-- ESCADA DE QUESTS (1 -> 3000)
--------------------------------------------------------------------
local QUESTS = {
    -- Sea 1
    {1,"Bandit"},{10,"Monkey"},{15,"Brute"},{20,"Pirate"},{30,"Sky Bandit"},{40,"Dark Master"},
    {55,"Snow Bandit"},{70,"Snowman"},{85,"Winter Warrior"},{100,"Desert Bandit"},{115,"Desert Officer"},
    {130,"Jungle Pirate"},{145,"Mob Leader"},{160,"Galley Pirate"},{175,"Galley Captain"},{190,"Raider"},
    {205,"Mercenary"},{220,"Fighter"},{235,"Swan Pirate"},{250,"Factory Staff"},{275,"Marine"},
    {290,"Diamond"},{310,"Jeremy"},{330,"Zombie"},{350,"Zombie Brute"},{375,"Reborn Skeleton"},
    {400,"Living Zombie"},{425,"Demonic Soul"},{450,"Posessed Mummy"},{475,"Snow Lurker"},
    {500,"Arctic Warrior"},{525,"Sea Soldier"},{550,"Water Fighter"},{575,"Pirate Millionaire"},
    {600,"Pistol Billionaire"},{625,"Dragon Crew Warrior"},{650,"Dragon Crew Archer"},{675,"Magma Ninja"},
    -- Sea 2
    {700,"Lava Pirate"},{725,"Pirate Millionaire"},{750,"Pistol Billionaire"},{775,"Water Fighter"},
    {800,"Sea Soldier"},{825,"Magma Ninja"},{850,"Lava Pirate"},{875,"Swan Pirate"},
    {900,"Factory Staff"},{925,"Marine Captain"},{950,"Diamond"},{975,"Jeremy"},
    {1000,"Zombie Brute"},{1025,"Reborn Skeleton"},{1050,"Living Zombie"},{1075,"Demonic Soul"},
    {1100,"Posessed Mummy"},{1125,"Snow Lurker"},{1150,"Arctic Warrior"},{1175,"Pirate Captain"},
    {1200,"Elite Pirate"},{1225,"Elite Hunter"},{1250,"Forest Pirate"},{1275,"Mythological Pirate"},
    {1300,"Dragon Crew Warrior"},{1325,"Dragon Crew Archer"},{1350,"Magma Ninja"},{1375,"Lava Pirate"},
    {1400,"Hydra Enforcer"},{1425,"Venom Assassin"},{1450,"Sharkman"},
    -- Sea 3
    {1475,"Sharkman"},{1500,"Fishman"},{1525,"Citizen"},{1550,"Vampire"},{1575,"Bounty Hunter"},
    {1600,"Tide Keeper"},{1625,"Pirate Captain"},{1650,"Elite Pirate"},{1675,"Elite Hunter"},
    {1700,"Island Boy"},{1725,"Tiki Warrior"},{1750,"Hydra Enforcer"},{1775,"Venom Assassin"},
    {1800,"Forest Pirate"},{1825,"Mythological Pirate"},{1850,"Candy Rebel"},{1875,"Candy Pirate"},
    {1900,"Snow Assassin"},{1925,"Cake Guard"},{1950,"Pirate Skeletons"},{1975,"Cursed Skeleton"},
    {2000,"Gladiator"},{2025,"Arena Champion"},{2050,"Treant"},{2075,"Forest Guardian"},
    {2100,"Dragon Crew Warrior"},{2125,"Dragon Crew Archer"},{2150,"Ancient One"},{2175,"Serpent"},
    {2200,"Cursed Captain"},{2225,"Forsaken Warrior"},{2250,"Forsaken Archer"},{2275,"Colosseum Beast"},
    {2300,"Gladiator"},{2325,"Arena Champion"},{2350,"Treant"},{2375,"Forest Guardian"},
    {2400,"Ancient One"},{2425,"Serpent"},{2450,"Cursed Captain"},{2475,"Forsaken Warrior"},
    {2500,"Forsaken Archer"},{2525,"Colosseum Beast"},{2550,"Island Boy"},{2575,"Tiki Warrior"},
    {2600,"Candy Rebel"},{2625,"Candy Pirate"},{2650,"Snow Assassin"},{2675,"Cake Guard"},
    {2700,"Gladiator"},{2725,"Arena Champion"},{2750,"Treant"},{2775,"Forest Guardian"},
    {2800,"Ancient One"},{2825,"Serpent"},{2850,"Cursed Captain"},{2875,"Forsaken Warrior"},
    {2900,"Forsaken Archer"},{2925,"Colosseum Beast"},{2950,"Dragon Crew Warrior"},{2975,"Dragon Crew Archer"},
    {3000,"Gladiator"},
}

local function baseIndex()
    local lvl = math.clamp(level(), 1, math.clamp(S.TargetLevel or MAX_LEVEL, 1, MAX_LEVEL))
    local idx = 1
    for i, e in ipairs(QUESTS) do if lvl >= e[1] then idx = i end end
    return idx
end

local function currentTier()
    if S.ManualMob ~= "" then return S.ManualMob, nil end
    local b = baseIndex()
    if b ~= S.LastBase then S.TierOffset = 0; S.LastBase = b end
    local idx = math.clamp(b + S.TierOffset, 1, #QUESTS)
    return QUESTS[idx][2], idx
end

local function questText()
    local ok, t = pcall(function()
        local q = LP.PlayerGui.Main.Quest
        if q and q.Visible then return q.Container.QuestTitle.Text end
    end)
    if ok and type(t) == "string" then return t end
end

local function questDone()
    local t = questText(); if not t then return false end
    local a, b = t:match("(%d+)%s*/%s*(%d+)")
    return a and b and tonumber(a) >= tonumber(b) or false
end

local function questActiveFor(mob)
    local t = questText()
    return t ~= nil and t:find(mob, 1, true) ~= nil
end

local function startQuest(mob)
    local key = mob:gsub("%s+", "")
    for _, idx in ipairs({1, 2, 3}) do
        pcall(function() CommF:InvokeServer("StartQuest", key .. "Quest" .. idx, level()) end)
        task.wait(0.45)
        if questActiveFor(mob) then return true end
    end
    return false
end

local function findGiver(mob)
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name == mob and (v:FindFirstChildOfClass("ClickDetector") or v:FindFirstChildOfClass("ProximityPrompt")) then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp end
        end
    end
end

local function enemiesOf(mob, radius)
    local out, c = {}, char()
    if not c then return out end
    local origin = c.HumanoidRootPart.Position
    local folder = workspace:FindFirstChild("Enemies")
    for _, e in ipairs(folder and folder:GetChildren() or {}) do
        if mob == "" or e.Name == mob then
            local hrp = e:FindFirstChild("HumanoidRootPart")
            local hum = e:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - origin).Magnitude
                if d <= radius then out[#out+1] = {hrp = hrp, dist = d} end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

local function equipBest()
    local c = char(); if not c then return end
    if c:FindFirstChildOfClass("Tool") then return end
    local bp = LP:FindFirstChild("Backpack"); if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Handle") and not t.Name:find("-") then
            pcall(function() c.Humanoid:EquipTool(t) end)
            return
        end
    end
end

local function attack(hrp)
    local c = char(); if not c then return end
    if S.AutoEquip then equipBest() end
    local tool = c:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    touch(c.HumanoidRootPart, hrp)
end

--------------------------------------------------------------------
-- ANTI-BAN
--------------------------------------------------------------------
bind(LP.Idled, function()
    if not S.AntiAfk then return end
    local vu = game:GetService("VirtualUser")
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

pcall(function()
    if queue_on_teleport then
        queue_on_teleport("loadstring(game:HttpGet('" .. SRC .. "'))()")
    end
end)

--------------------------------------------------------------------
-- LOOPS
--------------------------------------------------------------------
task.spawn(function()
    local questCd, claimCd, fails = 0, 0, 0
    while task.wait(0.1) do
        if not S.Farm then S.Status = "Farm: off"; continue end
        local c = char(); if not c then continue end
        if level() >= MAX_LEVEL and S.ManualMob == "" then S.Status = "Level maximo (3000)" end

        local mob, idx = currentTier()
        if not mob then continue end

        if S.AutoQuest and not questActiveFor(mob) and os.clock() > questCd then
            questCd = os.clock() + 2
            local giver = findGiver(mob)
            if giver then
                S.Status = "Quest: " .. mob
                tp(giver.Position + Vector3.new(0, 3, 0))
                task.wait(0.35)
                talk(giver)
                task.wait(0.3)
                if startQuest(mob) then
                    fails = 0
                else
                    fails = fails + 1
                    if fails >= 3 and idx and idx > 1 then
                        S.TierOffset = S.TierOffset - 1
                        fails = 0
                        S.Status = "Tier " .. mob .. " falhou, descendo"
                    end
                end
            else
                S.Status = "Sem quest giver de " .. mob
            end
            jitter()
        end

        if S.AutoQuest and questDone() and os.clock() > claimCd then
            claimCd = os.clock() + 3
            local giver = findGiver(mob)
            if giver then
                S.Status = "Entregando quest"
                tp(giver.Position + Vector3.new(0, 3, 0))
                task.wait(0.4)
                talk(giver)
                task.wait(0.4)
                startQuest(mob)
            end
        end

        local target = enemiesOf(mob, 6000)[1]
        if target then
            S.Status = "Matando " .. mob
            tp(target.hrp.Position - target.hrp.CFrame.LookVector * 3 + Vector3.new(0, 2, 0))
            attack(target.hrp)
            task.wait(S.AtkDelay * S.Stealth)
        else
            S.Status = "Sem " .. mob .. " no mapa"
            task.wait(0.6)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not S.KillAura then continue end
        local list = enemiesOf("", S.Radius)
        for i = 1, math.min(#list, 6) do
            if not S.KillAura then break end
            attack(list[i].hrp)
            task.wait(S.AtkDelay * S.Stealth)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not S.Chests then continue end
        local c = char(); if not c then continue end
        local origin = c.HumanoidRootPart.Position
        local best, bestD
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "Chest" and v:IsA("BasePart") then
                local d = (v.Position - origin).Magnitude
                if d < 4000 and (not bestD or d < bestD) then best, bestD = v, d end
            end
        end
        if best then
            S.Status = "Bau a " .. math.floor(bestD) .. "m"
            tp(best.Position + Vector3.new(0, 3, 0))
            task.wait(0.15)
            touch(c.HumanoidRootPart, best)
            task.wait(0.25)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while task.wait(0.4) do
        if not S.Fruits then continue end
        local c = char(); if not c then continue end
        local origin = c.HumanoidRootPart.Position
        local found
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("Handle") then
                if (v.Handle.Position - origin).Magnitude < 4000 then found = v break end
            end
        end
        if found then
            S.Status = "Coletando " .. found.Name
            tp(found.Handle.Position + Vector3.new(0, 2, 0))
            task.wait(0.2)
            touch(c.HumanoidRootPart, found.Handle)
            task.wait(0.4)
        end
    end
end)

--------------------------------------------------------------------
-- UI
--------------------------------------------------------------------
local ACCENT = Color3.fromRGB(255, 210, 63)
local BG     = Color3.fromRGB(13, 13, 17)
local PANEL  = Color3.fromRGB(19, 19, 25)
local ELEM   = Color3.fromRGB(26, 26, 33)
local TEXT   = Color3.fromRGB(236, 236, 242)
local SUB    = Color3.fromRGB(132, 132, 148)
local STROKE = Color3.fromRGB(40, 40, 52)

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local guiParent = game:GetService("CoreGui")
if not pcall(function() local f = Instance.new("Folder"); f.Parent = guiParent; f:Destroy() end) then
    guiParent = LP:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", {Name = "VeniceHub", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true}, guiParent)

local main = new("Frame", {Size = UDim2.fromOffset(600, 400), Position = UDim2.new(0.5, -300, 0.5, -200),
    BackgroundColor3 = BG, BorderSizePixel = 0}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, main)
new("UIStroke", {Color = STROKE, Thickness = 1}, main)

local top = new("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = PANEL, BorderSizePixel = 0}, main)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, top)
new("TextLabel", {Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = ACCENT,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "VENICE HUB  |  BLOX FRUITS"}, top)

local closeBtn = new("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0, 4),
    BackgroundColor3 = ELEM, Text = "X", Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = TEXT, BorderSizePixel = 0, AutoButtonColor = false}, top)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, closeBtn)
local minBtn = new("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -62, 0, 4),
    BackgroundColor3 = ELEM, Text = "_", Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = TEXT, BorderSizePixel = 0, AutoButtonColor = false}, top)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, minBtn)

do
    local dragging, start, origin
    bind(top.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; start = i.Position; origin = main.Position
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            main.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
        end
    end)
    bind(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local sidebar = new("Frame", {Size = UDim2.new(0, 138, 1, -44), Position = UDim2.fromOffset(10, 40),
    BackgroundColor3 = PANEL, BorderSizePixel = 0}, main)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, sidebar)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, sidebar)

local content = new("Frame", {Size = UDim2.new(1, -168, 1, -74), Position = UDim2.fromOffset(158, 40), BackgroundTransparency = 1}, main)
local uiStatus = new("TextLabel", {Size = UDim2.new(1, -168, 0, 22), Position = UDim2.new(0, 158, 1, -28),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = SUB,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "Ocioso"}, main)

local pages = {}
local function makePage(name)
    local p = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, CanvasSize = UDim2.new(), Visible = false, ScrollBarImageColor3 = ACCENT,
        AutomaticCanvasSize = Enum.AutomaticSize.Y}, content)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, p)
    pages[name] = p
    return p
end

local function section(page, text)
    new("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Text = text:upper()}, page)
end

local function toggle(page, text, default, cb)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = ELEM, BorderSizePixel = 0}, page)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, row)
    new("TextLabel", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = text}, row)
    local sw = new("Frame", {Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -46, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(50, 50, 62), BorderSizePixel = 0}, row)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, sw)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = TEXT, BorderSizePixel = 0}, sw)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local state = default
    local function render()
        TS:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)}):Play()
        TS:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and ACCENT or Color3.fromRGB(50, 50, 62)}):Play()
    end
    render()
    local btn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = ""}, row)
    btn.MouseButton1Click:Connect(function() state = not state; render(); cb(state) end)
end

local function button(page, text, cb)
    local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = ELEM, BorderSizePixel = 0,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TEXT, Text = text, AutoButtonColor = false}, page)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
    b.MouseEnter:Connect(function() TS:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = ACCENT, TextColor3 = BG}):Play() end)
    b.MouseLeave:Connect(function() TS:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = ELEM, TextColor3 = TEXT}):Play() end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function slider(page, text, min, max, default, fmt, cb)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = ELEM, BorderSizePixel = 0}, page)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, row)
    local lbl = new("TextLabel", {Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 3), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
        Text = text .. "  [" .. fmt(default) .. "]"}, row)
    local bar = new("Frame", {Size = UDim2.new(1, -20, 0, 6), Position = UDim2.fromOffset(10, 28),
        BackgroundColor3 = Color3.fromRGB(44, 44, 56), BorderSizePixel = 0}, row)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, bar)
    local fill = new("Frame", {Size = UDim2.fromScale((default - min) / (max - min), 1),
        BackgroundColor3 = ACCENT, BorderSizePixel = 0}, bar)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    local dragging = false
    local function set(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * a
        fill.Size = UDim2.fromScale(a, 1)
        lbl.Text = text .. "  [" .. fmt(v) .. "]"
        cb(v)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; set(i.Position.X)
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then set(i.Position.X) end
    end)
    bind(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function textbox(page, placeholder, cb)
    local box = new("TextBox", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = ELEM, BorderSizePixel = 0,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TEXT, PlaceholderText = placeholder,
        PlaceholderColor3 = SUB, Text = "", ClearTextOnFocus = false}, page)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, box)
    box.FocusLost:Connect(function() cb(box.Text) end)
    return box
end

local function notify(msg)
    local n = new("TextLabel", {Size = UDim2.fromOffset(230, 30), Position = UDim2.new(1, -245, 0, 10 + #gui:GetChildren()),
        BackgroundColor3 = PANEL, Text = "  " .. msg, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0}, gui)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, n)
    new("UIStroke", {Color = ACCENT, Thickness = 1}, n)
    task.delay(2.5, function()
        TS:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.wait(0.35); n:Destroy()
    end)
end

local TABS = {"Anti-Ban", "Farm", "Itens", "Misc"}
local tabButtons = {}
local function showTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabButtons) do b.BackgroundColor3 = (n == name) and ACCENT or ELEM end
end

for _, name in ipairs(TABS) do
    local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = ELEM, BorderSizePixel = 0,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TEXT, Text = name, AutoButtonColor = false}, sidebar)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
    b.MouseButton1Click:Connect(function() showTab(name) end)
    tabButtons[name] = b
    makePage(name)
end

-- ANTI-BAN
local pA = pages["Anti-Ban"]
section(pA, "Protecao")
toggle(pA, "Anti-AFK", true, function(v) S.AntiAfk = v; notify("Anti-AFK " .. (v and "on" or "off")) end)
toggle(pA, "Teleporte suave", true, function(v) S.SafeTp = v end)
toggle(pA, "Auto-rejoin em queda", true, function(v) S.AutoRejoin = v end)
section(pA, "Ritmo")
slider(pA, "Multiplicador furtivo", 0.5, 3, 1, function(v) return string.format("%.1fx", v) end, function(v) S.Stealth = v end)
slider(pA, "Delay de ataque", 0.05, 0.5, 0.12, function(v) return string.format("%.2fs", v) end, function(v) S.AtkDelay = v end)
section(pA, "Rede")
button(pA, "Travar FPS em 60", function() pcall(function() setfpscap(60) end); notify("FPS limitado") end)

-- FARM
local pF = pages["Farm"]
section(pF, "Automacao")
toggle(pF, "Auto farm de level", false, function(v) S.Farm = v; notify("Farm " .. (v and "on" or "off")) end)
toggle(pF, "Auto quest", true, function(v) S.AutoQuest = v end)
toggle(pF, "Kill aura", false, function(v) S.KillAura = v end)
section(pF, "Coleta")
toggle(pF, "Auto baus", false, function(v) S.Chests = v end)
toggle(pF, "Auto frutas", false, function(v) S.Fruits = v end)
section(pF, "Ajustes")
slider(pF, "Raio da kill aura", 20, 250, 60, function(v) return math.floor(v) .. "m" end, function(v) S.Radius = v end)
textbox(pF, "Level alvo (1-3000, vazio = 3000)", function(t)
    local n = tonumber(t)
    S.TargetLevel = (n and n > 0) and math.clamp(n, 1, MAX_LEVEL) or MAX_LEVEL
    notify("Alvo: level " .. S.TargetLevel)
end)
textbox(pF, "Mob fixo (vazio = automatico)", function(t)
    S.ManualMob = t
    notify(t == "" and "Modo automatico" or "Mob fixo: " .. t)
end)
section(pF, "Mobs no servidor")
local scanFrame = new("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y}, pF)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, scanFrame)

button(pF, "Escanear mobs do mapa", function()
    for _, c in ipairs(scanFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local folder = workspace:FindFirstChild("Enemies")
    local seen, list = {}, {}
    for _, e in ipairs(folder and folder:GetChildren() or {}) do
        if not seen[e.Name] and e:FindFirstChild("HumanoidRootPart") then
            seen[e.Name] = true; list[#list+1] = e.Name
        end
    end
    table.sort(list)
    if #list == 0 then notify("Nenhum mob no mapa") return end
    for i = 1, math.min(#list, 25) do
        local name = list[i]
        local b = button(scanFrame, name, function()
            S.ManualMob = name
            notify("Mob fixo: " .. name)
        end)
        b.LayoutOrder = i
    end
    notify(#list .. " tipos de mob encontrados")
end)
button(pF, "Limpar mob fixo", function() S.ManualMob = ""; notify("Modo automatico") end)

-- ITENS
local pI = pages["Itens"]
section(pI, "Compras")
toggle(pI, "Auto equipar arma", true, function(v) S.AutoEquip = v end)
button(pI, "Comprar espada (Cousin)", function()
    pcall(function() CommF:InvokeServer("Cousin", "Buy") end); notify("Comprando espada")
end)
button(pI, "Comprar Buso Haki", function()
    pcall(function() CommF:InvokeServer("BuyHaki", "Buso") end); notify("Buso Haki")
end)
button(pI, "Comprar Geppo", function()
    pcall(function() CommF:InvokeServer("BuyHaki", "Geppo") end); notify("Geppo")
end)
button(pI, "Comprar Ken", function()
    pcall(function() CommF:InvokeServer("BuyHaki", "Ken") end); notify("Ken")
end)
section(pI, "Utilidades")
button(pI, "Coletar frutas proximas (unico)", function()
    local c = char(); if not c then return end
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            if (v.Handle.Position - c.HumanoidRootPart.Position).Magnitude < 4000 then
                tp(v.Handle.Position + Vector3.new(0, 2, 0))
                task.wait(0.2)
                touch(c.HumanoidRootPart, v.Handle)
                task.wait(0.4)
            end
        end
    end
    notify("Varredura concluida")
end)

-- MISC
local pM = pages["Misc"]
section(pM, "Servidor")
button(pM, "Rejoin", function() pcall(function() TeleportSvc:Teleport(game.PlaceId, LP) end) end)
button(pM, "Server hop", function()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if not ok or not data or not data.data then notify("Falha ao listar") return end
    for _, sv in ipairs(data.data) do
        if sv.playing < sv.maxPlayers - 2 and sv.id ~= game.JobId then
            notify("Entrando em " .. sv.playing .. "/" .. sv.maxPlayers)
            pcall(function() TeleportSvc:TeleportToPlaceInstance(game.PlaceId, sv.id, LP) end)
            return
        end
    end
    notify("Nenhum servidor livre")
end)
section(pM, "Jogador")
local tpName = ""
textbox(pM, "Nome do jogador", function(n) tpName = n end)
button(pM, "Teleportar ate o jogador", function()
    local pl = Players:FindFirstChild(tpName)
    if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
        tp(pl.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0))
        notify("Teleportado")
    else
        notify("Jogador nao encontrado")
    end
end)
button(pM, "Resetar personagem", function() if LP.Character then LP.Character:BreakJoints() end end)
section(pM, "Codigos")
textbox(pM, "Digite o codigo", function(c)
    if c ~= "" then pcall(function() CommF:InvokeServer("Redeem", c) end); notify("Resgatando " .. c) end
end)
section(pM, "Sessao")
button(pM, "Desligar hub", function() _G.__VeniceHub() end)

task.spawn(function()
    while task.wait(0.25) do
        uiStatus.Text = "Lv " .. level() .. "/" .. MAX_LEVEL .. "  |  " .. S.Status
    end
end)

minBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
closeBtn.MouseButton1Click:Connect(function() _G.__VeniceHub() end)

_G.__VeniceHub = function()
    for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
    S.Farm, S.KillAura, S.Chests, S.Fruits = false, false, false, false
    gui:Destroy()
    _G.__VeniceHub = nil
end

showTab("Anti-Ban")
notify("Venice Hub carregado")
