local EM = EVENT_MANAGER
CCTracker = {
	["name"] = "barnysCCTracker",
	["version"] = {
		["patch"] = 1,
		["major"] = 0,
		["minor"] = 1,
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
	if global then
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
	if LibChatMessage then CCTracker.debug = LibChatMessage("barnysCCTracker", "BCC") end
	
	self.started = true
	
	self.currentCharacterName = GetUnitName("player")
	self.variables = {
		[32] = {["icon"] = "/esoui/art/icons/ability_debuff_disorient.dds", ["tracked"] = self.SV.settings.tracked.Disoriented, ["res"] = 2340, ["active"] = false, ["name"] = "Disoriented",}, --ABILITY_TYPE_DISORIENT
		[27] = {["icon"] = "/esoui/art/icons/ability_debuff_fear.dds", ["tracked"] = self.SV.settings.tracked.Fear, ["res"] = 2320, ["active"] = false, ["name"] = "Fear",}, --ABILITY_TYPE_FEAR
		[17] = {["icon"] = "/esoui/art/icons/ability_debuff_knockback.dds", ["tracked"] = self.SV.settings.tracked.Knockback, ["res"] = 2475, ["active"] = false, ["name"] = "Knockback",}, --ABILITY_TYPE_KNOCKBACK
		[48] = {["icon"] = "/esoui/art/icons/ability_debuff_levitate.dds", ["tracked"] = self.SV.settings.tracked.Levitating, ["res"] = 2400, ["active"] = false, ["name"] = "Levitating",}, --ABILITY_TYPE_LEVITATE
		[53] = {["icon"] = "/esoui/art/icons/ability_debuff_offbalance.dds", ["tracked"] = self.SV.settings.tracked.Offbalance, ["res"] = 2440, ["active"] = false, ["name"] = "Offbalance",}, --ABILITY_TYPE_OFFBALANCE
		-- ["rootPlaceholder"] = {["icon"] = "/esoui/art/icons/ability_debuff_root.dds", ["tracked"] = self.SV.settings.tracked.Root, ["res"] = 2480 ["active"] = false, ["name"] = "Rooted",}, --ACTION_RESULT_ROOTED
		[11] = {["icon"] = "/esoui/art/icons/ability_debuff_silence.dds", ["tracked"] = self.SV.settings.tracked.Silence, ["res"] = 2010, ["active"] = false, ["name"] = "Silence",}, --ABILITY_TYPE_SILENCE
		[10] = {["icon"] = "/esoui/art/icons/ability_debuff_snare.dds", ["tracked"] = self.SV.settings.tracked.Snare, ["res"] = 2025, ["active"] = false, ["name"] = "Snare",}, --ABILITY_TYPE_SNARE
		[33] = {["icon"] = "/esoui/art/icons/ability_debuff_stagger.dds", ["tracked"] = self.SV.settings.tracked.Stagger, ["res"] = 2470, ["active"] = false, ["name"] = "Stagger",}, --ABILITY_TYPE_STAGGER
		[9] = {["icon"] = "/esoui/art/icons/ability_debuff_stun.dds", ["tracked"] = self.SV.settings.tracked.Stun, ["res"] = 2020, ["active"] = false, ["name"] = "Stun",}, --ABILITY_TYPE_STUN
	}
	
	self.UI = self:BuildUI()
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
	if CCTracker:CheckForCCRegister() and tName == self.currentCharacterName and not err then
		if res == ACTION_RESULT_EFFECT_FADED then
			for i, check in pairs(self.ccActive) do
				if check.cacheId and check.cacheId == aId then
					table.remove(self.ccActive, i)
					self.UI.ApplyIcons()
					break
				end
			end
			return
		end
		for ccType, check in pairs(self.variables) do
			if check.tracked and check.res == res then
				-- d("caching cc ability")
				self.ccCache = {}
				local newAbility = {["type"] = ccType, ["recorded"] = GetFrameTimeMilliseconds(), ["id"] = aId,}
				table.insert(self.ccCache, newAbility)
				if self.SV.debug.ccCache then d("Caching ability "..aName) end
				break
			end
			return
		end
	else return
	end
end

	--------------------------------
	---- Handle Effects Changed ----
	--------------------------------

function CCTracker:HandleEffectsChanged(_,changeType,_,eName,unitTag,beginTime,endTime,_,_,_,buffType,abilityType,_,unitName,_,aId,_)
	-- d(unitName.." - "..GetUnitName("player"))
	time = GetFrameTimeMilliseconds()
	if not (unitTag == "player" or unitName == self.currentCharacterName) then
		return
	else
		-- self.currentBuffs = {}
		if IsUnitDeadOrReincarnating("player") then
			self.ccActive = {}
			self.UI.ApplyIcons()
			return
		elseif changeType == EFFECT_RESULT_UPDATED or changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_ITERATION_BEGIN or changeType == EFFECT_RESULT_FULL_REFRESH then
			if self.variables[abilityType] and self.variables[abilityType].tracked then
				local ending = ((endTime-beginTime~=0) and endTime) or 0
				local newAbility = {["id"] = aId, ["type"] = abilityType, ["endTime"] = ending*1000}
				if self.ccCache and self.ccCache[1].type == abilityType then newAbility.cacheId = self.ccCache[1].id end
				local inList, num = self:AIdInList(aId)
				-- if not self:ResInList(abilityType) then
				if not inList then
					self.ccChanged = true
					table.insert(self.ccActive, newAbility)
				else
					self.ccActive[num].endTime = endTime*1000
				end
				if self.SV.debug.ccCache then d("New cc "..eName) end
				-- end
			elseif self.ccCache and self.ccCache[1] and self.ccCache[1].recorded == time and not self.variables[abilityType] then
				local ending = ((endTime-beginTime~=0) and endTime) or 0
				local newAbility = {["id"] = aId, ["type"] = self.ccCache[1].type, ["endTime"] = ending*1000, ["cacheId"] = self.ccCache[1].id }
				local inList, num = self:AIdInList(aId)
				-- if not self:ResInList(self.ccCache[1][2]) then
				if not inList then
					self.ccChanged = true
					table.insert(self.ccActive, newAbility)
				else
					self.ccActive[num].endTime = endTime*1000
				end
				if self.SV.debug.ccCache then d("New cc from cache "..eName) end
				self.ccCache = {}
				if self.SV.debug.ccCache then d("Clearing CC cache") end
				-- end
			end
		elseif changeType == EFFECT_RESULT_FADED or changeType == EFFECT_RESULT_ITERATION_END or changeType == EFFECT_RESULT_TRANSFER then
			for i, entry in ipairs(self.ccActive) do
				if entry.id == aId then
					table.remove(self.ccActive, i)
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
					-- d("deleting entries in cc list")
				end
			-- else
				-- if not self.currentBuffs then
					-- for i = 1, GetNumBuffs() do
						-- local _, _, _, _, _, _, _, _, _, _, aId, _, _ = GetUnitBuffInfo("player", i)
						-- self.currentBuffs[aId] = true
					-- end
				-- end
				-- if not self.currentBuffs[self.ccActive[i].id] then
					-- table.remove(self.ccActive, i)
				-- end
			end
		end
	end
	if self.ccChanged then self.UI.ApplyIcons() end
end