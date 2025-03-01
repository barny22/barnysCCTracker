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
		tlw:SetDimensions(self.SV.UI.sizes[name], self.SV.UI.sizes[name])
		tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.SV.UI.xOffsets[name], self.SV.UI.yOffsets[name])
		tlw:SetDrawTier(DT_HIGH)
		tlw:SetClampedToScreen(self.SV.settings.unlocked)
		tlw:SetResizeHandleSize(2)
		tlw:SetHandler("OnMoveStop", function(...)
			self.SV.UI.xOffsets[name] = tlw:GetLeft()
			self.SV.UI.yOffsets[name] = tlw:GetTop()
		end)
		tlw:SetHandler("OnResizeStop", function(...)
			if tlw:GetHeight() == self.SV.UI.size and tlw:GetWidth() ~= self.SV.UI.size then
				self.SV.UI.sizes[name] = tlw:GetWidth()
				-- tlw:SetHeight(self.SV.UI.sizes[name])
				self.UI.ApplySize(name)
			elseif tlw:GetHeight() ~= self.SV.UI.size and tlw:GetWidth() == self.SV.UI.size then
				self.SV.UI.sizes[name] = tlw:GetHeight()
				-- tlw:SetWidth(self.SV.UI.sizes[name])
				self.UI.ApplySize(name)
			elseif tlw:GetHeight() ~= self.SV.UI.size and tlw:GetWidth() ~= self.SV.UI.size then
				self.SV.UI.sizes[name] = tlw:GetHeight()
				-- tlw:SetWidth(self.SV.UI.sizes[name])
				self.UI.ApplySize(name)
			end
		end)
		local fragment = ZO_HUDFadeSceneFragment:New(tlw)
		
		local icon = WM:CreateControl(self.name..name.."Icon", tlw, CT_TEXTURE)
		icon:ClearAnchors()
		icon:SetAnchorFill()
		icon:SetTexture(iconPath)
		icon:SetHidden(true)
		
		local tlwShadow = WM:CreateControl(self.name..name.."FrameBG", tlw, CT_BACKDROP)
		tlwShadow:SetAnchorFill()
		tlwShadow:SetDimensions(self.SV.UI.size, self.SV.UI.size)
		tlwShadow:SetEdgeColor(0,0,0,0)
		tlwShadow:SetEdgeTexture(nil,1,1,0,0)
		tlwShadow:SetCenterColor(0.5,0.5,0.5,0.75)
		tlwShadow:SetDrawTier(DT_HIGH)
		tlwShadow:SetHidden(true)
		
		local tlwLabel = WM:CreateControl(self.name..name.."Label", tlw, CT_LABEL)
		tlwLabel:SetText(name)
		tlwLabel:SetAnchor(CENTER, tlw, CENTER, 0, 0)
		tlwLabel:SetHidden(true)
		tlwLabel:SetFont("$(MEDIUM_FONT)|"..(self.SV.UI.sizes[name]/5).."|outline")
		
		local frame = WM:CreateControl(self.name..name.."IconFrame", tlw, CT_TEXTURE)
		frame:ClearAnchors()
		frame:SetAnchorFill()
		frame:SetTexture("/esoui/art/actionbar/abilityframe64_up.dds")
		frame:SetHidden(true)
		
		local controls = {
			tlw = tlw,
			tlwShadow = tlwShadow,
			tlwLabel = tlwLabel,
			frame = frame,
			icon = icon,
			fragment = fragment,
		}
		
		return {
			controls = controls,
		}
	end
	
	for _, entry in pairs(self.ccVariables) do
		indicator[entry.name] = GetIndicator(entry.name, entry.icon)
		-- indicator[entry.name].tracker = ZO_HUDFadeSceneFragment:New(tlw)
	end
	
	local function CreateLiveCCWindow()
		local tlw = WM:CreateTopLevelWindow(self.name.."LiveCCFrame")
		tlw:SetDimensionConstraints(10, 10, 800, 400)
		tlw:SetDimensions(self.SV.UI.debugWindow.width, self.SV.UI.debugWindow.height)
		tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.SV.UI.debugWindow.xOffset, self.SV.UI.debugWindow.yOffset)
		tlw:SetDrawTier(DT_HIGH)
		tlw:SetClampedToScreen(false)
		tlw:SetResizeHandleSize(2)
		tlw:SetMouseEnabled(true)
		tlw:SetMovable(true)
		tlw:SetHandler("OnMoveStop", function(...)
			self.SV.UI.debugWindow.xOffset = tlw:GetLeft()
			self.SV.UI.debugWindow.yOffset = tlw:GetTop()
		end)
		tlw:SetHandler("OnResizeStop", function(...)
			self.SV.UI.debugWindow.width = tlw:GetWidth()
			self.SV.UI.debugWindow.height = tlw:GetHeight()
		end)
		local fragment = ZO_HUDFadeSceneFragment:New(tlw)
		
		local tlwShadow = WM:CreateControl(self.name.."LiveCCBG", tlw, CT_BACKDROP)
		tlwShadow:SetAnchorFill()
		tlwShadow:SetDimensions(self.SV.UI.debugWindow.width, self.SV.UI.debugWindow.height)
		tlwShadow:SetEdgeColor(0,0,0,1)
		tlwShadow:SetEdgeTexture(nil,1,1,0,0)
		tlwShadow:SetCenterColor(0.25,0.25,0.25,0.75)
		tlwShadow:SetDrawTier(DT_HIGH)
		tlwShadow:SetHidden(true)
				
		local tlwLabel = WM:CreateControl(self.name.."LiveCCLabel", tlw, CT_LABEL)
		tlwLabel:SetText("")
		tlwLabel:SetAnchor(TOPLEFT, tlw, TOPLEFT, 4, 2)
		tlwLabel:SetHidden(true)
		tlwLabel:SetFont("$(MEDIUM_FONT)|17|outline")
		tlwLabel:SetDrawTier(DT_HIGH)
		
		local controls = {
			fragment = fragment,
			tlw = tlw,
			tlwShadow = tlwShadow,
			tlwLabel = tlwLabel,
		}
		
		return {
			controls = controls,
		}
	end
	
	local liveCCWindow = CreateLiveCCWindow()
	
	local function HideLiveCCWindow(value)
		liveCCWindow.controls.tlwShadow:SetHidden(not value)
		liveCCWindow.controls.tlwLabel:SetHidden(not value)
	end
	 
	local function FadeScenes(value)
		if value == "UI" then
			for _, entry in pairs(CCTracker.ccVariables) do
				SCENE_MANAGER:GetScene("hud"):AddFragment(CCTracker.UI.indicator[entry.name].controls.fragment)
				SCENE_MANAGER:GetScene("hudui"):AddFragment(CCTracker.UI.indicator[entry.name].controls.fragment)
			end
			SCENE_MANAGER:GetScene("hud"):AddFragment(CCTracker.UI.liveCCWindow.controls.fragment)
			SCENE_MANAGER:GetScene("hudui"):AddFragment(CCTracker.UI.liveCCWindow.controls.fragment)
		elseif value == "Unlocked" then
			for _, entry in pairs(CCTracker.ccVariables) do
				SCENE_MANAGER:GetScene("gameMenuInGame"):AddFragment(CCTracker.UI.indicator[entry.name].controls.fragment)
			end
		elseif value == "Locked" then
			for _, entry in pairs(CCTracker.ccVariables) do
				SCENE_MANAGER:GetScene("gameMenuInGame"):RemoveFragment(CCTracker.UI.indicator[entry.name].controls.fragment)
			end
		end
	end
		
	-- for i=1,10 do
		-- indicator[i] = GetIndicator(i)
	-- end
	
	local function SetUnlocked(value)
		for _, entry in pairs(self.ccVariables) do
			if value and entry.tracked then
				indicator[entry.name].controls.tlw:SetDrawTier(DT_HIGH)
				indicator[entry.name].controls.tlw:SetMouseEnabled(true)
				indicator[entry.name].controls.tlw:SetMovable(true)
				indicator[entry.name].controls.tlw:SetHidden(false)
				indicator[entry.name].controls.tlwShadow:SetHidden(false)
				indicator[entry.name].controls.tlwLabel:SetHidden(false)
				indicator[entry.name].controls.icon:SetHidden(false)
				indicator[entry.name].controls.tlw:SetClampedToScreen(false)
			elseif not value or not entry.tracked then 
				indicator[entry.name].controls.tlw:SetDrawTier(DT_LOW)
				indicator[entry.name].controls.tlw:SetMouseEnabled(false)
				indicator[entry.name].controls.tlw:SetMovable(false)
				indicator[entry.name].controls.tlw:SetHidden(true)
				indicator[entry.name].controls.tlwShadow:SetHidden(true)
				indicator[entry.name].controls.tlwLabel:SetHidden(true)
				indicator[entry.name].controls.icon:SetHidden(true)
				indicator[entry.name].controls.tlw:SetClampedToScreen(true)
			end
		end
		if value then self.UI.FadeScenes("Unlocked") else self.UI.FadeScenes("Locked") end
		self.SV.settings.unlocked = value
	end
	-- indicator.SetUnlocked = SetUnlocked
	
	local function ApplySize(name)
		indicator[name].controls.tlw:SetDimensions(self.SV.UI.sizes[name], self.SV.UI.sizes[name])
		indicator[name].controls.tlwShadow:SetDimensions(self.SV.UI.sizes[name], self.SV.UI.sizes[name])
		indicator[name].controls.frame:SetDimensions(self.SV.UI.sizes[name], self.SV.UI.sizes[name])
		indicator[name].controls.icon:SetDimensions(self.SV.UI.sizes[name], self.SV.UI.sizes[name])
		indicator[name].controls.tlwLabel:SetFont("$(MEDIUM_FONT)|"..(self.SV.UI.sizes[name]/5).."|outline")
	end
	-- indicator.ApplySize = ApplySize

	local function ApplyIcons()
		for _, entry in pairs(self.ccVariables) do
			entry.active = false
			self.UI.indicator[entry.name].controls.frame:SetHidden(true)
			self.UI.indicator[entry.name].controls.icon:SetHidden(true)
		end
		-- self:PrintDebug("enabled", "CC icons hidden")
		
		for _, entry in ipairs(self.ccActive) do
				self.ccVariables[entry.type].active = true
				self.UI.indicator[self.ccVariables[entry.type].name].controls.frame:SetHidden(false)
				self.UI.indicator[self.ccVariables[entry.type].name].controls.icon:SetHidden(false)
			-- end
		end
		-- self:PrintDebug("enabled", "CC icons are shown")
	end
	
	local function ApplyAlpha()
		for _, entry in pairs(self.ccVariables) do
			indicator[entry.name].controls.icon:SetAlpha(self.SV.UI.alpha/100)
			indicator[entry.name].controls.frame:SetAlpha(self.SV.UI.alpha/100)
		end
	end
	
	SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, newState)
		if scene:GetName() == "gameMenuInGame" and newState == "hiding" and self.SV.settings.sample then
			self.SV.settings.sample = false
			self.UI.FadeScenes("Locked")
			self.UI.indicator.Stun.controls.tlw:ClearAnchors()
			self.UI.indicator.Stun.controls.tlw:SetHidden(true)
			self.UI.indicator.Stun.controls.icon:SetHidden(true)
			self.UI.indicator.Stun.controls.frame:SetHidden(true)
			self.UI.indicator.Stun.controls.tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.SV.UI.xOffsets.Stun, self.SV.UI.yOffsets.Stun)
		end
	end)
		
	return {
	indicator = indicator,
	ApplyIcons = ApplyIcons,
	ApplySize = ApplySize,
	SetUnlocked = SetUnlocked,
	FadeScenes = FadeScenes,
	ApplyAlpha = ApplyAlpha,
	liveCCWindow = liveCCWindow,
	HideLiveCCWindow = HideLiveCCWindow,
	}
end