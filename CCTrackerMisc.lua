local WM = WINDOW_MANAGER
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
			["Root"] = 450,
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
			["Root"] = 0,
		},
		["sizes"] = {
			["Disoriented"] = 50,
			["Fear"] = 50,
			["Knockback"] = 50,
			["Levitating"] = 50,
			["Offbalance"] = 50,
			["Silence"] = 50,
			["Snare"] = 50,
			["Stagger"] = 50,
			["Stun"] = 50,
			["Root"] = 50,
		},
		["size"] = 50,
		["alpha"] = 100,
	},
	["settings"] = {
		["tracked"] = {},
		["unlocked"] = true,
		["sample"] = false,
	},
	["debug"] = {
		["enabled"] = false,
		["ccCache"] = false,
		["chat"] = false,
	},
}

CCTracker.possibleRoots = {1856,5655,5656,5657,8373,8668,10896,14138,14467,14468,14469,16353,16668,18391,20253,20527,20528,20816,21114,21776,22004,23277,23402,23831,23916,23924,26118,26869,27145,27156,27167,27303,27304,27306,27307,27309,27311,28025,28308,29721,30083,30085,30087,30089,30092,30095,30218,30221,30224,31713,32685,33903,33912,33921,34183,34187,34578,35750,37001,38705,38984,38989,40372,40382,40769,40773,40777,40977,40988,40995,41000,41006,41013,42008,42706,42713,42720,42727,42737,42747,42757,42764,42771,45481,47084,47086,47109,47210,48287,49557,49630,50286,50287,50544,50981,52436,54795,54819,55485,56731,60790,60792,60798,60799,60801,64133,65892,65893,65894,67514,68564,70246,72208,73652,76423,76448,76449,79122,79124,79457,79459,80574,80812,80815,80821,80822,80823,80830,80831,80834,82054,82055,82318,84434,85128,86175,86176,86177,86178,86179,86180,86181,86182,86183,86184,86185,86186,86238,86506,86508,86510,86518,86520,86522,87236,87260,87264,87443,87560,88310,88462,88801,89680,89812,91224,91227,91246,91627,92038,92038,92039,92039,92058,92060,97002,97005,98637,99367,100420,101755,102008,102023,104196,104686,104688,104894,104897,104900,105011,105017,105232,105235,105286,105292,105293,105627,105641,105642,107238,107303,107305,107311,107312,110190,110916,110919,110920,110922,110923,110940,110965,110966,110968,110969,110970,110971,110975,110976,110977,110978,111346,111570,111571,111847,112131,112550,112763,113133,113261,113513,113566,114162,115177,116798,117133,118308,118352,119035,119068,124575,127193,127194,127226,127227,129348,129897,129907,137917,137918,141310,142962,146956,149956,149957,157747,160299,160301,160302,163569,165357,165363,165379,165871,167678,167683,169698,169701,171560,171566,171581,171582,171583,171584,171603,171742,171751,171752,171759,171760,171761,171789,171879,171880,172831,172833,174174,174455,174958,175540,175810,175811,176658,176659,176660,177194,177195,177196,177197,177564,177578,177595,178464,178566,178863,178864,178865,178875,178969,179089,179205,179413,179553,181211,182338,182401,183006,183401,185817,185823,187362,188624,188627,188678,188679,188680,188695,188696,188699,191568,193017,195893,198781,201973,201974,201978,201979,201980,201981,202047,202048,202049,202050,202075,202718,202725,202727,202728,202729,202777,203033,203034,203035,203036,203378,204176,204942,206265,206266,206296,206297,206298,206299,206762,206763,206764,206765,206766,207298,209479,209483,209884,209886,209891,209892,209894,209904,209905,209906,209907,209908,209910,209911,209912,209913,210053,210054,210107,210415,210417,210424,210433,210434,210435,210436,210460,210461,210477,214487,215348,215349,215350,215351,215358,215662,215663,215664,216393,216399,216972,217190,217208,217209,217529,217529,218162,218251,218252,218334,218335,219388,219407,219418,222594,222595,222597,222611,222612,222614,223477,20115177,20118308,20118352,20183006,20183401,20185817,20185823,20217190,30115177,30118308,30118352,30183006,30183401,30185817,30185823,30217190,40115177,40118308,40118352,40183006,40183401,40185817,40185823,40217190,}

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

function CCTracker:IsPossibleRoot(id)
	local time = GetFrameTimeMilliseconds()
	for _, check in ipairs(self.possibleRoots) do
		if check == id then
			if self.SV.debug.chat then self.debug:Print("Found possible root. It took "..tostring(GetFrameTimeMilliseconds()-time).."ms") end
			return true
		end
	end
	if self.SV.debug.chat then self.debug:Print("Checked for possible root, looked for "..tostring(GetFrameTimeMilliseconds()-time).."ms, didn't find anything interesting") end
	return false
end

-- function CCTracker:ResInList(res, table)
	-- for _, entry in ipairs(table) do
        -- if entry == res then
            -- return true -- 'res' wurde gefunden
        -- end
    -- end
    -- return false -- 'res' wurde nicht gefunden
-- end

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
	local number
	for i, entry in ipairs(barnysCCTrackerOptions.controlsToRefresh) do
		if ControlName == entry.data.name then
			number = i
		end
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