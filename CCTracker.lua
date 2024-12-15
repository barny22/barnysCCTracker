local EM = EVENT_MANAGER
CCTracker = {
	["name"] = "barnysCCTracker",
	["version"] = {
		["patch"] = 1,
		["major"] = 0,
		["minor"] = 6,
	},
	["menu"] = {},
	["SV"] = {},
	["ccActive"] = {},
	["UI"] = {},
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
	
	if self.SV.additionalRoots and next(self.SV.additionalRoots) then
		self:PrintDebug("additionalRoots", "Importing additional root abilities to constants")
		for _, entry in ipairs(self.SV.additionalRoots) do
			table.insert(self.constants.possibleRoots, entry)
		end
	end
	
	self.started = true
	
	self.ccAdded = {["combatEvents"] = 0, ["effectsChanged"] = 0, ["endTimeUpdated"] = 0,}
	
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

function CCTracker:HandleCombatEvents	(_, res,  err,	aName, _, _, sName, _, tName, 
										 _,	hVal, 	_,		_, _, _, 	_, aId,   _)
	local name = self:CropZOSString(aName)
	if self:CropZOSString(tName) == self.currentCharacterName then
		if self.constants.ignore[aId] then
			-- self:PrintDebug("ccCache", "ccActive", "Ignored CC "..aId..": "..self.constants.ignore[aId])
			return
		elseif self.SV.ignored[aId] then
			self:PrintDebug("ignoreList", "Ignored CC from ignore-list "..aId..": "..name)
			return		
		end
		if aId == self.constants.breakFree and self.currentCharacterName == self:CropZOSString(sName) and self:DoesBreakFreeWork() then			-- remove stuns, fear and charm if player breaks free
			self:BreakFreeDetected()
			return
		elseif aId == self.constants.rollDodge and self.currentCharacterName == self:CropZOSString(sName) and res == ACTION_RESULT_EFFECT_GAINED then	-- remove roots when player uses dodgeroll
			self:RolldodgeDetected()
			return
		end		
		local time = GetFrameTimeMilliseconds()
		
		self:ClearOutdatedLists(time, "Combat events")
		
		if res == ACTION_RESULT_EFFECT_FADED then
			for i, check in ipairs(self.ccActive) do
				if check.cacheId == aId or check.id == aId then
								-- "snare"
					if check.type == 10 and self.couldBeRoot and next(self.couldBeRoot) then
						self:CheckForActualRoot(aId)
					end
					table.remove(self.ccActive, i)
					self.UI.ApplyIcons()
					self:PrintDebug("ccActive", "Removing ability "..name.." from ccActive list")
					-- break
				end
			end
			return
		end
		if res == ACTION_RESULT_SNARED then
			if CCTracker:IsPossibleRoot(aId) then res = 2480 end
		end
		for ccType, check in pairs(self.ccVariables) do
			if check.res == res and check.tracked and not self.constants.exceptions[aId] then
				-- self:PrintDebug("ccCache", "Caching cc result")
				
				-- trying direct import of abilities from combat events
				local newAbility = {}
				newAbility.id = aId
				if --[[self.SV.settings.advancedTracking and ]]self:CropZOSString(sName) ~= self.currentCharacterName and not err then
					newAbility.type = ccType
					newAbility.endTime = 0
					newAbility.cacheId = 0
					local ccChanged = false
					local inList, num = self:AbilityInList(aId, newAbility.cacheId)
					if not inList then
						if not self:TypeInList(newAbility.type) then
							ccChanged = true
						end
						table.insert(self.ccActive, newAbility)
						self:PrintDebug("ccActive", "New cc from combat events "..name.." - ID: "..aId.." - "..check.name)
						self.ccAdded.combatEvents = self.ccAdded.combatEvents + 1
						self:PrintDebug("ccAdded", "So far I've added "..self.ccAdded.combatEvents.." cc abilities from combatEvents and "..self.ccAdded.effectsChanged.." from effectsChanged")
					end
					if ccChanged then
						self.UI.ApplyIcons()
						if self.SV.sound[check.name].enabled then
							check.playSound = true
							self:PlayCCSound()
						end
					end
					--------------------------
					-- IGNORE CC CHAT LINKS --
					--------------------------
					if self.SV.settings.ccIgnoreLinks then
						self:PrintIgnoreLink(name, aId)
					end
					break
				else
					if not self.ccCache then self.ccCache = {} end
					local newAbility = {["type"] = ccType, ["recorded"] = time, ["id"] = aId, ["name"] = name}
					table.insert(self.ccCache, newAbility)
					self:PrintDebug("ccCache", "Caching ability "..name.." ID: "..aId)
					break
				end
			end
		end
	else return
	end
end

	--------------------------------
	---- Handle Effects Changed ----
	--------------------------------

function CCTracker:HandleEffectsChanged(_,changeType,_,eName,unitTag,beginTime,endTime,_,_,_,buffType,abilityType,_,unitName,_,aId,sType)
	--  self:PrintDebug("enabled", unitName.." - "..GetUnitName("player"))
	
	if not self.couldBeRoot then self.couldBeRoot = {} end	-- initialize "couldBeRoot" table
	
	if not (unitTag == "player" or unitName == self.currentCharacterName) then
		return
	elseif self.SV.ignored[aId] or self.constants.ignore[aId] then
		self:PrintDebug("ignoreList", "ccActvie", "Ignored CC from ignore-list "..aId..": "..self:CropZOSString(eName))
		return
	-- elseif aId == self.constants.dodgeRoll and sType == COMBAT_UNIT_TYPE_PLAYER and changeType == EFFECT_RESULT_UPDATED and self:TypeInList("root") then	-- remove roots if player uses dodgeroll
		-- self:RolldodgeDetected()
		-- self.UI.ApplyIcons()
		-- return
	else
		local playCCSound = false
		local time = GetFrameTimeMilliseconds()
		
		self:ClearOutdatedLists(time, "Effect changed")
		
		if IsUnitDeadOrReincarnating("player") then
			self.ccActive = {}
			self.UI.ApplyIcons()
			return
		elseif changeType == EFFECT_RESULT_FADED or changeType == EFFECT_RESULT_ITERATION_END --[[or changeType == EFFECT_RESULT_TRANSFER]] then
			for i, entry in ipairs(self.ccActive) do
				if entry.id == aId or entry.cacheId == aId then
								--	"snare"
					if entry.type == 10 and self.couldBeRoot and next(self.couldBeRoot) then
						self:CheckForActualRoot(entry.id)
					end
					table.remove(self.ccActive, i)
					-- self.ccVariables[entry.type].playSound = false
					-- break
					self:CCChanged()
				end
			end
		elseif changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_FULL_REFRESH or changeType == EFFECT_RESULT_ITERATION_BEGIN --[[or changeType == EFFECT_RESULT_UPDATED]] then
			local inList, num = self:AbilityInList(aId)
			local name = self:CropZOSString(eName)
			if inList then
				self.ccActive[num].endTime = endTime*1000
				self:PrintDebug("ccActive", "Adjusting endTime of ability "..aId.." - "..name)
				self.ccAdded.endTimeUpdated = self.ccAdded.endTimeUpdated + 1
				self:PrintDebug("ccAdded", "Updated the endtime of "..self.ccAdded.endTimeUpdated.." cc abilities")
			else
				if abilityType == ABILITY_TYPE_SNARE then
					if CCTracker:IsPossibleRoot(aId) then abilityType = "root" end
				end
				if self.ccVariables[abilityType] and self.ccVariables[abilityType].tracked then
					local ending = ((endTime-beginTime~=0) and endTime) or 0
					local newAbility = {["id"] = aId, ["type"] = abilityType, ["endTime"] = ending*1000}
					if self.ccCache and next(self.ccCache) then
						for i = #self.ccCache, 1, -1 do
							if self.ccCache[i].type == abilityType then
								newAbility.cacheId = self.ccCache[i].id
								table.remove(self.ccCache, i)
								self:PrintDebug("ccCache", "Clearing CC cache position "..i)
								break
							elseif self.ccCache and self.ccCache[i].type == "charm" and self.ccVariables.charm.tracked then
								newAbility.type = "charm"
								newAbility.cacheId = self.ccCache[i].id
								table.remove(self.ccCache, i)
								self:PrintDebug("ccCache", "Clearing CC cache position "..i..". Charm was detected")
								break
							end
						end
					else
						newAbility.cacheId = 0
					end
					if not self:TypeInList(newAbility.type) then
						if self.SV.sound[self.ccVariables[abilityType].name].enabled then
							self.ccVariables[abilityType].playSound = true
							playCCSound = true
						end
						self:CCChanged(playCCSound)
					end
					table.insert(self.ccActive, newAbility)
					self:PrintDebug("ccActive", "New cc "..name.." - ID: "..newAbility.id.." - "..self.ccVariables[newAbility.type].name)
					self.ccAdded.effectsChanged = self.ccAdded.effectsChanged + 1
					self:PrintDebug("ccAdded", "So far I've added "..self.ccAdded.combatEvents.." cc abilities from combatEvents and "..self.ccAdded.effectsChanged.." from effectsChanged")
					--------------------------
					-- IGNORE CC CHAT LINKS --
					--------------------------
					if self.SV.settings.ccIgnoreLinks then
						self:PrintIgnoreLink(name, newAbility.id)
					end
				end
			end
			if self.ccCache and next(self.ccCache) then
				local debugMessageSent = false
				for i = #self.ccCache, 1, -1 do
					inList, num = self:AbilityInList(self.ccCache[i].id)
					if inList then
						self.ccActive[num].endTime = endTime*1000
						self:PrintDebug("ccActive", "Adjusting endTime of ability "..aId.." - "..self.ccCache[i].name)
					else
						local ending = ((endTime-beginTime~=0) and endTime) or 0
						local newAbility = {["id"] = aId, ["type"] = self.ccCache[i].type, ["endTime"] = ending*1000, ["cacheId"] = self.ccCache[i].id }
						-- local inList, num = self:AbilityInList(aId, newAbility.cacheId)
						-- if not inList then
							if not self:TypeInList(newAbility.type) then
								if self.SV.sound[self.ccVariables[newAbility.type].name].enabled then
									self.ccVariables[newAbility.type].playSound = true
									playCCSound = true
								end
								self:CCChanged(playCCSound)
							end
							table.insert(self.ccActive, newAbility)
							self:PrintDebug("ccActive", "ccCache", "New cc from cache "..self.ccCache[i].name.." - ID: "..self.ccCache[i].id.." - "..self.ccVariables[self.ccCache[i].type].name)
							self.ccAdded.effectsChanged = self.ccAdded.effectsChanged + 1
							self:PrintDebug("ccAdded", "So far I've added "..self.ccAdded.combatEvents.." cc abilities from combatEvents and "..self.ccAdded.effectsChanged.." from effectsChanged")
					-- else
						-- self.ccActive[num].endTime = endTime*1000
						-- end
						--------------------------
						-- IGNORE CC CHAT LINKS --
						--------------------------
						if self.SV.settings.ccIgnoreLinks then
							self:PrintIgnoreLink(name, newAbility.cacheId)
						end
						if not debugMessageSent then
							self:PrintDebug("ccActive", "ccCache", "Adding "..i.." additional CC abilities from combat events")
							debugMessageSent = true
							-- self.debug:Print("CC ability detected from combat event. Clearing CC cache position "..i)
						end
					end
				end
				self.ccCache = {}
			end
		end
	end
end