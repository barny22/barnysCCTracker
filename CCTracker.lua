local EM = EVENT_MANAGER
CCTracker = {
	["name"] = "barnysCCTracker",
	["version"] = {
		["patch"] = 1,
		["major"] = 1,
		["minor"] = 0,
	},
	["menu"] = {},
	["SV"] = {},
	["activeEffects"] = {},
	["status"] = {
		["alive"] = 0,
		["immunityToImmobilization"] = false,
		["zone"] = "",
	},
	["ccActive"] = {},
	["UI"] = {},
	["couldBeRoot"] = {},
	["couldJustBeSnare"] = {},
}

local function OnAddOnLoaded(eventCode, addOnName)
    --Check if that is your addons on Load, if not quit
    if(addOnName ~= CCTracker.name) then return end
 
    --Unregister Loaded Callback
    EM:UnregisterForEvent(CCTracker.name, EVENT_ADD_ON_LOADED)
 
    --create the default table
    --create the saved variable access object here and assign it to savedVars
	local worldName = GetWorldName()
	CCTracker.SV = ZO_SavedVars:NewCharacterIdSettings("CCTrackerSV", 1, nil, CCTracker.DEFAULT_SAVED_VARS, worldName)
	if CCTracker.SV.global then
		CCTracker.SV = ZO_SavedVars:NewAccountWide("CCTrackerSV", 1, nil, CCTracker.DEFAULT_SAVED_VARS, worldName)
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
		CCTracker:HandleLibChatMessage()
		LibChatMessage:RegisterCustomChatLink("CC_ABILITY_IGNORE_LINK", function(linkStyle, linkType, name, id, zone, displayText)
			return ZO_LinkHandler_CreateLinkWithBrackets(displayText, nil, "CC_ABILITY_IGNORE_LINK", name, id, zone)
		end)
		CCTracker:InitLinkHandler()
	else 
		self:SetAllDebugFalse()
	end
	if NonContiguousCount(self.SV.additionalRoots) > 0 then
		self:PrintDebug("additionalRootList", "Importing additional root abilities to constants")
		for i = #self.SV.additionalRoots, 1, -1 do
			local rId = self.SV.additionalRoots[i]
			local inPossibleList, num = self:AbilityInList(rId, self.constants.possibleRoots)
			local inRootList, _ = self:AbilityInList(rId, self.constants.definiteRoots)
			local inSnaresList, _ = self:AbilityInList(rId, self.constants.definiteSnares)
			if inPossibleList then
				table.remove(self.constants.possibleRoots, num)
			end
			if not inRootList and not inSnaresList then
				table.insert(self.constants.definiteRoots, rId)
			else
				self:PrintDebug("additionalRootList", "Deleting skill "..rId..": "..self:CropZOSString(GetAbilityName(rId)).." from additional roots. Already in definite list")
				table.remove(self.SV.additionalRoots, i)
			end
		end
	end
	
	if NonContiguousCount(self.SV.actualSnares) > 0 then
		self:PrintDebug("actualSnares", "Deleting snares from possible root constants and cleaning up actual snares list")
		for i = #self.SV.actualSnares, 1, -1 do
			local sId = self.SV.actualSnares[i]
			local inPossibleList, num = self:AbilityInList(sId, self.constants.possibleRoots)
			local inSnaresList, _ = self:AbilityInList(sId, self.constants.definiteSnares)
			local inRootList, _ = self:AbilityInList(sId, self.constants.definiteRoots)
			if inPossibleList then
				table.remove(self.constants.possibleRoots, num)
			end
			if not inSnaresList and not inRootList then
				table.insert(self.constants.definiteSnares, sId)
			else
				self:PrintDebug("actualSnares", "Deleting skill "..sId..": "..self:CropZOSString(GetAbilityName(sId)).." from actual snares. Already in definite list")
				table.remove(self.SV.actualSnares, i)
			end
		end
	end
	
	self.started = true
	
	self.status.alive = GetFrameTimeMilliseconds()
	-- self.status.zone = GetUnitZone("player")
	
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
	
	self.UI.SetUnlocked(self.SV.settings.unlocked)
	self.UI.HideLiveCCWindow(self.SV.debug.activeCCList)
	self.UI.FadeScenes("UI")
	self:BuildMenu()
	self:CCChanged()
	
	self:CheckForCCRegister()
end

	-----------------------------
	---- Register/Unregister ----
	-----------------------------

function CCTracker:CheckForCCRegister()
	for _, check in pairs(self.SV.settings.tracked) do
		if check == true then
			self:Register()
			break
		end
	end
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
	-- EM:RegisterForEvent(
		-- self.name.."PlayerDeactivated",
		-- EVENT_PLAYER_DEACTIVATED,
		-- function()
			-- Clear all CC when player is deactivated
			-- if NonContiguousCount(CCTracker.ccActive) > 0 then
				-- for _, entry in ipairs(CCTracker.ccActive) do
					-- entry = nil
				-- end
				-- CCTracker:CCChanged()
			-- end
		-- end
	-- )
	EM:RegisterForEvent(
		self.name.."PlayerActivated",
		EVENT_PLAYER_ACTIVATED,
		function()
			CCTracker:UpdateZone()
		end
	)
	EM:RegisterForEvent(
		self.name.."ZoneChanged",
		EVENT_ZONE_CHANGED,
		function(e,zName,_,_,zId,sZId)
		-- EVENT_ZONE_UPDATE,
		-- function(e, tag, zName)
			CCTracker:UpdateZone(zId)
			-- CCTracker:PrintDebug("enabled", zName)
			-- if self.status.zone == zName then
				-- return
			-- else
				-- self.status.zone = zName 
				-- if NonContiguousCount(CCTracker.ccActive) then
					-- local ccChanged = false
					-- local time = GetFrameTimeMilliseconds()
					-- local cache = {}
					-- for _, entry in ipairs(CCTracker.ccActive) do
						-- if entry.endTime ~= 0 then
							-- table.insert(cache, entry)
						-- else
							-- ccChanged = true
							-- if entry.isSubeffect then CCTracker:ClearSubeffects(entry.id, time) end
						-- end
					-- end
					-- if ccChanged then
						-- CCTracker.ccActive = cache
						-- CCTracker:CCChanged()
						-- CCTracker:PrintDebug("enabled", "Zone was changed. Cleared all active CC effects that are not debuffs")
					-- end
				-- end
			-- end
		end
	)
	EM:RegisterForEvent(
		self.name.."PlayerAlive",
		EVENT_PLAYER_ALIVE,
		function()
			self.status.alive = GetFrameTimeMilliseconds()
		end
	)
	EM:RegisterForEvent(
		self.name.."PlayerDead",
		EVENT_PLAYER_DEAD,
		function()
			CCTracker.status.alive = 0
			-- Clear all CC when player dies
			if NonContiguousCount(CCTracker.ccActive) > 0 then
				local time = GetFrameTimeMilliseconds()
				for _, entry in ipairs(CCTracker.ccActive) do
					if entry.isSubeffect then CCTracker:ClearSubeffects(entry.id, time) end
					entry = nil
				end
				CCTracker:CCChanged()
			end
		end
	)
	EM:RegisterForEvent(
		self.name.."WeaponPairLockChanged",
		EVENT_WEAPON_PAIR_LOCK_CHANGED,
		function(e, isLocked)
			--clear knockbacks if not isLocked
			if CCTracker.ccVariables[17].active and not isLocked then
				local cache = {}
				local time = GetFrameTimeMilliseconds()
				for _, entry in ipairs(CCTracker.ccActive) do
					if entry.type ~= 17 then
						table.insert(cache, entry)
					elseif entry.isSubeffect then
						self:ClearSubeffects(entry.id, time)					
					end
				end
				CCTracker.ccActive = cache
				CCTracker:CCChanged()
				-- self:PrintDebug("enabled", "Eliminated knockbacks")
			end
		end
	)
	
	self.registered = true
end

function CCTracker:Unregister()
	EM:UnregisterForEvent(
		self.name.."CombatEvents")
		
	EM:UnregisterForEvent(
		self.name.."EffectsChanged")
		
	EM:UnregisterForEvent(
		self.name.."PlayerAlive")
	
	EM:UnregisterForEvent(
		self.name.."PlayerActivated")
	
	-- EM:UnregisterForEvent(
		-- self.name.."PlayerDeactivated")
	
	EM:UnregisterForEvent(
		self.name.."ZoneChanged")
	
	EM:UnregisterForEvent(
		self.name.."PlayerDead")
	
	EM:UnregisterForEvent(
		self.name.."WeaponPairLockChanged")
	
	self.registered = false
end

function CCTracker:HandleCombatEvents	(_, res,  err,	aName, _, _, sName, _, tName, 
										 _,	hVal, 	_,		_, _, _, 	_, aId,   _)
	local aName = self:CropZOSString(aName)
	
	----------------------------------------
	-- useful debug section do not delete!--
	----------------------------------------
	
	-- local checkInList, k = self:AbilityInList(aId, self.couldJustBeSnare)
	-- if checkInList and GetFrameTimeMilliseconds() == self.couldJustBeSnare[k].time then
		-- self:PrintDebug("actualSnares", "Root in list "..aId..": "..aName.." - "..res)
	-- end
	
	local time = GetFrameTimeMilliseconds()
	if self.status.alive == 0 or self.status.alive == time then
		return
	elseif self:CropZOSString(tName) == self.currentCharacterName then
		if aId == self.constants.breakFree and self.currentCharacterName == self:CropZOSString(sName) and self:DoesBreakFreeWork() then			-- remove stuns, fear and charm if player breaks free
			self:BreakFreeDetected()
			return
		elseif aId == self.constants.rollDodge.abilityId and self.currentCharacterName == self:CropZOSString(sName) and res == ACTION_RESULT_EFFECT_GAINED then	-- remove roots when player uses dodgeroll
			self:RolldodgeDetected()
			return
		elseif self.constants.ignore[aId] or self.SV.ignored[aId] then
			self:PrintDebug("ignoreList", "Ignored CC from ignore-list "..aId..": "..aName)
			return
		end	
		
		self:ClearOutdatedLists(time, "Combat events")
		
		if res == ACTION_RESULT_EFFECT_FADED then
			if aId == self.constants.rollDodge.buffId then
				self.status.immunityToImmobilization = false
				return
			elseif self.activeEffects[aId] and self.activeEffects[aId].subeffects then
				for _, id in ipairs(self.activeEffects[aId].subeffects) do
					local inActiveList, number = self:AbilityInList(id, self.ccActive)
					if inActiveList then
						self:SnareRootCheck(id, number, aName)
						
						-----------------------------------------------------------------------------
						-- removing ability from all possible subeffects it may have been saved to --
						-----------------------------------------------------------------------------
						if self.ccActive[number].isSubeffect then self:ClearSubeffects(id, time) end
						
						table.remove(self.ccActive, number)
						self:CCChanged()
						self:PrintDebug("ccActive", "Removing ability "..self:CropZOSString(GetAbilityName(id)).." from ccActive list")
					end
				end
				self.activeEffects[aId] = nil
				self:PrintDebug("ccActive", "Cleared active effect "..aId.." - "..aName)
				return
			else
				local inList, num = self:AbilityInList(aId, self.ccActive)
				if inList then
					self:SnareRootCheck(aId, num, aName)
					if self.ccActive[num].isSubeffect then self:ClearSubeffects(aId, time) end
					table.remove(self.ccActive, num)
					self:CCChanged()
					self:PrintDebug("ccActive", "Removing ability "..aName.." from ccActive list")
					return
				end
			end
		elseif res == ACTION_RESULT_EFFECT_GAINED then
			if aId == self.constants.rollDodge.buffId then
				self.status.immunityToImmobilization = true
				return
			elseif not self.activeEffects[aId] then
				local newEffect = {["name"] = aName, ["time"] = time}
				self.activeEffects[aId] = newEffect
			end
			return
		elseif not err then
			if res == ACTION_RESULT_SNARED and not (self:AbilityInList(aId, self.constants.definiteSnares) or self:AbilityInList(aId, self.SV.actualSnares)) and CCTracker:IsRoot(aId) then
				res = 2480
				if self.status.immunityToImmobilization then
					self:PrintDebug("roots", "actualSnares", "Someone tried to root you, when you were immune to immobilization. What a foolish rookie mistake, it's probably just a snare though.")
					table.insert(self.SV.actualSnares, aId)
					local inList, num = self:AbilityInList(aId, self.SV.additionalRoots)
					if inList then
						table.remove(self.SV.additionalRoots, num)
					end
					return
				end
			end
			for ccType, check in pairs(self.ccVariables) do
				if check.res == res and check.tracked and not self.constants.exceptions[aId] then
					-- self:PrintDebug("ccCache", "Caching cc result")
					local isSubeffect = false
					for eId, entry in pairs(self.activeEffects) do
						-- self:PrintDebug("ccActive", "Checking for active effects at time: "..time)
						if entry.time == time then
							-- self:PrintDebug("ccActive", "Found active effect and will add "..aId.." to active effect "..eId)
							if not entry.subeffects then
								-- self:PrintDebug("ccActive", "Initializing subeffects for effect "..eId)
								entry.subeffects = {}
							end
							table.insert(entry.subeffects, aId)
							isSubeffect = true
							-- self:PrintDebug("ccActive", "Adding effect "..aId.." to subeffects for effect "..eId)
						end
					end
					
					-- trying direct import of abilities from combat events
					local newAbility = {
						["id"] = aId,
						["type"] = ccType,
						["startTime"] = time,
						["endTime"] = 0,
						["cacheId"] = 0,
						["isSubeffect"] = isSubeffect,
					}
					local inList, num = self:AbilityInList(aId, self.ccActive)
					if not inList then
						-- if not self:TypeInList(newAbility.type) then
						if not self.ccVariables[ccType].active then
							check.playSound = true
						end
						table.insert(self.ccActive, newAbility)
						self:PrintDebug("ccActive", "New cc from combat events "..aName.." - ID: "..aId.." - "..check.name)
						self.ccAdded.combatEvents = self.ccAdded.combatEvents + 1
						self:PrintDebug("ccAdded", "So far I've added "..self.ccAdded.combatEvents.." cc abilities from combatEvents and "..self.ccAdded.effectsChanged.." from effectsChanged")
						if check.playSound then self:CCChanged(check.playSound) end
					end
					--------------------------
					-- IGNORE CC CHAT LINKS --
					--------------------------
					if self.SV.settings.ccIgnoreLinks then
						self:PrintIgnoreLink(aName, aId)
					end
					break
				-- else
					-- if not self.ccCache then self.ccCache = {} end
					-- local newAbility = {["type"] = ccType, ["recorded"] = time, ["id"] = aId, ["name"] = aName}
					-- table.insert(self.ccCache, newAbility)
					-- self:PrintDebug("ccCache", "Caching ability "..aName.." ID: "..aId)
					-- break
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
		
	if not (unitTag == "player" or unitName == self.currentCharacterName) or not self.status.alive then
		return
	elseif self.SV.ignored[aId] or self.constants.ignore[aId] then
		self:PrintDebug("ignoreList", "Ignored CC from ignore-list "..aId..": "..self:CropZOSString(eName))
		return
	else
		local eName = self:CropZOSString(eName)
		local playCCSound = false
		local ccChanged = false
		local time = GetFrameTimeMilliseconds()
		
		self:ClearOutdatedLists(time, "Effect changed")
		
		if IsUnitDeadOrReincarnating("player") then
			if self.ccActive and next(self.ccActive) then
				for _, entry in ipairs(self.ccActive) do
					entry = nil
				end
				self:CCChanged()
			end
			return
		elseif changeType == EFFECT_RESULT_FADED or changeType == EFFECT_RESULT_ITERATION_END --[[or changeType == EFFECT_RESULT_TRANSFER]] then
			if aId == self.constants.rollDodge.buffId then
				self.status.immunityToImmobilization = false
				return
			end
			local inList, num = self:AbilityInList(aId, self.ccActive)
			if inList then
				self:SnareRootCheck(aId, num, eName)
				table.remove(self.ccActive, num)
				ccChanged = true
			end
		elseif changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_FULL_REFRESH or changeType == EFFECT_RESULT_ITERATION_BEGIN --[[or changeType == EFFECT_RESULT_UPDATED]] then
			if aId == self.constants.rollDodge.buffId then
				self.status.immunityToImmobilization = true
				return
			end
			local inList, num = self:AbilityInList(aId, self.ccActive)
			if inList then
				self.ccActive[num].endTime = endTime*1000
				self:PrintDebug("ccActive", "Adjusting endTime of ability "..aId.." - "..eName)
				self.ccAdded.endTimeUpdated = self.ccAdded.endTimeUpdated + 1
				self:PrintDebug("ccAdded", "Updated the endtime of "..self.ccAdded.endTimeUpdated.." cc abilities")
			else
				if abilityType == ABILITY_TYPE_SNARE and not (self:AbilityInList(aId, self.constants.definiteSnares) or self:AbilityInList(aId, self.SV.actualSnares)) and self:IsRoot(aId) then
					abilityType = "root"
					if self.status.immunityToImmobilization then
						self:PrintDebug("roots", "actualSnares", "Someone tried to root you, when you were immune to immobilization. That was a rookie mistake")
						table.insert(self.SV.actualSnares, aId)
						local inList, num = self:AbilityInList(aId, self.SV.additionalRoots)
						if inList then
							table.remove(self.SV.additionalRoots, num)
						end
						return
					end
				end
				if self.ccVariables[abilityType] and self.ccVariables[abilityType].tracked then
					local ending = ((endTime-beginTime~=0) and endTime) or 0
					local newAbility = {
						["id"] = aId,
						["type"] = abilityType,
						["startTime"] = time,
						["endTime"] = ending*1000
					}
					-- if self.ccCache and next(self.ccCache) then
						-- for i = #self.ccCache, 1, -1 do
							-- if self.ccCache[i].type == abilityType then
								-- newAbility.cacheId = self.ccCache[i].id
								-- table.remove(self.ccCache, i)
								-- self:PrintDebug("ccCache", "Clearing CC cache position "..i)
								-- break
							-- elseif self.ccCache and self.ccCache[i].type == "charm" and self.ccVariables.charm.tracked then
								-- newAbility.type = "charm"
								-- newAbility.cacheId = self.ccCache[i].id
								-- table.remove(self.ccCache, i)
								-- self:PrintDebug("ccCache", "Clearing CC cache position "..i..". Charm was detected")
								-- break
							-- end
						-- end
					-- else
						-- newAbility.cacheId = 0
					-- end
					-- if not self:TypeInList(newAbility.type) then
					if not self.ccVariables[abilityType].active then
						if self.SV.sound[self.ccVariables[abilityType].name].enabled then
							self.ccVariables[abilityType].playSound = true
							playCCSound = true
						end
						ccChanged = true
					end
					table.insert(self.ccActive, newAbility)
					self:PrintDebug("ccActive", "New cc "..eName.." - ID: "..newAbility.id.." - "..self.ccVariables[newAbility.type].name)
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
			-- if self.ccCache and next(self.ccCache) then
				-- local debugMessageSent = false
				-- for i = #self.ccCache, 1, -1 do
					-- inList, num = self:AbilityInList(self.ccCache[i].id, self.ccActive)
					-- if inList then
						-- self.ccActive[num].endTime = endTime*1000
						-- self:PrintDebug("ccActive", "Adjusting endTime of ability "..aId.." - "..self.ccCache[i].name)
					-- else
						-- local ending = ((endTime-beginTime~=0) and endTime) or 0
						-- local newAbility = {["id"] = aId, ["type"] = self.ccCache[i].type, ["endTime"] = ending*1000, ["cacheId"] = self.ccCache[i].id }
						-- if not self:TypeInList(newAbility.type) then
							-- if self.SV.sound[self.ccVariables[newAbility.type].name].enabled then
								-- self.ccVariables[newAbility.type].playSound = true
								-- playCCSound = true
							-- end
							-- ccChanged = true
						-- end
						-- table.insert(self.ccActive, newAbility)
						-- self:PrintDebug("ccActive", "ccCache", "New cc from cache "..self.ccCache[i].name.." - ID: "..self.ccCache[i].id.." - "..self.ccVariables[self.ccCache[i].type].name)
						-- self.ccAdded.effectsChanged = self.ccAdded.effectsChanged + 1
						-- self:PrintDebug("ccAdded", "So far I've added "..self.ccAdded.combatEvents.." cc abilities from combatEvents and "..self.ccAdded.effectsChanged.." from effectsChanged")
						--------------------
						-- IGNORE CC CHAT LINKS --
						--------------------
						-- if self.SV.settings.ccIgnoreLinks then
							-- self:PrintIgnoreLink(name, newAbility.cacheId)
						-- end
						-- if not debugMessageSent then
							-- self:PrintDebug("ccActive", "ccCache", "Adding "..i.." additional CC abilities from combat events")
							-- debugMessageSent = true
							-- self.debug:Print("CC ability detected from combat event. Clearing CC cache position "..i)
						-- end
					-- end
				-- end
				-- self.ccCache = {}
			-- end
			if ccChanged then self:CCChanged(playCCSound) end
		end
	end
end