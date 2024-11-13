local LAM = LibAddonMenu2
local WM = WINDOW_MANAGER
CCTracker = CCTracker or {}
CCTracker.menu = CCTracker.menu or {}
CCTracker.menu.icons = {}

CCTracker.menu.constants = {
	{
		["Name"] = "Charm",
		["Icon"] = "/esoui/art/icons/ability_u34_sea_witch_mindcontrol.dds",
		["Id"] = "charm" --2340
	},
	{
		["Name"] = "Disoriented",
		["Icon"] = "/esoui/art/icons/ability_debuff_disorient.dds",
		["Id"] = 32 --2340
	},
	{
		["Name"] = "Fear",
		["Icon"] = "/esoui/art/icons/ability_debuff_fear.dds",
		["Id"] = 27 --2320
	},
	{
		["Name"] = "Knockback",
		["Icon"] = "/esoui/art/icons/ability_debuff_knockback.dds",
		["Id"] =  17 --2475
	}, 
	{
		["Name"] = "Levitating",
		["Icon"] = "/esoui/art/icons/ability_debuff_levitate.dds",
		["Id"] = 48 --2400
	},
	{
		["Name"] = "Offbalance",
		["Icon"] = "/esoui/art/icons/ability_debuff_offbalance.dds",
		["Id"] =  53 --2440
	},
	{
		["Name"] = "Root",
		["Icon"] = "/esoui/art/icons/ability_debuff_root.dds",
		["Id"] = "root" --2480
	},
	{
		["Name"] = "Silence",
		["Icon"] = "/esoui/art/icons/ability_debuff_silence.dds",
		["Id"] = 11 --2010
	},
	{
		["Name"] = "Snare",
		["Icon"] = "/esoui/art/icons/ability_debuff_snare.dds",
		["Id"] = 10 --2025
	},
	{
		["Name"] = "Stagger",
		["Icon"] = "/esoui/art/icons/ability_debuff_stagger.dds",
		["Id"] = 33 --2470
	},
	{
		["Name"] = "Stun",
		["Icon"] = "/esoui/art/icons/ability_debuff_stun.dds",
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
			if value then
				CCTracker.menu.icons[i]:SetDesaturation(0)
			else
				CCTracker.menu.icons[i]:SetDesaturation(1)
			end
			if value and not CCTracker.registered then
				CCTracker:Register()
			elseif not value and CCTracker.registered and not CCTracker:CheckForCCRegister() then
				CCTracker:Unregister()
			end
			if CCTracker.SV.settings.unlocked then CCTracker.UI.SetUnlocked(true) end
		end
		table.insert(CCTracker.menu.options[position].controls, control)
	end
end

function CCTracker.menu.CreateIcons(panel)					-- Thanks to DakJaniels who came up with this solution
	if CCTracker.SV.debug.enabled then
		CCTracker.debug:Print("Panel was created.")
		if CCTracker.menu.icons[1] then CCTracker.debug:Print("Menu Icons seem to have been initialized before") else CCTracker.debug:Print("Menu Icons have not been initialized yet") end
	end
	for i = 1, #CCTracker.menu.constants do
		local number = CCTracker.menu.CreateMenuIconsPath(CCTracker.menu.constants[i].Name)
		CCTracker.menu.icons[i] = WM:CreateControl(CCTracker.name.."MenuIcon"..i, panel.controlsToRefresh[number].checkbox, CT_TEXTURE)
		CCTracker.menu.icons[i]:SetAnchor(RIGHT, panel.controlsToRefresh[number].checkbox, LEFT, -25, 0)
		CCTracker.menu.icons[i]:SetTexture(CCTracker.menu.constants[i].Icon)
		CCTracker.menu.icons[i]:SetDimensions(35, 35)
		if CCTracker.ccVariables[CCTracker.menu.constants[i].Id].tracked then
			CCTracker.menu.icons[i]:SetDesaturation(0)
		else
			CCTracker.menu.icons[i]:SetDesaturation(1)
		end
	end
	CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CCTracker.menu.CreateIcons)
	if CCTracker.SV.debug.enabled then CCTracker.debug:Print("Deleting LAM Callback") end
end

function CCTracker:BuildMenu()
	
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", function(panel)
		if panel == barnysCCTrackerOptions then self.menu.CreateIcons(panel) end
	end)
	CALLBACK_MANAGER:RegisterCallback("LAM-PanelOpened", function(panel)
		if panel ~= barnysCCTrackerOptions then return end
		self.menu.UpdateLists()
	end)
	
	self.menu.ccList = {}
	self.menu.ccList.active = {
		["string"] = {},
		["id"] = {},
		["type"] = {},
	}
	self.menu.ccList.ignored = {
		["string"] = {},
		["id"] = {},
	}
	
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
			type = "submenu",
			name = "UI",
			controls = {
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
			},
		},
		{
			type = "submenu",
			name = "CCs to track",
			controls = {},
		},
		-- {
			-- type = "divider",
		-- },
		{
			type = "submenu",
			name = "CC Ignore List",
			controls = {
				{	
					type = "checkbox",
					name = "Enable chat links",
					tooltip = "This enables clickable links in chat, that let you ignore the linked CC ability",
					warning = "To use this you need to have LibChatMessage installed!",
					disabled = function() return not self.debug end,
					getFunc = function() return self.SV.settings.ccIgnoreLinks end,
					setFunc = function(value)
						self.SV.settings.ccIgnoreLinks = value
					end,
				},
				{	
					type = "dropdown",
					name = "List of current cc abilities",
					tooltip = "You can use this to look for unwanted abilities, for example if your stun icon doesn't disappear, you can look here which ability causes the stun to be recognized",
					choices = self.menu.ccList.active.string,	
					getFunc = function()
						if self.menu.ccList.active.string[1] == "No cc active" then
							return self.menu.ccList.active.string[1]
						else
							for i, entry in ipairs(self.menu.ccList.active.id) do
								if entry == self.menu.ccList.abilityId then return self.menu.ccList.active.string[i] end
							end
						end
					end,
					setFunc = function(value)
						if value ~= "No cc active" then
							for i, entry in ipairs(self.menu.ccList.active.string) do
								if entry == value then
									self.menu.ccList.abilityId = self.menu.ccList.active.id[i]
									self.menu.ccList.abilityType = self.menu.ccList.active.type[i]
								end
							end
							self.menu.ccList.abilityAction = "ignore"
						end
					end,
					width = "half",
				},
				{	
					type = "button",
					name = "Ignore ability",
					tooltip = "This puts the currently selected ability on an ignore list",
					disabled = function() return self.menu.ccList.abilityAction ~= "ignore" end,
					func = function()
						self.SV.ignored[self.menu.ccList.abilityId] = self.menu.ccList.abilityType
						self.menu.ccList.abilityAction = nil
						for i, entry in ipairs(self.ccActive) do
							if entry.id == self.menu.ccList.abilityId then table.remove(self.ccActive, i) end
						end
						self.menu.ccList.abilityId = nil
						self.menu.ccList.abilityType = nil
						self.menu.UpdateLists()
						self.UI.ApplyIcons()
					end,
					width = "half",
				},
				{	
					type = "dropdown",
					name = "List of ignored cc abilities",
					tooltip = "This is the list of your ignored abilities",
					choices = self.menu.ccList.ignored.string,		
					getFunc = function()
						if self.menu.ccList.ignored.string[1] == "No ignored abilities" then
							return self.menu.ccList.ignored.string[1]
						else
							for i, entry in ipairs(self.menu.ccList.ignored.id) do
								if entry == self.menu.ccList.abilityId then return self.menu.ccList.ignored.string[i] end
							end
						end
					end,
					setFunc = function(value)
						if value ~= "No ignored abilities" then
							for i, entry in ipairs(self.menu.ccList.ignored.string) do
								if entry == value then
									self.menu.ccList.abilityId = self.menu.ccList.ignored.id[i]
								end
							end
							self.menu.ccList.abilityAction = "unignore"
						end
					end,
					width = "half",
				},
				{	
					type = "button",
					name = "Reenable ability",
					tooltip = "This unignores the currently selected ability",
					disabled = function() return self.menu.ccList.abilityAction ~= "unignore" end,
					func = function()
						self.SV.ignored[self.menu.ccList.abilityId] = nil
						self.menu.ccList.abilityId = nil
						self.menu.ccList.abilityType = nil
						self.menu.ccList.abilityAction = nil
						self.menu.UpdateLists()
					end,
					width = "half",
				},
				{
					type = "editbox",
					name = "Manually add ability id to ignore list",
					warning = "If you enable chat links, you'll see any CC that is recognized, including its ID",
					isMultiline = false,
					getFunc = function() return self.menu.ccList.abilityId end,
					setFunc = function(value)
						self.menu.ccList.abilityId = value
						self.menu.ccList.abilityAction = "manually"
					end,
					width = "half",
				},
				{
					type = "editbox",
					name = "Ability description",
					tooltip = "If you want, you can add a description to the ability you'd like to ignore",
					warning = "Only enabled, if you add manually!",
					disabled = function() return self.menu.ccList.abilityAction ~= "manually" end,
					isMultiline = false,
					getFunc = function() return self.menu.ccList.abilityType end,
					setFunc = function(value)
						self.menu.ccList.abilityType = value
					end,
					width = "half",
				},
				{	
					type = "button",
					name = "Add ability to ignore list",
					tooltip = "This adds the current manually selected ID to the ability ignore list",
					disabled = function() return self.menu.ccList.abilityAction ~= "manually" end,
					func = function()
						self.SV.ignored[self.menu.ccList.abilityId] = self.menu.ccList.abilityType or "manually added"
						if self:AIdInList(self.menu.ccList.abilityId) then
							local _, i = self:AIdInList(self.menu.ccList.abilityId)
							table.remove(self.ccActive, i)
							self.UI.ApplyIcons()
							if self.SV.debug.ignoreList then self.debug:Print("Manually removed currrently active CC ability ID: "..self.menu.ccList.abilityId) end
						end
						self.menu.ccList.abilityId = nil
						self.menu.ccList.abilityType = nil
						self.menu.ccList.abilityAction = nil
						self.menu.UpdateLists()
						self.UI.ApplyIcons()
					end,
				},
			},
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
			type = "submenu",
			name = "Debug options",
			controls = {
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
				{	
					type = "checkbox",
					name = "Debug ignore list detection",
					disabled = function() return not self.SV.debug.enabled end,
					getFunc = function() return self.SV.debug.ignoreList end,
					setFunc = function(value)
						self.SV.debug.ignoreList = value
						-- self.log = value
					end,
					width = "half",
				},
			},
		},
	}
	
	CreateCCCheckboxes()
	self.menu.panel = LAM:RegisterAddonPanel(self.name.."Options", self.menu.metadata)
    LAM:RegisterOptionControls(self.name.."Options", self.menu.options)
end