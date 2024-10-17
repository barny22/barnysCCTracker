local WM = WINDOW_MANAGER
CCTracker = CCTracker or {}

	--------------------------
	---- Build CC Tracker ----
	--------------------------

function CCTracker:BuildUI()
	
	local indicator = {}
	
	local function GetIndicator(name, iconPath)
		
		local tlw = WM:CreateTopLevelWindow(self.name..name.."Frame")
		tlw:SetDimensionConstraints(10, 10, 200, 200)
		tlw:SetHeight(self.SV.UI.size)
		tlw:SetWidth(self.SV.UI.size)
		tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.SV.UI.xOffsets[name], self.SV.UI.yOffsets[name])
		tlw:SetDrawTier(DT_HIGH)
		tlw:SetClampedToScreen(self.SV.settings.unlocked)
		tlw:SetHandler("OnMoveStop", function(...)
			self.SV.UI.xOffset[name] = tlw:GetLeft()
			self.SV.UI.yOffset[name] = tlw:GetTop()
		end)
		tlw:SetHandler("OnResizeStop", function(...)
			if tlw:GetHeight() == self.SV.UI.size and tlw:GetWidth() ~= self.SV.UI.size then
				self.SV.UI.size = tlw:GetWidth()
				self.UI.ApplySize(self.SV.UI.size)
			elseif tlw:GetHeight() ~= self.SV.UI.size and tlw:GetWidth() == self.SV.UI.size then
				self.SV.UI.size = tlw:GetHeight()
				self.UI.ApplySize(self.SV.UI.size)
			elseif tlw:GetHeight() ~= self.SV.UI.size and tlw:GetWidth() ~= self.SV.UI.size then
				self.SV.UI.size = tlw:GetHeight()
				self.UI.ApplySize(self.SV.UI.size)
			end
		end)
		
		local tlwbg = WM:CreateControl(self.name..name.."FrameBG", tlw, CT_TEXTURE)
		tlwbg:SetAnchorFill()
		tlwbg:SetHeight(self.SV.UI.size)
		tlwbg:SetWidth(self.SV.UI.size)
		tlwbg:SetColor(0.2,0.2,0.2,0.2)
		tlwbg:SetDrawTier(DT_HIGH)
		tlwbg:SetHidden(true)
		
		local tlwLabel = WM:CreateControl(self.name..name.."Label", tlw, CT_LABEL)
		tlwLabel:SetText(name)
		tlwLabel:SetAnchor(CENTER, tlw, CENTER, 0, 0)
		tlwLabel:SetHidden(true)
		
		local icon = WM:CreateControl(self.name..name.."Icon", tlw, CT_TEXTURE)
		icon:ClearAnchors()
		icon:SetAnchorFill()
		icon:SetTexture(iconPath)
		icon:SetHidden(true)
		
		local frame = WM:CreateControl(self.name..name.."IconFrame", tlw, CT_TEXTURE)
		frame:ClearAnchors()
		frame:SetAnchorFill()
		frame:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
		frame:SetHidden(true)
		
		local controls = {
		tlw = tlw,
		tlwbg = tlwbg,
		tlwLabel = tlwLabel,
		frame = frame,
		icon = icon,
		}
		return {
		controls = controls,
		}
	end
	
	for _, entry in pairs(self.variables) do
		indicator[entry.name] = GetIndicator(entry.name, entry.icon)
		-- indicator[entry.name].tracker = ZO_HUDFadeSceneFragment:New(tlw)
	end
	 
	-- local function FadeScenes(value)
		-- if value == "UI" then
			-- for _, entry in pairs(self.variables) do
				-- SCENE_MANAGER:GetScene("hud"):AddFragment(indicator[entry.name].tracker)
				-- SCENE_MANAGER:GetScene("hudui"):AddFragment(indicator[entry.name].tracker)
			-- end
		-- elseif value == "NoUI" then
			-- for _, entry in pairs(self.variables) do
				-- SCENE_MANAGER:GetScene("hud"):RemoveFragment(indicator[entry.name].tracker)
				-- SCENE_MANAGER:GetScene("hudui"):RemoveFragment(indicator[entry.name].tracker)
			-- end
		-- elseif value == "Sample" then
			-- for _, entry in pairs(self.variables) do
				-- SCENE_MANAGER:GetScene("gameMenuInGame"):AddFragment(indicator[entry.name].tracker)
			-- end
		-- elseif value == "NoSample" then
			-- for _, entry in pairs(self.variables) do
				-- SCENE_MANAGER:GetScene("gameMenuInGame"):RemoveFragment(indicator[entry.name].tracker)
			-- end
		-- end
	-- end
	
	-- FadeScenes("UI")
	
	-- for i=1,10 do
		-- indicator[i] = GetIndicator(i)
	-- end
	
	local function SetUnlocked(value)
		for _, entry in pairs(self.variables) do
			if entry.tracked then
				if value then
					indicator[entry.name].controls.tlw:SetDrawTier(DT_HIGH)
					indicator[entry.name].controls.tlw:SetHidden(false)
					indicator[entry.name].controls.tlwbg:SetHidden(false)
					indicator[entry.name].controls.tlwLabel:SetHidden(false)
					indicator[entry.name].controls.icon:SetHidden(false)
				else
					indicator[entry.name].controls.tlw:SetDrawTier(DT_LOW)
					indicator[entry.name].controls.tlw:SetHidden(true)
					indicator[entry.name].controls.tlwbg:SetHidden(true)
					indicator[entry.name].controls.tlwLabel:SetHidden(true)
					indicator[entry.name].controls.icon:SetHidden(true)
				end
				indicator[entry.name].controls.tlw:SetClampedToScreen(not value)
			end
		end
		self.SV.settings.unlocked = value
	end
	-- indicator.SetUnlocked = SetUnlocked
	
	local function ApplySize(size)
		for _, entry in pairs(self.variables) do 
			indicator[entry.name].controls.tlw:SetDimensions(size, size)
			indicator[entry.name].controls.tlwbg:SetDimensions(size, size)
			indicator[entry.name].controls.frame:SetDimensions(size, size)
			indicator[entry.name].controls.icon:SetDimensions(size, size)
			indicator[entry.name].controls.tlwLabel:SetFont("$(MEDIUM_FONT)|"..(self.SV.UI.size/5).."|outline")
		end
		
	end
	-- indicator.ApplySize = ApplySize

	local function ApplyIcons()
		local active = {}
		for _, entry in pairs(self.variables) do
			entry.active = false
			self.UI.indicator[entry.name].controls.frame:SetHidden(true)
			self.UI.indicator[entry.name].controls.icon:SetHidden(true)
		end
		if self.SV.debug.ccCache then d("Done with hiding CC icons") end
		
		for _, entry in ipairs(self.ccActive) do
				self.variables[entry.type].active = true
				self.UI.indicator[self.variables[entry.type].name].controls.frame:SetHidden(false)
				self.UI.indicator[self.variables[entry.type].name].controls.icon:SetHidden(false)
			-- end
		end
		if self.SV.debug.ccCache then d("CC icons are shown") end
		self.ccChanged = false
	end
		
	return {
	indicator = indicator,
	ApplyIcons = ApplyIcons,
	ApplySize = ApplySize,
	SetUnlocked = SetUnlocked,
	FadeScenes = FadeScenes,
	}
end