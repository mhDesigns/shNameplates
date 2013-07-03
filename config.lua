--CONFIG: shNameplates (REQUIRES RELOADING your UI for changes to take effect)

--**IMPORTANT** - BE very careful and ONLY change the values themselves, keep all commas/syntax entact or you will break the addon!

local _, shNameplates = ...

local cfg = CreateFrame("Frame")

--> To change fonts just copy/paste your favorite font(s) into the media folder of the addon and change the string values
	--> after the mediapath syntax (just change the name in " "
local mediapath = [=[Interface\AddOns\shNameplates\media\]=]

--> TEXTURE options (add your own textures here)
	cfg.bartex = 	mediapath.."statusbar"
	cfg.bg =		mediapath.."bg"
	cfg.icontex = 	mediapath.."icontexture"
		
--> BEHAVIOR options
	cfg.autohide		= false		--> automatically hide nameplates when OUT OF COMBAT only
	cfg.autoshow 		= true		--> automatically show nameplates when IN COMBAT only
	cfg.tankmode 		= false		--> true: will show custom color overlay/statusbar if you HAVE aggro and false: will show RED overlay if you HAVE aggro
	cfg.namecolor 		= false		--> true: will show unit names in color of their hostility/pvp or false: will show static color given below
	cfg.powerbar 		= true		--> true: will show power bar or false: will not show power bar (NOTE: only show power bar on enemy players in PVP ONLY)
	cfg.hidecastinfo	= false		--> true: will hide all text related to castbar (name/time) - false: will show casting related info
	cfg.hidepoints		= false		--> true: will hide small point textures on nameplate representing class specific spells/etc (ie combo points, holy power, shadow orbs...)
	cfg.showhpvalue 	= true		--> show hp value text in healthbar if not at 100% health 
	cfg.hpallthetime 	= false		--> ***NOTE: will create error in addon if this is set to true and showhpvalue option set to false! --shows the hp value of the mob at all times
	
--> COLOR options (any RGB percent color of your choosing)
	cfg.colors = {
		hostile = 		{ r = 0.65, g = 0.34, b = 0.34 },	--> Default: red 
		friendlynpc =	{ r = 0.34, g = 0.80, b = 0.34 },	--> Default: green 
		friendly = 		{ r = 0.31, g = 0.45, b = 0.63 },	--> Default: blue 
		neutral = 		{ r = 0.65, g = 0.63, b = 0.35 }, 	--> Default: yellow 
		
	--> tankmode color options (ONLY APPLY if you have tankmode SET to TRUE)
		aggro =			{ r = 0.34, g = 0.60, b = 0.34 }, 	--> If you have aggro, the status bar color itself (ONLY WORKS if TANKMODE = true)
		highthreat =	{ r = 0.65, g = 0.65, b = 0.34 }, 	--> If you have HIGH threat, the status bar color itself (ONLY WORKS if TANKMODE = true)		
	}

--> POWERBAR colors (any RGB percent color of your choosing)
	cfg.powercolors = {
		mana = 			{ r = 0.31, g = 0.45, b = 0.63 },
		rage = 			{ r = 0.69, g = 0.31, b = 0.31 },
		focus =			{ r = 0.71, g = 0.43, b = 0.27 },
		energy =		{ r = 0.65, g = 0.63, b = 0.35 },
		runic =			{ r = 0.00, g = 0.82, b = 1.00 }, 
	}
	
--> BACKDROP table for the statusbars 
	cfg.backdrop = {
		bgFile   =  mediapath.."bg",
		edgeFile = 	mediapath.."glowtexture", 
		edgeSize = 	2,
		insets   = 	{ left = 2, right = 2, top = 2, bottom = 2 }, 
	}
	
--> RAIDICON
	cfg.raidicon = {
		textures = 	mediapath.."raidicons.blp", --"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 
		size = 24,					--> square dimension (in pixels)
		anchor = "BOTTOM",			--> anchor point of the raidicon to the health bar
		anchor2 = "TOP",			--> anchor point of the healthbar to the raid icons
		xoffset = 0,				--> x-offset of the anchor
		yoffset = 8,				--> y-offset of the anchor
	}
	
--> SPELLICON
	cfg.spellicon = {
		size = 		18,				--> square dimension (in pixels)
		anchor = 	"BOTTOMRIGHT",	--> anchor point of the spell icon to cast bar
		anchor2 = 	"BOTTOMLEFT",	--> anchor point of the cast bar to spell icon
		xoffset = 	-2,				--> x-offset of the anchor
		yoffset = 	-1,				--> y-offset of the anchor
	}
	
	--****easy bar width to match for both health and cast
	local barwidth = 100
	
--> HEALTHBAR 	
	cfg.healthbar = {
		width = 	barwidth, 		--> healthbar bar width
		height = 	8,				--> healthbar bar height
		yoffset = 	0, 				--> y-offset of the nameplate itself from the default blizzard nameplate
	}
	
--> CASTBAR
	cfg.castbar = {
		width =		barwidth, 				--> castbar bar width
		height = 	4,						--> castbar bar height
		anchor = 	"TOP", 					--> anchor point of the castbar to the health bar
		anchor2 =	"BOTTOM", 				--> anchor point of the healthbar to the cast bar
		xoffset =	0, 						--> x-offset of the anchor 
		yoffset =	-4, 					--> y-offset of the anchor
	}
		
--> CASTTIME
	cfg.casttime = {
		--> Cast time options
		font = 		mediapath.."osb.ttf", 			--> cast time font
		fontSize = 	6, 								--> cast time font size
		fontFlag =  nil, 							--> cast time font flag					
		anchor = 	"TOPRIGHT", 					--> anchor point of cast time to the castbar
		anchor2 =	"BOTTOMRIGHT", 					--> anchor point of castbar to the cast time
		xoffset =	0, 								--> x-offset of the anchor 
		yoffset =	-2, 							--> y-offset of the anchor
	}	
	
--> SPELL NAME text attributes
	cfg.spellname = {
		font =		mediapath.."osb.ttf", 			--> spell name font
		fontSize =	6,								--> spell name font size
		fontFlag = 	nil,							--> spell name font flag
		anchor = 	"TOPLEFT", 						--> anchor point of the spell name text to the cast bar
		anchor2 =	"BOTTOMLEFT",					--> anchor point of the cast bar to the spell name text
		xoffset =	2, 								--> x-offset of the anchor 
		yoffset =	-2, 							--> y-offset of the anchor
	}
	
--> NAME text attributes
	cfg.name = {
		font = 		mediapath.."osb.ttf", 
		fontSize = 	6.5,	
		fontFlag =  nil,
		color = 	{ r = 0.95, g = 0.95, b = 0.95 },	
		uppercase = true,							--> change to false to format in all lower cases
		anchor = 	"BOTTOM", 						--> anchor point of the name text to the health bar
		anchor2 =	"TOP",							--> anchor point of the healtbar to the name text
		xoffset =	0, 								--> x-offset of the anchor 
		yoffset =	1, 								--> y-offset of the anchor
	}
	
--> LEVEL text attributes
	cfg.level = {
		font = 		mediapath.."samsonpx.ttf",  
		fontSize =  5,
		fontFlag = 	"OUTLINEMONONCHROME",
		anchor = 	"LEFT", 						--> anchor point of the level text to the healthbar
		anchor2 =	"RIGHT", 						--> anchor point of the healthbar to the level text
		xoffset =	2,								--> x-offset of the anchor 
		yoffset =	0, 								--> y-offset of the anchor
	}
		
--> HEALTH text attributes
	cfg.health = {
		font = 		mediapath.."samsonpx.ttf", 
		fontSize = 	5,
		fontFlag = 	"OUTLINEMONOCHROME", 
		anchor = 	"CENTER", 						--> anchor point of the health text to the health bar 
		anchor2 = 	"CENTER", 						--> anchor point of the health bar to the health text
		xoffset =	0, 								--> x-offset of the anchor 
		yoffset =	0, 								--> y-offset of the anchor
	}
	
--HANDOVER for other lua files
shNameplates.cfg = cfg

