CCTracker = CCTracker or {}

CCTracker.DEFAULT_SAVED_VARS = {
	["version"] = 1,
	["global"] = true,
	["UI"] = {
		["xOffsets"] = {
			["Disoriented"] = 0,
			["Fear"] = 50,
			["Knockback"] = 100,
			["Levitating"] = 150,
			["Offbalance"] = 200,
			["Silence"] = 250,
			["Snare"] = 300,
			["Stagger"] = 350,
			["Stun"] = 400,
		},
		["yOffsets"] = {
			["Disoriented"] = 0,
			["Fear"] = 0,
			["Knockback"] = 0,
			["Levitating"] = 0,
			["Offbalance"] = 0,
			["Silence"] = 0,
			["Snare"] = 0,
			["Stagger"] = 0,
			["Stun"] = 0,
		},
		["size"] = 50,
	},
	["settings"] = {
		["tracked"] = {},
		["unlocked"] = true,
	},
	["debug"] = {
		["enabled"] = false,
		["ccCache"] = false,
	},
}

	--------------------------
	---- Helper functions ----
	--------------------------

function CCTracker:AIdInList(aId)
	for i, entry in ipairs(self.ccActive) do
        if entry.id == aId then
            return true, i -- 'aId' wurde gefunden
        end
    end
    return false -- 'aId' wurde nicht gefunden
end

function CCTracker:ResInList(res, table)
	for _, entry in ipairs(table) do
        if entry == res then
            return true -- 'res' wurde gefunden
        end
    end
    return false -- 'res' wurde nicht gefunden
end

-- function CCTracker:NameInList(aName)
	-- for i, entry in ipairs(CCTracker.cc) do
        -- if entry[3] == aName then
            -- return true, i -- 'aName' wurde gefunden
        -- end
    -- end
    -- return false -- 'aName' wurde nicht gefunden
-- end

function CCTracker:IsUnlocked()
	for _, entry in pairs(self.variables) do
		if self.UI.indicator[entry.name].controls.tlw.IsUnlocked() then
			return true
		end
	end
	return false
end

function CCTracker:CreateMenuIconsPath(ControlName)
	local number = 0
	if barnysCCTrackerOptions then
		for i, entry in ipairs(barnysCCTrackerOptions.controlsToRefresh) do
			if ControlName == entry.data.name then
				number = i
			end
		end
	else return
	end
	return number
end

	---------------
	---- Debug ----
	---------------

function CCTracker:SetAllDebugFalse()
	for option, _ in pairs(self.SV.debug) do
		self.SV.debug[option] = false
	end
end