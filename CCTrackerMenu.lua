CCTracker = CCTracker or {}
CCTracker.menu = {}

CCTracker.menu.constants = {
	{
		["Name"] = "Disoriented",
		["Icon"] = "/esoui/art/icons/ability_debuff_disorient.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 2340
	},
	{
		["Name"] = "Fear",
		["Icon"] = "/esoui/art/icons/ability_debuff_fear.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 15 --2320
	},
	{
		["Name"] = "Knockback",
		["Icon"] = "/esoui/art/icons/ability_debuff_knockback.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 2475
	}, 
	{
		["Name"] = "Levitate",
		["Icon"] = "/esoui/art/icons/ability_debuff_levitate.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 18 --2400
	},
	{
		["Name"] = "Offbalance",
		["Icon"] = "/esoui/art/icons/ability_debuff_offbalance.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 2440
	},
	-- {
		-- ["Name"] = "Root",
		-- ["Icon"] = "/esoui/art/icons/ability_debuff_root.dds",
		-- ["Dimensions"] = 35,
		-- ["Offset"] = -25,
		-- ["Id"] = 1 --2480
	-- },
	{
		["Name"] = "Silence",
		["Icon"] = "/esoui/art/icons/ability_debuff_silence.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 13 --2010
	},
	{
		["Name"] = "Snare",
		["Icon"] = "/esoui/art/icons/ability_debuff_snare.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 2 --2025
	},
	{
		["Name"] = "Stagger",
		["Icon"] = "/esoui/art/icons/ability_debuff_stagger.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 2470
	},
	{
		["Name"] = "Stun",
		["Icon"] = "/esoui/art/icons/ability_debuff_stun.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		-- ["Id"] = 19 --2020
	},
}

local function CreateCCCheckboxes()
	local CCCheckboxes = {}
	for i = 1, #self.menu.constants do
		local control = {}
		control.type = "checkbox"
		control.name = self.menu.constants[i].Name
		control.width = "half"
		control.default = false
		control.getFunc = function() return self.SV.settings.tracked[self.menu.constants[i].Name] end
		control.setFunc = function(value)
			self.SV.settings.tracked[self.menu.constants[i].Name] = value
			if value and not self.registered then
				self:Register()
			elseif not value and self.registered and not self:CheckForCombatEventsRegister() then
				self:Unregister()
			end
		end
		table.insert(CCCheckboxes, control)
	end
	return CCCheckboxes
end

local function CreateCCIcons(panel)
		if panel == self.name.."Options" then
			for i = 1, #self.menu.constants do
				local number = self:CreateMenuIconsPath(self.menu.constants[i].Name)
				self.menu.icons[i] = WINDOW_MANAGER:CreateControl(self.name.."MenuIcon"..i, panel.controlsToRefresh[number].checkbox, CT_TEXTURE)
				self.menu.icons[i]:SetAnchor(RIGHT, panel.controlsToRefresh[number].checkbox, LEFT, self.menu.constants[i].Offset, 0)
				self.menu.icons[i]:SetTexture(self.menu.constants[i].Icon)
				self.menu.icons[i]:SetDimensions(self.menu.constants[i].Dimensions, self.menu.constants[i].Dimensions)
			end
			CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CreateCCIcons(panel))
		end
	end

function CCTracker:BuildMenu()
	self.menu = self.menu or {}
	self.menu.icons = {}
	local CreateIcons = CreateCCIcons(panel)
	local CCCheckboxes = CreateCCCheckboxes()
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", CreateCCIcons(panel))
	
	self.menu.metadata = {
		type = "panel",
        name = "barnysCCTracker",
        displayName = "|ce11212b|c3645d6arny|rs|ce11212CC|rTracker",
        author = "|ce11212b|c3645d6arny|r",
        version = self.version.patch.."."..self.version.major.."."..self.version.minor,
		website = "https://www.esoui.com/downloads/info2373-selfGCDTracker.html",
		feedback = "https://www.esoui.com/portal.php?&id=386",
        slashCommand = "/bcc"
        registerForRefresh = true,
		registerForDefaults = true,
	}
	self.menu.options = {
		{
            type = "header",
            name = "Settings"
        },
        {
            type = "checkbox",
            name = "Account Wide",
            tooltip = "Check for account wide addon settings",
            getFunc = function() return self.SV.global end,
            setFunc = function(value) 
                if self.SV.global == value then return end

                if value then
                    self.SV.global = true
                    self.SV = ZO_SavedVars:NewAccountWide(self.name.."SV", 1, nil, self.DEFAULT_SAVED_VARS, GetWorldName())
                else
                    self.SV = ZO_SavedVars:NewCharacterIdSettings(self.name.."SV", 1, nil, CCTracker.DEFAULT_SAVED_VARS, GetWorldName())
                    self.SV.global = false
                end
                self.UI.ApplySize()
            end,
        },
		{
			type = "header",
			name = "CCs to track",
		},
		unpack(CCCheckboxes)
		{
			type = "header",
			name = "Debug section",
		},
        {	
			type = "checkbox",
            name = "Enable debugging",
            getFunc = function() return self.SV.debug.enabled end,
            setFunc = function(value)
                self.SV.debug.enabled = value
				if not value then
					self:SetAllDebugFalse()
				end
                -- self.log = value
            end
        },
		{	
			type = "checkbox",
			name = "Debug CCTracker ccCache",
			disabled = function() return not self.SV.debug.enabled end,
			getFunc = function() return self.SV.debug.ccCache end,
			setFunc = function(value)
				self.SV.debug.ccCache = value
				-- self.log = value
			end,
			-- width = "half",
		},
	}
end