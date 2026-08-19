AntiInspector = AntiInspector or {}
local REA = AntiInspector
local L = REA.L

REA.VERSION = "2.0.5"
REA.INSPECT_TIMEOUT = 4.0
REA.INSPECT_DELAY = 1.0
REA.INSPECT_POLL_DELAY = 0.25
REA.INSPECT_TALENT_GRACE = 1.5

REA.Slots = {
    { id = 1,  key = "HEAD",      short = L.SLOTS.HEAD[1],      full = L.SLOTS.HEAD[2],      normallyEnchantable = true },
    { id = 3,  key = "SHOULDER",  short = L.SLOTS.SHOULDER[1],  full = L.SLOTS.SHOULDER[2],  normallyEnchantable = true },
    { id = 5,  key = "CHEST",     short = L.SLOTS.CHEST[1],     full = L.SLOTS.CHEST[2],     normallyEnchantable = true },
    { id = 6,  key = "WAIST",     short = L.SLOTS.WAIST[1],     full = L.SLOTS.WAIST[2] },
    { id = 7,  key = "LEGS",      short = L.SLOTS.LEGS[1],      full = L.SLOTS.LEGS[2],      normallyEnchantable = true },
    { id = 8,  key = "FEET",      short = L.SLOTS.FEET[1],      full = L.SLOTS.FEET[2],      normallyEnchantable = true },
    { id = 9,  key = "WRIST",     short = L.SLOTS.WRIST[1],     full = L.SLOTS.WRIST[2],     normallyEnchantable = true },
    { id = 10, key = "HANDS",     short = L.SLOTS.HANDS[1],     full = L.SLOTS.HANDS[2],     normallyEnchantable = true },
    { id = 15, key = "BACK",      short = L.SLOTS.BACK[1],      full = L.SLOTS.BACK[2],      normallyEnchantable = true },
    { id = 16, key = "MAINHAND",  short = L.SLOTS.MAINHAND[1],  full = L.SLOTS.MAINHAND[2],  normallyEnchantable = true },
    { id = 17, key = "OFFHAND",   short = L.SLOTS.OFFHAND[1],   full = L.SLOTS.OFFHAND[2],   conditionalEnchantable = true },
    { id = 18, key = "RANGED",    short = L.SLOTS.RANGED[1],    full = L.SLOTS.RANGED[2] },
}

-- The gem tab includes every equipment slot that can carry sockets in WotLK.
-- Shirt and tabard are intentionally excluded.
REA.GemSlots = {
    { id = 1,  key = "HEAD",      short = L.SLOTS.HEAD[1],      full = L.SLOTS.HEAD[2] },
    { id = 2,  key = "NECK",      short = L.SLOTS.NECK[1],      full = L.SLOTS.NECK[2] },
    { id = 3,  key = "SHOULDER",  short = L.SLOTS.SHOULDER[1],  full = L.SLOTS.SHOULDER[2] },
    { id = 5,  key = "CHEST",     short = L.SLOTS.CHEST[1],     full = L.SLOTS.CHEST[2] },
    { id = 6,  key = "WAIST",     short = L.SLOTS.WAIST[1],     full = L.SLOTS.WAIST[2] },
    { id = 7,  key = "LEGS",      short = L.SLOTS.LEGS[1],      full = L.SLOTS.LEGS[2] },
    { id = 8,  key = "FEET",      short = L.SLOTS.FEET[1],      full = L.SLOTS.FEET[2] },
    { id = 9,  key = "WRIST",     short = L.SLOTS.WRIST[1],     full = L.SLOTS.WRIST[2] },
    { id = 10, key = "HANDS",     short = L.SLOTS.HANDS[1],     full = L.SLOTS.HANDS[2] },
    { id = 11, key = "RING1",     short = L.SLOTS.RING1[1],     full = L.SLOTS.RING1[2] },
    { id = 12, key = "RING2",     short = L.SLOTS.RING2[1],     full = L.SLOTS.RING2[2] },
    { id = 13, key = "TRINKET1",  short = L.SLOTS.TRINKET1[1],  full = L.SLOTS.TRINKET1[2] },
    { id = 14, key = "TRINKET2",  short = L.SLOTS.TRINKET2[1],  full = L.SLOTS.TRINKET2[2] },
    { id = 16, key = "MAINHAND",  short = L.SLOTS.MAINHAND[1],  full = L.SLOTS.MAINHAND[2] },
    { id = 17, key = "OFFHAND",   short = L.SLOTS.OFFHAND[1],   full = L.SLOTS.OFFHAND[2] },
    { id = 18, key = "RANGED",    short = L.SLOTS.RANGED[1],    full = L.SLOTS.RANGED[2] },
}

-- Scan the union of both report layouts.  BACK is still required by the enchant
-- tab even though it is intentionally hidden from the gem report.
REA.ScanSlots = {}
REA.EnchantSlotByKey = {}
do
    local seen = {}
    local i
    for i = 1, #REA.GemSlots do
        local slot = REA.GemSlots[i]
        table.insert(REA.ScanSlots, slot)
        seen[slot.key] = true
    end
    for i = 1, #REA.Slots do
        local slot = REA.Slots[i]
        REA.EnchantSlotByKey[slot.key] = slot
        if not seen[slot.key] then
            table.insert(REA.ScanSlots, slot)
            seen[slot.key] = true
        end
    end
end

REA.ScanFrame = CreateFrame("Frame")
REA.ScanFrame:RegisterEvent("ADDON_LOADED")
REA.ScanFrame:RegisterEvent("INSPECT_TALENT_READY")
REA.ScanFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

local function Chat(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAntiInspector:|r " .. message)
end

local function CopyArray(source)
    local target = {}
    local i
    for i = 1, #source do
        target[i] = source[i]
    end
    return target
end

local function TooltipLines(tooltip, link)
    local lines = {}
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    local ok = pcall(tooltip.SetHyperlink, tooltip, link)
    if not ok then
        tooltip:Hide()
        return lines
    end

    local tooltipName = tooltip:GetName()
    local i
    for i = 1, tooltip:NumLines() do
        local fontString = _G[tooltipName .. "TextLeft" .. i]
        if fontString then
            local text = fontString:GetText()
            if text and text ~= "" then
                local r, g, b = fontString:GetTextColor()
                table.insert(lines, { text = text, r = r or 1, g = g or 1, b = b or 1 })
            end
        end
    end
    tooltip:Hide()
    return lines
end

local function RemoveEnchantFromLink(itemLink)
    local plainLink = string.gsub(itemLink, "(item:%-?%d+:)%-?%d+", function(prefix)
        return prefix .. "0"
    end, 1)
    return plainLink
end

local function FindLocalizedEnchantText(itemLink, enchantID)
    if not REA.ActualTooltip or not REA.PlainTooltip then
        return REA.EnchantFallbacks[enchantID]
    end

    local actualLines = TooltipLines(REA.ActualTooltip, itemLink)
    local plainLines = TooltipLines(REA.PlainTooltip, RemoveEnchantFromLink(itemLink))
    local plainCounts = {}
    local i
    for i = 1, #plainLines do
        local text = plainLines[i].text
        plainCounts[text] = (plainCounts[text] or 0) + 1
    end

    local extras = {}
    for i = 1, #actualLines do
        local line = actualLines[i]
        if plainCounts[line.text] and plainCounts[line.text] > 0 then
            plainCounts[line.text] = plainCounts[line.text] - 1
        else
            table.insert(extras, line)
        end
    end

    -- Permanent enchant lines are normally green in the 3.3.5 tooltip.
    for i = 1, #extras do
        local line = extras[i]
        if line.g > line.r + 0.12 and line.g > line.b + 0.12 then
            return line.text
        end
    end
    if #extras > 0 then
        return extras[1].text
    end
    return REA.EnchantFallbacks[enchantID]
end

local function ParseItemLink(itemLink)
    if not itemLink then
        return nil, nil, { 0, 0, 0, 0 }
    end
    local itemID, enchantID, gem1, gem2, gem3, gem4 = string.match(
        itemLink,
        "item:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)"
    )
    if not itemID then
        itemID, enchantID = string.match(itemLink, "item:(%-?%d+):(%-?%d+)")
    end
    return tonumber(itemID), tonumber(enchantID), {
        tonumber(gem1) or 0,
        tonumber(gem2) or 0,
        tonumber(gem3) or 0,
        tonumber(gem4) or 0,
    }
end

local function BaseItemLinkWithoutEnchantOrGems(itemLink)
    if not itemLink then
        return nil
    end
    return string.gsub(
        itemLink,
        "(item:%-?%d+):%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+",
        function(prefix)
            return prefix .. ":0:0:0:0:0"
        end,
        1
    )
end

local function GetBaseSocketCount(itemLink)
    if not GetItemStats or not itemLink then
        return 0
    end

    local stats = {}
    local ok, returned = pcall(GetItemStats, BaseItemLinkWithoutEnchantOrGems(itemLink), stats)
    if not ok then
        return 0
    end
    if type(returned) == "table" then
        stats = returned
    end

    local count = 0
    local key, value
    for key, value in pairs(stats) do
        if type(key) == "string" and string.find(key, "EMPTY_SOCKET_", 1, true) == 1 then
            count = count + (tonumber(value) or 0)
        end
    end
    return count
end

local function EnchantAddsSocket(enchantID)
    local effect = enchantID and REA.EnchantFallbacks[enchantID]
    return effect and string.find(effect, "Socket ", 1, true) == 1
end

local function FillGemData(item)
    item.gems = {}
    item.gemEnchantIDs = item.gemEnchantIDs or { 0, 0, 0, 0 }

    -- WotLK normally has three visible gem slots.  The fourth item-link field
    -- may carry the enchant that created a prismatic profession socket.
    local fourthFieldID = tonumber(item.gemEnchantIDs[4]) or 0
    if EnchantAddsSocket(fourthFieldID) then
        item.linkSocketEnchantID = fourthFieldID
    end

    local filledCount = 0
    local highestFilled = 0
    local effects = {}
    local index
    for index = 1, 4 do
        local gemEnchantID = tonumber(item.gemEnchantIDs[index]) or 0
        local isSocketMarker = index == 4 and item.linkSocketEnchantID ~= nil
        if gemEnchantID ~= 0 and not isSocketMarker then
            local gemName, gemLink
            if GetItemGem then
                local ok, nameResult, linkResult = pcall(GetItemGem, item.itemLink, index)
                if ok then
                    gemName = nameResult
                    gemLink = linkResult
                end
            end
            local effect = REA.EnchantFallbacks[gemEnchantID]
                or ("Unknown gem effect ID " .. tostring(gemEnchantID))
            local displayText = gemName
                or (REA.isRussian and string.format(L.UNKNOWN_GEM_EFFECT_FMT, tostring(gemEnchantID)))
                or effect
            item.gems[index] = {
                index = index,
                enchantID = gemEnchantID,
                name = gemName,
                itemLink = gemLink,
                effect = effect,
                displayText = displayText,
            }
            filledCount = filledCount + 1
            highestFilled = index
            table.insert(effects, displayText)
        end
    end

    local socketCount = GetBaseSocketCount(item.itemLink)
    if EnchantAddsSocket(item.enchantID) or item.linkSocketEnchantID then
        socketCount = socketCount + 1
    end
    socketCount = math.max(socketCount, highestFilled)

    item.gemSocketCount = socketCount
    item.gemFilledCount = filledCount
    item.gemEmptyCount = math.max(0, socketCount - filledCount)

    if socketCount <= 0 and filledCount <= 0 then
        item.gemDisplayText = "—"
        item.gemState = "none"
    elseif filledCount <= 0 then
        item.gemDisplayText = L.EMPTY .. " x" .. tostring(socketCount)
        item.gemState = "missing"
    elseif item.gemEmptyCount > 0 then
        item.gemDisplayText = table.concat(effects, "; ") .. "; " .. L.EMPTY .. " x" .. tostring(item.gemEmptyCount)
        item.gemState = "partial"
    else
        item.gemDisplayText = table.concat(effects, "; ")
        item.gemState = "socketed"
    end
end

local function IsConditionalSlotEnchantable(slot, equipLoc)
    if not slot then
        return false
    end
    if not slot.conditionalEnchantable then
        return slot.normallyEnchantable and true or false
    end
    return equipLoc == "INVTYPE_WEAPON"
        or equipLoc == "INVTYPE_2HWEAPON"
        or equipLoc == "INVTYPE_WEAPONOFFHAND"
        or equipLoc == "INVTYPE_SHIELD"
end

local function GetBuild(isInspect)
    local activeGroup = GetActiveTalentGroup(isInspect)
    local points = { 0, 0, 0 }
    local names = { "?", "?", "?" }
    local bestIndex = 1
    local bestPoints = -1
    local i

    for i = 1, 3 do
        local name, _, spent = GetTalentTabInfo(i, isInspect, false, activeGroup)
        names[i] = name or "?"
        points[i] = tonumber(spent) or 0
        if points[i] > bestPoints then
            bestPoints = points[i]
            bestIndex = i
        end
    end

    if bestPoints <= 0 then
        return L.NO_DATA, points, names, activeGroup
    end

    local build = string.format("%s %d/%d/%d", names[bestIndex], points[1], points[2], points[3])
    return build, points, names, activeGroup
end

function REA:ScanUnit(entry, isInspect, talentsReady)
    local build = L.NO_DATA
    local talentPoints = { 0, 0, 0 }
    local talentTrees = { "?", "?", "?" }
    local talentGroup = nil
    if not isInspect or talentsReady then
        build, talentPoints, talentTrees, talentGroup = GetBuild(isInspect)
    end
    local result = {
        schemaVersion = 2,
        raidIndex = entry.raidIndex,
        guid = entry.guid,
        name = entry.name,
        class = entry.class,
        classFile = entry.classFile,
        subgroup = entry.subgroup,
        build = build,
        talentPoints = talentPoints,
        talentTrees = talentTrees,
        talentGroup = talentGroup,
        status = "ok",
        statusText = L.READY,
        gear = {},
    }

    -- An empty Off hand is expected when Main Hand contains a two-handed
    -- weapon.  Remember this before iterating over the equipment slots so the
    -- Off hand cell is not reported as a missing item/enchant.
    local mainHandLink = GetInventoryItemLink(entry.unit, 16)
    local mainHandEquipLoc
    if mainHandLink then
        local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(mainHandLink)
        mainHandEquipLoc = equipLoc
    end
    local mainHandIsTwoHanded = mainHandEquipLoc == "INVTYPE_2HWEAPON"

    local foundItems = 0
    local i
    for i = 1, #self.ScanSlots do
        local slot = self.ScanSlots[i]
        local itemLink = GetInventoryItemLink(entry.unit, slot.id)
        local texture = GetInventoryItemTexture(entry.unit, slot.id)
        local item = {
            slotID = slot.id,
            slotKey = slot.key,
            itemLink = itemLink,
            hasTexture = texture and true or false,
        }

        if itemLink then
            foundItems = foundItems + 1
            item.itemID, item.enchantID, item.gemEnchantIDs = ParseItemLink(itemLink)
            item.name = GetItemInfo(itemLink)
            if not item.name then
                item.name = string.match(itemLink, "%[(.-)%]") or ("item:" .. tostring(item.itemID or "?"))
            end
            local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
            item.equipLoc = equipLoc
            item.enchantExpected = IsConditionalSlotEnchantable(self.EnchantSlotByKey[slot.key], equipLoc)

            if item.enchantID and item.enchantID ~= 0 then
                item.enchantText = FindLocalizedEnchantText(itemLink, item.enchantID)
                    or string.format(L.UNKNOWN_ENCHANT_FMT, tostring(item.enchantID))
                item.displayText = item.enchantText
                item.state = "enchanted"
            elseif item.enchantExpected then
                item.displayText = L.NO_ENCHANT
                item.state = "missing"
            else
                item.displayText = "—"
                item.state = "none"
            end
            FillGemData(item)
        elseif slot.key == "OFFHAND" and mainHandIsTwoHanded then
            item.displayText = "—"
            item.state = "none"
            item.gemDisplayText = "—"
            item.gemState = "none"
            item.unavailableReason = "twoHandedMainHand"
        elseif texture then
            item.displayText = L.NO_DATA
            item.state = "unknown"
            item.gemDisplayText = L.NO_DATA
            item.gemState = "unknown"
        else
            item.displayText = L.EMPTY
            item.state = "empty"
            item.gemDisplayText = L.EMPTY
            item.gemState = "empty"
        end
        result.gear[slot.key] = item
    end

    if isInspect and foundItems == 0 then
        result.status = "failed"
        result.statusText = L.NO_DATA
    elseif build == L.NO_DATA then
        result.status = "partial"
        result.statusText = L.NO_TALENTS
    end

    return result
end

function REA:MakeUnavailableResult(entry, status, statusText)
    local result = {
        schemaVersion = 2,
        raidIndex = entry.raidIndex,
        guid = entry.guid,
        name = entry.name,
        class = entry.class,
        classFile = entry.classFile,
        subgroup = entry.subgroup,
        build = "—",
        status = status,
        statusText = statusText,
        gear = {},
    }
    local i
    for i = 1, #self.ScanSlots do
        local slot = self.ScanSlots[i]
        result.gear[slot.key] = {
            slotID = slot.id,
            slotKey = slot.key,
            displayText = "—",
            state = "unavailable",
            gemDisplayText = "—",
            gemState = "unavailable",
        }
    end
    return result
end

function REA:SetAction(delay, methodName)
    self.actionAt = GetTime() + delay
    self.actionName = methodName
end

function REA:ClearAction()
    self.actionAt = nil
    self.actionName = nil
end

function REA:SaveResult(result)
    self.results[result.raidIndex] = result
    AntiInspectorDB.lastScan = {
        schemaVersion = 2,
        addonVersion = self.VERSION,
        at = time(),
        realm = GetRealmName(),
        groupType = self.groupType,
        results = self.results,
    }
    if self.RefreshUI then
        self:RefreshUI()
    end
end

function REA:ProcessNext()
    if not self.scanning then
        return
    end

    while self.queuePosition <= #self.queue do
        local entry = self.queue[self.queuePosition]
        self.queuePosition = self.queuePosition + 1
        self.processed = self.processed + 1

        if not UnitExists(entry.unit) or UnitGUID(entry.unit) ~= entry.guid then
            self:SaveResult(self:MakeUnavailableResult(entry, "changed", L.ROSTER_CHANGED))
        elseif entry.isPlayer or UnitIsUnit(entry.unit, "player") then
            self:SaveResult(self:ScanUnit(entry, false, true))
        elseif not UnitIsConnected(entry.unit) then
            self:SaveResult(self:MakeUnavailableResult(entry, "offline", L.OFFLINE))
        elseif not UnitIsVisible(entry.unit) then
            self:SaveResult(self:MakeUnavailableResult(entry, "far", L.TOO_FAR))
        elseif not CanInspect(entry.unit) then
            self:SaveResult(self:MakeUnavailableResult(entry, "far", L.CANNOT_INSPECT))
        else
            local inspectRange = CheckInteractDistance(entry.unit, 1)
            if inspectRange ~= 1 and inspectRange ~= true then
                self:SaveResult(self:MakeUnavailableResult(entry, "far", L.TOO_FAR))
            else
                self.current = entry
                self.inspectReady = false
                self.inspectStartedAt = GetTime()
                self.inspectDeadline = self.inspectStartedAt + self.INSPECT_TIMEOUT
                NotifyInspect(entry.unit)
                self:SetAction(self.INSPECT_POLL_DELAY, "PollCurrent")
                if self.UpdateProgress then
                    self:UpdateProgress()
                end
                return
            end
        end
    end

    self:FinishScan()
end

function REA:CurrentGearLinkCount()
    if not self.current then
        return 0
    end
    local count = 0
    local i
    for i = 1, #self.ScanSlots do
        if GetInventoryItemLink(self.current.unit, self.ScanSlots[i].id) then
            count = count + 1
        end
    end
    return count
end

function REA:PollCurrent()
    if not self.scanning or not self.current then
        return
    end

    local entry = self.current
    if not UnitExists(entry.unit) or UnitGUID(entry.unit) ~= entry.guid then
        self:SaveResult(self:MakeUnavailableResult(entry, "changed", L.ROSTER_CHANGED))
        self.current = nil
        self.inspectStartedAt = nil
        self.inspectDeadline = nil
        ClearInspectPlayer()
        self:SetAction(self.INSPECT_DELAY, "ProcessNext")
        return
    end

    local elapsed = GetTime() - (self.inspectStartedAt or GetTime())
    local gearLinkCount = self:CurrentGearLinkCount()
    if gearLinkCount > 0 and (self.inspectReady or elapsed >= self.INSPECT_TALENT_GRACE) then
        self:CollectCurrent()
        return
    end

    if self.inspectDeadline and GetTime() < self.inspectDeadline then
        self:SetAction(self.INSPECT_POLL_DELAY, "PollCurrent")
    end
end

function REA:CollectCurrent()
    if not self.scanning or not self.current then
        return
    end
    local entry = self.current
    if not UnitExists(entry.unit) or UnitGUID(entry.unit) ~= entry.guid then
        self:SaveResult(self:MakeUnavailableResult(entry, "changed", L.ROSTER_CHANGED))
    else
        self:SaveResult(self:ScanUnit(entry, true, self.inspectReady))
    end
    self.current = nil
    self.inspectStartedAt = nil
    self.inspectDeadline = nil
    ClearInspectPlayer()
    self:SetAction(self.INSPECT_DELAY, "ProcessNext")
end

function REA:TimeoutCurrent()
    if not self.current then
        return
    end
    local entry = self.current
    self:SaveResult(self:MakeUnavailableResult(entry, "timeout", L.NO_RESPONSE))
    self.current = nil
    self.inspectStartedAt = nil
    self.inspectDeadline = nil
    ClearInspectPlayer()
    self:SetAction(self.INSPECT_DELAY, "ProcessNext")
end

function REA:FinishScan()
    local retryName = self.singleRetryName
    self.scanning = false
    self.current = nil
    self.inspectStartedAt = nil
    self.inspectDeadline = nil
    self.singleRetryName = nil
    self:ClearAction()
    ClearInspectPlayer()
    AntiInspectorDB.lastScan = {
        schemaVersion = 2,
        addonVersion = self.VERSION,
        at = time(),
        realm = GetRealmName(),
        groupType = self.groupType,
        results = self.results,
    }
    if self.UpdateProgress then
        self:UpdateProgress()
    end
    if retryName then
        Chat(string.format(L.RETRY_FINISHED_FMT, retryName))
    else
        Chat(string.format(L.SCAN_FINISHED_FMT, #self.results))
    end
end

function REA:CancelScan(silent)
    if not self.scanning then
        return
    end
    self.scanning = false
    self.current = nil
    self.inspectStartedAt = nil
    self.inspectDeadline = nil
    self.singleRetryName = nil
    self:ClearAction()
    ClearInspectPlayer()
    if self.UpdateProgress then
        self:UpdateProgress()
    end
    if not silent then
        Chat(L.SCAN_STOPPED)
    end
end

function REA:GetGroupRoster()
    local roster = {}
    local raidCount = GetNumRaidMembers()
    if raidCount > 0 then
        local playerGUID = UnitGUID("player")
        local playerName = UnitName("player")
        local i
        for i = 1, raidCount do
            local unit = "raid" .. i
            local name, _, subgroup, _, class, classFile = GetRaidRosterInfo(i)
            if name then
                local rosterGUID = UnitGUID(unit)
                local isPlayer = UnitIsUnit(unit, "player")
                    or (playerGUID and rosterGUID == playerGUID)
                    or (playerName and name == playerName)
                local scanUnit = isPlayer and "player" or unit
                table.insert(roster, {
                    raidIndex = i,
                    rosterIndex = i,
                    unit = scanUnit,
                    guid = UnitGUID(scanUnit) or rosterGUID,
                    isPlayer = isPlayer and true or false,
                    name = name,
                    class = class or select(1, UnitClass(scanUnit)) or "?",
                    classFile = classFile or select(2, UnitClass(scanUnit)) or "UNKNOWN",
                    subgroup = subgroup,
                })
            end
        end
        return roster, "raid"
    end

    local partyCount = GetNumPartyMembers()
    if partyCount > 0 then
        local position
        for position = 1, partyCount + 1 do
            local unit = position == 1 and "player" or ("party" .. tostring(position - 1))
            if UnitExists(unit) then
                local name = UnitName(unit)
                local class, classFile = UnitClass(unit)
                if name then
                    table.insert(roster, {
                        raidIndex = position,
                        rosterIndex = position,
                        unit = unit,
                        guid = UnitGUID(unit),
                        isPlayer = position == 1,
                        name = name,
                        class = class or "?",
                        classFile = classFile or "UNKNOWN",
                        subgroup = 1,
                    })
                end
            end
        end
        return roster, "party"
    end

    return roster, nil
end

function REA:FindGroupEntryForResult(result)
    if not result then
        return nil
    end

    local roster, groupType = self:GetGroupRoster()
    local i
    for i = 1, #roster do
        local entry = roster[i]
        local samePlayer = (result.guid and entry.guid and result.guid == entry.guid)
            or (result.name and entry.name and result.name == entry.name)
        if samePlayer then
            entry.raidIndex = result.raidIndex or entry.raidIndex
            return entry, groupType
        end
    end
    return nil, groupType
end

function REA:RetryResult(result)
    if self.scanning then
        Chat(L.WAIT_CURRENT_SCAN)
        return
    end
    if not result then
        return
    end
    if GetNumRaidMembers() <= 0 and GetNumPartyMembers() <= 0 then
        Chat(L.RETRY_GROUP_ONLY)
        return
    end
    if UnitAffectingCombat("player") then
        Chat(L.RETRY_AFTER_COMBAT)
        return
    end

    local entry, groupType = self:FindGroupEntryForResult(result)
    if not entry then
        Chat(string.format(L.PLAYER_NOT_FOUND_FMT, tostring(result.name or "?")))
        return
    end

    if InspectFrame and InspectFrame:IsShown() then
        HideUIPanel(InspectFrame)
    end
    ClearInspectPlayer()
    self.queue = { entry }
    self.queuePosition = 1
    self.processed = 0
    self.scanning = true
    self.groupType = groupType
    self.singleRetryName = entry.name
    if self.ShowWindow then
        self:ShowWindow()
    end
    if self.RefreshUI then
        self:RefreshUI()
    end
    Chat(string.format(L.RETRY_STARTED_FMT, entry.name))
    self:SetAction(0.05, "ProcessNext")
end

function REA:StartScan()
    local groupRoster, groupType = self:GetGroupRoster()
    if not groupType or #groupRoster <= 0 then
        Chat(L.GROUP_ONLY)
        return
    end
    if UnitAffectingCombat("player") then
        Chat(L.START_AFTER_COMBAT)
        return
    end

    self:CancelScan(true)
    if InspectFrame and InspectFrame:IsShown() then
        HideUIPanel(InspectFrame)
    end
    ClearInspectPlayer()

    self.queue = groupRoster
    self.results = {}
    self.queuePosition = 1
    self.processed = 0
    self.scanning = true
    self.groupType = groupType
    self.singleRetryName = nil

    if self.ShowWindow then
        self:ShowWindow()
    end
    if self.RefreshUI then
        self:RefreshUI()
    end
    local groupLabel = groupType == "raid" and L.GROUP_RAID or L.GROUP_PARTY
    Chat(string.format(L.SCAN_STARTED_FMT, groupLabel, #self.queue))
    self:SetAction(0.05, "ProcessNext")
end

function REA:LoadSavedScan()
    if AntiInspectorDB and AntiInspectorDB.lastScan and AntiInspectorDB.lastScan.results then
        self.results = AntiInspectorDB.lastScan.results
        self.groupType = AntiInspectorDB.lastScan.groupType
    else
        self.results = {}
    end
end

function REA:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "AntiInspector" then
            return
        end
        AntiInspectorDB = AntiInspectorDB or RaidEnchantAuditDB or {}
        RaidEnchantAuditDB = nil
        self:LoadSavedScan()
        self.ActualTooltip = CreateFrame("GameTooltip", "AntiInspectorActualTooltip", UIParent, "GameTooltipTemplate")
        self.PlainTooltip = CreateFrame("GameTooltip", "AntiInspectorPlainTooltip", UIParent, "GameTooltipTemplate")
        if self.InitializeUI then
            self:InitializeUI()
        end
    elseif event == "INSPECT_TALENT_READY" then
        if self.scanning and self.current and not self.inspectReady then
            self.inspectReady = true
            self:SetAction(0.10, "PollCurrent")
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if self.scanning then
            self:CancelScan(true)
            Chat(L.COMBAT_INTERRUPTED)
        end
    end
end

function REA:OnUpdate()
    local now = GetTime()
    if self.scanning and self.current and self.inspectDeadline and now >= self.inspectDeadline then
        self:TimeoutCurrent()
        return
    end
    if self.actionAt and now >= self.actionAt then
        local methodName = self.actionName
        self:ClearAction()
        if methodName and self[methodName] then
            self[methodName](self)
        end
    end
end

function REA:HandleRuntimeError(errorText)
    self.scanning = false
    self.current = nil
    self.inspectStartedAt = nil
    self.inspectDeadline = nil
    self:ClearAction()
    pcall(ClearInspectPlayer)
    if self.UpdateProgress then
        pcall(self.UpdateProgress, self)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff3333" .. L.ERROR_PREFIX .. "|r " .. tostring(errorText))
end

REA.ScanFrame:SetScript("OnEvent", function(_, event, ...)
    local ok, errorText = pcall(REA.OnEvent, REA, event, ...)
    if not ok then
        REA:HandleRuntimeError(errorText)
    end
end)
REA.ScanFrame:SetScript("OnUpdate", function()
    local ok, errorText = pcall(REA.OnUpdate, REA)
    if not ok then
        REA:HandleRuntimeError(errorText)
    end
end)

SLASH_ANTIINSPECTOR1 = "/enchinsp"
SLASH_ANTIINSPECTOR2 = "/antiinspector"
SLASH_ANTIINSPECTOR3 = "/ai"
SLASH_ANTIINSPECTOR4 = "/rea"
SLASH_ANTIINSPECTOR5 = "/raidcheck"
SlashCmdList.ANTIINSPECTOR = function(message)
    message = string.lower(string.match(message or "", "^%s*(.-)%s*$") or "")
    if message == "" or message == "scan" or message == "старт" then
        REA:StartScan()
    elseif message == "show" or message == "показать" then
        REA:ShowWindow()
    elseif message == "stop" or message == "стоп" then
        REA:CancelScan(false)
    elseif message == "export" or message == "экспорт" then
        REA:ShowExport()
    elseif message == "clear" or message == "очистить" then
        if not REA.scanning then
            REA.results = {}
            AntiInspectorDB.lastScan = nil
            REA:RefreshUI()
            Chat(L.TABLE_CLEARED)
        end
    else
        Chat(L.COMMANDS)
    end
end
