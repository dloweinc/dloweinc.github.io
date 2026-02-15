local ADDON_NAME = ...

local LootBrowser = {}
LootBrowser.MIN_QUALITY = 3 -- 3=Rare (blue), 4=Epic, 5=Legendary

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
    hint:SetText("Type /loot to toggle")

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

local function ShowItemTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    if self.itemData and self.itemData.itemID then
        GameTooltip:SetHyperlink("item:" .. self.itemData.itemID)
    else
        GameTooltip:AddLine(self.itemData and self.itemData.name or "Unknown Item", 1, 1, 1)
    end

    if self.itemData and self.itemData.stats and #self.itemData.stats > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Preview Stats", 0.0, 0.85, 1.0)
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

local function ToggleMainFrame()
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

SLASH_LOOTBROWSER1 = "/loot"
SlashCmdList.LOOTBROWSER = ToggleMainFrame

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    -- Initialize frame lazily on first /loot use.
end)
