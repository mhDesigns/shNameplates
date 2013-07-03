-- Would like to say thanks to the following authors for their inspiration
-- tekkub, cael, roth, and luzz 

local _, shNameplates = ...

local CreateFrame = CreateFrame
shNameplates.eventFrame = CreateFrame("Frame", nil, UIParent)
shNameplates.eventFrame:SetScript("OnEvent", function(self, event, ...)
	if type(self[event] == "function") then
		return self[event](self, event, ...)
	end
end)

local diag = [=[Interface\AddOns\shNameplates\media\diag]=]
local cfg = shNameplates.cfg -->Get the config data

-->failsafe
if cfg.showhpvalue == false and cfg.hpallthetime == true then
	print("|cff649DDFshNameplates:|r |cffFF0000ERROR|r with config settings - hpallthetime cannot be true if showhpvalue is false!  Values reset to false.")
	cfg.showhpvalue = false
	cfg.hpallthetime = false
end

--> Are you local?
local modf, len, lower, gsub, select, upper, sub, find, SetFormattedText = math.modf, string.len, string.lower, string.gsub, select, string.upper, string.sub, string.find, SetFormattedText
local IsShown, SetSize, ClearAllPoints, GetMinMaxValues = IsShown, SetSize, ClearAllPoints, GetMinMaxValues
local numKids = -1
local WorldFrame, GetNumChildren, GetChildren = WorldFrame, GetNumChildren, GetChildren
local tonumber = tonumber
local format = format
local UnitExists, UnitIsPlayer, UnitGUID = UnitExists, UnitIsPlayer, UnitGUID
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
local UnitPower, UnitPowerMax, UnitPowerType, UnitIsPlayer = UnitPower, UnitPowerMax, UnitPowerType, UnitIsPlayer
--local UnitLevel = UnitLevel("player")
local cFont = [=[Interface\AddOns\shNameplates\media\bullets.ttf]=]

---------------------------
-----UTILITY FUNCTIONS-----
---------------------------
local function round(num, idp)
	return tonumber(format("%." .. (idp or 0) .. "f", num))
end

local function formatNumber(number)
	if number >= 1e6 then
		return round(number/1e6, 1).."|cffEEEE00m|r"
	elseif number >= 1e3 then
		return round(number/1e3, 1).."|cffEEEE00k|r"
	else
		return number
	end
end

local function nameColoring(self, checker)
	if checker then
		local r, g, b = self.healthBar:GetStatusBarColor()
		return r * 1.5, g * 1.5, b * 1.5
	else
		return cfg.name.color.r, cfg.name.color.g, cfg.name.color.b
	end
end

-->IsTargetFrame?
local function IsTargetNameplate(self)
	return (self:IsShown() and self:GetAlpha() >= 0.99 and UnitExists("target")) or false
end

--[[IsMouseover??
local function IsMouseoverNameplate(self)
	if self.highlight then
		return self.highlight:IsShown() == 1 and true or false
	end
end]]

-->TEKKUB's color gradient function of awesomeness
local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end
	local segment, relperc = modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

----------------------------------
-----Castbar Helper Functions-----
----------------------------------

--> Castbar display of time
local function UpdateTime(self, curValue)
	if cfg.hidecastinfo then return end
	local minValue, maxValue = self:GetMinMaxValues()
	local chk = false
	if maxValue > 300 or maxValue == nil then chk = true end
	
	local oldname = self.channeling or self.casting
	local castname = oldname and (len(oldname) > 20) and gsub(oldname, "%s?(.[\128-\191]*)%S+%s", "%1. ") or oldname -->fixes really long names
	
	if self.channeling then
		if chk then self.time:SetFormattedText("|cffFFFFFF%.1f|r |cffBEBEBE(??)|r", curValue)
		else self.time:SetFormattedText("|cffFFFFFF%.1f|r |cffBEBEBE(%.1f)|r", curValue, maxValue) end
	else 
		if chk then self.time:SetFormattedText("|cffFFFFFF%.1f|r |cffBEBEBE(??)|r", maxValue - curValue)
		else self.time:SetFormattedText("|cffFFFFFF%.1f|r |cffBEBEBE(%.1f)|r", maxValue - curValue, maxValue) end		
	end	
	
	self.cname:SetText(castname)
end

-->Needed to fix castbar colors and bloat
local function FixCastbar(self)
	self:ClearAllPoints()
	self:SetParent(self.healthBar)
	self.castbarOverlay:Hide()	
	self:SetSize(cfg.castbar.width, cfg.castbar.height)
	self:SetPoint(cfg.castbar.anchor, self.healthBar, cfg.castbar.anchor2, cfg.castbar.xoffset, cfg.castbar.yoffset)

	if cfg.powerbar and self.powerBar:IsShown() == 1 then
		self:SetPoint(cfg.castbar.anchor, self.powerBar, cfg.castbar.anchor2, cfg.castbar.xoffset, cfg.castbar.yoffset)
	end
end

-->Color castbar depending on interruptability
local function ColorCastbar(self, shielded)
	if shielded then 
		self:SetStatusBarTexture(diag)
		self:SetStatusBarColor(0.83, 0.14, 0.14)
		self.cbGlow:SetBackdropBorderColor(0.95, 0.2, 0.2, 0.5)
		self.shield:Show()
	else
		self:SetStatusBarTexture(cfg.bartex)
		self:SetStatusBarColor(0.86, 0.71, 0.18)
		self.cbGlow:SetBackdropBorderColor(0.95, 0.95, 0.2, 0.5)
		self.shield:Hide()
	end
end

--------------------------
--- SHOW POWER UPDATE ----
--------------------------
local function updatePower(self)
	if not cfg.powerbar then return end
	if self.isTarget and UnitIsPlayer("target") then
		--if not UnitIsPlayer("target") then return end
		local curPower = UnitPower("target")
		local maxPower = UnitPowerMax("target")
		local pType = UnitPowerType("target")
		--local id = UnitGUID("target")
		self.powerBar:SetValue(curPower)
		self.powerBar:SetMinMaxValues(0, maxPower)
			
		if pType == 0 then 
			self.powerBar:SetStatusBarColor(cfg.powercolors.mana.r, cfg.powercolors.mana.g, cfg.powercolors.mana.b)
		elseif pType == 1 then
			self.powerBar:SetStatusBarColor(cfg.powercolors.rage.r, cfg.powercolors.rage.g, cfg.powercolors.rage.b)
		elseif pType == 2 then
			self.powerBar:SetStatusBarColor(cfg.powercolors.focus.r, cfg.powercolors.focus.g, cfg.powercolors.focus.b)
		elseif pType == 3 then
			self.powerBar:SetStatusBarColor(cfg.powercolors.energy.r, cfg.powercolors.energy.g, cfg.powercolors.energy.b)
		elseif pType == 6 then
			self.powerBar:SetStatusBarColor(cfg.powercolors.runic.r, cfg.powercolors.runic.g, cfg.powercolors.runic.b)
		else
			self.powerBar:SetStatusBarColor(0.55, 0.57, 0.61) -->generic color 
		end		
		
		self.powerBar:Show()
	else
		if self.powerBar:IsShown() then
			self.powerBar:Hide()
		end
	end
end

--------------------------
--- SHOW CLASS POINTS ----
--------------------------
local GetComboPoints, UnitClass, tContains = GetComboPoints, UnitClass, tContains
local class = UnitClass("player")
local classes = { "Rogue", "Druid", "Monk", "Paladin", "Warlock", "Priest" }

--helper function to get the points for display depending on class
local function getPoints(class)
	if not UnitExists then return end
	if (class == "Monk") then
		return UnitPower("player", SPELL_POWER_LIGHT_FORCE)
	elseif (class == "Warlock") then
		return (UnitPower("player", SPELL_POWER_BURNING_EMBERS) or UnitPower("player", SPELL_POWER_DEMONIC_FURY) or UnitPower("player", SPELL_POWER_SOUL_SHARDS))
	elseif (class == "Paladin") then
		return UnitPower("player", SPELL_POWER_HOLY_POWER)
	elseif (class == "Priest") then
		return UnitPower("player", SPELL_POWER_SHADOW_ORB)
	else
		return GetComboPoints("player", "target")
	end
end

local function updateExtras(self)
	if cfg.hidepoints then return end
	if self.isTarget and tContains(classes, class) then
		--if tContains(classes, class) then
			local points = getPoints(class)
			if points == 1 then 
				self.combo:SetText("|cffD94426>|r")
				return
			elseif points == 2 then
				self.combo:SetText("|cffD94426>|r   |cffD98826>|r")
				return
			elseif points == 3 then
				self.combo:SetText("|cffD94426>|r   |cffD98826>|r   |cffD9D326>|r")
				return
			elseif points == 4 then
				self.combo:SetText("|cffD94426>|r   |cffD98826>|r   |cffD9D326>|r   |cffB5D926>|r")
				return
			elseif points == 5 then
				self.combo:SetText("|cff5CD926>|r   |cff5CD926>|r   |cff5CD926>|r   |cff5CD926>|r   |cff5CD926>|r")
				return
			else
				self.combo:SetText(" ")
				return
			end
		--end		
	else
		self.combo:SetText(" ")
	end
end

--------------------------
--- SHOW HEALTH UPDATE ---
--------------------------
local function updateHealth(healthBar, maxHp)
	if healthBar then
		local self = healthBar:GetParent():GetParent() -- ADDED for 5.1 changes
		local _, maxhealth = self.healthBar:GetMinMaxValues()
		if maxHp == "x" then 
			maxHp = maxhealth
		end
		local currentValue = self.healthBar:GetValue()
		local p = (currentValue/maxhealth)*100
		local r, g, b = ColorGradient(currentValue/maxhealth, 1,0,0, 1,1,0, 0,1,0)				
		self.hp:SetTextColor(r, g, b)
	
		if p < 100 then
			self.hp:SetFormattedText("|cffFFFFFF%s|r|cffffffff - |r%.1f%%", formatNumber(currentValue), p)
		elseif p == 100 and cfg.hpallthetime then
			self.hp:SetFormattedText("|cffFFFFFF%s|r|cffffffff - |r%.0f%%", formatNumber(currentValue), p)	
		else
			self.hp:SetText("")
		end
	end
end

local function setBarColors(self)
	local r, g, b = self.healthBar:GetStatusBarColor()
	local newr, newg, newb
	if g + b == 0 then
		-- Hostile unit
		newr, newg, newb = cfg.colors.hostile.r, cfg.colors.hostile.g, cfg.colors.hostile.b
	elseif r + b == 0 then
		-- Friendly npc
		newr, newg, newb = cfg.colors.friendlynpc.r, cfg.colors.friendlynpc.g, cfg.colors.friendlynpc.b
	elseif r + g == 0 then
		-- Friendly player
		newr, newg, newb = cfg.colors.friendly.r, cfg.colors.friendly.g, cfg.colors.friendly.b
	elseif (2 - (r + g) < 0.05 and b == 0) then
		-- Neutral unit
		newr, newg, newb = cfg.colors.neutral.r, cfg.colors.neutral.g, cfg.colors.neutral.b
	else
		-- Hostile player - class colored.
		newr, newg, newb = r, g, b
	end	
	
	self.r, self.g, self.b = newr, newg, newb -->set them unique to each frame
	self.healthBar:SetStatusBarColor(newr, newg, newb) -->set our wanted colors
end

----------------------------
--- ONUPDATE/THREAT 2in1 ---
----------------------------
local InCombat = false
local function ThreatUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed > 0.25 then 	
		
		-->setting target attribute
		if IsTargetNameplate(self) then 
			self.isTarget = true
		else 
			self.isTarget = false 
		end
		
		-->mouseover highlighting
		if self.highlight:IsShown() then
			self.name:SetTextColor(1, 1, 0)
		else
			self.name:SetTextColor(nameColoring(self, cfg.namecolor))
		end
		
		updateExtras(self)
		updatePower(self)
		
		-->if in combat then start logic to figure out threat coloring
		if self.oldglow:IsShown() then
			-->used for threat comparisons and updates to coloring
			local r, g, b = self.oldglow:GetVertexColor()
			-->AGGRO
			if (g + b == 0) then
				self.healthBar.hpGlow:SetBackdropBorderColor(0.95, 0.2, 0.2)	
				if cfg.tankmode then 
					self.healthBar:SetStatusBarColor(cfg.colors.aggro.r, cfg.colors.aggro.g, cfg.colors.aggro.b)
				end		
			-->HIGHTHREAT, but not aggro...yet
			elseif (b == 0) then 
				self.healthBar.hpGlow:SetBackdropBorderColor(0.95, 0.95, 0.2)
				if cfg.tankmode then
					self.healthBar:SetStatusBarColor(cfg.colors.highthreat.r, cfg.colors.highthreat.g, cfg.colors.highthreat.b)
				end
			else
				if cfg.tankmode then 
					self.healthBar:SetStatusBarColor(self.r, self.g, self.b)
				end
				self.healthBar.hpGlow:SetBackdropBorderColor(0.2, 0.2, 0.2)
			end	
		
		-->if NOT in combat then just set the frames to normaality
		else
			if cfg.tankmode then 
				self.healthBar:SetStatusBarColor(self.r, self.g, self.b) 
			end
			
			if self.isTarget then 
				self.healthBar.hpGlow:SetBackdropBorderColor(0.6, 0.6, 0.6)
			else 
				self.healthBar.hpGlow:SetBackdropBorderColor(0.2, 0.2, 0.2)		
			end
		end
		
		self.elapsed = 0 --reset
	end
end

--------------------
--- UPDATE PLATE ---
--------------------
local function UpdatePlate(self)
	setBarColors(self)
	
	self.healthBar:ClearAllPoints()
	self.healthBar:SetPoint("CENTER", self.healthBar:GetParent(), 0, cfg.healthbar.yoffset)
	self.healthBar:SetSize(cfg.healthbar.width, cfg.healthbar.height)
	self.healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15, 0.8)
	
	-->initial castbar maintenance
	if self.castBar:IsShown() then self.castBar:Hide() end
	self.castBar.IconOverlay:SetVertexColor(0.6, 0.6, 0.6)
			
	self.highlight:ClearAllPoints()
	self.highlight:SetAllPoints(self.healthBar)
		
	local oldName = self.oldname:GetText()
	local newName = (len(oldName) > 25) and gsub(oldName, "%s?(.[\128-\191]*)%S+%s", "%1. ") or oldName -->fixes really long names
	self.name:SetTextColor(nameColoring(self, cfg.namecolor))
	if not cfg.name.uppercase then 
		self.name:SetText(lower(newName)) 
	else 
		self.name:SetText(newName) 
	end	
	
	local level, elite, rare = tonumber(self.level:GetText()), self.elite:IsShown()
	
	self.level:ClearAllPoints()
	self.level:SetPoint(cfg.level.anchor, self.healthBar, cfg.level.anchor2, cfg.level.xoffset, cfg.level.yoffset)
	
	-->fix mobtype icon
	self.mobtype:ClearAllPoints()	
	
	if self.boss:IsShown() then
		self.mobtype:SetPoint("CENTER", self.healthBar, "TOPLEFT", 8, 0)
		self.mobtype2:SetPoint("CENTER", self.mobtype, "LEFT", -2, 0)
		self.mobtype:Show()
		self.mobtype2:Show()
		self.mobtype:SetSize(10, 10)
		self.mobtype2:SetSize(10, 10)
		self.level:SetText("??")
		self.level:SetTextColor(0.8, 0.05, 0)
		self.level:Show()
	elseif elite then
		self.mobtype:SetPoint("CENTER", self.healthBar, "TOPLEFT", 1, 0)
		self.level:SetText(level.."+")
		self.mobtype:Show() 
		self.mobtype2:Hide() 
	else
		self.mobtype:Hide()
		self.mobtype2:Hide() 
	end	

	self.fade:SetChange(self:GetAlpha())
	self:SetAlpha(0)
	self.ag:Play()
end

----------------------------
--- EVENT HANDLERS/CUSTOM---
----------------------------
local function OnSizeChanged(self, width, height)
	if self:IsShown() ~= 1 then return end
		
	if height > cfg.castbar.height then
		self.needFix = true
	end
end

local function OnValueChanged(self, curValue)
	if self:IsShown() ~= 1 then return end
	UpdateTime(self, curValue) 
	
	--fix castbar from bloating - as a back up to onshow fixcastbar call
	if self:GetHeight() > cfg.castbar.height or self.needFix then
		FixCastbar(self)
		self.needFix = nil
	end
	
	--another safety to ensure proper casbar coloring for interruptable vs uninteruptable items
	if self.controller and select(2, self:GetStatusBarColor()) > 0.15 then 
		self:SetStatusBarColor(0.83, 0.14, 0.14) 
	end
end

local function OnShow(self)	
	FixCastbar(self)
	self.IconOverlay:Show()
	ColorCastbar(self, self.shieldedRegion:IsShown() == 1) 
end

local function OnHide(self)
    self.highlight:Hide()
end

local function CastbarEvents(self, event, unit)
	if unit == "target" then
		local chc, cc
		
		self.controller = nil

		self.channeling = select(1, UnitChannelInfo('target'))
		self.casting = select(1, UnitCastingInfo('target'))
		
		chc = select(8, UnitChannelInfo('target'))
		cc = select(9, UnitCastingInfo('target'))

		if self.channeling and not self.casting then self.controller = chc
		else self.controller = cc end
		
		if self:IsShown() == 1 then
			ColorCastbar(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" or self.controller or self.shieldedRegion:IsShown() == 1) 
		end
	end
end

--> Event used to update powerbar and combo points on current target
local function FrameEvents(self, event, unit)
	updatePower(self)
	updateExtras(self)
end

--------------------
--- CREATE PLATE ---
--------------------
local function createPlate(frame)
	frame.nameplate = true --for platebuffs

	--ADDITIONS in 5.1 patch for nameplate objects
	-----------------------------------------------
	--frame.barFrame, frame.nameFrame = frame:GetChildren()
	--frame.barFrame.threat, frame.barFrame.border, frame.barFrame.highlight, frame.barFrame.level, frame.barFrame.boss, frame.barFrame.raid, frame.barFrame.dragon = frame.barFrame:GetRegions()
	--frame.nameFrame.name = frame.nameFrame:GetRegions()
	--frame.barFrame.healthbar, frame.barFrame.castbar = frame.barFrame:GetChildren()
	--frame.barFrame.healthbar.texture =  frame.barFrame.healthbar:GetRegions()
	--frame.barFrame.castbar.texture, frame.barFrame.castbar.border, frame.barFrame.castbar.shield, frame.barFrame.castbar.icon =  frame.barFrame.castbar:GetRegions()
	
	frame.barFrame, frame.nameFrame = frame:GetChildren() --ADDED in patch 5.1 
	frame.healthBar, frame.castBar = frame.barFrame:GetChildren()

	local newParent = frame.barFrame -- ADDED in patch 5.1
	local healthBar, castBar = frame.healthBar, frame.castBar
	local nameTextRegion = frame.nameFrame:GetRegions()
	local glowRegion, overlayRegion, highlightRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame.barFrame:GetRegions()
	local _, castbarOverlay, shieldedRegion, spellIconRegion= castBar:GetRegions()	

	frame.oldname = nameTextRegion
	nameTextRegion:Hide()
		
	------------------
	---NAME TEXT------
	------------------
	frame.name = frame:CreateFontString(nil, 'OVERLAY')
	frame.name:SetParent(healthBar)
	frame.name:SetPoint(cfg.name.anchor, healthBar, cfg.name.anchor2, cfg.name.xoffset, cfg.name.yoffset)
	frame.name:SetFont(cfg.name.font, cfg.name.fontSize, cfg.name.fontFlag)
	frame.name:SetShadowOffset(0.5, -0.5)
	frame.name:SetShadowColor(0, 0, 0, 1)
	
	-----------------------
	---COMBO POINT ICONS---
	-----------------------
	frame.combo = frame:CreateFontString(nil, 'OVERLAY')
	frame.combo:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 2, 2)
	frame.combo:SetFont(cFont, 5, "THINOUTLINE")
	
	-----------------------
	---LEVEL TEXT INFO ----
	-----------------------
	levelTextRegion:SetFont(cfg.level.font, cfg.level.fontSize, cfg.level.fontFlag)
	levelTextRegion:SetShadowOffset(0,0)
	--levelTextRegion:SetShadowOffset(0.5, -0.5)
	--levelTextRegion:SetShadowColor(0, 0, 0, 1)
	frame.level = levelTextRegion
	
	---------------------
	---HEALTHBAR stuff---
	---------------------
	healthBar:SetStatusBarTexture(cfg.bartex)
		
	healthBar.hpBackground = healthBar:CreateTexture(nil, "BACKGROUND")
	healthBar.hpBackground:SetAllPoints()
	healthBar.hpBackground:SetTexture(cfg.bg)
	healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15, 0.8)
			
	healthBar.hpGlow = CreateFrame("Frame", nil, healthBar)
	healthBar.hpGlow:SetFrameLevel(healthBar:GetFrameLevel() -1 > 0 and healthBar:GetFrameLevel() -1 or 0)
	healthBar.hpGlow:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -2, 2)
	healthBar.hpGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 2, -2)
	healthBar.hpGlow:SetBackdrop(cfg.backdrop)
	healthBar.hpGlow:SetBackdropColor(0, 0, 0, 0)
	healthBar.hpGlow:SetBackdropBorderColor(0.2, 0.2, 0.2)
	
	------------------
	---HEALTH TEXT----
	------------------
	if cfg.showhpvalue then
		frame.hp = frame:CreateFontString(nil, 'ARTWORK')
		frame.hp:SetPoint(cfg.health.anchor, healthBar, cfg.health.anchor2, cfg.health.xoffset, cfg.health.yoffset)
		frame.hp:SetFont(cfg.health.font, cfg.health.fontSize, cfg.health.fontFlag)
		frame.hp:SetShadowOffset(0, 0)
		--frame.hp:SetShadowOffset(0.3, -0.3)
	    --frame.hp:SetShadowColor(0, 0, 0, 1)
		healthBar:SetScript("OnValueChanged", updateHealth)
		if cfg.hpallthetime then 
			updateHealth(healthBar, 'x')
		end
	end

	-------------------------
	---CASTBAR ATTRIBUTES----
	-------------------------
	castBar.castbarOverlay = castbarOverlay
	castBar.shieldedRegion = shieldedRegion
	castBar.healthBar = healthBar
	castBar:SetStatusBarTexture(cfg.bartex)
	castBar:SetParent(healthBar)
	castBar:ClearAllPoints()
	castBar:SetPoint(cfg.castbar.anchor, healthBar, cfg.castbar.anchor2, cfg.castbar.xoffset, cfg.castbar.yoffset)
	castBar:SetSize(cfg.castbar.width, cfg.castbar.height)	

	castBar:HookScript("OnShow", OnShow)
	castBar:SetScript("OnValueChanged", OnValueChanged)
	castBar:SetScript("OnSizeChanged", OnSizeChanged)
	castBar:SetScript("OnEvent", CastbarEvents)
	castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	castBar:RegisterEvent("UNIT_SPELLCAST_START")
			
	castBar.time = castBar:CreateFontString(nil, "ARTWORK")
	castBar.time:SetPoint(cfg.casttime.anchor, castBar, cfg.casttime.anchor2, cfg.casttime.xoffset, cfg.casttime.yoffset)
	castBar.time:SetFont(cfg.casttime.font, cfg.casttime.fontSize, cfg.casttime.fontFlag)
	castBar.time:SetTextColor(0.95, 0.95, 0.95)
	castBar.time:SetShadowOffset(0, 0)
	castBar.time:SetShadowOffset(0.5, -0.5)
	castBar.time:SetShadowColor(0, 0, 0, 1)
	
	castBar.cname = castBar:CreateFontString(nil, "ARTWORK")
	castBar.cname:SetPoint(cfg.spellname.anchor, castBar, cfg.spellname.anchor2, cfg.spellname.xoffset, cfg.spellname.yoffset)
	castBar.cname:SetFont(cfg.spellname.font, cfg.spellname.fontSize, cfg.spellname.fontFlag)
	castBar.cname:SetTextColor(1, 1, 1)
	castBar.cname:SetShadowOffset(0, 0)
	castBar.cname:SetShadowOffset(0.5, -0.5)
	castBar.cname:SetShadowColor(0, 0, 0, 1)
	
	castBar.cbBackground = castBar:CreateTexture(nil, "BACKGROUND")
	castBar.cbBackground:SetAllPoints()
	castBar.cbBackground:SetTexture(cfg.bg)
	castBar.cbBackground:SetVertexColor(0.15, 0.15, 0.15, 0.8)

	castBar.cbGlow = CreateFrame("Frame", nil, castBar)
	castBar.cbGlow:SetFrameLevel(castBar:GetFrameLevel() -1 > 0 and castBar:GetFrameLevel() -1 or 0)
	castBar.cbGlow:SetPoint("TOPLEFT", castBar, -2, 2)
	castBar.cbGlow:SetPoint("BOTTOMRIGHT", castBar, 2, -2)
	castBar.cbGlow:SetBackdrop(cfg.backdrop)
	castBar.cbGlow:SetBackdropColor(0, 0, 0, 0)
	castBar.cbGlow:SetBackdropBorderColor(0.2, 0.2, 0.2)

	castBar.HolderA = CreateFrame("Frame", nil, castBar)
	castBar.HolderA:SetFrameLevel(castBar.HolderA:GetFrameLevel() + 1)
	castBar.HolderA:SetAllPoints()

	castBar.spellicon = spellIconRegion
	castBar.spellicon:SetSize(cfg.spellicon.size, cfg.spellicon.size)
	castBar.spellicon:ClearAllPoints()
	castBar.spellicon:SetPoint(cfg.spellicon.anchor, castBar, cfg.spellicon.anchor2, cfg.spellicon.xoffset, cfg.spellicon.yoffset)
		
	castBar.HolderB = CreateFrame("Frame", nil, castBar)
	castBar.HolderB:SetFrameLevel(castBar.HolderA:GetFrameLevel() + 2)
	castBar.HolderB:SetAllPoints()

	castBar.IconOverlay = castBar.HolderB:CreateTexture(nil, "OVERLAY")
	castBar.IconOverlay:SetPoint("TOPLEFT", spellIconRegion, -1.5, 1.5)
	castBar.IconOverlay:SetPoint("BOTTOMRIGHT", spellIconRegion, 1.5, -1.5)
	castBar.IconOverlay:SetTexture(cfg.icontex)
	
	-------------------------
	---Interruptable icon----
	-------------------------
	castBar.shield = castBar:CreateTexture(nil, "OVERLAY")
	castBar.shield:SetSize(20, 20)
	castBar.shield:ClearAllPoints()
	castBar.shield:SetPoint("LEFT", castBar, "RIGHT", 1, -4)
	castBar.shield:SetTexture([=[Interface\AddOns\shNameplates\media\shield]=])
	
	---------------------
	---POWER/MANA Bar----
	---------------------
	if cfg.powerbar then
		local powerBar = CreateFrame("StatusBar", nil)
		powerBar:SetParent(healthBar)
		powerBar:SetStatusBarTexture(cfg.bartex)
		powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2)
		powerBar:SetSize(cfg.healthbar.width, cfg.castbar.height)
		powerBar:SetFrameLevel(healthBar:GetFrameLevel() -1 > 0 and healthBar:GetFrameLevel() -1 or 0)
				
		powerBar.pbBackground = powerBar:CreateTexture(nil, "BACKGROUND")
		powerBar.pbBackground:SetAllPoints()
		powerBar.pbBackground:SetTexture(cfg.bg)
		powerBar.pbBackground:SetVertexColor(0.15, 0.15, 0.15, 0.8)
	
		powerBar.pGlow = CreateFrame("Frame", nil, powerBar)
		powerBar.pGlow:SetPoint("TOPLEFT", powerBar, "TOPLEFT", -2, 2)
		powerBar.pGlow:SetPoint("BOTTOMRIGHT", powerBar, "BOTTOMRIGHT", 2, -2)
		powerBar.pGlow:SetBackdrop(cfg.backdrop)
		powerBar.pGlow:SetFrameLevel(powerBar:GetFrameLevel() -1 > 0 and powerBar:GetFrameLevel() -1 or 0)
		powerBar.pGlow:SetBackdropColor(0, 0, 0, 0)
		powerBar.pGlow:SetBackdropBorderColor(0.6, 0.6, 0.6)
		powerBar:Hide()
		frame.powerBar = powerBar
		castBar.powerBar = powerBar
	end
	
	-----------------------
	---HIGHTLIGHT REGION---
	-----------------------
	highlightRegion:SetTexture(cfg.bartex)
	highlightRegion:SetVertexColor(0.25, 0.25, 0.25, 0.8)
	frame.highlight = highlightRegion

	---------------------
	---RAID ICON-----
	---------------------
	raidIconRegion:ClearAllPoints()
	raidIconRegion:SetPoint(cfg.raidicon.anchor, healthBar, cfg.raidicon.anchor2, cfg.raidicon.xoffset, cfg.raidicon.yoffset)
	raidIconRegion:SetSize(cfg.raidicon.size, cfg.raidicon.size)
	raidIconRegion:SetTexture(cfg.raidicon.textures)

	---------------------
	---ELITE/BOSS ICON-----
	---------------------	
	local mobsize = 13
	frame.mobtype = healthBar:CreateTexture(nil, "OVERLAY")
	frame.mobtype:SetSize(mobsize, mobsize)
	frame.mobtype:SetTexture([=[Interface\AddOns\shNameplates\media\elite]=])
	
	frame.mobtype2 = healthBar:CreateTexture(nil, "OVERLAY")
	frame.mobtype2:SetSize(mobsize, mobsize)
	frame.mobtype2:SetTexture([=[Interface\AddOns\shNameplates\media\elite]=])
	
	frame.oldglow = glowRegion
	frame.elite = stateIconRegion
	frame.boss = bossIconRegion	

	-->hide uglies
	glowRegion:SetTexture("")	
    overlayRegion:SetTexture("")	
    shieldedRegion:SetTexture("")	
	castbarOverlay:SetTexture("")	
    stateIconRegion:SetTexture("")	
    bossIconRegion:SetTexture("")
	
	--animations for initial fade in
	frame.ag = frame:CreateAnimationGroup()
	frame.fade = frame.ag:CreateAnimation('Alpha')
	frame.fade:SetSmoothing("OUT")
	frame.fade:SetDuration(0.5)
	frame.fade:SetChange(1)
	frame.ag:SetScript('OnFinished', function()
		frame:SetAlpha(frame.fade:GetChange())
		-- otherwise it flashes
	end)
	
	---------------------
	---EVENT SCRIPTS-----
	---------------------
	frame:SetScript("OnShow", UpdatePlate)
	frame:SetScript("OnHide", OnHide)
	frame:SetScript("OnEvent", FrameEvents)
	frame:RegisterEvent("UNIT_POWER")
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("UNIT_COMBO_POINTS")
	frame:SetScript("OnUpdate", ThreatUpdate)
	
	frame.isTarget = false
	frame.skinned = true
	frame.elapsed = 1	
	UpdatePlate(frame)	
end

----------------------------------
-----CREATE/FIND ALL PLATES-------
----------------------------------
local function searchForNameplates(self)
	--set timer to loop instead of onupdate script
	local ag = self:CreateAnimationGroup()
	ag.anim = ag:CreateAnimation()
	ag.anim:SetDuration(0.25) -- time per loop
	ag:SetLooping("REPEAT")
	ag:SetScript("OnLoop", function(self, event, ...)
		local curKids = WorldFrame:GetNumChildren()
		local i
		if curKids ~= numKids then
			numKids = curKids		
			--for i = numKids + 1, curKids do
			for i = 1, curKids do
				local frame = select(i, WorldFrame:GetChildren())
				if (frame:GetName() and frame:GetName():find("NamePlate%d") and not frame.skinned) then
					createPlate(frame)
					frame.skinned = true
					--print("Skinned: ", frame.oldname:GetText())
				end
			end				
		end
	end)
	ag:Play() --start loop to search constantly
end


-->Register initial login event 
local updateFrame = CreateFrame("Frame")
updateFrame:RegisterEvent("PLAYER_LOGIN")
updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

updateFrame:SetScript("OnEvent", function(self, event, ...)
	if (event=="PLAYER_LOGIN") then 
		SetCVar("bloattest",0)
		SetCVar("bloatnameplates",0)
		SetCVar("bloatthreat",0)
		SetCVar("ShowClassColorInNameplate", 1)
		searchForNameplates(self)
	elseif (event == "PLAYER_REGEN_DISABLED") then 
		InCombat = true
		if cfg.autoshow then 
			SetCVar("nameplateShowEnemies", 1)
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		InCombat = false
		if cfg.autohide then 
			SetCVar("nameplateShowEnemies", 0) 
		end
	end
end)
--END OF ADDON--  