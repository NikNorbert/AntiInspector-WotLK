local REA = AntiInspector
local L = REA.L

REA.GEAR_COLUMNS_PER_PAGE = 5
REA.ROW_HEIGHT = 36

-- Keep the path extensionless for maximum compatibility with the legacy 3.3.5a
-- texture loader.  The unique basename also prevents an older rejected texture
-- from being reused from the client's cache after an addon update.
local BACKGROUND_TEXTURE = "Interface\\AddOns\\AntiInspector\\Textures\\MoonkinBackground"
local BACKGROUND_TEXTURE_VISIBLE_HEIGHT = 281 / 512
local TABLE_FONT_MIN = 8
local TABLE_FONT_MAX = 11
local TABLE_FONT_DEFAULT = 9

local CELL_COLORS = {
    enchanted = { 0.25, 1.00, 0.35 },
    missing = { 1.00, 0.25, 0.20 },
    none = { 0.55, 0.55, 0.55 },
    empty = { 0.70, 0.35, 0.35 },
    unknown = { 1.00, 0.75, 0.20 },
    unavailable = { 0.45, 0.45, 0.45 },
}

local GEM_CELL_COLORS = {
    socketed = { 0.25, 1.00, 0.35 },
    partial = { 1.00, 0.72, 0.20 },
    missing = { 1.00, 0.25, 0.20 },
    none = { 0.55, 0.55, 0.55 },
    empty = { 0.70, 0.35, 0.35 },
    unknown = { 1.00, 0.75, 0.20 },
    unavailable = { 0.45, 0.45, 0.45 },
}

local GEM_QUALITY_HEX = {
    [0] = "9d9d9d",
    [1] = "ffffff",
    [2] = "40ff59",
    [3] = "4a8dff",
    [4] = "c966ff",
    [5] = "ff8000",
}

local GEM_LINK_QUALITY = {
    ["9d9d9d"] = 0,
    ["ffffff"] = 1,
    ["1eff00"] = 2,
    ["0070dd"] = 3,
    ["a335ee"] = 4,
    ["ff8000"] = 5,
}

local function ColoredText(text, hex)
    return "|cff" .. (hex or "ffffff") .. tostring(text or "") .. "|r"
end

local function GetGemQuality(gem)
    if not gem then
        return nil
    end
    local quality = tonumber(gem.quality)
    if quality then
        return quality
    end
    if gem.itemLink and GetItemInfo then
        quality = tonumber(select(3, GetItemInfo(gem.itemLink)))
        if quality then
            gem.quality = quality
            return quality
        end
    end
    local linkColor = gem.itemLink and string.match(gem.itemLink, "|cff(%x%x%x%x%x%x)")
    if linkColor then
        linkColor = string.lower(linkColor)
    end
    return linkColor and GEM_LINK_QUALITY[linkColor] or nil
end

local function ColoredGemText(text, gem)
    local quality = GetGemQuality(gem)
    return ColoredText(text, GEM_QUALITY_HEX[quality] or "ffffff")
end

local function MissingGemText(text)
    return ColoredText(text, "ff3b30")
end

local function LocalizedGemEffect(gem)
    if not gem then
        return nil
    end
    if gem.localizedEffect and gem.localizedEffect ~= "" then
        return gem.localizedEffect
    end
    if gem.itemLink and REA.GetLocalizedGemEffect then
        local localizedEffect = REA:GetLocalizedGemEffect(gem.itemLink)
        if localizedEffect and localizedEffect ~= "" then
            gem.localizedEffect = localizedEffect
            gem.displayText = localizedEffect
            return localizedEffect
        end
    end
    if gem.effect and gem.effect ~= "" then
        return gem.effect
    end
    return string.format(L.UNKNOWN_GEM_EFFECT_FMT, tostring(gem.enchantID or "?"))
end

local STATUS_COLORS = {
    ok = { 0.25, 1.00, 0.35 },
    partial = { 1.00, 0.75, 0.20 },
    far = { 0.65, 0.65, 0.65 },
    offline = { 0.55, 0.55, 0.55 },
    timeout = { 1.00, 0.35, 0.25 },
    failed = { 1.00, 0.35, 0.25 },
    changed = { 1.00, 0.60, 0.20 },
}

local LOCALIZED_STATUS_TEXT = {
    ok = L.READY,
    partial = L.NO_TALENTS,
    failed = L.NO_DATA,
    changed = L.ROSTER_CHANGED,
    offline = L.OFFLINE,
    far = L.TOO_FAR,
    timeout = L.NO_RESPONSE,
}

local function LocalizedStatus(result)
    return result and (LOCALIZED_STATUS_TEXT[result.status] or result.statusText) or L.NO_DATA
end

local function LocalizedGemDisplay(item)
    if not item then
        return "—"
    end
    if item.gemState == "unavailable" or item.gemState == "none" then
        return "—"
    end
    if item.gemState == "unknown" then
        return L.NO_DATA
    end
    if item.gemState == "empty" then
        return MissingGemText(L.EMPTY)
    end

    local values = {}
    local groups = {}
    local groupOrder = {}
    local index
    for index = 1, 4 do
        local gem = item.gems and item.gems[index]
        if gem then
            local displayText = LocalizedGemEffect(gem)
            local quality = GetGemQuality(gem) or -1
            local groupKey = tostring(quality) .. "\031" .. tostring(displayText)
            local group = groups[groupKey]
            if group then
                group.count = group.count + 1
            else
                group = { text = displayText, gem = gem, count = 1 }
                groups[groupKey] = group
                table.insert(groupOrder, group)
            end
        end
    end

    for index = 1, #groupOrder do
        local group = groupOrder[index]
        local suffix = group.count > 1 and (" x" .. tostring(group.count)) or ""
        table.insert(values, ColoredGemText(group.text .. suffix, group.gem))
    end

    local emptyCount = tonumber(item.gemEmptyCount) or 0
    if emptyCount > 0 then
        table.insert(values, MissingGemText(L.EMPTY .. " x" .. tostring(emptyCount)))
    end
    if #values <= 0 then
        local socketCount = tonumber(item.gemSocketCount) or 0
        if socketCount > 0 then
            return MissingGemText(L.EMPTY .. " x" .. tostring(socketCount))
        end
        return "—"
    end
    return table.concat(values, "\n")
end

local function MakeText(parent, font, justify)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    text:SetJustifyH(justify or "LEFT")
    text:SetJustifyV("MIDDLE")
    return text
end

local function MakeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetText(label)
    return button
end

local function SetCellText(cell, text, color)
    cell.text:SetText(text or "—")
    if color then
        cell.text:SetTextColor(color[1], color[2], color[3])
    else
        cell.text:SetTextColor(0.85, 0.85, 0.85)
    end
end

local function SetGearCellFont(cell, fontSize)
    if not cell or not cell.text then
        return
    end
    local fontPath = STANDARD_TEXT_FONT
    if not fontPath and GameFontHighlightSmall and GameFontHighlightSmall.GetFont then
        fontPath = select(1, GameFontHighlightSmall:GetFont())
    end
    if fontPath then
        cell.text:SetFont(fontPath, fontSize, "OUTLINE")
    end
    if cell.text.SetWordWrap then
        cell.text:SetWordWrap(true)
    end
end

function REA:ApplyGearCellFonts()
    local fontSize = self.tableFontSize or TABLE_FONT_DEFAULT
    local rowIndex, column
    for rowIndex = 1, #(self.Rows or {}) do
        local row = self.Rows[rowIndex]
        for column = 1, #(row.gearCells or {}) do
            SetGearCellFont(row.gearCells[column], fontSize)
        end
    end
end

function REA:GetVisibleSlots()
    if self.activeTab == "gems" then
        return self.GemSlots
    end
    return self.Slots
end

function REA:SetActiveTab(tabName)
    if tabName ~= "gems" then
        tabName = "enchants"
    end
    self.activeTab = tabName
    self.gearPage = 1

    if self.EnchantTabButton and self.GemTabButton then
        if tabName == "gems" then
            self.EnchantTabButton:Enable()
            self.GemTabButton:Disable()
        else
            self.EnchantTabButton:Disable()
            self.GemTabButton:Enable()
        end
    end

    if self.LegendText then
        if tabName == "gems" then
            self.LegendText:SetText(L.LEGEND_GEMS)
        else
            self.LegendText:SetText(L.LEGEND_ENCHANTS)
        end
    end

    self:ApplyGearCellFonts()

    if self.RefreshUI then
        self:RefreshUI()
    end
end

function REA:CreateRow(index)
    local row = CreateFrame("Frame", nil, self.TableChild)
    row:SetHeight(self.ROW_HEIGHT)
    row:SetPoint("TOPLEFT", self.TableChild, "TOPLEFT", 0, -((index - 1) * self.ROW_HEIGHT))
    row:SetPoint("RIGHT", self.TableChild, "RIGHT", 0, 0)

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints(row)
    if index % 2 == 0 then
        row.background:SetTexture(1, 1, 1, 0.035)
    else
        row.background:SetTexture(0, 0, 0, 0.10)
    end

    row.nameButton = CreateFrame("Button", nil, row)
    row.nameButton:SetWidth(116)
    row.nameButton:SetHeight(self.ROW_HEIGHT - 1)
    row.nameButton:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.nameButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.name = MakeText(row.nameButton)
    row.name:SetAllPoints(row.nameButton)
    row.nameButton:SetScript("OnClick", function(button)
        if button.resultData then
            REA:RetryResult(button.resultData)
        end
    end)
    row.nameButton:SetScript("OnEnter", function(button)
        if button.resultData then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(button.resultData.name or "?", 1, 0.82, 0)
            local statusText = LocalizedStatus(button.resultData)
            if button.resultData.status == "ok" then
                GameTooltip:AddLine(string.format(L.STATUS_FMT, statusText), 0.35, 1, 0.35)
            else
                GameTooltip:AddLine(string.format(L.STATUS_FMT, statusText), 1, 0.45, 0.25)
            end
            GameTooltip:AddLine(L.RETRY_TOOLTIP, 0.35, 1, 0.35, true)
            GameTooltip:Show()
        end
    end)
    row.nameButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    row.class = MakeText(row)
    row.class:SetPoint("LEFT", row, "LEFT", 126, 0)
    row.class:SetWidth(78)

    row.build = MakeText(row)
    row.build:SetPoint("LEFT", row, "LEFT", 210, 0)
    row.build:SetWidth(146)

    row.status = MakeText(row)
    row.status:SetPoint("LEFT", row, "LEFT", 362, 0)
    row.status:SetWidth(94)

    row.gearCells = {}
    local column
    for column = 1, self.GEAR_COLUMNS_PER_PAGE do
        local cell = CreateFrame("Button", nil, row)
        cell:SetWidth(116)
        cell:SetHeight(self.ROW_HEIGHT - 1)
        cell:SetPoint("LEFT", row, "LEFT", 462 + ((column - 1) * 120), 0)
        cell.text = MakeText(cell, "GameFontHighlightSmall", "CENTER")
        cell.text:SetAllPoints(cell)
        SetGearCellFont(cell, self.tableFontSize or TABLE_FONT_DEFAULT)
        cell:SetScript("OnEnter", function(button)
            if not button.itemData then
                return
            end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            if button.itemData.itemLink then
                GameTooltip:SetHyperlink(button.itemData.itemLink)
                GameTooltip:AddLine(" ")
            end
            if REA.activeTab == "gems" then
                local socketCount = tonumber(button.itemData.gemSocketCount) or 0
                local index
                for index = 1, 4 do
                    local gem = button.itemData.gems and button.itemData.gems[index]
                    if gem then
                        local gemLabel = gem.itemLink or gem.name or gem.displayText or gem.effect or L.UNKNOWN_GEM
                        GameTooltip:AddLine(string.format(L.GEM_FMT, index, gemLabel), 0.25, 1, 0.35, true)
                        local localizedEffect = LocalizedGemEffect(gem)
                        if localizedEffect and localizedEffect ~= gem.name then
                            GameTooltip:AddLine("  " .. localizedEffect, 0.70, 0.85, 1, true)
                        end
                    end
                end
                local emptyCount = tonumber(button.itemData.gemEmptyCount) or 0
                if emptyCount > 0 then
                    GameTooltip:AddLine(string.format(L.EMPTY_SOCKETS_FMT, emptyCount), 1, 0.25, 0.20)
                elseif socketCount <= 0 then
                    GameTooltip:AddLine(L.NO_SOCKETS, 0.60, 0.60, 0.60)
                end
            elseif button.itemData.enchantID and button.itemData.enchantID ~= 0 then
                local enchantText = button.itemData.enchantText
                    or string.format(L.UNKNOWN_ENCHANT_FMT, tostring(button.itemData.enchantID))
                GameTooltip:AddLine(string.format(L.ENCHANT_FMT, enchantText), 0.25, 1, 0.35)
                GameTooltip:AddLine("Enchant ID: " .. button.itemData.enchantID, 0.65, 0.85, 1)
            elseif button.itemData.enchantExpected then
                GameTooltip:AddLine(L.NO_PERMANENT_ENCHANT, 1, 0.25, 0.20)
            end
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row.gearCells[column] = cell
    end

    self.Rows[index] = row
    return row
end

function REA:UpdateHeaders()
    local slots = self:GetVisibleSlots()
    local column
    local firstSlot = ((self.gearPage - 1) * self.GEAR_COLUMNS_PER_PAGE) + 1
    for column = 1, self.GEAR_COLUMNS_PER_PAGE do
        local slot = slots[firstSlot + column - 1]
        local header = self.GearHeaders[column]
        if slot then
            header:SetText(slot.short)
            header.slotData = slot
            header:Show()
        else
            header.slotData = nil
            header:Hide()
        end
    end
    local totalPages = math.max(1, math.ceil(#slots / self.GEAR_COLUMNS_PER_PAGE))
    self.PageText:SetText(string.format(L.ITEMS_PAGE_FMT, self.gearPage, totalPages))
    if self.gearPage <= 1 then
        self.PrevButton:Disable()
    else
        self.PrevButton:Enable()
    end
    if self.gearPage >= totalPages then
        self.NextButton:Disable()
    else
        self.NextButton:Enable()
    end
end

function REA:RefreshUI()
    if not self.MainFrame then
        return
    end
    self.results = self.results or {}
    self.TableChild:SetHeight(math.max(1, #self.results * self.ROW_HEIGHT))

    local slots = self:GetVisibleSlots()
    local i
    for i = 1, #self.results do
        local result = self.results[i]
        local row = self.Rows[i] or self:CreateRow(i)
        row:Show()
        row.nameButton.resultData = result
        row.name:SetText(result.name or "?")
        row.nameButton:Enable()
        local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[result.classFile]
        if classColor then
            row.name:SetTextColor(classColor.r, classColor.g, classColor.b)
            row.class:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            row.name:SetTextColor(1, 1, 1)
            row.class:SetTextColor(0.85, 0.85, 0.85)
        end
        row.class:SetText(result.class or "?")
        row.build:SetText(result.build or "—")
        row.status:SetText(LocalizedStatus(result))
        local statusColor = STATUS_COLORS[result.status]
        if statusColor then
            row.status:SetTextColor(statusColor[1], statusColor[2], statusColor[3])
        else
            row.status:SetTextColor(0.85, 0.85, 0.85)
        end

        local firstSlot = ((self.gearPage - 1) * self.GEAR_COLUMNS_PER_PAGE) + 1
        local column
        for column = 1, self.GEAR_COLUMNS_PER_PAGE do
            local slot = slots[firstSlot + column - 1]
            local cell = row.gearCells[column]
            if slot then
                local item = result.gear and result.gear[slot.key]
                cell.itemData = item
                if item then
                    if self.activeTab == "gems" then
                        SetCellText(cell, LocalizedGemDisplay(item), GEM_CELL_COLORS[item.gemState or "unavailable"])
                    else
                        SetCellText(cell, item.displayText, CELL_COLORS[item.state])
                    end
                else
                    if self.activeTab == "gems" then
                        SetCellText(cell, "—", GEM_CELL_COLORS.unavailable)
                    else
                        SetCellText(cell, "—", CELL_COLORS.unavailable)
                    end
                end
                cell:Show()
            else
                cell.itemData = nil
                cell:Hide()
            end
        end
    end

    for i = #self.results + 1, #self.Rows do
        self.Rows[i]:Hide()
    end
    self:UpdateHeaders()
    self:UpdateProgress()
end

function REA:UpdateProgress()
    if not self.StatusText then
        return
    end
    if self.scanning then
        local total = self.queue and #self.queue or 0
        local currentName = self.current and self.current.name
        if currentName then
            self.StatusText:SetText(string.format(L.SCANNING_NAME_FMT, math.min(self.processed, total), total, currentName))
        else
            self.StatusText:SetText(string.format(L.SCANNING_FMT, math.min(self.processed, total), total))
        end
        self.ScanButton:SetText(L.RESTART)
        self.StopButton:Enable()
    else
        local savedAt = AntiInspectorDB and AntiInspectorDB.lastScan and AntiInspectorDB.lastScan.at
        if savedAt then
            self.StatusText:SetText(string.format(L.LAST_TABLE_FMT, date("%d.%m.%Y %H:%M", savedAt)))
        else
            self.StatusText:SetText(L.NEVER_SCANNED)
        end
        self.ScanButton:SetText(L.CHECK_GROUP)
        self.StopButton:Disable()
    end
end

local function QuoteTSV(value)
    value = tostring(value or "")
    value = string.gsub(value, "[\t\r\n]", " ")
    return value
end

local ENGLISH_CLASS_NAMES = {
    DEATHKNIGHT = "Death Knight",
    DRUID = "Druid",
    HUNTER = "Hunter",
    MAGE = "Mage",
    PALADIN = "Paladin",
    PRIEST = "Priest",
    ROGUE = "Rogue",
    SHAMAN = "Shaman",
    WARLOCK = "Warlock",
    WARRIOR = "Warrior",
}

local ENGLISH_TALENT_TREES = {
    DEATHKNIGHT = { "Blood", "Frost", "Unholy" },
    DRUID = { "Balance", "Feral Combat", "Restoration" },
    HUNTER = { "Beast Mastery", "Marksmanship", "Survival" },
    MAGE = { "Arcane", "Fire", "Frost" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    PRIEST = { "Discipline", "Holy", "Shadow" },
    ROGUE = { "Assassination", "Combat", "Subtlety" },
    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    WARRIOR = { "Arms", "Fury", "Protection" },
}

local ENGLISH_STATUS_TEXT = {
    ok = "Ready",
    partial = "No talents",
    failed = "No data",
    changed = "Roster changed",
    offline = "Offline",
    far = "Out of range",
    timeout = "No response",
}

local function EnglishBuild(result)
    local points = result and result.talentPoints
    if not points then
        return "N/A"
    end

    local point1 = tonumber(points[1]) or 0
    local point2 = tonumber(points[2]) or 0
    local point3 = tonumber(points[3]) or 0
    local values = { point1, point2, point3 }
    local bestIndex = 1
    local bestPoints = point1
    local i
    for i = 2, 3 do
        if values[i] > bestPoints then
            bestIndex = i
            bestPoints = values[i]
        end
    end
    if bestPoints <= 0 then
        return "No data"
    end

    local trees = ENGLISH_TALENT_TREES[result.classFile]
    local treeName = trees and trees[bestIndex] or "Unknown"
    return string.format("%s %d/%d/%d", treeName, point1, point2, point3)
end

local function EnglishEnchant(item)
    -- Only a successfully inspected, equipped item that is known to require an
    -- enchant is exported as NONE. Unknown/unavailable cells stay blank so a
    -- failed scan cannot be mistaken for a missing enchant.
    if item and item.state == "missing" then
        return "NONE"
    end
    local enchantID = item and tonumber(item.enchantID)
    if not enchantID or enchantID == 0 then
        return ""
    end
    return REA.EnchantFallbacks[enchantID] or ("Unknown enchant ID " .. tostring(enchantID))
end

local function EnglishGems(item)
    if not item then
        return ""
    end
    local values = {}
    local index
    for index = 1, 4 do
        local gem = item.gems and item.gems[index]
        local gemEnchantID = gem and tonumber(gem.enchantID)
            or (item.gemEnchantIDs and tonumber(item.gemEnchantIDs[index]))
        local isSocketMarker = index == 4 and item.linkSocketEnchantID ~= nil
        if gemEnchantID and gemEnchantID ~= 0 and not isSocketMarker then
            table.insert(values, REA.EnchantFallbacks[gemEnchantID]
                or ("Unknown gem effect ID " .. tostring(gemEnchantID)))
        end
    end
    local emptyCount = tonumber(item.gemEmptyCount) or 0
    if emptyCount == 1 then
        table.insert(values, "EMPTY SOCKET")
    elseif emptyCount > 1 then
        table.insert(values, "EMPTY SOCKET x" .. tostring(emptyCount))
    end
    return table.concat(values, "; ")
end

local function EnglishSocketCount(item)
    if not item or item.gemState == "unavailable" or item.gemState == "unknown" then
        return "No data"
    end
    if not item.itemLink then
        return "No item"
    end

    local socketCount = tonumber(item.gemSocketCount) or 0
    if socketCount <= 0 then
        return "No sockets"
    end
    return tostring(socketCount)
end

local function CharacterExportValues(result)
    return {
        QuoteTSV(result.name),
        QuoteTSV(ENGLISH_CLASS_NAMES[result.classFile] or result.classFile or "Unknown"),
        QuoteTSV(EnglishBuild(result)),
        QuoteTSV(ENGLISH_STATUS_TEXT[result.status] or "Unknown"),
    }
end

function REA:BuildEnchantExportText()
    local header = { "Name", "Class", "Build", "Status" }
    local i
    for i = 1, #self.Slots do
        local slot = self.Slots[i]
        table.insert(header, slot.key .. "_Enchant")
    end

    local lines = { table.concat(header, "\t") }
    local rowIndex
    for rowIndex = 1, #(self.results or {}) do
        local result = self.results[rowIndex]
        local values = CharacterExportValues(result)
        local gearWasScanned = result.status == "ok" or result.status == "partial"
        for i = 1, #self.Slots do
            local slot = self.Slots[i]
            local item
            if gearWasScanned and result.gear then
                item = result.gear[slot.key]
            end
            table.insert(values, QuoteTSV(EnglishEnchant(item)))
        end
        table.insert(lines, table.concat(values, "\t"))
    end
    return table.concat(lines, "\n")
end

function REA:BuildGemExportText()
    local header = { "Name", "Class", "Build", "Status" }
    local i
    for i = 1, #self.GemSlots do
        table.insert(header, self.GemSlots[i].key .. "_SocketCount")
        table.insert(header, self.GemSlots[i].key .. "_Gem")
    end

    local lines = { table.concat(header, "\t") }
    local rowIndex
    for rowIndex = 1, #(self.results or {}) do
        local result = self.results[rowIndex]
        local values = CharacterExportValues(result)
        for i = 1, #self.GemSlots do
            local slot = self.GemSlots[i]
            local item = result.gear and result.gear[slot.key]
            table.insert(values, QuoteTSV(EnglishSocketCount(item)))
            table.insert(values, QuoteTSV(EnglishGems(item)))
        end
        table.insert(lines, table.concat(values, "\t"))
    end
    return table.concat(lines, "\n")
end

function REA:BuildExportText()
    if self.activeTab == "gems" then
        return self:BuildGemExportText()
    end
    return self:BuildEnchantExportText()
end

function REA:ShowExport()
    if not self.ExportFrame then
        return
    end
    self.ExportEditBox:SetText(self:BuildExportText())
    if self.ExportTitle then
        if self.activeTab == "gems" then
            self.ExportTitle:SetText(L.EXPORT_GEMS_TITLE)
        else
            self.ExportTitle:SetText(L.EXPORT_ENCHANTS_TITLE)
        end
    end
    self.ExportFrame:Show()
    self.ExportEditBox:SetFocus()
    self.ExportEditBox:HighlightText()
end

function REA:ShowWindow()
    if self.MainFrame then
        self.MainFrame:Show()
        self:RefreshUI()
    end
end

function REA:SetBackgroundOpacity(percent, saveValue)
    percent = tonumber(percent) or 100
    percent = math.max(0, math.min(100, percent))
    percent = math.floor(percent + 0.5)

    if self.BackgroundTexture then
        self.BackgroundTexture:SetAlpha(percent / 100)
    end
    if self.BackgroundOpacityLabel then
        self.BackgroundOpacityLabel:SetText(string.format(L.BACKGROUND_OPACITY_FMT, percent))
    end
    if saveValue and AntiInspectorDB then
        AntiInspectorDB.backgroundOpacity = percent
    end
end

function REA:SetTableFontSize(fontSize, saveValue)
    fontSize = tonumber(fontSize) or TABLE_FONT_DEFAULT
    fontSize = math.max(TABLE_FONT_MIN, math.min(TABLE_FONT_MAX, fontSize))
    fontSize = math.floor(fontSize + 0.5)
    self.tableFontSize = fontSize

    if self.TableFontLabel then
        self.TableFontLabel:SetText(string.format(L.TABLE_FONT_FMT, fontSize))
    end
    if saveValue and AntiInspectorDB then
        AntiInspectorDB.tableFontSize = fontSize
    end
    self:ApplyGearCellFonts()
end

local MINIMAP_BUTTON_RADIUS = 80

local function PositionMinimapButton(button, angle)
    angle = tonumber(angle) or 225
    local radians = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(radians) * MINIMAP_BUTTON_RADIUS,
        math.sin(radians) * MINIMAP_BUTTON_RADIUS
    )
end

local function UpdateMinimapButtonFromCursor(button)
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not centerX or not centerY or not scale or scale == 0 then
        return
    end

    cursorX = cursorX / scale
    cursorY = cursorY / scale
    local angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
    AntiInspectorDB.minimapAngle = angle
    PositionMinimapButton(button, angle)
end

function REA:InitializeMinimapButton()
    if self.MinimapButton or not Minimap then
        return
    end

    local button = CreateFrame("Button", "AntiInspectorMinimapButton", Minimap)
    button:SetWidth(31)
    button:SetHeight(31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetWidth(20)
    background:SetHeight(20)
    background:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    button.background = background

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Enchant_EssenceCosmicGreater")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.border = border

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnClick", function()
        if REA.MainFrame and REA.MainFrame:IsShown() then
            REA.MainFrame:Hide()
        else
            REA:ShowWindow()
        end
    end)
    button:SetScript("OnDragStart", function(dragged)
        dragged.dragging = true
        GameTooltip:Hide()
        dragged:SetScript("OnUpdate", UpdateMinimapButtonFromCursor)
    end)
    button:SetScript("OnDragStop", function(dragged)
        dragged.dragging = nil
        dragged:SetScript("OnUpdate", nil)
        UpdateMinimapButtonFromCursor(dragged)
    end)
    button:SetScript("OnEnter", function(entered)
        GameTooltip:SetOwner(entered, "ANCHOR_LEFT")
        GameTooltip:SetText("AntiInspector", 1, 0.82, 0)
        GameTooltip:AddLine(L.MINIMAP_TOGGLE, 1, 1, 1)
        GameTooltip:AddLine(L.MINIMAP_DRAG, 0.65, 0.85, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.MinimapButton = button
    PositionMinimapButton(button, AntiInspectorDB.minimapAngle)
end

function REA:InitializeUI()
    if self.MainFrame then
        return
    end

    self.gearPage = 1
    self.activeTab = "enchants"
    self.Rows = {}
    self.GearHeaders = {}

    local frame = CreateFrame("Frame", "AntiInspectorFrame", UIParent)
    frame:SetWidth(1130)
    frame:SetHeight(620)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(window) window:StartMoving() end)
    frame:SetScript("OnDragStop", function(window) window:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()
    self.MainFrame = frame
    table.insert(UISpecialFrames, "AntiInspectorFrame")

    local windowBackground = frame:CreateTexture(nil, "BACKGROUND")
    windowBackground:SetTexture(BACKGROUND_TEXTURE)
    windowBackground:SetAllPoints(frame)
    windowBackground:SetTexCoord(0, 1, 0, BACKGROUND_TEXTURE_VISIBLE_HEIGHT)
    self.BackgroundTexture = windowBackground

    local title = MakeText(frame, "GameFontNormalLarge", "CENTER")
    title:SetPoint("TOP", frame, "TOP", 0, -17)
    title:SetText("AntiInspector " .. tostring(REA.VERSION or "?") .. " — WoW 3.3.5a")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    self.ScanButton = MakeButton(frame, L.CHECK_GROUP, 130, 24)
    self.ScanButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -47)
    self.ScanButton:SetScript("OnClick", function() REA:StartScan() end)

    self.StopButton = MakeButton(frame, L.STOP, 70, 24)
    self.StopButton:SetPoint("LEFT", self.ScanButton, "RIGHT", 5, 0)
    self.StopButton:SetScript("OnClick", function() REA:CancelScan(false) end)

    self.ExportButton = MakeButton(frame, L.EXPORT_TSV, 105, 24)
    self.ExportButton:SetPoint("LEFT", self.StopButton, "RIGHT", 5, 0)
    self.ExportButton:SetScript("OnClick", function() REA:ShowExport() end)

    self.StatusText = MakeText(frame)
    self.StatusText:SetPoint("LEFT", self.ExportButton, "RIGHT", 12, 0)
    self.StatusText:SetWidth(350)

    self.EnchantTabButton = MakeButton(frame, L.TAB_ENCHANTS, 75, 24)
    self.EnchantTabButton:SetPoint("LEFT", self.StatusText, "RIGHT", 8, 0)
    self.EnchantTabButton:SetScript("OnClick", function() REA:SetActiveTab("enchants") end)

    self.GemTabButton = MakeButton(frame, L.TAB_GEMS, 65, 24)
    self.GemTabButton:SetPoint("LEFT", self.EnchantTabButton, "RIGHT", 5, 0)
    self.GemTabButton:SetScript("OnClick", function() REA:SetActiveTab("gems") end)

    self.PrevButton = MakeButton(frame, "<", 30, 24)
    self.PrevButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -230, -47)
    self.PrevButton:SetScript("OnClick", function()
        REA.gearPage = math.max(1, REA.gearPage - 1)
        REA:RefreshUI()
    end)

    self.PageText = MakeText(frame, "GameFontNormalSmall", "CENTER")
    self.PageText:SetPoint("LEFT", self.PrevButton, "RIGHT", 4, 0)
    self.PageText:SetWidth(145)

    self.NextButton = MakeButton(frame, ">", 30, 24)
    self.NextButton:SetPoint("LEFT", self.PageText, "RIGHT", 4, 0)
    self.NextButton:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil(#REA:GetVisibleSlots() / REA.GEAR_COLUMNS_PER_PAGE))
        REA.gearPage = math.min(pages, REA.gearPage + 1)
        REA:RefreshUI()
    end)

    local headers = {
        { text = L.HEADER_NAME, x = 22, width = 116 },
        { text = L.HEADER_CLASS, x = 144, width = 78 },
        { text = L.HEADER_BUILD, x = 228, width = 146 },
        { text = L.HEADER_STATUS, x = 380, width = 94 },
    }
    local i
    for i = 1, #headers do
        local info = headers[i]
        local header = MakeText(frame, "GameFontNormalSmall", "LEFT")
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", info.x, -82)
        header:SetWidth(info.width)
        header:SetText(info.text)
    end

    for i = 1, self.GEAR_COLUMNS_PER_PAGE do
        local header = CreateFrame("Button", nil, frame)
        header:SetWidth(116)
        header:SetHeight(22)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 480 + ((i - 1) * 120), -76)
        header.text = MakeText(header, "GameFontNormalSmall", "CENTER")
        header.text:SetAllPoints(header)
        header.SetText = function(button, value) button.text:SetText(value) end
        header:SetScript("OnEnter", function(button)
            if button.slotData then
                GameTooltip:SetOwner(button, "ANCHOR_TOP")
                GameTooltip:SetText(button.slotData.full, 1, 0.82, 0)
                GameTooltip:Show()
            end
        end)
        header:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.GearHeaders[i] = header
    end

    local scroll = CreateFrame("ScrollFrame", "AntiInspectorScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -101)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 58)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(1065)
    child:SetHeight(1)
    scroll:SetScrollChild(child)
    self.TableScroll = scroll
    self.TableChild = child

    self.LegendText = MakeText(frame, "GameFontHighlightSmall")
    self.LegendText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 43)

    local hint = MakeText(frame, "GameFontDisableSmall", "RIGHT")
    hint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 43)
    hint:SetWidth(320)
    hint:SetText(L.RETRY_HINT)

    local fontSlider = CreateFrame("Slider", "AntiInspectorTableFontSlider", frame, "OptionsSliderTemplate")
    fontSlider:SetWidth(100)
    fontSlider:SetHeight(16)
    fontSlider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 154, 19)
    fontSlider:SetMinMaxValues(TABLE_FONT_MIN, TABLE_FONT_MAX)
    fontSlider:SetValueStep(1)
    local fontLowText = _G[fontSlider:GetName() .. "Low"]
    local fontHighText = _G[fontSlider:GetName() .. "High"]
    local fontNameText = _G[fontSlider:GetName() .. "Text"]
    if fontLowText then fontLowText:SetText("") end
    if fontHighText then fontHighText:SetText("") end
    if fontNameText then fontNameText:SetText("") end

    local fontLabel = MakeText(frame, "GameFontHighlightSmall", "RIGHT")
    fontLabel:SetPoint("RIGHT", fontSlider, "LEFT", -8, 0)
    fontLabel:SetWidth(125)
    self.TableFontLabel = fontLabel
    self.TableFontSlider = fontSlider

    fontSlider:SetScript("OnValueChanged", function(_, value)
        REA:SetTableFontSize(value, true)
    end)
    fontSlider:SetScript("OnEnter", function(slider)
        GameTooltip:SetOwner(slider, "ANCHOR_TOP")
        GameTooltip:SetText(string.format(L.TABLE_FONT_FMT, math.floor((slider:GetValue() or TABLE_FONT_DEFAULT) + 0.5)), 1, 0.82, 0)
        GameTooltip:AddLine(L.TABLE_FONT_TOOLTIP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    fontSlider:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local savedFontSize = AntiInspectorDB and tonumber(AntiInspectorDB.tableFontSize)
        or (AntiInspectorDB and tonumber(AntiInspectorDB.gemFontSize))
        or TABLE_FONT_DEFAULT
    savedFontSize = math.max(TABLE_FONT_MIN, math.min(TABLE_FONT_MAX, savedFontSize))
    fontSlider:SetValue(savedFontSize)
    self:SetTableFontSize(savedFontSize, false)

    local opacitySlider = CreateFrame("Slider", "AntiInspectorBackgroundOpacitySlider", frame, "OptionsSliderTemplate")
    opacitySlider:SetWidth(150)
    opacitySlider:SetHeight(16)
    opacitySlider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 19)
    opacitySlider:SetMinMaxValues(0, 100)
    opacitySlider:SetValueStep(5)
    local lowText = _G[opacitySlider:GetName() .. "Low"]
    local highText = _G[opacitySlider:GetName() .. "High"]
    local nameText = _G[opacitySlider:GetName() .. "Text"]
    if lowText then lowText:SetText("") end
    if highText then highText:SetText("") end
    if nameText then nameText:SetText("") end

    local opacityLabel = MakeText(frame, "GameFontHighlightSmall", "RIGHT")
    opacityLabel:SetPoint("RIGHT", opacitySlider, "LEFT", -8, 0)
    opacityLabel:SetWidth(115)
    self.BackgroundOpacityLabel = opacityLabel
    self.BackgroundOpacitySlider = opacitySlider

    opacitySlider:SetScript("OnValueChanged", function(_, value)
        REA:SetBackgroundOpacity(value, true)
    end)
    opacitySlider:SetScript("OnEnter", function(slider)
        GameTooltip:SetOwner(slider, "ANCHOR_TOP")
        GameTooltip:SetText(string.format(L.BACKGROUND_OPACITY_FMT, math.floor((slider:GetValue() or 0) + 0.5)), 1, 0.82, 0)
        GameTooltip:AddLine(L.BACKGROUND_OPACITY_TOOLTIP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    opacitySlider:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local savedOpacity = AntiInspectorDB and tonumber(AntiInspectorDB.backgroundOpacity) or 100
    savedOpacity = math.max(0, math.min(100, savedOpacity))
    opacitySlider:SetValue(savedOpacity)
    self:SetBackgroundOpacity(savedOpacity, false)

    local export = CreateFrame("Frame", "AntiInspectorExportFrame", UIParent)
    export:SetWidth(800)
    export:SetHeight(520)
    export:SetPoint("CENTER")
    export:SetFrameStrata("FULLSCREEN_DIALOG")
    export:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    export:Hide()
    table.insert(UISpecialFrames, "AntiInspectorExportFrame")
    self.ExportFrame = export

    local exportTitle = MakeText(export, "GameFontNormalLarge", "CENTER")
    exportTitle:SetPoint("TOP", export, "TOP", 0, -18)
    exportTitle:SetText(L.EXPORT_TITLE)
    self.ExportTitle = exportTitle
    local exportClose = CreateFrame("Button", nil, export, "UIPanelCloseButton")
    exportClose:SetPoint("TOPRIGHT", export, "TOPRIGHT", -4, -4)

    local exportScroll = CreateFrame("ScrollFrame", "AntiInspectorExportScrollFrame", export, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", export, "TOPLEFT", 22, -52)
    exportScroll:SetPoint("BOTTOMRIGHT", export, "BOTTOMRIGHT", -38, 22)
    local editBox = CreateFrame("EditBox", nil, exportScroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(735)
    editBox:SetHeight(440)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetScript("OnTextChanged", function(box)
        ScrollingEdit_OnTextChanged(box, exportScroll)
    end)
    editBox:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged)
    editBox:SetScript("OnUpdate", function(box, elapsed)
        ScrollingEdit_OnUpdate(box, elapsed, exportScroll)
    end)
    editBox:SetScript("OnEscapePressed", function(box)
        box:ClearFocus()
        export:Hide()
    end)
    exportScroll:SetScrollChild(editBox)
    self.ExportEditBox = editBox

    self:InitializeMinimapButton()
    self:SetActiveTab("enchants")
end
