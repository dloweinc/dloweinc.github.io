local ADDON_NAME = ...

local LootBrowser = {}
LootBrowser.MIN_QUALITY = 3 -- 3=Rare (blue), 4=Epic, 5=Legendary
LootBrowser.SLASH_COMMAND = "/rloot"

local ToggleMainFrame

LootBrowser.dungeons = {
    {
        id = "blood_furnace",
        name = "The Blood Furnace",
        zone = "Hellfire Citadel",
        bosses = {
            {
                name = "The Maker",
                loot = {
                    { itemID = 24384, quality = 3, name = "Diamond-Core Sledgemace", icon = 133046, stats = {"+23 Stamina", "+21 Strength", "Equip: Improves critical strike rating by 12."} },
                    { itemID = 24385, quality = 3, name = "Pendant of Battle-Lust", icon = 133319, stats = {"+18 Stamina", "Equip: Improves hit rating by 9.", "Equip: Improves attack power by 34."} },
                    { itemID = 24381, quality = 3, name = "Spaulders of the Unseen", icon = 135059, stats = {"+21 Stamina", "+13 Agility", "Equip: Improves defense rating by 14."} },
                },
            },
            {
                name = "Broggok",
                loot = {
                    { itemID = 24388, quality = 3, name = "Girdle of the Gale Storm", icon = 132493, stats = {"+19 Stamina", "+16 Intellect", "Equip: Increases spell damage and healing by up to 21."} },
                    { itemID = 24387, quality = 3, name = "Ironblade Gauntlets", icon = 132961, stats = {"+21 Stamina", "+18 Strength", "Equip: Improves your resilience rating by 12."} },
                    { itemID = 24389, quality = 3, name = "Legion Blunderbuss", icon = 135615, stats = {"67 - 126 Damage", "Speed 2.90", "Equip: Improves critical strike rating by 11."} },
                },
            },
            {
                name = "Keli'dan the Breaker",
                loot = {
                    { itemID = 24392, quality = 3, name = "Arcing Bracers", icon = 132611, stats = {"+15 Stamina", "+14 Intellect", "Equip: Increases spell damage and healing by up to 24."} },
                    { itemID = 24393, quality = 3, name = "Bloody Surgeon's Mitts", icon = 132968, stats = {"+18 Stamina", "+17 Intellect", "Equip: Improves spell critical strike rating by 13."} },
                    { itemID = 24390, quality = 3, name = "Auslese's Light Channeler", icon = 135147, stats = {"42 - 115 Damage", "Speed 1.80", "Equip: Restores 6 mana per 5 sec."} },
                },
            },
        },
    },
}

local function GetQualityColor(quality)
    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    if color then
        return color.r, color.g, color.b
    end

    if quality == 3 then return 0.0, 0.44, 0.87 end
    if quality == 4 then return 0.64, 0.21, 0.93 end
    if quality == 5 then return 1.0, 0.5, 0.0 end
    return 1.0, 1.0, 1.0
end

local function IsAllowedQuality(item)
    return (item.quality or 1) >= LootBrowser.MIN_QUALITY
end

local function BuildMainFrame()
    local frame = CreateFrame("Frame", "LootBrowserMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(760, 500)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Loot Browser |cff00ccffTBC Classic|r")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -6, -4)
    hint:SetText("Type " .. LootBrowser.SLASH_COMMAND .. " to toggle")

    local leftPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", 12, -42)
    leftPanel:SetPoint("BOTTOMLEFT", 12, 12)
    leftPanel:SetWidth(220)
    leftPanel:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8x8",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    leftPanel:SetBackdropColor(0.09, 0.09, 0.11, 0.9)

    local dungeonHeader = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonHeader:SetPoint("TOPLEFT", 10, -10)
    dungeonHeader:SetText("Dungeons / Raids")

    local rightPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 10, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", -12, 12)
    rightPanel:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8x8",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    rightPanel:SetBackdropColor(0.09, 0.09, 0.11, 0.9)

    local contentTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    contentTitle:SetPoint("TOPLEFT", 12, -10)
    contentTitle:SetText("Select a dungeon")

    local qualityHint = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qualityHint:SetPoint("TOPRIGHT", -12, -12)
    qualityHint:SetText("Showing: Rare (blue)+")

    local scrollFrame = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -34)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(480, 1)
    scrollFrame:SetScrollChild(scrollChild)

    frame.leftPanel = leftPanel
    frame.rightPanel = rightPanel
    frame.contentTitle = contentTitle
    frame.scrollChild = scrollChild

    LootBrowser.frame = frame
end

local EQUIP_LOC_TO_SLOT = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_ROBE = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = 15,
    INVTYPE_WEAPON = 16,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_SHIELD = 17,
    INVTYPE_RANGED = 18,
    INVTYPE_RANGEDRIGHT = 18,
    INVTYPE_RELIC = 18,
}

local STAT_KEYS = {
    { key = "ITEM_MOD_STRENGTH_SHORT", label = "Strength" },
    { key = "ITEM_MOD_AGILITY_SHORT", label = "Agility" },
    { key = "ITEM_MOD_STAMINA_SHORT", label = "Stamina" },
    { key = "ITEM_MOD_INTELLECT_SHORT", label = "Intellect" },
    { key = "ITEM_MOD_SPIRIT_SHORT", label = "Spirit" },
    { key = "RESISTANCE0_NAME", label = "Armor" },
    { key = "ITEM_MOD_HEALTH_SHORT", label = "Health" },
    { key = "ITEM_MOD_MANA_SHORT", label = "Mana" },
    { key = "ITEM_MOD_ATTACK_POWER_SHORT", label = "Attack Power" },
    { key = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", label = "Ranged Attack Power" },
    { key = "ITEM_MOD_SPELL_POWER_SHORT", label = "Spell Power" },
    { key = "ITEM_MOD_HEALING_DONE_SHORT", label = "Healing" },
    { key = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", label = "Damage Per Second" },
    { key = "ITEM_MOD_EXPERTISE_RATING_SHORT", label = "Expertise" },
    { key = "ITEM_MOD_CRIT_RATING_SHORT", label = "Crit Rating" },
    { key = "ITEM_MOD_SPELL_CRIT_RATING_SHORT", label = "Spell Crit Rating" },
    { key = "ITEM_MOD_HASTE_RATING_SHORT", label = "Haste Rating" },
    { key = "ITEM_MOD_HIT_RATING_SHORT", label = "Hit Rating" },
    { key = "ITEM_MOD_SPELL_HIT_RATING_SHORT", label = "Spell Hit Rating" },
    { key = "ITEM_MOD_BLOCK_RATING_SHORT", label = "Block Rating" },
    { key = "ITEM_MOD_DODGE_RATING_SHORT", label = "Dodge Rating" },
    { key = "ITEM_MOD_PARRY_RATING_SHORT", label = "Parry Rating" },
    { key = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", label = "Defense Rating" },
    { key = "ITEM_MOD_RESILIENCE_RATING_SHORT", label = "Resilience" },
}

local function FormatStatDiff(diff)
    if math.floor(diff) ~= diff then
        return string.format("%.1f", diff)
    end

    return tostring(diff)
end

local function ChooseComparisonSlot(itemLink)
    local equipLoc = select(9, GetItemInfo(itemLink or ""))
    local slotInfo = EQUIP_LOC_TO_SLOT[equipLoc]
    if not slotInfo then return nil end

    if type(slotInfo) == "table" then
        local leftSlot, rightSlot = slotInfo[1], slotInfo[2]
        local leftLink = GetInventoryItemLink("player", leftSlot)
        local rightLink = GetInventoryItemLink("player", rightSlot)

        if leftLink and not rightLink then return leftSlot end
        if rightLink and not leftLink then return rightSlot end
        return leftSlot
    end

    return slotInfo
end

local function AddComparisonLines(itemLink)
    local slotID = ChooseComparisonSlot(itemLink)
    if not slotID then
        GameTooltip:AddLine("No equipment slot comparison for this item.", 0.7, 0.7, 0.7)
        return
    end

    local equippedLink = GetInventoryItemLink("player", slotID)
    if not equippedLink then
        GameTooltip:AddLine("Compared slot is currently empty.", 0.6, 1.0, 0.6)
        return
    end

    local newStats = GetItemStats(itemLink) or {}
    local equippedStats = GetItemStats(equippedLink) or {}
    local shownAny = false

    for _, stat in ipairs(STAT_KEYS) do
        local diff = (newStats[stat.key] or 0) - (equippedStats[stat.key] or 0)
        if diff ~= 0 then
            shownAny = true
            local value = FormatStatDiff(diff)
            if diff > 0 then
                GameTooltip:AddLine("+" .. value .. " " .. stat.label, 0.3, 1.0, 0.3)
            else
                GameTooltip:AddLine(value .. " " .. stat.label, 1.0, 0.35, 0.35)
            end
        end
    end

    if not shownAny then
        GameTooltip:AddLine("No primary stat change vs equipped item.", 0.75, 0.75, 0.75)
    end
end

local function BuildMinimapButton()
    if LootBrowser.minimapButton then return end

    local button = CreateFrame("Button", "LootBrowserMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -4, 4)
    button:RegisterForClicks("LeftButtonUp")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface/Minimap/UI-Minimap-Background")
    background:SetSize(52, 52)
    background:SetPoint("TOPLEFT")
    background:SetVertexColor(0, 0, 0, 0.75)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface/Buttons/UI-GuildButton-PublicNote-Up")

    button:SetScript("OnClick", function()
        ToggleMainFrame()
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Loot Browser", 1, 1, 1)
        GameTooltip:AddLine("Click to open", 0.8, 0.95, 0.8)
        GameTooltip:AddLine("Command: " .. LootBrowser.SLASH_COMMAND, 0.8, 0.95, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    LootBrowser.minimapButton = button
end

local function ShowItemTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local itemLink

    if self.itemData and self.itemData.itemID then
        itemLink = "item:" .. self.itemData.itemID
        GameTooltip:SetHyperlink(itemLink)
    else
        GameTooltip:AddLine(self.itemData and self.itemData.name or "Unknown Item", 1, 1, 1)
    end

    if itemLink then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Compared to your equipped item", 0.0, 0.85, 1.0)
        AddComparisonLines(itemLink)
    end

    if self.itemData and self.itemData.stats and #self.itemData.stats > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Loot Table Notes", 0.5, 0.8, 1.0)
        for _, statLine in ipairs(self.itemData.stats) do
            GameTooltip:AddLine(statLine, 0.8, 0.95, 0.8)
        end
    end

    GameTooltip:Show()
end

local function HideItemTooltip()
    GameTooltip:Hide()
end

local function RenderDungeon(dungeon)
    local frame = LootBrowser.frame
    if not frame then return end

    local parent = frame.scrollChild
    if parent.rows then
        for _, row in ipairs(parent.rows) do
            row:Hide()
            row:SetParent(nil)
        end
    end
    parent.rows = {}

    frame.contentTitle:SetText(dungeon.name .. "  -  " .. dungeon.zone)

    local y = -4
    for _, boss in ipairs(dungeon.bosses) do
        local bossHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        bossHeader:SetPoint("TOPLEFT", 8, y)
        bossHeader:SetText(boss.name)
        table.insert(parent.rows, bossHeader)
        y = y - 26

        local shownCount = 0
        for _, item in ipairs(boss.loot) do
            if IsAllowedQuality(item) then
                local row = CreateFrame("Button", nil, parent)
                row:SetSize(430, 24)
                row:SetPoint("TOPLEFT", 10, y)
                row.itemData = item
                row:SetScript("OnEnter", ShowItemTooltip)
                row:SetScript("OnLeave", HideItemTooltip)

                local highlight = row:CreateTexture(nil, "BACKGROUND")
                highlight:SetAllPoints(row)
                highlight:SetColorTexture(1, 1, 1, 0.03)

                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(18, 18)
                icon:SetPoint("LEFT", 2, 0)
                icon:SetTexture(item.icon or 134400)
                row.icon = icon

                local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
                local r, g, b = GetQualityColor(item.quality)
                name:SetText(item.name)
                name:SetTextColor(r, g, b)
                name:SetJustifyH("LEFT")
                row.name = name

                table.insert(parent.rows, row)
                y = y - 26
                shownCount = shownCount + 1
            end
        end

        if shownCount == 0 then
            local noLoot = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            noLoot:SetPoint("TOPLEFT", 12, y)
            noLoot:SetText("No Rare+ boss drops configured.")
            table.insert(parent.rows, noLoot)
            y = y - 24
        end

        y = y - 8
    end

    parent:SetHeight(-y + 20)
end

local function BuildDungeonButtons()
    local frame = LootBrowser.frame
    if not frame then return end

    local buttons = {}
    local y = -34

    for _, dungeon in ipairs(LootBrowser.dungeons) do
        local button = CreateFrame("Button", nil, frame.leftPanel, "UIPanelButtonTemplate")
        button:SetSize(196, 30)
        button:SetPoint("TOPLEFT", 10, y)
        button:SetText(dungeon.name)
        button:SetScript("OnClick", function()
            RenderDungeon(dungeon)
        end)

        table.insert(buttons, button)
        y = y - 36
    end

    frame.dungeonButtons = buttons

    if LootBrowser.dungeons[1] then
        RenderDungeon(LootBrowser.dungeons[1])
    end
end

ToggleMainFrame = function()
    if not LootBrowser.frame then
        BuildMainFrame()
        BuildDungeonButtons()
    end

    if LootBrowser.frame:IsShown() then
        LootBrowser.frame:Hide()
    else
        LootBrowser.frame:Show()
    end
end

SLASH_LOOTBROWSER1 = LootBrowser.SLASH_COMMAND
SlashCmdList.LOOTBROWSER = ToggleMainFrame

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    BuildMinimapButton()
    -- Main frame is still initialized lazily on first slash command or minimap click.
end)
