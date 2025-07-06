local _, playerClass = UnitClass("player")
if playerClass ~= "HUNTER" then return end

local L = HunterBiuBiu.L


StaticPopupDialogs["RESET_HBB_PROFILE"] = {
	text = L["Do you really want to reset to default for your current profile?"],
	button1 = L["OK"],
	button2 = L["Cancel"],
	OnAccept = function()
		HunterBiuBiu:ResetDB("profile")
		HunterBiuBiu:SystemMessage(HunterBiuBiu.L["Current profile has been reset."])
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

-- Default Settings ------------------------------------------------------------------------
HunterBiuBiu.defaults = {
	profile = {
		secondCastLimit = 0.5,
		showIcon = true,
		hasIcon = "Interface\\Icons\\Ability_Hunter_RunningShot",
		defaultMinimapPosition = false,
		tranq = false,
		tranqmsg = L["TRANQ_SUCCEEDMSG"],
		tranqfailmsg = L["TRANQ_FAILEDMSG"],
		channel = "SAY",
		channels = {
			["SAY"] = false,
			["YELL"] = false,
			["RAID"] = false,
			["PARTY"] = false,
			["EMOTE"] = false
		},
		tv1 = 2.7,
		tv2 = 2.1,
		howl = false,
		multishot = true,
		aimedshot = false,
		steadyshotActionId = 22,
		multishotActionId = 23,
		autoshotActionId = 24,
		optimizeSec = false,
		optimizeSecLimit = 0.8,
		autoshotbar = false,
		restoreauto = false,
		priorauto = false,
		autoshotbarw = 200,
		autoshotbarh = 20,
		autoshotbarr1 = 0.1,
		autoshotbarg1 = 0.7,
		autoshotbarb1 = 0.1,
		autoshotbarr2 = 0.7,
		autoshotbarg2 = 0.1,
		autoshotbarb2 = 0.1,
		autoshotbartemp = 'l2rr2l',
		autoshotbartext = true,
		autoshotbartmr = true,
		feigndeathon = false,
		feigndeathdelay = 2,
		feigndeathmask = true,
		feigndeathtext = L["Feign Death Resisted"],
		feigndeathfontsize = 20,
		feigndeathtextr = 1,
		feigndeathtextg = 1,
		feigndeathtextb = 1,
		feigndeathtexta = 0.9,
		feigndeathalarm = false,
		feigndeathr = 1,
		feigndeathg = 0,
		feigndeathb = 0,
		feigndeatha = 0.3,
		feigndeathx = 0,
		feigndeathy = 100,
		feigndeathalert = false,
		feigndeathalertmsg = L["Feign Death Alert Message"],
		aconlycombat=false,
		secondspell=false,
		secondspellonlyboss=true,
		secondspelllimit=1,
		secondspellserpent=true,
		secondspellarcane=false,
		secondspellserpentlimit=300000,
		secondspellarcanelv1=false,
		secondspellarcanelimit=3000,
		multishotfirst=false,
		multishotfirstlimit=1.5,
		lightningbreath=false,
		autoshotbarshow=false
	},
}
--------------------------------------------------------------------------------------------
