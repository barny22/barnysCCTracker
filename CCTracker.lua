local EM = EVENT_MANAGER
CCTracker = {
	["name"] = "barnysCCTracker",
	["version"] = {
		["patch"] = 1,
		["major"] = 0,
		["minor"] = 5,
	},
	["menu"] = {},
	["SV"] = {},
	["ccActive"] = {},
	["UI"] = {},
	["ignore"] = {
		[202995] = "IA",
		[203125] = "IA",
	}
}

local function OnAddOnLoaded(eventCode, addOnName)
    --Check if that is your addons on Load, if not quit
    if(addOnName ~= CCTracker.name) then return end
 
    --Unregister Loaded Callback
    EM:UnregisterForEvent(CCTracker.name, EVENT_ADD_ON_LOADED)
 
    --create the default table
    --create the saved variable access object here and assign it to savedVars
	CCTracker.SV = ZO_SavedVars:NewCharacterIdSettings("CCTrackerSV", 1, nil, CCTracker.DEFAULT_SAVED_VARS, GetWorldName())
	if CCTracker.SV.global then
		CCTracker.SV = ZO_SavedVars:NewAccountWide("CCTrackerSV", 1, nil, CCTracker.DEFAULT_SAVED_VARS, GetWorldName())
		CCTracker.SV.global = true
	end
	CCTracker:Init()
end
 
--Register Loaded Callback
EM:RegisterForEvent(CCTracker.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

ZO_CreateStringId("SI_BINDING_NAME_CCTRACKER_RESET", "Reset CCTracker")

function CCTracker:Init()
	if self.started then return end
	if LibChatMessage then
		CCTracker.debug = LibChatMessage("|c2a52beb|rarnys|c2a52beCC|rTracker", "|c2a52beBCC|r")
		LibChatMessage:RegisterCustomChatLink("CC_ABILITY_IGNORE_LINK", function(linkStyle, linkType, name, id, zone, displayText)
			return ZO_LinkHandler_CreateLinkWithBrackets(displayText, nil, "CC_ABILITY_IGNORE_LINK", name, id, zone)
		end)
		CCTracker:InitLinkHandler()
	else 
		self:SetAllDebugFalse()
	end
	
	self.started = true
	
	self.currentCharacterName = self:CropZOSString(GetUnitName("player"))
	self.ccVariables = {
		["charm"] = {["icon"] = "/esoui/art/icons/ability_u34_sea_witch_mindcontrol.dds", ["tracked"] = self.SV.settings.tracked.Charm, ["res"] = 3510, ["active"] = false, ["name"] = "Charm",}, --ACTION_RESULT_CHARMED
		[32] = {["icon"] = "/esoui/art/icons/ability_debuff_disorient.dds", ["tracked"] = self.SV.settings.tracked.Disoriented, ["res"] = 2340, ["active"] = false, ["name"] = "Disoriented",}, --ABILITY_TYPE_DISORIENT
		[27] = {["icon"] = "/esoui/art/icons/ability_debuff_fear.dds", ["tracked"] = self.SV.settings.tracked.Fear, ["res"] = 2320, ["active"] = false, ["name"] = "Fear",}, --ABILITY_TYPE_FEAR
		[17] = {["icon"] = "/esoui/art/icons/ability_debuff_knockback.dds", ["tracked"] = self.SV.settings.tracked.Knockback, ["res"] = 2475, ["active"] = false, ["name"] = "Knockback",}, --ABILITY_TYPE_KNOCKBACK
		[48] = {["icon"] = "/esoui/art/icons/ability_debuff_levitate.dds", ["tracked"] = self.SV.settings.tracked.Levitating, ["res"] = 2400, ["active"] = false, ["name"] = "Levitating",}, --ABILITY_TYPE_LEVITATE
		[53] = {["icon"] = "/esoui/art/icons/ability_debuff_offbalance.dds", ["tracked"] = self.SV.settings.tracked.Offbalance, ["res"] = 2440, ["active"] = false, ["name"] = "Offbalance",}, --ABILITY_TYPE_OFFBALANCE
		["root"] = {["icon"] = "/esoui/art/icons/ability_debuff_root.dds", ["tracked"] = self.SV.settings.tracked.Root, ["res"] = 2480, ["active"] = false, ["name"] = "Root",}, --ACTION_RESULT_ROOTED
		[11] = {["icon"] = "/esoui/art/icons/ability_debuff_silence.dds", ["tracked"] = self.SV.settings.tracked.Silence, ["res"] = 2010, ["active"] = false, ["name"] = "Silence",}, --ABILITY_TYPE_SILENCE
		[10] = {["icon"] = "/esoui/art/icons/ability_debuff_snare.dds", ["tracked"] = self.SV.settings.tracked.Snare, ["res"] = 2025, ["active"] = false, ["name"] = "Snare",}, --ABILITY_TYPE_SNARE
		[33] = {["icon"] = "/esoui/art/icons/ability_debuff_stagger.dds", ["tracked"] = self.SV.settings.tracked.Stagger, ["res"] = 2470, ["active"] = false, ["name"] = "Stagger",}, --ABILITY_TYPE_STAGGER
		[9] = {["icon"] = "/esoui/art/icons/ability_debuff_stun.dds", ["tracked"] = self.SV.settings.tracked.Stun, ["res"] = 2020, ["active"] = false, ["name"] = "Stun",}, --ABILITY_TYPE_STUN
	}
	
	self.UI = self:BuildUI()
	-- for _, entry in pairs(self.ccVariables) do self.UI.ApplySize(entry.name) end
	-- self.UI.ApplySize(self.SV.UI.size)
	self.UI.SetUnlocked(self.SV.settings.unlocked)
	self.UI.FadeScenes("UI")
	self:BuildMenu()
	if self:CheckForCCRegister() then
		self:Register()
	end
end

	-----------------------------
	---- Register/Unregister ----
	-----------------------------

function CCTracker:CheckForCCRegister()
	for _, check in pairs(self.SV.settings.tracked) do
		if check == true then
			return true
		end
	end
	return false
end

function CCTracker:Register()
	EM:RegisterForEvent(
		self.name.."CombatEvents",
		EVENT_COMBAT_EVENT,
		function(...)
			CCTracker:HandleCombatEvents(...)
		end
	)
	EM:RegisterForEvent(
		self.name.."EffectsChanged",
		EVENT_EFFECT_CHANGED,
		function(...)
			CCTracker:HandleEffectsChanged(...)
		end
	)
	self.registered = true
end

function CCTracker:Unregister()
	EM:UnregisterForEvent(
		self.name.."CombatEvents")
		
	EM:UnregisterForEvent(
		self.name.."EffectsChanged")
	
	self.registered = false
end

function CCTracker:HandleCombatEvents	(_,   res,  err, aName, aGraphic, aSlotType, sName, sType, tName, 
										tType, hVal, pType, dType, _, 		sUId, 	 tUId,  aId,   _     )
	if CCTracker.ignore[aId] then 
		if self.SV.debug.ccCache then self.debug:Print("Ignored CC in "..CCTracker.ignore[aId]..": "..CCTracker:CropZOSString(aName)) end
		return
	elseif CCTracker.SV.ignored[aId] then
		if self.SV.debug.ignoreList then self.debug:Print("Ignored CC from ignore-list "..aId..": "..CCTracker:CropZOSString(aName)) end
		return		
	end
	if self:CropZOSString(tName) == self.currentCharacterName then
		if res == ACTION_RESULT_EFFECT_FADED then
			if aId == 165424 then																							-- remove stun after using the arsenal to switch specs
				self.ccActive = {}
				self.UI.ApplyIcons()
				if self.SV.debug.ccCache then self.debug:Print("Removing all cc after using arsenal") end
				return
			end
			for i, check in ipairs(self.ccActive) do
				if check.cacheId and check.cacheId == aId then
					table.remove(self.ccActive, i)
					self.UI.ApplyIcons()
					if self.SV.debug.ccCache then self.debug:Print("Removing ability "..aName) end
					break
				end
			end
			return
		end
		if res == ACTION_RESULT_SNARED then
			if CCTracker:IsPossibleRoot(aId) then res = 2480 end
		end
		for ccType, check in pairs(self.ccVariables) do
			if check.tracked and check.res == res then
				if self.SV.debug.ccCache then self.debug:Print("Caching cc result") end
				self.ccCache = {}
				local newAbility = {["type"] = ccType, ["recorded"] = GetFrameTimeMilliseconds(), ["id"] = aId,}
				table.insert(self.ccCache, newAbility)
				if self.SV.debug.ccCache then self.debug:Print("Caching ability "..aName.." ID: "..aId) end
				break
			-- elseif check.tracked and check.name == "Root" and res == "ACTION_RESULT_SNARED" and self:IsPossibleRoot(aId) then
				-- self.ccCache = {}
				-- local newAbility = {["type"] = "root", ["recorded"] = GetFrameTimeMilliseconds(), ["id"] = aId,}
				-- table.insert(self.ccCache, newAbility)
				-- if self.SV.debug.ccCache then self.debug:Print("Caching ability "..aName) end
				-- break
			end
		end
	else return
	end
end

	--------------------------------
	---- Handle Effects Changed ----
	--------------------------------

function CCTracker:HandleEffectsChanged(_,changeType,_,eName,unitTag,beginTime,endTime,_,_,_,buffType,abilityType,_,unitName,_,aId,_)
	--  if self.SV.debug.enabled then self.debug:Print(unitName.." - "..GetUnitName("player")) end
	if not (unitTag == "player" or unitName == self.currentCharacterName) then
		return
	elseif CCTracker.SV.ignored[aId] then
		if self.SV.debug.ignoreList then self.debug:Print("Ignored CC from ignore-list "..aId..": "..CCTracker:CropZOSString(aName)) end
		return	
	else
		local playCCSound = false
		local time = GetFrameTimeMilliseconds()
		if IsUnitDeadOrReincarnating("player") then
			self.ccActive = {}
			self.UI.ApplyIcons()
			return
		elseif changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_FULL_REFRESH or changeType == EFFECT_RESULT_ITERATION_BEGIN --[[or changeType == EFFECT_RESULT_UPDATED]] then
			if abilityType == ABILITY_TYPE_SNARE then
				if CCTracker:IsPossibleRoot(aId) then abilityType = "root" end
			end
			if self.ccVariables[abilityType] and self.ccVariables[abilityType].tracked then
				local ending = ((endTime-beginTime~=0) and endTime) or 0
				local newAbility = {["id"] = aId, ["type"] = abilityType, ["endTime"] = ending*1000}
				if self.ccCache and self.ccCache[1].type == abilityType then
					newAbility.cacheId = self.ccCache[1].id
					self.ccCache = nil
					if self.SV.debug.ccCache then self.debug:Print("Clearing CC cache") end
				elseif self.ccCache and self.ccCache[1].type == "charm" and self.ccVariables.charm.tracked then
					newAbility.type = "charm"
					self.ccCache = nil
					if self.SV.debug.ccCache then self.debug:Print("Clearing CC cache. Charm was detected") end
				end
				local inList, num = self:AIdInList(aId)
				if not inList then
					self.ccChanged = true
					table.insert(self.ccActive, newAbility)
					if self.SV.sound[self.ccVariables[abilityType].name].enabled then
						self.ccVariables[abilityType].playSound = true
						playCCSound = true
					end
				else
					self.ccActive[num].endTime = endTime*1000
				end
				if self.SV.debug.enabled then self.debug:Print("New cc "..eName.." - ID: "..newAbility.id) end
				--------------------------
				-- IGNORE CC CHAT LINKS --
				--------------------------
				if self.SV.settings.ccIgnoreLinks then
					self.debug:Print("New cc ability detected "..self:CropZOSString(eName))
					self.debug:Print("Click |c2a52be|H1:CC_ABILITY_IGNORE_LINK:"..self:CropZOSString(eName)..":"..newAbility.id..":"..self:CropZOSString(GetUnitZone('player')).."|h[here]|h|r to ignore it in the future,")
					self.debug:Print("or ignore the ID: "..newAbility.id.." manually in the |c2a52be/bcc|r menu")
				end
			-- elseif self.ccVariables.root.tracked and abilityType == ABILITY_TYPE_SNARE and self:IsPossibleRoot(aId) then
				-- local ending = ((endTime-beginTime~=0) and endTime) or 0
				-- local newAbility = {["id"] = aId, ["type"] = "root", ["endTime"] = ending*1000}
				-- if self.ccCache and self.ccCache[1].type == "root" then
					-- newAbility.cacheId = self.ccCache[1].id
					-- self.ccCache = {}
					-- if self.SV.debug.ccCache then self.debug:Print("Clearing CC cache") end
				-- end
				-- local inList, num = self:AIdInList(aId)
				-- if not self:ResInList(abilityType) then
				-- if not inList then
					-- self.ccChanged = true
					-- table.insert(self.ccActive, newAbility)
				-- else
					-- self.ccActive[num].endTime = endTime*1000
				-- end
				-- if self.SV.debug.ccCache then self.debug:Print("New cc "..eName) end
			elseif self.ccCache and self.ccCache[1] and self.ccCache[1].recorded == time and not self.ccVariables[abilityType] then
				local ending = ((endTime-beginTime~=0) and endTime) or 0
				local newAbility = {["id"] = aId, ["type"] = self.ccCache[1].type, ["endTime"] = ending*1000, ["cacheId"] = self.ccCache[1].id }
				local inList, num = self:AIdInList(aId)
				if not inList then
					self.ccChanged = true
					table.insert(self.ccActive, newAbility)
					if self.SV.sound[self.ccVariables[abilityType].name].enabled then
						self.ccVariables[abilityType].playSound = true
						playCCSound = true
					end
				else
					self.ccActive[num].endTime = endTime*1000
				end
				if self.SV.debug.enabled then self.debug:Print("New cc from cache "..eName.." - ID: "..newAbility.cacheId) end
				--------------------------
				-- IGNORE CC CHAT LINKS --
				--------------------------
				if self.SV.settings.ccIgnoreLinks then
					self.debug:Print("New cc ability detected "..self:CropZOSString(eName))
					self.debug:Print("Click |c2a52be|H1:CC_ABILITY_IGNORE_LINK:"..self:CropZOSString(eName)..":"..newAbility.cacheId..":"..self:CropZOSString(GetUnitZone('player')).."|h[here]|h|r to ignore it in the future,")
					self.debug:Print("or ignore the ID: "..newAbility.cacheId.." manually in the |c2a52be/bcc|r menu")
				end
				self.ccCache = nil
				if self.SV.debug.ccCache then self.debug:Print("Clearing CC cache") end
			end
		elseif changeType == EFFECT_RESULT_FADED or changeType == EFFECT_RESULT_ITERATION_END --[[or changeType == EFFECT_RESULT_TRANSFER]] then
			for i, entry in ipairs(self.ccActive) do
				if entry.id == aId then
					table.remove(self.ccActive, i)
					self.ccVariables[entry.type].playSound = false
					self.ccChanged = true
					break
				end
			end
		end
		for i = #self.ccActive, 1, -1 do
			if self.ccActive[i].endTime ~= 0 then
				if self.ccActive[i].endTime < time then
					table.remove(self.ccActive, i)
					self.ccChanged = true
					-- if self.SV.debug.enabled then self.debug:Print("deleting entries in cc list") end
				end
			end
		end
		if self.ccChanged then
			if playCCSound then
				self:PlayCCSound()
			end
			self.UI.ApplyIcons()
		end
	end
end