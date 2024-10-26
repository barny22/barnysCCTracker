local LAM = LibAddonMenu2
local WM = WINDOW_MANAGER
CCTracker = CCTracker or {}
CCTracker.menu = CCTracker.menu or {}
CCTracker.menu.icons = {}

CCTracker.menu.constants = {
	{
		["Name"] = "Disoriented",
		["Icon"] = "/esoui/art/icons/ability_debuff_disorient.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = 32 --2340
	},
	{
		["Name"] = "Fear",
		["Icon"] = "/esoui/art/icons/ability_debuff_fear.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = 27 --2320
	},
	{
		["Name"] = "Knockback",
		["Icon"] = "/esoui/art/icons/ability_debuff_knockback.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] =  17 --2475
	}, 
	{
		["Name"] = "Levitating",
		["Icon"] = "/esoui/art/icons/ability_debuff_levitate.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = 48 --2400
	},
	{
		["Name"] = "Offbalance",
		["Icon"] = "/esoui/art/icons/ability_debuff_offbalance.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] =  53 --2440
	},
	{
		["Name"] = "Root",
		["Icon"] = "/esoui/art/icons/ability_debuff_root.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = "root" --2480
	},
	{
		["Name"] = "Silence",
		["Icon"] = "/esoui/art/icons/ability_debuff_silence.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = 11 --2010
	},
	{
		["Name"] = "Snare",
		["Icon"] = "/esoui/art/icons/ability_debuff_snare.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = 10 --2025
	},
	{
		["Name"] = "Stagger",
		["Icon"] = "/esoui/art/icons/ability_debuff_stagger.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = 33 --2470
	},
	{
		["Name"] = "Stun",
		["Icon"] = "/esoui/art/icons/ability_debuff_stun.dds",
		["Dimensions"] = 35,
		["Offset"] = -25,
		["Id"] = 9 --2020
	},
}

local function CreateCCCheckboxes()
	local position
	for i, entry in ipairs(CCTracker.menu.options) do
		if entry.name == "CCs to track" then position = i break end
	end
	for i = 1, #CCTracker.menu.constants do
		local control = {}
		control.type = "checkbox"
		control.name = CCTracker.menu.constants[i].Name
		control.width = "half"
		control.default = false
		control.getFunc = function() return CCTracker.SV.settings.tracked[CCTracker.menu.constants[i].Name] end
		control.setFunc = function(value)
			CCTracker.SV.settings.tracked[CCTracker.menu.constants[i].Name] = value
			CCTracker.ccVariables[CCTracker.menu.constants[i].Id].tracked = value
			if value and not CCTracker.registered then
				CCTracker:Register()
			elseif not value and CCTracker.registered and not CCTracker:CheckForCCRegister() then
				CCTracker:Unregister()
			end
			if CCTracker.SV.settings.unlocked then CCTracker.UI.SetUnlocked(true) end
		end
		table.insert(CCTracker.menu.options, position+i, control)
	end
end

function CCTracker.menu.CreateIcons(panel)					-- Thanks to DakJaniels who came up with this solution
    if panel == barnysCCTrackerOptions then
        if CCTracker.SV.debug.enabled then
			CCTracker.debug:Print("Panel was created.")
			if CCTracker.menu.icons[1] then CCTracker.debug:Print("Menu Icons seem to have been initialized before") else CCTracker.debug:Print("Menu Icons have not been initialized yet") end
		end
        for i = 1, #CCTracker.menu.constants do
            local number = CCTracker:CreateMenuIconsPath(CCTracker.menu.constants[i].Name)
            CCTracker.menu.icons[i] = WM:CreateControl(CCTracker.name.."MenuIcon"..i, panel.controlsToRefresh[number].checkbox, CT_TEXTURE)
            CCTracker.menu.icons[i]:SetAnchor(RIGHT, panel.controlsToRefresh[number].checkbox, LEFT, CCTracker.menu.constants[i].Offset, 0)
            CCTracker.menu.icons[i]:SetTexture(CCTracker.menu.constants[i].Icon)
            CCTracker.menu.icons[i]:SetDimensions(CCTracker.menu.constants[i].Dimensions, CCTracker.menu.constants[i].Dimensions)
        end
        CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CCTracker.menu.CreateIcons)
        if CCTracker.SV.debug.enabled then CCTracker.debug:Print("Deleting LAM Callback") end
    else
        return
    end
end

function CCTracker:BuildMenu()
	
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", self.menu.CreateIcons)
	
	self.menu.metadata = {
		type = "panel",
        name = "barnysCCTracker",
        displayName = "|c2a52beb|rarnys|c2a52beCC|rTracker",
        author = "|c2a52beb|rarny",
        version = self.version.patch.."."..self.version.major.."."..self.version.minor,
		website = "https://www.esoui.com/downloads/info3971-barnysCCTracker.html",
		feedback = "https://www.esoui.com/portal.php?&id=386",
        slashCommand = "/bcc",
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
                    self.SV = ZO_SavedVars:NewCharacterIdSettings(self.name.."SV", 1, nil, self.DEFAULT_SAVED_VARS, GetWorldName())
                    self.SV.global = false
                end
                for _, entry in pairs(self.ccVariables) do self.UI.ApplySize(entry.name) end
            end,
        },
		{	
			type = "checkbox",
			name = "Unlock CCTracker",
			tooltip = "Reposition and resize icons by dragging the edges or the center.",
			disabled = function() return self.SV.settings.sample end,
			-- width = "half",
			getFunc = function() return self.SV.settings.unlocked end,
			setFunc = function(value) self.UI.SetUnlocked(value) end,
		},
		{	
			type = "checkbox",
			name = "Show sample",
			tooltip = "Gives you a sample icon so you can see the changes you're making, when adjusting size or alpha.",
			warning = "Only enabled in locked mode. This also disables unlocked mode.",
			disabled = function() return self.SV.settings.unlocked end,
			-- width = "half",
			getFunc = function() return self.SV.settings.sample end,
			setFunc = function(value)
				self.SV.settings.sample = value
				self.UI.indicator.Stun.controls.tlw:ClearAnchors()
				self.UI.indicator.Stun.controls.tlw:SetHidden(not value)
				self.UI.indicator.Stun.controls.icon:SetHidden(not value)
				self.UI.indicator.Stun.controls.frame:SetHidden(not value)
				if value then
					self.UI.indicator.Stun.controls.tlw:SetAnchor(RIGHT, GuiRoot, RIGHT, -GuiRoot:GetWidth()/8, 0)
					self.UI.FadeScenes("Unlocked")
				else
					self.UI.indicator.Stun.controls.tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.SV.UI.xOffsets.Stun, self.SV.UI.yOffsets.Stun)
					self.UI.FadeScenes("Locked")
				end
			end,
		},
		{
			type = "slider",
			name = "Icon size",
			warning = "If you change this ALL icons are being resized to the given size! ALL individual sizes will be overwritten!",
			default = 50,
			min = 20,
			max = 200,
			step = 1,
			getFunc = function() return self.SV.UI.size end,
			setFunc = function(value)
				self.SV.UI.size = value
				for _, entry in pairs(self.ccVariables) do
					self.SV.UI.sizes[entry.name] = value
					self.UI.ApplySize(entry.name)
				end
			end,
		},
		{
			type = "slider",
			name = "Icon alpha",
			tooltip = "The CC icons are too prominent for you? Simply adjust alpha with this slider to make them disappear.",
			default = 100,
			min = 0,
			max = 100,
			step = 1,
			getFunc = function() return self.SV.UI.alpha end,
			setFunc = function(value)
				self.SV.UI.alpha = value
				self.UI.ApplyAlpha()
			end,
		},
		{
			type = "header",
			name = "CCs to track",
		},
		{
			type = "header",
			name = "Debug section",
		},
        {	
			type = "checkbox",
            name = "Enable debugging",
			disabled = function() if self.debug then return false else return true end end,
            getFunc = function() return self.SV.debug.enabled end,
            setFunc = function(value)
                self.SV.debug.enabled = value
				self.debug:SetEnabled(value)
				if not value then
					self:SetAllDebugFalse()
				end
                -- self.log = value
            end
        },
		{	
			type = "checkbox",
			name = "Debug ccCache",
			disabled = function() return not self.SV.debug.enabled end,
			getFunc = function() return self.SV.debug.ccCache end,
			setFunc = function(value)
				self.SV.debug.ccCache = value
				-- self.log = value
			end,
			width = "half",
		},
		{	
			type = "checkbox",
			name = "Debug root detection",
			disabled = function() return not self.SV.debug.enabled end,
			getFunc = function() return self.SV.debug.roots end,
			setFunc = function(value)
				self.SV.debug.roots = value
				-- self.log = value
			end,
			width = "half",
		},
	}
	
	CreateCCCheckboxes()
	self.menu.panel = LAM:RegisterAddonPanel(self.name.."Options", self.menu.metadata)
    LAM:RegisterOptionControls(self.name.."Options", self.menu.options)
end