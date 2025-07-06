local _, playerClass = UnitClass("player")
local L = AceLibrary("AceLocale-2.2"):new("HunterBiuBiu")-- 多语言
HunterBiuBiu = {}
HunterBiuBiu.L = L

local split_string = function(str, delim)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delim, from)
	while delim_from do
			table.insert(result, string.sub(str, from, delim_from-1))
			from = delim_to + 1
			delim_from, delim_to = string.find(str, delim, from)
	end
	table.insert(result, string.sub(str, from))
	return result
end

HbbContainerItemMap = {}
HbbSpellIdMap = {}
HbbSerpentMap = {}
function UseBagItem(name, onself)
	if not name or type(name) ~= 'string' then
		return
	end

	local names = { name }

	if string.find(name, ',') then
		names = split_string(name, ',')
	end

	for _, n in ipairs(names) do
		if HbbContainerItemMap[n] then
			local link = GetContainerItemLink(HbbContainerItemMap[n][1],HbbContainerItemMap[n][2])
			if link then
				local itemName = string.lower(gsub(link,"^.*%[(.*)%].*$","%1"))
				if itemName ~= n then
					HbbContainerItemMap[n] = nil
				end
			else
				HbbContainerItemMap[n] = nil
			end
		end
	end

	local needFindNames = {}
	for _, n in ipairs(names) do
		if not HbbContainerItemMap[n] then
			table.insert(needFindNames, n)
		end
	end

	for i = 0,NUM_BAG_FRAMES do
		for j = 1,MAX_CONTAINER_ITEMS do
			link = GetContainerItemLink(i,j);
			if ( link ) then
				local itemName = string.lower(gsub(link,"^.*%[(.*)%].*$","%1"))
				for _, n in ipairs(needFindNames) do
					if n and n == itemName then
						HbbContainerItemMap[n] = { i, j }
					end
				end
			end
		end
	end

	for _, n in ipairs(names) do
		if HbbContainerItemMap[n] then
			UseContainerItem(HbbContainerItemMap[n][1], HbbContainerItemMap[n][2], onself)
		end
	end
end

local assertNum = function(v, dv)
	return tonumber(v) or dv or 0
end

local localCastOnMouseOver = function(spellName, stopIfUnitNotExists)
	local exists = UnitExists("mouseover")
	if not exists and stopIfUnitNotExists then
		return false
	end
	if exists and not UnitIsUnit("target", "mouseover") then
		TargetUnit("mouseover")
		CastSpellByName(spellName)
		TargetLastTarget()
		return true
	end

	if UnitExists("target") then
		CastSpellByName(spellName)
		return true
	end

	return false
end

-- IFunctions ----------------------------------------------------------------------------
function CastKeep(spellName, unit, buff, autoChangeTarget)
	if not buffed then return end
	if not unit then
		unit = "target"
	end
	if buff == nil then
		buff = 1
	end
	if autoChangeTarget == nil then
		autoChangeTarget = 1
	end

	local unitName,currTargetName,targetUnit,targetChanged = UnitName(unit),UnitName("target")
	if currTargetName ~= nil then
		targetUnit = "target"
	end
	if unitName~= nil and unitName ~= currTargetName then
		targetUnit = unit
		targetChanged = true
	end

	if not targetUnit then
		-- 没有目标
		return
	end

	if buff == 1 then
		-- 是buff
		if UnitIsEnemy("player", targetUnit) then
			-- 目标不是友方，尝试选择目标的目标
			if autoChangeTarget == 0 then
				return
			end
			TargetUnit(targetUnit)
			if not UnitIsEnemy("player", "targettarget") and not UnitIsDeadOrGhost("targettarget") and not buffed(spellName, "targettarget") then
				-- 目标的目标是友方且活着
				TargetUnit("targettarget")
				CastSpellByName(spellName)
				TargetLastTarget()
				if targetChanged then
					TargetLastTarget()
				end
				return
			end
		else
			-- 目标是友方
			if not UnitIsDeadOrGhost(targetUnit) and not buffed(spellName, targetUnit) then
				-- 活着
				TargetUnit(targetUnit)
				CastSpellByName(spellName)
				if targetChanged then
					TargetLastTarget()
				end
			end
		end
	else
		-- 是debuff
		if not UnitIsEnemy("player", targetUnit) then
			-- 是友方，尝试协助
			if autoChangeTarget == 0 then
				return
			end
			TargetUnit(targetUnit)
			if UnitIsEnemy("player", "targettarget") and not UnitIsDead("targettarget") and not buffed(spellName, "targettarget") then
				TargetUnit("targettarget")
				CastSpellByName(spellName)
				TargetLastTarget()
				if targetChanged then
					TargetLastTarget()
				end
				return
			end
		else
			if not UnitIsDead(targetUnit) and not buffed(spellName, targetUnit) then
				-- 活着
				TargetUnit(targetUnit)
				CastSpellByName(spellName)
				if targetChanged then
					TargetLastTarget()
				end
			end
		end
	end
end

function CastKeepBuff(spellName, unit, autoChangeTarget)
	if autoChangeTarget == nil then
		autoChangeTarget = 1
	end
	CastKeep(spellName, unit, 1, autoChangeTarget)
end

function CastKeepDebuff(spellName, unit, autoChangeTarget)
	if autoChangeTarget == nil then
		autoChangeTarget = 1
	end
	CastKeep(spellName, unit, 0, autoChangeTarget)
end

-- 没超级宏不可用，都是返回false
local unitinbuff = function(unit, buffNames)
	for _,buffName in ipairs(buffNames) do
		if buffed and buffed(buffName, unit) then
			return true
		end
	end
	return false
end

local buffable = function(unitId)
	return UnitExists(unitId) and not UnitIsDeadOrGhost(unitId) and CheckInteractDistance(unitId,4)
	-- and not inbuff(unitId)
end

local isImp = function(unitId)
	-- 是恶魔，且有相位变换buff则判定为小鬼（不加buff）
	if UnitCreatureType(unitId) == L['Demon'] and unitinbuff(unitId, {L["Phase Shift"]}) then
		return 1
	end
end

-- function TargetIsImp()
-- 	return isImp("target")
-- end

function CastRaidBuff(spellName)
	-- 没有超级宏不能用
	if not buffed then return end
	if not spellName then return end

	local buffNames = { spellName };
	if spellName == '真言术：韧' or spellName == '坚韧祷言' then
		buffNames = { '真言术：韧', '坚韧祷言'}
	elseif spellName == '神圣之灵' or spellName == '精神祷言' then
		buffNames = { '神圣之灵', '精神祷言'}
	elseif spellName == '野性印记' or spellName == '野性赐福' then
		buffNames = { '野性印记', '野性赐福'}
	elseif spellName == '奥术智慧' or spellName == '奥术光辉' then
		buffNames = { '奥术智慧', '奥术光辉'}
	elseif spellName == '王者祝福' or spellName == '强效王者祝福' then
		buffNames = { '王者祝福', '强效王者祝福'}
	elseif spellName == '拯救祝福' or spellName == '强效拯救祝福' then
		buffNames = { '拯救祝福', '强效拯救祝福'}
	end

	local inbuff = function(unit)
		return unitinbuff(unit, buffNames)
	end

	-- 记录当前目标
	local currentTarget, i, unitId = UnitName("target"), 0

	local hasTarget = UnitName("target")

	local castbuff = function(unit)
		-- if UnitName(unit) ~= currentTarget then
		if not UnitIsUnit(unit, 'target') then
			TargetUnit(unit)
			CastSpellByName(spellName)
			-- 有目标才需要恢复最后目标
			if hasTarget then
				TargetLastTarget()
			end
		else
			CastSpellByName(spellName)
		end
	end

	-- 给自己补
	if not inbuff("player") then
		castbuff("player")
		return
	end
	-- 给宠物补
	if buffable("pet") and not inbuff("pet") then
		castbuff("pet")
		return
	end

	-- 队员/团员
	-- 优先加自己小队
	if GetNumPartyMembers() > 0 then
		-- 在小队中
		for i=1, GetNumPartyMembers() do
			unitId = 'party'..i
			if buffable(unitId) and not inbuff(unitId) then
				-- 小队成员存在、没死、在施法距离内
				castbuff(unitId)
				return
			end
		end
	end

	if (GetNumRaidMembers() > 0) then
		-- 在团队中
		for i=1, GetNumRaidMembers() do
			unitId = 'raid'..i
			if buffable(unitId) and not inbuff(unitId) then
				-- 小队成员存在、没死、在施法距离内
				castbuff(unitId)
				return
			end
		end
	end

	-- 队员/团员的宠物
	-- 优先加自己小队
	if GetNumPartyMembers() > 0 then
		-- 在小队中
		for i=1, GetNumPartyMembers() do
			unitId = 'partypet'..i
			if not isImp(unitId) and buffable(unitId) and not inbuff(unitId) then
				-- 不是小鬼、小队成员存在、没死、在施法距离内
				castbuff(unitId)
				return
			end
		end
	end

	if (GetNumRaidMembers() > 0) then
		-- 在团队中
		for i=1, GetNumRaidMembers() do
			unitId = 'raidpet'..i
			if buffable(unitId) and not inbuff(unitId) then
				-- 小队成员存在、没死、在施法距离内
				castbuff(unitId)
				return
			end
		end
	end
end

HbbCastMouseover = function(a, b)
	localCastOnMouseOver(a, b)
end

if playerClass ~= "HUNTER" then
	function HunterBiuBiu:CastOnMouseover(a,b)
		localCastOnMouseOver(a, b)
	end
	return
end

HunterBiuBiu = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "AceHook-2.1", "FuBarPlugin-2.0")
HunterBiuBiu:RegisterDB("hbbdb")

-- Localization Stuff ----------------------------------------------------------------------
-- HunterBiuBiu.L = AceLibrary("AceLocale-2.2"):new("HunterBiuBiu")
-- L = HunterBiuBiu.L
HunterBiuBiu.L = L
--------------------------------------------------------------------------------------------

-- FUBAR Stuff -----------------------------------------------------------------------------
HunterBiuBiu.name = "HunterBiuBiu"
HunterBiuBiu.hasNoColor = true
HunterBiuBiu.hasIcon = "Interface\\Icons\\Ability_Hunter_RunningShot"
HunterBiuBiu.defaultMinimapPosition = 170
HunterBiuBiu.cannotDetachTooltip = true
HunterBiuBiu.hideWithoutStandby = true

-- HunterBiuBiu local -----------------------------------------------------------------------
local SWING_TIME = 0.65
local scantip = CreateFrame("GameTooltip", "HunterBiuBiuScanTip", nil, "GameTooltipTemplate")
local lastcast, lastshot, lastAmmoCount, lastSpellName, lastTranqTime, lastTranqFailTime, lastAimTime, lastAmmoCountUpdated
local secondReadyStart, secondReadyEnd, yz, yztime, nextSwingStart, nextShotTime

local roundNum2 = function(n)
	return math.floor(n * 100 + 0.5) / 100
end
local floorNum = function(n, d)
	local p = math.pow(10, d)
	return math.floor(n * p) / p
end

local checkSpellCooldown = function(spellName)
	local _,_,offset,numSpells = GetSpellTabInfo(GetNumSpellTabs())
	local numAllSpell = offset + numSpells;
	local cd, gcd
	for i=1,numAllSpell do
		local name = GetSpellName(i,"BOOKTYPE_SPELL");
		if ( name == spellName ) then
			cd,gcd = GetSpellCooldown(i,"BOOKTYPE_SPELL")
			return cd == 0 and gcd == 0
		end
	end
end

local getSpellId = function(spellName)
	local _,_,offset,numSpells = GetSpellTabInfo(GetNumSpellTabs())
	local numAllSpell = offset + numSpells;
	for i=1,numAllSpell do
		local name = GetSpellName(numAllSpell - i + 1,"BOOKTYPE_SPELL");
		if ( name == spellName ) then
			return numAllSpell - i + 1
		end
	end
end

local checkGCDSpellId
local checkGCD = function(spellName)
	if not spellName then spellName = L["Serpent Sting"] end
	if not checkGCDSpellId or GetSpellName(checkGCDSpellId, "BOOKTYPE_SPELL") ~= spellName then
		local _,_,offset,numSpells = GetSpellTabInfo(GetNumSpellTabs())
		local numAllSpell = offset + numSpells
		for i=1,numAllSpell do
			local name = GetSpellName(i,"BOOKTYPE_SPELL")
			if ( name == spellName ) then
				checkGCDSpellId = i
				break
			end
		end
	end

	local _,gcd = GetSpellCooldown(checkGCDSpellId,"BOOKTYPE_SPELL")
	return gcd == 1.5
end

-- Hooks -----------------------------------------------------------------------------------
local HbbCastSpell = function (spellId, spellbookTabNum)
	-- local cdStart,cd = GetSpellCooldown(spellId, spellbookTabNum)
	local spellName, rank = GetSpellName(spellId, spellbookTabNum)
	_,_,rank = string.find(rank,"(%d+)")

	if HunterBiuBiu.ShotSpells[spellName] and checkGCD() and not HunterBiuBiu.castblock then
		lastSpellName = spellName
		HunterBiuBiu:StartCast(spellName, rank)
	end
end

local HbbCastSpellByName = function (spellName, onSelf)
	local _,_,rank = string.find(spellName,"(%d+)")
	local _, _, spellShortName = string.find(spellName, "^([^%(]+)")

	if HunterBiuBiu.ShotSpells[spellShortName] and checkGCD() and not HunterBiuBiu.castblock then
		lastSpellName = spellShortName
		HunterBiuBiu:StartCast(spellShortName, rank)
	end
end

local getActionText = function(slot)
	if type(slot) ~= 'number' or slot > 120 or slot < 1 then
		return nil
	end
	scantip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scantip:ClearLines()
	scantip:SetAction(slot)
	local spellName = HunterBiuBiuScanTipTextLeft1:GetText()
	scantip:Hide()
	return spellName
end
local getBuffText = function(unit, buffIndex, isDebuff)
	scantip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scantip:ClearLines()
	if isDebuff then
		scantip:SetUnitDebuff(unit, buffIndex)
	else
		scantip:SetUnitBuff(unit, buffIndex)
	end
	local name = HunterBiuBiuScanTipTextLeft1:GetText()
	scantip:Hide()
	return name
end
local HbbUseAction = function (slot, checkCursor, onSelf)
	if GetActionText(slot) or not IsCurrentAction(slot) then return end
	local spellName = getActionText(slot)

	if HunterBiuBiu.ShotSpells[spellName] and checkGCD() and not HunterBiuBiu.castblock then
		lastSpellName = spellName
		HunterBiuBiu:StartCast(spellName, nil)
	end
end

hooksecurefunc('CastSpell', HbbCastSpell)
hooksecurefunc('CastSpellByName', HbbCastSpellByName)
hooksecurefunc('UseAction', HbbUseAction)

local toNum = function(str)
	local v = tonumber(str)
	if not v then
		return nil
	end
	return math.floor(v)
end

local toActionSlot = function(str)
	local num = toNum(str)

	if num and num >= 1 and num < 173 then
		return math.floor(num)
	end
	return nil
end
HunterBiuBiu.toActionSlot = toActionSlot

local isAmmo = function(bagSlot, slot)
	local itemLink, ammos = GetContainerItemLink(bagSlot, slot), L["Ammos"]
	if not itemLink then
		return false
	end
	for _,v in ipairs(ammos) do
		if (string.find(itemLink, v)) then
			return true
		end
	end
	return false
end

local getAmmoCount = function()
	-- local ammoCount = 0
	-- for i = 0,4 do
	-- 	-- for j = 1,GetContainerNumSlots(i) do
	-- 	for j = 1,36 do
	-- 		if (isAmmo(i, j)) then
	-- 			local _, c = GetContainerItemInfo(i, j)
	-- 			ammoCount = ammoCount + c
	-- 		end
	-- 	end
	-- end

	-- return ammoCount

	-- 感谢kook的朋友醉夢溪提供的获取弹药数量方法
	local ammoCount = GetInventoryItemCount("player", 0)
	return ammoCount
end

local tryInitAmmoCount = function ()
	if not lastAmmoCountUpdated and (not lastAmmoCount or lastAmmoCount <= 1) then
		lastAmmoCount = getAmmoCount()
		if lastAmmoCount > 1 then
			lastAmmoCountUpdated = true
		end
	end
end

local getCastTime = function(casttime)
	for i = 1,32 do
		local b = UnitBuff("player",i)
		local d = UnitDebuff("player",i)
		if not b and not d then break end

		if b == "Interface\\Icons\\Ability_Warrior_InnerRage" then
			casttime = casttime/1.3
		end
		if b == "Interface\\Icons\\Ability_Hunter_RunningShot" then
			casttime = casttime/1.4
		end
		if b == "Interface\\Icons\\Racial_Troll_Berserk" then
			casttime = casttime/ (1 + HunterBiuBiu.berserkValue)
		end
		if b == "Interface\\Icons\\Inv_Trinket_Naxxramas04" then
			casttime = casttime/1.2
		end

		-- 醉夢溪测试语言诅咒不会延长射击施法
		-- 后续： 语言诅咒不会延长， 上古恐慌会的， 图标是同一个
		-- if d == "Interface\\Icons\\Spell_Shadow_CurseOfTounges" then
		-- 	casttime = casttime/0.5
		-- end
		if d == "Interface\\Icons\\Spell_Shadow_CurseOfTounges" then
			local text = getBuffText("player", i)
			if string.find(text or "", "上古恐慌") then
				casttime = casttime/0.5
			end
		end
	end

	return casttime
end

-- fastcast
local spellIds = {}
local startAutoshot = function(reset)
	if HunterBiuBiu.lockautoshot then
		return
	end
	local slot
	if spellIds['autoshot'] and getActionText(spellIds['autoshot']) == L["Auto Shot"] then
		slot = spellIds['autoshot']
	else
		for i = 1, 120 do
			if getActionText(i) == L["Auto Shot"] then
				slot = i
				spellIds['autoshot'] = i
				break
			end
		end
		if not slot then
			HunterBiuBiu:SystemMessage(L["Auto Shot Not In Action"])
		end
	end
	if slot and (not IsAutoRepeatAction(slot) or reset) then
		UseAction(slot)
		if reset then
			HunterBiuBiu.lockautoshot = true
			local _,_, latency = GetNetStats()
			HunterBiuBiu:ScheduleEvent("RESTORE_AUTOSHOT", function() HunterBiuBiu.lockautoshot=nil end, (latency/1000)+0.1, HunterBiuBiu)
		end
	end
end

local getSpellCooldownCompleteTime = function(spellName)
	if not HbbSpellIdMap[spellName] or GetSpellName(HbbSpellIdMap[spellName], 'spell') ~= spellName then
		HbbSpellIdMap[spellName] = nil
		local spellId = getSpellId(spellName)
		if spellId then
			HbbSpellIdMap[spellName] = spellId
		end
	end

	if HbbSpellIdMap[spellName] then
		local a,b,c = GetSpellCooldown(HbbSpellIdMap[spellName], 'spell')

		if b == 1.5 then
			return 0
		end

		return a + b
	end
end

local isAutoshotActive = function()
	local slot
	if spellIds['autoshot'] and getActionText(spellIds['autoshot']) == L["Auto Shot"] then
		slot = spellIds['autoshot']
	else
		for i = 1, 120 do
			if getActionText(i) == L["Auto Shot"] then
				slot = i
				spellIds['autoshot'] = i
				break
			end
		end
		if not slot then
			HunterBiuBiu:SystemMessage(L["Auto Shot Not In Action"])
		end
	end
	return slot and IsAutoRepeatAction(slot)==1
end

local castSteadyshot = function()
	if checkGCD() then return end
	-- local spellId
	-- if spellIds['Steadyshot'] and GetSpellName(spellIds['Steadyshot'], "spell") == L["Steady Shot"] then
	-- 	spellId = spellIds['Steadyshot']
	-- else
	-- 	spellId = getSpellId(L["Steady Shot"])
	-- 	spellIds['Steadyshot'] = spellId
	-- end
	-- CastSpell(spellId, 'spell')
	CastSpellByName(L["Steady Shot"])
end

local castMultishot = function(p)
	if checkGCD() then return end
	-- local spellId
	-- if spellIds['multishot'] and GetSpellName(spellIds['multishot'], "spell") == L["Multi-Shot"] then
	-- 	spellId = spellIds['multishot']
	-- else
	-- 	spellId = getSpellId(L["Multi-Shot"])
	-- 	spellIds['multishot'] = spellId
	-- end
	-- CastSpell(spellId, 'spell')
	if p and (p == 0 or UnitMana("player") < p*500) then
		-- 英文为百度结果，可能不对
		CastSpellByName(L["Multi-Shot"].."("..L["Level"].." 1)")
		return
	end
	CastSpellByName(L["Multi-Shot"])
end

local castAimshot = function()
	if checkGCD() then return end
	-- local spellId
	-- if spellIds['aimshot'] and GetSpellName(spellIds['aimshot'], "spell") == L["Aimed Shot"] then
	-- 	spellId = spellIds['aimshot']
	-- else
	-- 	spellId = getSpellId(L["Aimed Shot"])
	-- 	spellIds['aimshot'] = spellId
	-- end
	-- CastSpell(spellId, 'spell')
	CastSpellByName(L["Aimed Shot"])
end

function HunterBiuBiu:OnClick()
	if HbbConfigFrame then
		if HbbConfigFrame:IsVisible() then
			HbbConfigFrame:Hide()
		else
			HbbConfigFrameShow()
		end
	end
end

--Upon Loading
function HunterBiuBiu:OnInitialize()
	DEFAULT_CHAT_FRAME:AddMessage("hbb loaded")
	self.cmdtable = {
		type = "group",
		args =
		{
			SteadyshotActionId = {
				type = "text",
				name = L["Steadyshot Action Id"],
				desc = L["Steadyshot Action Id"],
				usage = L["Steadyshot Action Id"],
				get = function() return HunterBiuBiu.db.profile.steadyshotActionId end,
				set = function(v) if toActionSlot(v) then HunterBiuBiu.db.profile.steadyshotActionId = toActionSlot(v); self.steadyshotActionId = toActionSlot(v); end end,
				order = 1,
			},
			multishotActionId = {
				type = "text",
				name = L["Multishot Action Id"],
				desc = L["Multishot Action Id"],
				usage = L["Multishot Action Id"],
				get = function() return HunterBiuBiu.db.profile.multishotActionId end,
				set = function(v) if toActionSlot(v) then HunterBiuBiu.db.profile.multishotActionId = toActionSlot(v); self.multishotActionId = toActionSlot(v); end end,
				order = 2,
			},
			autoshotActionId = {
				type = "text",
				name = L["Autoshot Action Id"],
				desc = L["Autoshot Action Id"],
				usage = L["Autoshot Action Id"],
				get = function() return HunterBiuBiu.db.profile.autoshotActionId end,
				set = function(v) if toActionSlot(v) then HunterBiuBiu.db.profile.autoshotActionId = toActionSlot(v); self.autoshotActionId = toActionSlot(v); end end,
				order = 3,
			},
			autoSetAction = {
				type = "execute",
				name = L["Auto Set Action"],
				desc = L["Auto Set Action"],
				func = function() self:autoSetAction() end,
				order = 4,
			},
			tv1 = {
				type = "range",
				name = L["ThresholdValue"].."1",
				desc = L["ThresholdValue"].."1",
				min = 2,
				max = 3,
				step = 0.1,
				get = function() return HunterBiuBiu.db.profile.tv1 end,
				set = function(v) HunterBiuBiu.db.profile.tv1 = v; self.tv1 = v; end,
				order = 14
			},
			tv2 = {
				type = "range",
				name = L["ThresholdValue"].."2",
				desc = L["ThresholdValue"].."2",
				min = 1.8,
				max = 2.2,
				step = 0.01,
				get = function() return HunterBiuBiu.db.profile.tv2 end,
				set = function(v) HunterBiuBiu.db.profile.tv2 = v; self.tv2 = v; end,
				order = 14
			},
			multishot = {
				type = "toggle",
				name = L["Multi-Shot"],
				desc = L["Multi-Shot"],
				get = function() return HunterBiuBiu.db.profile.multishot end,
				set = function () self:ToggleCastMultishot() end,
				order = 7,
			},
			aimedshot = {
				type = "toggle",
				name = L["Aimed Shot"],
				desc = L["Aimed Shot"],
				get = function() return HunterBiuBiu.db.profile.aimedshot end,
				set = function () self:ToggleCastAimedshot() end,
				order = 8,
			},
			howl = {
				type = "toggle",
				name = L["Howl"],
				desc = L["Howl"],
				get = function() return HunterBiuBiu.db.profile.howl end,
				set = function() local v = not HunterBiuBiu.db.profile.howl;HunterBiuBiu.db.profile.howl = v;self.castHowl = v; end,
				order = 9,
			},
			tranq = {
				type = "toggle",
				name = L["Tranq Alert"],
				desc = L["Tranq Alert"],
				get = function() return HunterBiuBiu.db.profile.tranq end,
				set = function() local v = not HunterBiuBiu.db.profile.tranq;HunterBiuBiu.db.profile.tranq = v; end,
				order = 10,
			},
			channel = {
				type = "group",
				name = L["Tranq Notification Channel"],
				desc = L["Tranq Notification Channel"],
				usage = L["Tranq Notification Channel"],
				order = 11,
				args = {
					SAY = {
						type = "toggle",
						name = L["CHAT_SAY"],
						desc = L["CHAT_SAY"],
						get = function() return HunterBiuBiu.db.profile.channels["SAY"] end,
						set = function() HunterBiuBiu.db.profile.channels["SAY"] = not HunterBiuBiu.db.profile.channels["SAY"] end
					},
					EMOTE = {
						type = "toggle",
						name = L["CHAT_EMOTE"],
						desc = L["CHAT_EMOTE"],
						get = function() return HunterBiuBiu.db.profile.channels["EMOTE"] end,
						set = function() HunterBiuBiu.db.profile.channels["EMOTE"] = not HunterBiuBiu.db.profile.channels["EMOTE"] end
					},
					YELL = {
						type = "toggle",
						name = L["CHAT_YELL"],
						desc = L["CHAT_YELL"],
						get = function() return HunterBiuBiu.db.profile.channels["YELL"] end,
						set = function() HunterBiuBiu.db.profile.channels["YELL"] = not HunterBiuBiu.db.profile.channels["YELL"] end
					},
					PARTY = {
						type = "toggle",
						name = L["CHAT_PARTY"],
						desc = L["CHAT_PARTY"],
						get = function() return HunterBiuBiu.db.profile.channels["PARTY"] end,
						set = function() HunterBiuBiu.db.profile.channels["PARTY"] = not HunterBiuBiu.db.profile.channels["PARTY"] end
					},
					RAID = {
						type = "toggle",
						name = L["CHAT_RAID"],
						desc = L["CHAT_RAID"],
						get = function() return HunterBiuBiu.db.profile.channels["RAID"] end,
						set = function() HunterBiuBiu.db.profile.channels["RAID"] = not HunterBiuBiu.db.profile.channels["RAID"] end
					},
				}
			},
			-- channel = {
			-- 	type = "text",
			-- 	name = L["Tranq Notification Channel"],
			-- 	desc = L["Tranq Notification Channel"],
			-- 	usage = L["Tranq Notification Channel"],
			-- 	get = function() return HunterBiuBiu.db.profile.channel end,
			-- 	set = function(v) HunterBiuBiu.db.profile.channel = v; end,
			-- 	order = 10,
			-- },
			beta = {
				type = "group",
				name = L["Beta Func"],
				desc = L["Beta Func"],
				usage = L["Beta Func"],
				order = 11,
				args = {
					priorauto = {
						type = "toggle",
						name = L["Prior Autoshot"],
						desc = L["Prior Autoshot"],
						get = function() return HunterBiuBiu.db.profile.priorauto end,
						set = function() HunterBiuBiu.db.profile.priorauto = not HunterBiuBiu.db.profile.priorauto end,
						order = 1
					},
					autoshotbar = {
						type = "toggle",
						name = L["AutoshotBar"],
						desc = L["AutoshotBar"],
						get = function() return HunterBiuBiu.db.profile.autoshotbar end,
						set = function() HunterBiuBiu.db.profile.autoshotbar = not HunterBiuBiu.db.profile.autoshotbar; self:UpdateAutoshotBarVisible() end,
						order = 2
					},
					autoshotbartemp = {
						type = "group",
						name = L["AutoshotBarTemp"],
						desc = L["AutoshotBarTemp"],
						usage = L["AutoshotBarTemp"],
						order = 3,
						args = {
							l2rr2l = {
								type = "toggle",
								name = L["AutoshotBarL2rr2l"],
								desc = L["AutoshotBarL2rr2l"],
								get = function() return HunterBiuBiu.db.profile.autoshotbartemp=='l2rr2l' end,
								set = function() HunterBiuBiu.db.profile.autoshotbartemp ='l2rr2l' end,
								order = 1
							},
							l2rl2r = {
								type = "toggle",
								name = L["AutoshotBarL2rl2r"],
								desc = L["AutoshotBarL2rl2r"],
								get = function() return HunterBiuBiu.db.profile.autoshotbartemp=='l2rl2r' end,
								set = function() HunterBiuBiu.db.profile.autoshotbartemp ='l2rl2r' end,
								order = 2
							},
							s2cc2s = {
								type = "toggle",
								name = L["AutoshotBarS2cc2s"],
								desc = L["AutoshotBarS2cc2s"],
								get = function() return HunterBiuBiu.db.profile.autoshotbartemp=='s2cc2s' end,
								set = function() HunterBiuBiu.db.profile.autoshotbartemp ='s2cc2s' end,
								order = 3
							},
						}
					},
					autoshotbarw = {
						type = "range",
						name = L["AutoshotBar Width"],
						desc = L["AutoshotBar Width"],
						min = 120,
						max = 360,
						step = 5,
						get = function() return HunterBiuBiu.db.profile.autoshotbarw end,
						set = function(v) HunterBiuBiu.db.profile.autoshotbarw = v; self:UpdateAutoshotBarW() end,
						order = 4
					},
					autoshotbarh = {
						type = "range",
						name = L["AutoshotBar Height"],
						desc = L["AutoshotBar Height"],
						min = 6,
						max = 60,
						step = 1,
						get = function() return HunterBiuBiu.db.profile.autoshotbarh end,
						set = function(v) HunterBiuBiu.db.profile.autoshotbarh = v; self:UpdateAutoshotBarH() end,
						order = 5
					},
					autoshotbarshowtext = {
						type = "toggle",
						name = L["AutoshotBarShowText"],
						desc = L["AutoshotBarShowText"],
						get = function() return HunterBiuBiu.db.profile.autoshotbartext end,
						set = function() HunterBiuBiu.db.profile.autoshotbartext = not HunterBiuBiu.db.profile.autoshotbartext; self:UpdateAutobarLockStatus() end,
						order = 6
					},
					autoshotbarshowtimer = {
						type = "toggle",
						name = L["AutoshotBarShowTimer"],
						desc = L["AutoshotBarShowTimer"],
						get = function() return HunterBiuBiu.db.profile.autoshotbartmr end,
						set = function() HunterBiuBiu.db.profile.autoshotbartmr = not HunterBiuBiu.db.profile.autoshotbartmr; self:UpdateAutobarLockStatus() end,
						order = 7
					},
					autoshotbarl = {
						type = "toggle",
						name = L["AutoshotBar Lock"],
						desc = L["AutoshotBar Lock"],
						get = function() return HunterBiuBiu.db.profile.autoshotbarl end,
						set = function() HunterBiuBiu.db.profile.autoshotbarl = not HunterBiuBiu.db.profile.autoshotbarl; self:UpdateAutobarLockStatus() end,
						order = 8
					},
					autoshotbarc1 = {
						type = 'color',
						name = L["AutoshotBar Color1"],
						desc = L["AutoshotBar Color1"],
						get = function() return HunterBiuBiu.db.profile.autoshotbarr1, HunterBiuBiu.db.profile.autoshotbarg1, HunterBiuBiu.db.profile.autoshotbarb1 end,
						set = function(r, g, b) HunterBiuBiu.db.profile.autoshotbarr1 = r; HunterBiuBiu.db.profile.autoshotbarg1 = g; HunterBiuBiu.db.profile.autoshotbarb1 = b; self:UpdateAutoshotBarColor() end,
						order = 9
					},
					autoshotbarc2 = {
						type = 'color',
						name = L["AutoshotBar Color2"],
						desc = L["AutoshotBar Color2"],
						get = function() return HunterBiuBiu.db.profile.autoshotbarr2, HunterBiuBiu.db.profile.autoshotbarg2, HunterBiuBiu.db.profile.autoshotbarb2 end,
						set = function(r, g, b) HunterBiuBiu.db.profile.autoshotbarr2 = r; HunterBiuBiu.db.profile.autoshotbarg2 = g; HunterBiuBiu.db.profile.autoshotbarb2 = b; self:UpdateAutoshotBarColor() end,
						order = 10
					},
					restoreauto = {
						type = "toggle",
						name = L["Restore Autoshot"],
						desc = L["Restore Autoshot"],
						get = function() return HunterBiuBiu.db.profile.restoreauto end,
						set = function() HunterBiuBiu.db.profile.restoreauto = not HunterBiuBiu.db.profile.restoreauto end,
						order = 12
					},
					resetautoshotbar = {
						type = "execute",
						name = L["Reset AutoshotBar"],
						desc = L["Reset AutoshotBar"],
						func = function() self:ResetAutoshotBar() end,
						order = 13
					},
					feigndeath = {
						type = "group",
						name = L["Feign Death"],
						desc = L["Feign Death"],
						usage = L["Feign Death"],
						args = {
							stat = {
								type = "toggle",
								name = L["On"],
								desc = L["On"],
								get = function() return HunterBiuBiu.db.profile.feigndeathon end,
								set = function() HunterBiuBiu.db.profile.feigndeathon = not HunterBiuBiu.db.profile.feigndeathon end,
								order = 1
							},
							alarm = {
								type = "toggle",
								name = L["Feign Death Alarm"],
								desc = L["Feign Death Alarm"],
								get = function() return HunterBiuBiu.db.profile.feigndeathalarm end,
								set = function() HunterBiuBiu.db.profile.feigndeathalarm = not HunterBiuBiu.db.profile.feigndeathalarm end,
								order = 2
							},
							delay = {
								type = "range",
								name = L["Feign Death Delay"],
								desc = L["Feign Death Delay"],
								min = 0.5,
								max = 5,
								step = 0.5,
								get = function() return HunterBiuBiu.db.profile.feigndeathdelay end,
								set = function(v) HunterBiuBiu.db.profile.feigndeathdelay = v end,
								order = 3
							},
							mask = {
								type = "toggle",
								name = L["Feign Death Mask"],
								desc = L["Feign Death Mask"],
								get = function() return HunterBiuBiu.db.profile.feigndeathmask end,
								set = function() HunterBiuBiu.db.profile.feigndeathmask = not HunterBiuBiu.db.profile.feigndeathmask end,
								order = 4
							},
							color = {
								type = 'color',
								name = L["Feign Death Color"],
								desc = L["Feign Death Color"],
								get = function() return HunterBiuBiu.db.profile.feigndeathr, HunterBiuBiu.db.profile.feigndeathg, HunterBiuBiu.db.profile.feigndeathb end,
								set = function(r, g, b) HunterBiuBiu.db.profile.feigndeathr = r; HunterBiuBiu.db.profile.feigndeathg = g; HunterBiuBiu.db.profile.feigndeathb = b; self:UpdateFeignDeathSetting() end,
								order = 5
							},
							alpha = {
								type = "range",
								min = 0,
								max = 1,
								step = 0.05,
								name = L["Feign Death Alpha"],
								desc = L["Feign Death Alpha"],
								get = function() return HunterBiuBiu.db.profile.feigndeatha end,
								set = function(v) HunterBiuBiu.db.profile.feigndeatha = v; self:UpdateFeignDeathSetting() end,
								order = 6
							},
							text = {
								type = "text",
								name = L["Feign Death Text"],
								desc = L["Feign Death Text"],
								usage = L["Feign Death Text"],
								get = function() return HunterBiuBiu.db.profile.feigndeathtext end,
								set = function(v) HunterBiuBiu.db.profile.feigndeathtext = v; self:UpdateFeignDeathSetting() end,
								order = 7
							},
							textsize = {
								type = "range",
								min = 12,
								max = 24,
								step = 1,
								name = L["Feign Death Text Size"],
								desc = L["Feign Death Text Size"],
								get = function() return HunterBiuBiu.db.profile.feigndeathfontsize end,
								set = function(v) HunterBiuBiu.db.profile.feigndeathfontsize = v; self:UpdateFeignDeathSetting() end,
								order = 8
							},
							textcolor = {
								type = 'color',
								name = L["Feign Death Text Color"],
								desc = L["Feign Death Text Color"],
								get = function() return HunterBiuBiu.db.profile.feigndeathtextr, HunterBiuBiu.db.profile.feigndeathtextg, HunterBiuBiu.db.profile.feigndeathtextb end,
								set = function(r, g, b) HunterBiuBiu.db.profile.feigndeathtextr = r; HunterBiuBiu.db.profile.feigndeathtextg = g; HunterBiuBiu.db.profile.feigndeathtextb = b; self:UpdateFeignDeathSetting() end,
								order = 9
							},
							x = {
								type = "text",
								name = L["Feign Death X"],
								desc = L["Feign Death X"],
								usage = L["Feign Death X"],
								get = function() return HunterBiuBiu.db.profile.feigndeathx end,
								set = function(v) if tonumber(v) then HunterBiuBiu.db.profile.feigndeathx = v; self:UpdateFeignDeathSetting() end end,
								order = 10
							},
							y = {
								type = "text",
								name = L["Feign Death Y"],
								desc = L["Feign Death Y"],
								usage = L["Feign Death Y"],
								get = function() return HunterBiuBiu.db.profile.feigndeathy end,
								set = function(v) if tonumber(v) then HunterBiuBiu.db.profile.feigndeathy = v; self:UpdateFeignDeathSetting() end end,
								order = 11
							},
							preview = {
								type = "execute",
								name = L["Feign Death Preview"],
								desc = L["Feign Death Preview"],
								func = function() self:FeignDeathFailed() end,
								order = 12
							},
							-- preview = {
							-- 	type = "execute",
							-- 	name = "配置",
							-- 	desc = "配置",
							-- 	func = function() HbbConfigFrame:Show() end,
							-- 	order = 13
							-- }
						}
					}
				}
			},
			optimizesec = {
				type = "toggle",
				name = L["OptimizeSecondCast"],
				desc = L["OptimizeSecondCast"],
				get = function() return HunterBiuBiu.db.profile.optimizeSec end,
				set = function() HunterBiuBiu.db.profile.optimizeSec = not HunterBiuBiu.db.profile.optimizeSec end,
				order = 13
			},
			settings = {
				type = "execute",
				name = L["Open Settings"],
				desc = L["Open Settings"],
				func = HbbConfigFrameShow,
				order = 15,
			},
			reset = {
				type = "execute",
				name = L["Reset Settings"],
				desc = L["Reset Settings"],
				func = function() StaticPopup_Show("RESET_HBB_PROFILE"); end,
				order = 16,
			}
		}
	}
	self.OnMenuRequest = self.cmdtable
	self:RegisterChatCommand({"/hbb", "/hunterbiubiu"}, self.cmdtable)
	----------------------------------------------------------------------------------------

	if (self.defaults ~=nil and self.defaults.profile ~= nil) then
		self:RegisterDefaults("profile", self.defaults.profile)
	end

	self.x, self.y = GetPlayerMapPosition("player")
	-- self:ScheduleRepeatingEvent("UPDATE_PLAYER_POSITION", self.UPDATE_PLAYER_POSITION, 0.1, self)

	-- self:Init()

	local _, playerRace = UnitRace("player")
	if playerRace == "Troll" then
	end

		self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("SPELLCAST_FAILED")
	self:RegisterEvent("SPELLCAST_INTERRUPTED")
	self:RegisterEvent("SPELLCAST_STOP")
	self:RegisterEvent("SPELLCAST_DELAYED")
	-- self:RegisterEvent("SPELLCAST_START")
	self:RegisterEvent("START_AUTOREPEAT_SPELL")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	self:RegisterEvent("ITEM_LOCK_CHANGED")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
	self:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	-- self:RegisterEvent("PLAYER_TARGET_CHANGED")

end

local autoshotted = function(t)
	local ttime = GetTime()
	HunterBiuBiu.roundcasttime = 0
	HunterBiuBiu.reallastshottime = ttime
	if t then
		HunterBiuBiu.realnextshotstart = t
		HunterBiuBiu.realnextshot = nil
	else
		HunterBiuBiu.realnextshot = ttime + UnitRangedDamage("player")
		HunterBiuBiu.realnextshotstart = HunterBiuBiu.realnextshot - SWING_TIME
		-- HunterBiuBiu.restoretime = nil

		HunterBiuBiu.seccaststart = nil
		HunterBiuBiu.seccastend = nil
	end
end

function HunterBiuBiu:PLAYER_ENTERING_WORLD()
	tryInitAmmoCount()
	self.realammocount = getAmmoCount()
	self.autoshotstopped = 1
	autoshotted(GetTime())
end

function HunterBiuBiu:UNIT_INVENTORY_CHANGED()
	--- print('UNIT_INVENTORY_CHANGED')
	--- print(self.casting and '技能' or '自动')
	local ammoCount = getAmmoCount()
	if arg1 == "player" and self.realammocount - ammoCount == 1 then
		-- 一次射击

		self.realammochanged = 1
		HunterBiuBiu:ScheduleEvent("HBB_AUTOSHOT", function()
			self.realammochanged = nil
			autoshotted()
		end, 0, self)

		self.realammocount = ammoCount
	end
end

-- function HunterBiuBiu:PLAYER_TARGET_CHANGED()
-- 	if not isAutoshotActive() then
-- 		self.roundcasttime = 0
-- 	end
-- end

-- onShotTime
function HunterBiuBiu:OnAutoShot(currentTime, rtime)
	-- self.mnsst = GetTime()
	-- self.mnct = self.mnsst + (SWING_TIME-self.cct)
	lastAimTime = nil;
	lastcast = nil
	secondReadyStart = nil
	secondReadyEnd = nil
	yz = nil
	yztime = nil
	-- self.multishooting = nil
	self.SwingStart = nil
	-- self.ignoregcd = nil
	if self.newswingtime then
		self.swingtime = self.newswingtime
	end

	lastshot = currentTime
	self.lastSwingTime = rtime or UnitRangedDamage("player")
	nextShotTime = currentTime + self.lastSwingTime
	nextSwingStart = nextShotTime - SWING_TIME
	if not rtime then
		self:StartAutoshotTimer()
		-- if not self:IsEventScheduled("HBB_ON_UPDATE") then
		-- 	self:ScheduleRepeatingEvent("HBB_ON_UPDATE", self.HBB_ON_UPDATE, 0, self)
		-- end
	end
end

function HunterBiuBiu:VARIABLES_LOADED()
	local ttime = GetTime()
	-- lastshot = ttime
	-- lastcast = ttime - 1

	lastAmmoCountUpdated = false
	-- self.cct = 0
	self.lockautoshot = nil
	-- self.lastSwingTime = UnitRangedDamage("player")
	-- self:onShotTime()
	self:OnAutoShot(ttime, UnitRangedDamage("player"))
	tryInitAmmoCount() -- 此时可能无法获取弹药数量，获取到的是1或者0
	-- self:CheckActionSlots() -- 1.9.3开始使用CastSpell 不依赖UseAction了
	self.berserkValue = 0
	self.ShotSpells = {
		[L["Aimed Shot"]] = true,
		[L["Multi-Shot"]] = true,
		[L["Arcane Shot"]] = true,
		[L["Concussive Shot"]] = true,
		[L["Distracting Shot"]] = true,
		[L["Scatter Shot"]] = true,
		[L["Scorpid Sting"]] = true,
		[L["Serpent Sting"]] = true,
		[L["Viper Sting"]] = true,
		[L["Tranquilizing Shot"]] = true,
		[L["Steady Shot"]] = true,
	}
	self.nocastingshots = {
		[L["Serpent Sting"]] = true,
		[L["Arcane Shot"]] = true,
		[L["Concussive Shot"]] = true,
		[L["Distracting Shot"]] = true,
		[L["Scatter Shot"]] = true,
		[L["Scorpid Sting"]] = true,
		[L["Viper Sting"]] = true,
		[L["Tranquilizing Shot"]] = true,
	}
	self.castingshots = {
		[L["Aimed Shot"]] = true,
		[L["Multi-Shot"]] = true,
		[L["Steady Shot"]] = true,
	}
	self.ChatTypes = {
		["SAY"] = true,
		["EMOTE"] = true,
		["YELL"] = true,
		["PARTY"] = true,
		["GUILD"] = true,
		["OFFICER"] = true,
		["RAID"] = true,
		["RAID_WARNING"] = true,
	}

	self.castHowl = HunterBiuBiu.db.profile.howl == nil and false or HunterBiuBiu.db.profile.howl
	self.castMultishot = HunterBiuBiu.db.profile.multishot == nil and true or HunterBiuBiu.db.profile.multishot
	self.castAimedshot = HunterBiuBiu.db.profile.aimedshot == nil and true or HunterBiuBiu.db.profile.aimedshot
	-- 上面三条应该不用了，暂留一下

	self.tv1 = HunterBiuBiu.db.profile.tv1 == nil and 2.61 or HunterBiuBiu.db.profile.tv1
	self.tv2 = HunterBiuBiu.db.profile.tv2 == nil and 2 or HunterBiuBiu.db.profile.tv2
	self.steadyshotActionId = HunterBiuBiu.db.profile.steadyshotActionId or 22
	self.multishotActionId = HunterBiuBiu.db.profile.multishotActionId or 23
	self.autoshotActionId = HunterBiuBiu.db.profile.autoshotActionId or 24

	local needSyncChannels = true
	for _,isOn in pairs(HunterBiuBiu.db.profile.channels) do
		if isOn then
			needSyncChannels = false
		end
	end

	if HunterBiuBiu.db.profile.channel and needSyncChannels then
		if HunterBiuBiu.db.profile.channels[HunterBiuBiu.db.profile.channel] ~= nil then
			HunterBiuBiu.db.profile.channels[HunterBiuBiu.db.profile.channel] = true
			HunterBiuBiu.db.profile.channel = "DEPRECATED"
		end
	end

	self:InitAutoshotBar()
	self:InitFeignDeathFrame()
	FeignDeathTex:SetAlpha(0)
	FeignDeathText:Hide()

	-- if HbbConfigFrame then
		HbbConfigFrameInit()
		SlashCmdList["HBBCFG"] = function() HbbConfigFrameShow() end
		SLASH_HBBCFG1 = "/hbbcfg"
	-- end

	if not self:IsEventScheduled("HBB_UPDATE_PLAYER_POSITION") then
		self:ScheduleRepeatingEvent("HBB_UPDATE_PLAYER_POSITION", self.HBB_UPDATE_PLAYER_POSITION, 0, self)
	end
	self:SystemMessage(L["Loaded. The hunt begins!"])

	-- if HunterBiuBiu.db.profile.lightningbreath then
	-- 	if not self:IsEventScheduled("HBB_LB") then
	-- 		self:ScheduleRepeatingEvent("HBB_LB", function() print('CastPetAction')CastPetAction(5) if UnitMana("pet") == 100 and UnitExists("target") then
	-- 			print('PetAttack')
	-- 			PetAttack()
	-- 		else
	-- 			print('PetWait')
	-- 			PetWait()
	-- 		end end, 0.2, self)
	-- 	end
	-- end
end


function HunterBiuBiu:InitAutoshotBar()
	if self.Bar then return end
	self.Bar = CreateFrame("Frame", "HbbAutoshotBar", UIParent)

	self.Bar:SetScript("OnUpdate", function()
		self:HBB_ON_UPDATE()
	end)


	HbbAutoBar = self.Bar

	HbbAutoBar:SetFrameStrata("MEDIUM")
	HbbAutoBar:RegisterForDrag("LeftButton")
	HbbAutoBar:SetClampedToScreen(true)

	HbbAutoBar.Background = HbbAutoBar:CreateTexture(nil,"BACKGROUND")
	HbbAutoBar.Background:SetTexture(0, 0, 0, 0.5)
	HbbAutoBar.Background:SetAllPoints(HbbAutoBar)

	HbbAutoBar.Texture2 = HbbAutoBar:CreateTexture("HbbAutoshotBarTexture","ARTWORK")
	HbbAutoBar.Texture2:SetTexture(0, 0, 0, 0.75)
	HbbAutoBar.Texture2:SetPoint("LEFT",HbbAutoBar,"LEFT")

	HbbAutoBar.Texture = HbbAutoBar:CreateTexture("HbbAutoshotBarTexture","OVERLAY")
	HbbAutoBar.Texture:SetTexture(0, 1, 0, 0.7)
	HbbAutoBar.Texture:SetPoint("LEFT",HbbAutoBar,"LEFT")

	HbbAutoBar.Text = HbbAutoBar:CreateFontString("HbbAutoshotBarText","OVERLAY","GameFontHighlight")
	HbbAutoBar.Text:SetTextColor(1, 1, 1, 0.9)
	HbbAutoBar.Text:SetPoint("LEFT",HbbAutoBar,"LEFT")
	HbbAutoBar.Text:SetJustifyH("LEFT")
	HbbAutoBar.Text:SetJustifyV("CENTER")
	HbbAutoBar.Text:SetWidth(HunterBiuBiu.db.profile.autoshotbarw)
	HbbAutoBar.Text:SetFont(GameFontNormal:GetFont(), math.max(HunterBiuBiu.db.profile.autoshotbarh*0.6, 10))
	HbbAutoBar.Text:SetText("自动射击 Biu~")

	HbbAutoBar.Tmr = HbbAutoBar:CreateFontString("HbbAutoshotBarTmr","OVERLAY","GameFontHighlight")
	HbbAutoBar.Tmr:SetTextColor(1, 1, 1, 0.9)
	HbbAutoBar.Tmr:SetPoint("LEFT",HbbAutoBar,"RIGHT")
	HbbAutoBar.Tmr:SetJustifyH("LEFT")
	HbbAutoBar.Tmr:SetJustifyV("CENTER")
	HbbAutoBar.Tmr:SetWidth(40)
	HbbAutoBar.Tmr:SetFont(GameFontNormal:GetFont(), math.max(HunterBiuBiu.db.profile.autoshotbarh*0.6, 10))
	HbbAutoBar.Tmr:SetText("")

	HbbAutoBar:EnableMouse(1)
	HbbAutoBar:SetMovable(1)
	HbbAutoBar:SetScript("OnDragStart", function() if not HunterBiuBiu.db.profile.autoshotbarl then this:StartMoving() end end)
	HbbAutoBar:SetScript("OnDragStop", function()
		if not HunterBiuBiu.db.profile.autoshotbarl then
			this:StopMovingOrSizing()
			local _, _, _, x, y = this:GetPoint()
			HunterBiuBiu.db.profile.autobarx = x
			HunterBiuBiu.db.profile.autobary = y
		end
	end)

	if not HunterBiuBiu.db.profile.autobarx then
		HunterBiuBiu.db.profile.autobarx = GetScreenWidth() / 2 - 100
		HunterBiuBiu.db.profile.autobary = (GetScreenHeight() / 2 - 10) * -1
	end
	HbbAutoBar:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", HunterBiuBiu.db.profile.autobarx, HunterBiuBiu.db.profile.autobary)

	HbbAutoBar.Texture:SetWidth(HunterBiuBiu.db.profile.autoshotbarw)
	HbbAutoBar.Texture:SetHeight(HunterBiuBiu.db.profile.autoshotbarh)
	HbbAutoBar.Texture2:SetWidth(HunterBiuBiu.db.profile.autoshotbarw)
	HbbAutoBar.Texture2:SetHeight(HbbAutoBar.Texture:GetHeight()+2)
	HbbAutoBar:SetWidth(HunterBiuBiu.db.profile.autoshotbarw)
	HbbAutoBar:SetHeight(HunterBiuBiu.db.profile.autoshotbarh)
	self:HideAutoshotBar()
end

function HunterBiuBiu:UpdateAutoshotBarW()
	HbbAutoBar:SetWidth(HunterBiuBiu.db.profile.autoshotbarw)
	HbbAutoBar.Texture:SetWidth(HbbAutoBar:GetWidth())
	HbbAutoBar.Texture2:SetWidth(HbbAutoBar:GetWidth())
end

function HunterBiuBiu:UpdateAutoshotBarH()
	HbbAutoBar:SetHeight(HunterBiuBiu.db.profile.autoshotbarh)
	HbbAutoBar.Texture:SetHeight(HunterBiuBiu.db.profile.autoshotbarh)
	HbbAutoBar.Texture2:SetHeight(HbbAutoBar.Texture:GetHeight()+2)
	HbbAutoBar.Text:SetFont(GameFontNormal:GetFont(), math.max(HunterBiuBiu.db.profile.autoshotbarh*0.6, 10))
	HbbAutoBar.Tmr:SetFont(GameFontNormal:GetFont(), math.max(HunterBiuBiu.db.profile.autoshotbarh*0.6, 10))
end

function HunterBiuBiu:StartCast(spellName, rank)
	local _,_, latency = GetNetStats()
	-- local castbar
	if spellName == L["Aimed Shot"] then
		-- castbar = HunterBiuBiu.db.profile.aimed
		self.casttime = getCastTime(3)
	elseif spellName == L["Multi-Shot"] then
		-- castbar = HunterBiuBiu.db.profile.multi
		self.casttime = 0.5
	-- elseif spellName == L["Tranquilizing Shot"] and HunterBiuBiu.db.profile.tranq then
	-- 	self:ScheduleEvent("HunterBiuBiu_TRANQ", self.Announce, 0.2, self, string.gsub(HunterBiuBiu.db.profile.tranqmsg, "%%t", UnitName("target")))
	elseif spellName == L["Steady Shot"]  then
		-- castbar = HunterBiuBiu.db.profile.steady
		self.casttime = getCastTime(1.5)
	elseif spellName == L["Serpent Sting"]  then
		local targetName = UnitName("target")
		if targetName then
			HbbSerpentMap[targetName] = GetTime()
		end
	end

	-- ["Auto Shot"] = "自动射击",
	-- ["Aimed Shot"] = "瞄准射击",
	-- ["Multi-Shot"] = "多重射击",
	-- ["Serpent Sting"] = "毒蛇钉刺",
	-- ["Arcane Shot"] = "奥术射击",
	-- ["Concussive Shot"] = "震荡射击",
	-- ["Distracting Shot"] = "扰乱射击",
	-- ["Scatter Shot"] = "驱散射击",
	-- ["Scorpid Sting"] = "毒蝎钉刺",
	-- ["Viper Sting"] = "蝰蛇钉刺",
	-- ["Steady Shot"] = "稳固射击",
	-- ["Tranquilizing Shot"] = "宁神射击",

	-- if spellName == L["Aimed Shot"] or spellName == L["Multi-Shot"] or spellName == L["Steady Shot"] or spellName == L["Arcane Shot"] or spellName == L["Tranquilizing Shot"] then
	-- 	self.casting = true
	-- end

	if self.nocastingshots[spellName] then
		self.casting = true
	elseif self.castingshots[spellName] then
		HunterBiuBiu:ScheduleEvent("HBB_CASTING", function() HunterBiuBiu.casting = true end, (latency/1000)+0.2, self)
	end

	if self.casttime then
		self.castblock = true
		self.casttime = self.casttime + (latency/1000)
	end
end

-- 自动射击条--------------------------------------------------------------------------------
function HunterBiuBiu:UpdateAutobarLockStatus(forceShow)
	if HunterBiuBiu.db.profile.autoshotbarl then
		HbbAutoBar:EnableMouse(nil)
		HbbAutoBar:SetMovable(nil)
		HbbAutoBar:SetScript("OnDragStart", nil)
		HbbAutoBar:SetScript("OnDragStop", nil)
	else
		HbbAutoBar:EnableMouse(1)
		HbbAutoBar:SetMovable(1)
		HbbAutoBar:SetScript("OnDragStart", function() this:StartMoving() end)
		HbbAutoBar:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			local _, _, _, x, y = this:GetPoint()
			HunterBiuBiu.db.profile.autobarx = x
			HunterBiuBiu.db.profile.autobary = y
		end)
	end

	if not self.shooting and HunterBiuBiu.db.profile.autoshotbarl then
		HbbAutoBar:SetAlpha(0)
	else
		HbbAutoBar:SetAlpha(1)
	end

	if forceShow then
		HbbAutoBar:SetAlpha(1)
		HbbAutoBar:Show()
		HbbAutoBar.Texture:SetWidth(HbbAutoBar:GetWidth())
	end
end

--System Message Output --------------------------------------------------------------------
function HunterBiuBiu:SystemMessage(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFAAD372HunterBiuBiu|cFFFFFFFF: "..msg)
end
--------------------------------------------------------------------------------------------

local shootDelayed = false
--Event functions --------------------------------------------------------------------------
function HunterBiuBiu:HBB_UPDATE_PLAYER_POSITION()
	-- if HbbAutoBar.ltt and GetTime() - HbbAutoBar.ltt > 0.5 then
	-- 	HbbAutoBar:Hide()
	-- 	self:CancelScheduledEvent("HBB_ON_UPDATE")
	-- end
	local x, y = GetPlayerMapPosition("player")
	if x ~= self.x or y ~= self.y then
		self.moving = true
		self.x = x
		self.y = y
		shootDelayed = true
	else
		self.moving = nil
		self.startAt = GetTime()
		if shootDelayed then
			-- if IsAutoRepeatAction(self.autoshotActionId) then
			-- 	Hbb_AutoTimer.et = math.max(GetTime() + SWING_TIME, Hbb_AutoTimer.et)
			-- end
			shootDelayed = false
		end
	end
end

-- 弃用了
function HunterBiuBiu:Announce(msg)
	if self.ChatTypes[strupper(HunterBiuBiu.db.profile.channel)] then
		SendChatMessage(msg, strupper(HunterBiuBiu.db.profile.channel))
	-- else
	-- 	local id = GetChannelName(HunterBiuBiu.db.profile.channel)
	-- 	if id then
	-- 		SendChatMessage(msg, "CHANNEL", nil, id)
	-- 	end
	end
end

function HunterBiuBiu:SendMessageToChannels(msg)
	if not HunterBiuBiu.db.profile.channels then
		return
	end

	for k,v in HunterBiuBiu.db.profile.channels do
		if v then
			if not (k == "RAID" and GetNumRaidMembers() == 0) and not (k == "PARTY" and GetNumPartyMembers() == 0) then
				SendChatMessage(msg, k)
			end
		end
	end
end

function HunterBiuBiu:SendTranqMessage()
	if HunterBiuBiu.db.profile.tranq and (lastTranqTime == nil or GetTime()-lastTranqTime > 2) then
		lastTranqTime = GetTime()
		local msg = string.gsub(HunterBiuBiu.db.profile.tranqmsg, "%%t", UnitName("target"))
		self:SendMessageToChannels(msg)
	end
end

function HunterBiuBiu:SendTranqFailMessage()
	if HunterBiuBiu.db.profile.tranq and self.ChatTypes[strupper(HunterBiuBiu.db.profile.channel)] and (lastTranqFailTime == nil or GetTime()-lastTranqFailTime > 2) then
		lastTranqFailTime = GetTime()
		local msg = HunterBiuBiu.db.profile.tranqfailmsg
		self:SendMessageToChannels(msg)
	end
end

-- 这个似乎无效
function HunterBiuBiu:CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF()
	if string.find(arg1, L["TRANQ_MISS"]) and HunterBiuBiu.db.profile.tranq then
		self:SendTranqFailMessage()
	end
end

function HunterBiuBiu:CHAT_MSG_SPELL_SELF_DAMAGE()
	if string.find(arg1, L["TRANQ_MISS"]) and HunterBiuBiu.db.profile.tranq then
		self:SendTranqFailMessage()
	elseif string.find(arg1, L["TRANQ_SUCCEED"]) and HunterBiuBiu.db.profile.tranq then
		self:SendTranqMessage()
	end
end

function HunterBiuBiu:CHAT_MSG_SPELL_SELF_BUFF()
	if string.find(arg1, L["TRANQ_FAIL"]) and HunterBiuBiu.db.profile.tranq then
		self:SendTranqFailMessage()
	end
end

function HunterBiuBiu:CHAT_MSG_SPELL_FAILED_LOCALPLAYER()
	if string.find(arg1, '失败：不能在') then
		-- 被控
		self.lostcontrol = 1
	end
end

function HunterBiuBiu:SPELLCAST_FAILED()
	self.casting = nil
	if self:IsEventScheduled("HBB_CASTING") then
		self:CancelScheduledEvent("HBB_CASTING")
	end
	self.castblock = nil
end

function HunterBiuBiu:SPELLCAST_INTERRUPTED()
	self.casting = nil
	if self:IsEventScheduled("HBB_CASTING") then
		self:CancelScheduledEvent("HBB_CASTING")
	end
	self.castblock = nil
end

local function isBuffed()
	for i=1, 32 do
		if UnitBuff("player",i) == "Interface\\Icons\\Racial_Troll_Berserk" then
			return true
		end
	end
end

function HunterBiuBiu:UNIT_AURA()
	local newBuffStatus = isBuffed()
	if not self.hasBerserk and newBuffStatus then
		self.hasBerserk = true
		if((UnitHealth("player")/UnitHealthMax("player")) >= 0.40) then
			self.berserkValue = (1.30 - (UnitHealth("player")/UnitHealthMax("player")))/3
		else
			self.berserkValue = 0.3
		end
	elseif self.hasBerserk and not newBuffStatus then
		self.berserkValue = 0
		self.hasBerserk = nil
	end
end

function HunterBiuBiu:UNIT_RANGEDDAMAGE()
	lastAmmoCount = getAmmoCount()
	self.newswingtime = UnitRangedDamage("player") - SWING_TIME
end

function HunterBiuBiu:SPELLCAST_DELAYED()
	if self.casttime then
		self.casttime = self.casttime + (arg1/1000)
	end
end

-- 猎人的射击技能不会触发
-- function HunterBiuBiu:SPELLCAST_START()
-- 	print('SPELLCAST_START')
-- 	print(arg1) -- 法术名称
-- 	print(arg2) -- 施法时间（毫秒）
-- end

function HunterBiuBiu:PLAYER_REGEN_ENABLED()
	if self:IsEventScheduled("CHECK_FEIGN_DEATH") then
		self:CancelScheduledEvent("CHECK_FEIGN_DEATH")
	end
end

function HunterBiuBiu:UpdateFeignDeathSetting()
	local profile = HunterBiuBiu.db.profile
	local maskr = assertNum(profile.feigndeathr, self.defaults.feigndeathr)
	local maskg = assertNum(profile.feigndeathg, self.defaults.feigndeathg)
	local maskb = assertNum(profile.feigndeathb, self.defaults.feigndeathb)
	local maska = assertNum(profile.feigndeatha, self.defaults.feigndeatha)
	local textr = assertNum(profile.feigndeathtextr, self.defaults.feigndeathtextr)
	local textg = assertNum(profile.feigndeathtextg, self.defaults.feigndeathtextg)
	local textb = assertNum(profile.feigndeathtextb, self.defaults.feigndeathtextb)
	local texta = assertNum(profile.feigndeathtexta, self.defaults.feigndeathtexta)
	local x = assertNum(profile.feigndeathx, self.defaults.feigndeathx)
	local y = assertNum(profile.feigndeathy, self.defaults.feigndeathy)
	local fontSize = assertNum(profile.feigndeathfontsize, self.defaults.feigndeathfontsize)

	FeignDeathTex:SetTexture(maskr, maskg, maskb, maska)
	FeignDeathText:SetTextColor(textr, textg, textb, texta)
	FeignDeathText:SetPoint("CENTER",WorldFrame,"CENTER", x, y)
	FeignDeathText:SetFont(GameFontNormal:GetFont(), fontSize)
	FeignDeathText:SetText(profile.feigndeathtext)
end

function HunterBiuBiu:InitFeignDeathFrame()
	if not FeignDeathFrame then
		CreateFrame("Frame", "FeignDeathFrame", UIParent)
		FeignDeathFrame:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT")
	end
	if not FeignDeathTex then
		FeignDeathTex = FeignDeathFrame:CreateTexture(nil, "ARTWORK")
		FeignDeathTex:SetAllPoints(WorldFrame)

		FeignDeathText = FeignDeathFrame:CreateFontString("FeignDeathFrameText","OVERLAY","GameFontHighlight")
	end

	self:UpdateFeignDeathSetting()
end

function HunterBiuBiu:FeignDeathFailed()
	FeignDeathTex:SetAlpha(0)
	self:CancelScheduledEvent("FEIGN_DEATH_FAILED_FADE_OUT")
	FeignDeathText:Hide()

	local profile = HunterBiuBiu.db.profile
	if not profile.feigndeathon then
		return
	end

	if profile.feigndeathalarm then
		PlaySoundFile("Interface\\Addons\\HunterBiuBiu\\media\\BikeHorn.ogg")
	end

	if profile.feigndeathalert
	and profile.feigndeathalertmsg
	and GetNumRaidMembers() > 1 then
		SendChatMessage(profile.feigndeathalertmsg, 'RAID')
	end

	local delay = assertNum(profile.feigndeathdelay or self.defaults.profile.feigndeathdelay)
	FeignDeathText:Show()
	if profile.feigndeathmask then
		self.feignDeathFailedFadeOutStart = GetTime()
		FeignDeathTex:SetAlpha(1)
		self:ScheduleRepeatingEvent("FEIGN_DEATH_FAILED_FADE_OUT", function()
			if GetTime() > self.feignDeathFailedFadeOutStart + delay then
				FeignDeathTex:SetAlpha(0)
				self:CancelScheduledEvent("FEIGN_DEATH_FAILED_FADE_OUT")
				FeignDeathText:Hide()
			else
				FeignDeathTex:SetAlpha(1-((GetTime() - self.feignDeathFailedFadeOutStart) / delay))
			end
		end, 0.1, self)
	end
end

function HunterBiuBiu:SPELLCAST_STOP()
	--- print('SPELLCAST_STOP')
	-- local realammocount = GetInventoryItemCount("player",0)
	-- print('SPELLCAST_STOP >> '..realammocount)
	-- if self.realammocount and realammocount < self.realammocount then
	-- 	self.roundcasttime = (self.roundcasttime or 0) + 1
	-- end
	-- self.realammocount = realammocount
	if self.realammochanged then
		self:CancelScheduledEvent("HBB_AUTOSHOT")
		self.realammochanged = nil
		self.roundcasttime = (self.roundcasttime or 0) + 1
		if self.roundcasttime == 1 then
			local ttime = GetTime()
			self.seccaststart = ttime
			self.seccastend = ttime + 0.5
		else
			self.seccaststart = nil
			self.seccastend = nil
		end
	end

	if HunterBiuBiu.db.profile.feigndeathon then
		local _,_,l = GetNetStats()

		local feignDeathSpellId
		if self.feignDeathSpellId then
			local name = GetSpellName(self.feignDeathSpellId, 'spell')
			if name == L["Feign Death"] then
				feignDeathSpellId = self.feignDeathSpellId
			end
		end
		if not feignDeathSpellId then
			feignDeathSpellId = getSpellId(L["Feign Death"])
			self.feignDeathSpellId = feignDeathSpellId
		end
		if feignDeathSpellId and not self:IsEventScheduled("CHECK_FEIGN_DEATH") then
			HunterBiuBiu:ScheduleEvent("CHECK_FEIGN_DEATH", function()
				local a,b,c = GetSpellCooldown(feignDeathSpellId, 'spell')
				if ((b == 0.001 and c == 0) ) and UnitAffectingCombat("player") then
					-- 群友说假死不起来会误报，但是不起来应该不会进入SPELLCAST_STOP，待考证
					self:FeignDeathFailed()
				end
			end, l/1000+0.1, HunterBiuBiu)
		end
	end


	self.casting = nil

	if self:IsEventScheduled("HBB_CASTING") then
		self:CancelScheduledEvent("HBB_CASTING")
	end
	self.castblock = nil
end

function HunterBiuBiu:START_AUTOREPEAT_SPELL()
	self.autoshotstopped = nil
	local ttime = GetTime()
	self.swingtime = UnitRangedDamage("player") - SWING_TIME
	HunterBiuBiu.swingtime = UnitRangedDamage("player") - SWING_TIME
	if not self.lastSwingTime or (nextShotTime and GetTime() > nextShotTime) then
		self.lastSwingTime = self.swingtime + SWING_TIME
	end
	self.shooting = true
	self.startAt = ttime
	-- self.ignoregcd = checkGCD()
	if ttime - lastshot >= self.swingtime then
		self.SwingStart = ttime
	end
	self:StartAutoshotTimer(true)
	-- if not self:IsEventScheduled("HBB_ON_UPDATE") then
	-- 	self:ScheduleRepeatingEvent("HBB_ON_UPDATE", self.HBB_ON_UPDATE, 0, self)
	-- end
end

function HunterBiuBiu:STOP_AUTOREPEAT_SPELL()
	self.autoshotstopped = 1
	self.roundcasttime = 0
	self:HideAutoshotBar()
	self.shooting = nil
	-- if not lastshot or not self.swingtime or GetTime() - lastshot >= self.swingtime then
	-- 	self:CancelScheduledEvent("HBB_ON_UPDATE")
	-- end
end

function HunterBiuBiu:ITEM_LOCK_CHANGED()
	--- print('ITEM_LOCK_CHANGED')
	-- print(getAmmoCount())
	-- HunterBiuBiu:ScheduleEvent("HBB_LOCK_CHANGED", function()
	-- 	local ammoCount = GetInventoryItemCount("player",0)
	-- 	if self.realammocount and self.realammocount > ammoCount then
	-- 		print('这是自动射击')
	-- 		self.realammocount = ammoCount
	-- 	end
	-- end, 0, self)

	local currAmmoCount = getAmmoCount()
	if lastAmmoCount == nil or lastAmmoCount < 2 then
		lastAmmoCount = getAmmoCount()
	elseif currAmmoCount >= lastAmmoCount or currAmmoCount < lastAmmoCount - 2 then
		return
	end

	local currentTime = GetTime()
	self.castblock = nil

	if self.casting then
		self.casting = nil
		self.casttime = nil
		if lastSpellName == L["Tranquilizing Shot"] and HunterBiuBiu.db.profile.tranq then
			self:SendTranqMessage()
		elseif lastSpellName == L["Aimed Shot"] then
			lastAimTime = currentTime
		end

		if lastcast == nil or currentTime - lastcast > 2.5 then
			lastcast = currentTime
			-- 第一次技能
			secondReadyStart = currentTime
			-- 0.5比较适合手动，用鼠标宏调整为0.2或0.3也是可以的，手动则有可能漏技能
			secondReadyEnd = currentTime + HunterBiuBiu.db.profile.secondCastLimit
		else
			-- 第二次技能
			secondReadyStart = nil
			secondReadyEnd = nil
		end

		nextSwingStart = nil
		-- 这里不能清除，否则会干扰技能2判断
		-- nextShotTime = nil
	else
		self:OnAutoShot(currentTime)
	end

	lastAmmoCount = currAmmoCount
end
--------------------------------------------------------------------------------------------

------------------- 抽筋宏底层逻辑 --------------------
function HunterBiuBiu:AllowCast()
	-- 1.9.8.2 反馈团本时会只打稳固，未发现原因，先用回老的判定
	-- local ttime = GetTime()

	-- if HunterBiuBiu.db.profile.priorauto and ttime > self.realnextshotstart then
	-- 	if self.autoshotstopped then
	-- 		startAutoshot()
	-- 	end
	-- 	return nil
	-- end

	-- return (self.roundcasttime or 0) < 1 or (self.realnextshot and ttime > self.realnextshot + 2)

	local inswing = HunterBiuBiu:InSwing(HunterBiuBiu.db.profile.priorautoos)
	if (not lastcast or lastcast <= lastshot) and not HunterBiuBiu.casting and (
		not HunterBiuBiu.db.profile.priorauto
		or
		not inswing
	 ) then
		HunterBiuBiu.castrefuseTime = nil
		return 1
	end

	if inswing and not isAutoshotActive() then
		startAutoshot(1)
	end
	-- 尝试恢复自动射击功能在HbbShot处理
	-- local ttime = GetTime()
	-- HunterBiuBiu.castrefuseTime = HunterBiuBiu.castrefuseTime or ttime
	-- local _,_,l = GetNetStats()
	-- if self.lastSwingTime and ttime - HunterBiuBiu.castrefuseTime > self.lastSwingTime+1.5 + (l/1000) and isAutoshotActive() and (not self.startAt or ttime - self.startAt > SWING_TIME + (l/1000)) and HunterBiuBiu.db.profile.restoreauto then
	-- 	HunterBiuBiu.castrefuseTime = nil
	-- 	startAutoshot(1)
	-- end
end

function HunterBiuBiu:AllowSecondCast()
	-- 见缝插针的技能2逻辑
	if lastcast and HunterBiuBiu.db.profile.secondspell and HunterBiuBiu.db.profile.secondspelllimit and nextShotTime
	  and (not HunterBiuBiu.db.profile.secondspellonlyboss or string.find(UnitClassification("target"),"boss"))
		and nextShotTime - GetTime() > HunterBiuBiu.db.profile.secondspelllimit then
			return 2
	end

	if lastcast and secondReadyStart then
		local currTime = GetTime()
		if HunterBiuBiu.db.profile.optimizeSec and not checkSpellCooldown(L["Multi-Shot"]) then
			local slimit = HunterBiuBiu.db.profile.optimizeSecLimit or 0.8
			if nextShotTime and (nextShotTime - currTime < slimit) then
				return nil
			end
		end
		if (currTime >= secondReadyStart and currTime < secondReadyEnd) or (nextSwingStart and currTime < nextSwingStart) then
			return 1
		end
	end

	-- 因团本卡顿会出问题，先停用1.9.8.2新的逻辑
	-- if self.seccaststart then
	-- 	local ttime = GetTime()
	-- 	if HunterBiuBiu.db.profile.optimizeSec and not checkSpellCooldown(L["Multi-Shot"]) then
	-- 		local slimit = HunterBiuBiu.db.profile.optimizeSecLimit or 0.8
	-- 		if self.realnextshot and (self.realnextshot - ttime < slimit) then
	-- 			return nil
	-- 		end
	-- 	end
	-- 	if (ttime >= self.seccaststart and ttime < self.seccastend) or (self.realnextshotstart and ttime < self.realnextshotstart) then
	-- 		return 1
	-- 	end
	-- end
end

-- 保持当前轮策略
local y1 = function ()
	if (yz == nil or (yztime ~= nil and GetTime()-yztime > 3.5)) then
		yz = 1
		yztime = GetTime()
	end
end
local y2 = function ()
	if (yz == nil or (yztime ~= nil and GetTime()-yztime > 3)) then
		yz = 2
		yztime = GetTime()
	end
end
local y3 = function ()
	if (yz == nil or (yztime ~= nil and GetTime()-yztime > 2.5)) then
		yz = 3
		yztime = GetTime()
	end
end

--------------------------------------------------------------------------------------------

local function howl()
	if not UnitHealth("pet") then return end

	local act;
	for i=1,10 do
		act = GetPetActionInfo(i)
		if act ~= nil and string.find(act, L["Howl"]) then
			if GetPetActionCooldown(i)==0 then CastPetAction(i) end
			return
		end
	end
end

function HunterBiuBiu:checkShotSlot()
	local steadyshotSpellId, multishotSpellId,autoshotSpellId
	for i = 1,GetNumSpellTabs() do
		local spellTabName,_,skipNum,SpellNum = GetSpellTabInfo(i)
		if spellTabName == L["Shot"] then
			for j = 1, SpellNum do
				local spellName = GetSpellName(j + skipNum, "spell")

				if string.find(spellName, L["Steady Shot"]) then
					steadyshotSpellId = j + skipNum
				elseif string.find(spellName, string.gsub(L["Multi-Shot"], "%-", "%%-")) then
					multishotSpellId = j + skipNum
				elseif string.find(spellName, L["Auto Shot"]) then
					autoshotSpellId = j + skipNum
				end
			end
			return steadyshotSpellId, multishotSpellId, autoshotSpellId
		end
	end
end

function HunterBiuBiu:autoSetAction()
	local steadyshotSpellId, multishotSpellId, autoshotSpellId = self:checkShotSlot()
	if steadyshotSpellId and multishotSpellId and autoshotSpellId then
		if HasAction(self.steadyshotActionId) then
			PickupAction(self.steadyshotActionId)
			ClearCursor()
		end
		if HasAction(self.multishotActionId) then
			PickupAction(self.multishotActionId)
			ClearCursor()
		end
		if HasAction(self.autoshotActionId) then
			PickupAction(self.autoshotActionId)
			ClearCursor()
		end

		PickupSpell(steadyshotSpellId, "spell");
		PlaceAction(self.steadyshotActionId);

		PickupSpell(multishotSpellId, "spell");
		PlaceAction(self.multishotActionId);

		PickupSpell(autoshotSpellId, "spell");
		PlaceAction(self.autoshotActionId);
	end
end

local checkRapid = function(originCastTime, targetCastTime)
	local t = originCastTime
	t = getCastTime(t)

	return t <= targetCastTime
end

function HunterBiuBiu:ActionReady(actionId, gcdok)
	local start, cd = GetActionCooldown(actionId)
	return start == 0 and (cd == 0 or (cd == 1.5 and not gcdok))
end

local parseHbbArg = function(a)
	if not a then return {} end
	local s,m,r = string.upper(a),{
		["0"]=0,["1"]=1,["2"]=2,["3"]=3,["4"]=4,["5"]=5,["6"]=6,["7"]=7,["8"]=8,["9"]=9,["A"]=10,["B"]=11,["C"]=12,["D"]=13,["E"]=14,["F"]=15,["G"]=16,["H"]=17,["I"]=18,["J"]=19,["K"]=20,["L"]=21,["M"]=22,["N"]=23,["O"]=24,["P"]=25,["Q"]=26,["R"]=27,["S"]=28,["T"]=29,["U"]=30,["V"]=31,["W"]=32,["X"]=33,["Y"]=34,["Z"]=35
	},{}
	for i = 1, string.len(s) do
		r[i] = m[string.sub(s, i, i)]
	end
	return r
end

local checkRaceSpell = function()
	local _, race = UnitRace("player")
	if race ~= "Orc" and race ~= "Troll" then return end

	for i=1,GetNumSpellTabs() do
		local n,_,s,c = GetSpellTabInfo(i)
		-- 第一个必定是综合
		-- if n == "综合" then
			for j=1,c do
				local sn = GetSpellName(j+s, "spell")
				if sn == L["Blood Fury"] or sn == L["Berserking"] and GetSpellCooldown(j+s, "spell") then
					return j+s
				end
			end
		-- end
		break
	end
end

local icd = function(slot)
	if type(slot) == 'number' and slot >=1 and slot <= 18 then
		local a,_,c = GetInventoryItemCooldown("player", slot)
		return c == 1 and a == 0
	end
end

function HunterBiuBiu:Buffed(name)
	-- name可以是一个，也可以是table（多个），一个则返回结果，多个则返回table
	local single = type(name) == 'string'
	if single then
		name = { name }
	end

	local results = {}

	if type(FindBuff) == 'function' then
		for index, buffName in ipairs(name) do
			if FindBuff(buffName, "player") then
				results[index] = 1
			end
		end
	else
		local i,a,b = 0
		while 1 do
			a, b = GetPlayerBuff(i)
			if not a or a < 0 then
				break;
			end

			for index, buffName in ipairs(name) do
				if string.find(getBuffText("player", a+1) or "", buffName) then
					results[index] = 1
				end
			end
			i = i + 1
		end
	end

	if single then
		return results[1]
	end

	return results
end

-- 对元素和机械目标不打毒蛇，判定条件不一定准确，待实测
local allowSerpent = function()
	local n = UnitName("target")
	if n and HunterBiuBiu.db.profile.secondspellserpentlimit and UnitHealth("target") > HunterBiuBiu.db.profile.secondspellserpentlimit
	and not string.find(UnitCreatureType("target"), L["Elemental"])
	and not string.find(UnitCreatureType("target"), L["Mechanical"])
	and (not HbbSerpentMap[n] or GetTime()-HbbSerpentMap[n] > 15) then
			return 1
	end
end

function HunterBiuBiu.StayLightningBreath()
	if not UnitHealth("pet") then return end

	local act, b;
	for i=1,10 do
		act = GetPetActionInfo(i)
		if act ~= nil and string.find(act, L["Lightning Breath"]) then
			b = 1
			if GetPetActionCooldown(i)==0 then CastPetAction(i) end
			break
		end
	end
	if b then
		if UnitMana("pet") == 100 and UnitExists("target") and UnitCanAttack("player", "target") and UnitHealth("target") > 0 then
			PetAttack()
		elseif UnitMana("pet") < 100 then
			PetWait()
		end
	end
end

-- paras 1：是否强制不打多重 1=不打， 2：对多少万血量以下使用急速射击 0=任何血量 空格=不放， 后面延续这个规则， 3： 开饰品1， 4： 开饰品2， 5： 开种族天赋（巨魔狂暴，兽人血性狂暴）,6 急速互斥（1）急速射击 快速射击 巨魔种族天赋，7 多少蓝量打1级多重（单位为五百）
function HunterBiuBiu:HbbShot(paras)
	-- 正在尝试恢复自动射击
	if HunterBiuBiu.hbbshotpaused then
		if not PlayerFrame.inCombat then
			AttackTarget()
		else
			-- 近战攻击成功，恢复自动射击完成（实际表现未知）
			HunterBiuBiu:STOP_AUTOREPEAT_SPELL()
			HunterBiuBiu.roundcasttime = 0
			HunterBiuBiu.hbbshotpaused = nil
		end
		return
	end
	-- local ttime = GetTime()

	if HunterBiuBiu.db.profile.restoreauto and HunterBiuBiu.lostcontrol then
		-- 尝试恢复自动射击
		AttackTarget()
		HunterBiuBiu.hbbshotpaused = 1
		HunterBiuBiu.lostcontrol = nil

		return
		-- if self.repeatstart and ttime - self.repeatstart < 0.5 then
		-- 	self.repeatstart = ttime
		-- 	if (not HunterBiuBiu.nextrestoretry or ttime > HunterBiuBiu.nextrestoretry) and self.realnextshot then
		-- 		local latestshottime = self.realnextshot + 1
		-- 		if yz == 1 then
		-- 			latestshottime = self.reallastshottime and (self.reallastshottime + 4)  or (self.realnextshot + 2)
		-- 		end
		-- 		if ttime > latestshottime then
		-- 			startAutoshot(1)
		-- 			self.hbbshotpaused = 1
		-- 			local _,_, latency = GetNetStats()
		-- 			self:ScheduleEvent("HBB_CANCEL_PAUSE", function()
		-- 				HunterBiuBiu:STOP_AUTOREPEAT_SPELL()
		-- 				HunterBiuBiu.roundcasttime = 0
		-- 				HunterBiuBiu.hbbshotpaused = nil
		-- 				HunterBiuBiu.nextrestoretry = ttime + 10
		-- 			end, latency / 1000 + 0.1, self);

		-- 			return
		-- 		end
		-- 	end
		-- else
		-- 	self.repeatstart = ttime
		-- 	self.roundcasttime = 0
		-- 	HunterBiuBiu.nextrestoretry = ttime + 3
		-- end
	end

	local p,uh = parseHbbArg(paras),UnitHealth("target")

	local ignoreMultishot = p[1] == 1
	local buffedResults = HunterBiuBiu:Buffed({L["Quick Shots"], L["Rapid Fire"], L["Berserking"], L["Kiss of the Spider"]})
	local anyRapidBuffed
	for _, value in ipairs(buffedResults) do
		if value then
			anyRapidBuffed = 1
			break
		end
	end


	while 1 do
		if uh and uh ~= 0 and (
			not HunterBiuBiu.db.profile.aconlycombat
			or UnitAffectingCombat("player")
		) then
			if p[3] then
				if (p[3] == 0 or (uh and uh > p[3]*10000)) and icd(13) then
					UseInventoryItem(13)
				end
			end
			if p[4] then
				if (p[4] == 0 or (uh and uh > p[4]*10000)) and icd(14) then
					UseInventoryItem(14)
				end
			end
			if p[2] then
				if (p[2] == 0 or (uh and uh > p[2]*10000)) and checkSpellCooldown(L["Rapid Fire"]) then
					if p[6] ~= 1 or not anyRapidBuffed then
						CastSpellByName(L["Rapid Fire"])
						break
					end
				end
			end
			if p[5] then
				local raceSpellId = checkRaceSpell()
				if (p[5] == 0 or (uh and uh > p[5]*10000)) and raceSpellId then
					if ({UnitRace("player")})[2] ~= "Troll" or p[6] ~= 1 or not anyRapidBuffed then
						CastSpell(raceSpellId, "spell")
						break
					end
				end
			end
		end
		break
	end

	if HunterBiuBiu.db.profile.howl then
		howl()
	end

	if HunterBiuBiu.db.profile.lightningbreath then
		HunterBiuBiu.StayLightningBreath()
	end

	local spd = HunterBiuBiu.lastSwingTime
	local ac1, ac2 = HunterBiuBiu:AllowCast(), HunterBiuBiu:AllowSecondCast()
	local allowMultishot = not ignoreMultishot and HunterBiuBiu.db.profile.multishot and checkSpellCooldown(L["Multi-Shot"])

	-- startAutoshot()

	local keepPolicy = function ()
		if spd > HunterBiuBiu.tv1 then
			y1()
		elseif spd > HunterBiuBiu.tv2 then
			y2()
		else
			y3()
		end
	end

	if ac1 then
		-- 判断强制使用多重
		if not ignoreMultishot
		and HunterBiuBiu.db.profile.multishot then
			local multishotCooldownCompleteTime = getSpellCooldownCompleteTime(L["Multi-Shot"])

			if HunterBiuBiu.db.profile.multishotfirst
			and HunterBiuBiu.db.profile.multishotfirstlimit
			and nextShotTime then
				if multishotCooldownCompleteTime
					and multishotCooldownCompleteTime > 0
					and nextShotTime - multishotCooldownCompleteTime >= HunterBiuBiu.db.profile.multishotfirstlimit then
					-- 等待多重cd好打多重
					return
				end
			end

			if HunterBiuBiu.db.profile.multishotfirst
			and multishotCooldownCompleteTime == 0 then
				castMultishot(p[7])
				return
			end
		end





		if HunterBiuBiu.db.profile.aimedshot and checkRapid(3, 1.65) and checkSpellCooldown(L["Aimed Shot"]) == true then
			-- 瞄准开启、cd好了、急速buff中
			castAimshot()
		else
			if (spd <= HunterBiuBiu.tv2 or yz == 3) and allowMultishot then
				castMultishot(p[7])
				keepPolicy()
			else
				castSteadyshot()
				keepPolicy()
			end
		end
	elseif ac2 and not checkGCD() then
		if ac2 == 1 then
			if HunterBiuBiu.db.profile.aimedshot and lastAimTime ~= nil  then
				return
			else
				if (spd > HunterBiuBiu.tv2 or yz == 1 or yz == 2) and allowMultishot then
					castMultishot(p[7])
				elseif (spd > HunterBiuBiu.tv1 or yz == 1) then
					castSteadyshot()
				end
			end
		elseif ac2 == 2 then
			-- 见缝插针使用第二技能
			if allowMultishot then
				castMultishot(p[7])
			elseif HunterBiuBiu.db.profile.secondspellserpent and allowSerpent() then
				CastSpellByName(L["Serpent Sting"])
			elseif HunterBiuBiu.db.profile.secondspellarcane and checkSpellCooldown(L["Arcane Shot"]) then
				if UnitMana("player") > HunterBiuBiu.db.profile.secondspellarcanelimit then
					CastSpellByName(L["Arcane Shot"])
				else
					CastSpellByName(L["Arcane Shot"].."("..L["Level"].." 1)")
				end
			end
		end
	end
end

function HunterBiuBiu:CheckAction()
	if getActionText(self.steadyshotActionId) ~= L["Steady Shot"] then
		return false
	end
	if getActionText(self.multishotActionId) ~= L["Multi-Shot"] then
		return false
	end
	if getActionText(self.autoshotActionId) ~= L["Auto Shot"] then
		return false
	end

	return true
end

function HunterBiuBiu:CheckActionSlots()
	if not self:CheckAction() then
		self:SystemMessage(L["Action Slots Erorr"])
	end
end

function HunterBiuBiu:ToggleCastMultishot(b)
	local oldv, v = HunterBiuBiu.db.profile.multishot
	if b == nil then
		v = not HunterBiuBiu.db.profile.multishot
	else
		v = b and true or false
	end

	if oldv ~= v then
		HunterBiuBiu.db.profile.multishot = v
		self.castMultishot = v;
		self:SystemMessage(v and L["MultiOn"] or L["MultiOff"])
	end
end

function HunterBiuBiu:ToggleCastAimedshot(b)
	local oldv, v = HunterBiuBiu.db.profile.aimedshot
	if b == nil then
		v = not HunterBiuBiu.db.profile.aimedshot
	else
		v = b and true or false
	end

	if oldv ~= v then
		HunterBiuBiu.db.profile.aimedshot = v
		self.castAimedshot = v;
		self:SystemMessage(v and L["AimOn"] or L["AimOff"])
	end
end

function HunterBiuBiu:CastOnMouseover(spellName, stopIfUnitNotExists)
	return localCastOnMouseOver(spellName, stopIfUnitNotExists)
end

function HunterBiuBiu:InSwing(offset)
	if not offset then
		offset = 0
	end
	if offset > 0  then
		-- 最多允许0.5秒偏移，即前摇时间往前推0.5秒
		offset = math.max(offset, 0.5)
	end

	return not nextSwingStart or (GetTime() + offset) > nextSwingStart
end

-----------------------------------------------------------
-- 射击条 --
local lastlock,autoshotlocked,autoshotRestoreTime = false,false

function HunterBiuBiu.HideAutoshotBar()
	if not HunterBiuBiu.db.profile.autoshotbar or not HunterBiuBiu.db.profile.autoshotbarshow then
		HbbAutoBar:Hide()
	end
end

function HunterBiuBiu:ResetAutoshotBar()
	HunterBiuBiu.db.profile.autoshotbarr1 = self.defaults.profile.autoshotbarr1
	HunterBiuBiu.db.profile.autoshotbarg1 = self.defaults.profile.autoshotbarg1
	HunterBiuBiu.db.profile.autoshotbarb1 = self.defaults.profile.autoshotbarb1
	HunterBiuBiu.db.profile.autoshotbarr2 = self.defaults.profile.autoshotbarr2
	HunterBiuBiu.db.profile.autoshotbarg2 = self.defaults.profile.autoshotbarg2
	HunterBiuBiu.db.profile.autoshotbarb2 = self.defaults.profile.autoshotbarb2
	HunterBiuBiu.db.profile.autoshotbarw = self.defaults.profile.autoshotbarw
	HunterBiuBiu.db.profile.autoshotbarh = self.defaults.profile.autoshotbarh
	HunterBiuBiu.db.profile.autobarx = GetScreenWidth() / 2 - 100
	HunterBiuBiu.db.profile.autobary = (GetScreenHeight() / 2 - 10) * -1

	HbbAutoBar:ClearAllPoints()
	HbbAutoBar:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", HunterBiuBiu.db.profile.autobarx, HunterBiuBiu.db.profile.autobary)
	self:UpdateAutoshotBarColor()
	self:UpdateAutoshotBarW()
	self:UpdateAutoshotBarH()
end

function HunterBiuBiu:UpdateAutoshotBarVisible()
	if HunterBiuBiu.db.profile.autoshotbar then
		if not HbbAutoBar:IsVisible() then
			HbbAutoBar:Show()
			-- if not self:IsEventScheduled("HBB_ON_UPDATE") then
			-- 	self:ScheduleRepeatingEvent("HBB_ON_UPDATE", self.HBB_ON_UPDATE, 0, self)
			-- end
		end
	else
		self:HideAutoshotBar()
		-- self:CancelScheduledEvent("HBB_ON_UPDATE")
	end
end

function HunterBiuBiu:UpdateAutoshotBarColor()
	if HunterBiuBiu.db.profile.autoshotbartemp == 's2cc2s' then
		if HbbAutoBar.Texture:GetPoint(1) == "LEFT" then
			HbbAutoBar.Texture:ClearAllPoints();
			HbbAutoBar.Texture:SetPoint("CENTER",HbbAutoBar,"CENTER")
			HbbAutoBar.Texture2:ClearAllPoints();
			HbbAutoBar.Texture2:SetPoint("CENTER",HbbAutoBar,"CENTER")
		end
	else
		if HbbAutoBar.Texture:GetPoint(1) == "CENTER" then
			HbbAutoBar.Texture:ClearAllPoints();
			HbbAutoBar.Texture:SetPoint("LEFT",HbbAutoBar,"LEFT")
			HbbAutoBar.Texture2:ClearAllPoints();
			HbbAutoBar.Texture2:SetPoint("LEFT",HbbAutoBar,"LEFT")
		end
	end

	if HunterBiuBiu.db.profile.autoshotbartext then
		HbbAutoBar.Text:Show()
	else
		HbbAutoBar.Text:Hide()
	end
	if HunterBiuBiu.db.profile.autoshotbartmr then
		HbbAutoBar.Tmr:Show()
	else
		HbbAutoBar.Tmr:Hide()
	end

	if HbbAutoBar.st then
		if GetTime() < HbbAutoBar.et - SWING_TIME then
			HbbAutoBar.Texture:SetTexture(HunterBiuBiu.db.profile.autoshotbarr1, HunterBiuBiu.db.profile.autoshotbarg1, HunterBiuBiu.db.profile.autoshotbarb1, 0.9)
		else
			HbbAutoBar.Texture:SetTexture(HunterBiuBiu.db.profile.autoshotbarr2, HunterBiuBiu.db.profile.autoshotbarg2, HunterBiuBiu.db.profile.autoshotbarb2, 0.9)
		end
	end
end

function HunterBiuBiu:StartAutoshotTimer(startAutoRepeat)

	-- todo 重置读条
	if HbbAutoBar:IsVisible() then
		self:HideAutoshotBar()
	end

	if not HunterBiuBiu.db.profile.autoshotbar then return end
	lastlock = false
	autoshotlocked = false
	autoshotRestoreTime = nil
	local _, _, latencyAb = GetNetStats()
	local rangeAttackSpeed = self.lastSwingTime;
	local swingTimeLeft = SWING_TIME

	if not nextShotTime then
		swingTimeLeft = 0.5
	elseif GetTime() > nextShotTime then
		swingTimeLeft = SWING_TIME - (GetTime() - nextShotTime)
		if swingTimeLeft < 0.5 then
			swingTimeLeft = 0.5
		end
	end

	if not nextShotTime or GetTime() > nextShotTime then
		rangeAttackSpeed = UnitRangedDamage("player")
	end

	local ttime = GetTime()
	if startAutoRepeat then
		if not (HbbAutoBar.et and GetTime() < HbbAutoBar.et) then
			HbbAutoBar.st = ttime - rangeAttackSpeed + swingTimeLeft -- - (latencyAb/1000)
			HbbAutoBar.et = ttime + swingTimeLeft
			HbbAutoBar.Text:SetText("自动射击 Biu~")
		end
	else
		HbbAutoBar.st = ttime - (latencyAb/1000)
		HbbAutoBar.et = ttime + rangeAttackSpeed
	end
	self:UpdateAutoshotBarColor();
	HbbAutoBar:SetAlpha(1)
	-- HbbAutoBar:ClearAllPoints()
	-- HbbAutoBar:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", HunterBiuBiu.db.profile.autobarx, HunterBiuBiu.db.profile.autobary)
	HbbAutoBar:Show()
end


function HunterBiuBiu:HBB_ON_UPDATE()
	if not self.swingtime or self.autobarMoving then return end
	local ttime,bartemp = GetTime(),HunterBiuBiu.db.profile.autoshotbartemp
	HbbAutoBar.ltt = ttime
	if not self.SwingStart and (ttime - lastshot) >= self.swingtime then
		if self.shooting and not self.casting then
			self.SwingStart = ttime
		else
			-- if not self.shooting then
			-- 	self:CancelScheduledEvent("HBB_ON_UPDATE")
			-- end
		end
	elseif self.SwingStart and self.moving then
		self.SwingStart = ttime
	end

	if not HunterBiuBiu.db.profile.autoshotbar or not HbbAutoBar.et then return end
	local locktime = 0.5
	local left, oleft, oleft2 = 0.00, 0.00

	oleft = HbbAutoBar.et - ttime
	oleft2 = HbbAutoBar.et - ttime
	left = floorNum(oleft, 1)
	if self.casting or self.moving then
		oleft = math.max(locktime, oleft)
		left = math.max(locktime, left)
		if left == locktime then
			autoshotlocked = true
			autoshotRestoreTime = nil
		end
	elseif autoshotlocked and not autoshotRestoreTime then
		autoshotRestoreTime = ttime
	end

	-- 绿色正读红色反读
	-- (Hbb_AutoTimer.et - ttime) - math.mod((Hbb_AutoTimer.et - ttime), 0.1) <= SWING_TIME
	self:UpdateAutoshotBarColor()
	local per,per2 = 0,0
	if ttime >= HbbAutoBar.et - SWING_TIME then
		if autoshotRestoreTime then
			oleft = locktime - (ttime - autoshotRestoreTime)
			left = floorNum(oleft, 1)
		end

		if oleft < 0 then
			oleft = 0
			left = 0
		end

		per = math.max(oleft / SWING_TIME, 0)

		if oleft2 >= self.lastSwingTime then
			per2 = 0
		else
			per2 = math.max(oleft2 / SWING_TIME, 0.001)
		end
		if per < 0.02 then
			HbbAutoBar.Texture:Hide()
		else
			HbbAutoBar.Texture:Show()
		end
		if per2 < 0.02 then
			HbbAutoBar.Texture2:Hide()
		else
			HbbAutoBar.Texture2:Show()
		end
		if bartemp == 'l2rl2r' or bartemp == 's2cc2s' then
			per = 1 - per
			per2 = 1 - per2
		end
	else
		HbbAutoBar.Texture:Show()
		HbbAutoBar.Texture2:Show()
		HbbAutoBar.Text:SetText("自动射击 "..floorNum(self.lastSwingTime, 2))
		per = math.min((ttime - HbbAutoBar.st) / (HbbAutoBar.et - SWING_TIME - HbbAutoBar.st), 1)
		if bartemp == 's2cc2s' then
			per = 1 - per
		end
		per2 = per
	end

	if left < 0 then
		left = 0
		self:HideAutoshotBar()
		-- self:CancelScheduledEvent("HBB_ON_UPDATE")
		return
	end

	HbbAutoBar.Texture:SetWidth(HunterBiuBiu.db.profile.autoshotbarw * per)
	HbbAutoBar.Texture2:SetWidth(HunterBiuBiu.db.profile.autoshotbarw * per2)
	HbbAutoBar.Tmr:SetText(left)
end


-----------------------------------------------------------

HbbShot = function(ignoreMultishot)
	HunterBiuBiu:HbbShot(ignoreMultishot)
end
ToggleHbbCastMultishot = function()
	HunterBiuBiu:ToggleCastMultishot()
end
HbbCastMultishotOn = function()
	HunterBiuBiu:ToggleCastMultishot(true)
end
HbbCastMultishotOff = function()
	HunterBiuBiu:ToggleCastMultishot(false)
end
ToggleHbbCastAimedShot = function()
	HunterBiuBiu:ToggleCastAimedShot()
end
HbbCastAimedShotOn = function()
	HunterBiuBiu:ToggleCastAimedShot(true)
end
HbbCastAimedShotOff = function()
	HunterBiuBiu:ToggleCastAimedShot(false)
end

HbbCastMouseover = function(a, b)
	HunterBiuBiu:CastOnMouseover(a, b)
end

SlashCmdList["HBBSHOT"] = HbbShot
SLASH_HBBSHOT1 = "/hbbshot"
SlashCmdList["HBBMULTI"] = ToggleHbbCastMultishot
SLASH_HBBMULTI1 = "/hbbmulti"
SlashCmdList["HBBMULTION"] = HbbCastMultishotOn
SLASH_HBBMULTION1 = "/hbbmultion"
SlashCmdList["HBBMULTIOFF"] = HbbCastMultishotOff
SLASH_HBBMULTIOFF1 = "/hbbmultioff"
SlashCmdList["HBBAIM"] = ToggleHbbCastAimedShot
SLASH_HBBAIM1 = "/hbbaim"
SlashCmdList["HBBAIMON"] = HbbCastAimedShotOn
SLASH_HBBAIMON1 = "/hbbaimon"
SlashCmdList["HBBAIMOFF"] = HbbCastAimedShotOff
SLASH_HBBAIMOFF1 = "/hbbaimoff"

--test