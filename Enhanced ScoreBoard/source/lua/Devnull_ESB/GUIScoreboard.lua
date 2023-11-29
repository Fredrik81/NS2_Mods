-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIScoreboard.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages the player scoreboard (scores, pings, etc).
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SpecialSkillTierRecipients.lua")

class "GUIScoreboard"(GUIScript)

-- Horizontal size for the game time background is irrelevant as it will be expanded to SB width
GUIScoreboard.kGameTimeBackgroundSize = Vector(640, GUIScale(32), 0)
GUIScoreboard.kClickForMouseBackgroundSize = Vector(GUIScale(200), GUIScale(32), 0)
GUIScoreboard.kClickForMouseText = Locale.ResolveString("SB_CLICK_FOR_MOUSE")

GUIScoreboard.kFavoriteIconSize = Vector(26, 26, 0)
GUIScoreboard.kFavoriteTexture = PrecacheAsset("ui/menu/favorite.dds")
GUIScoreboard.kNotFavoriteTexture = PrecacheAsset("ui/menu/nonfavorite.dds")

GUIScoreboard.kBlockedIconSize = Vector(26, 26, 0)
GUIScoreboard.kBlockedTexture = PrecacheAsset("ui/menu/blocked.dds")
GUIScoreboard.kNotBlockedTexture = PrecacheAsset("ui/menu/notblocked.dds")

GUIScoreboard.kSlidebarSize = Vector(7.5, 25, 0)
GUIScoreboard.kBgColor = Color(0, 0, 0, 0.5)
GUIScoreboard.kBgMaxYSpace = Client.GetScreenHeight() - ((GUIScoreboard.kClickForMouseBackgroundSize.y + 5) + (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 20)

local kIconSize = Vector(40, 40, 0)
local kIconOffset = Vector(-15, -10, 0)

-- Shared constants.
GUIScoreboard.kTeamInfoFontName = Fonts.kArial_15
GUIScoreboard.kTeamSmallFont = ReadOnly {family = "Arial", size = 10}
GUIScoreboard.kTeamSmallBoldFont = ReadOnly {family = "Arial", size = 11}
GUIScoreboard.kTeamLargeFont = ReadOnly {family = "Arial", size = 12}
GUIScoreboard.kTeamLargeBoldFont = ReadOnly {family = "Arial", size = 13}
GUIScoreboard.kPlayerStatsFontName = Fonts.kArial_15
--GUIScoreboard.kPlayerStatsFontName = Fonts.kInsight
GUIScoreboard.kTeamNameFontName = Fonts.kArial_17
--GUIScoreboard.kTeamNameFontName = Fonts.kInsight
GUIScoreboard.kGameTimeFontName = Fonts.kArial_17
GUIScoreboard.kTeamNameFontName = Fonts.kArial_17
GUIScoreboard.kTeamNameFontName = Fonts.kInsight
GUIScoreboard.kClickForMouseFontName = Fonts.kArial_17
--GUIScoreboard.kClickForMouseFontName = Fonts.kInsight

GUIScoreboard.kLowPingThreshold = 100
GUIScoreboard.kLowPingColor = Color(0, 1, 0, 1)
GUIScoreboard.kMedPingThreshold = 249
GUIScoreboard.kMedPingColor = Color(1, 1, 0, 1)
GUIScoreboard.kHighPingThreshold = 499
GUIScoreboard.kHighPingColor = Color(1, 0.5, 0, 1)
GUIScoreboard.kInsanePingColor = Color(1, 0, 0, 1)
GUIScoreboard.kVoiceMuteColor = Color(1, 1, 1, 1)
GUIScoreboard.kVoiceDefaultColor = Color(1, 1, 1, 0.5)
GUIScoreboard.kHighPresThreshold = 75
GUIScoreboard.kHighPresColor = Color(1, 1, 0, 1)
GUIScoreboard.kVeryHighPresThreshold = 90
GUIScoreboard.kVeryHighPresColor = Color(1, 0.5, 0, 1)

-- Team constants.
GUIScoreboard.kTeamBackgroundYOffset = 50
GUIScoreboard.kTeamNameFontSize = 26
GUIScoreboard.kTeamInfoFontSize = 16
GUIScoreboard.kTeamItemWidth = 600
GUIScoreboard.kTeamItemHeight = GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 8
GUIScoreboard.kTeamSpacing = 32
GUIScoreboard.kTeamScoreColumnStartX = 200
GUIScoreboard.kTeamColumnSpacingX = ConditionalValue(Client.GetScreenWidth() < 1280, 30, 40)

-- Player constants.
GUIScoreboard.kPlayerStatsFontSize = 16
GUIScoreboard.kPlayerItemWidthBuffer = 10
GUIScoreboard.kPlayerItemWidth = 275
GUIScoreboard.kPlayerItemHeight = 32
GUIScoreboard.kPlayerSpacing = 4

local kPlayerItemLeftMargin = 10
local kPlayerNumberWidth = 20
local kPlayerVoiceChatIconSize = 20
local kPlayerBadgeIconSize = 20
local kPlayerBadgeRightPadding = 4

local kPlayerSkillIconSize = Vector(62, 20, 0)
local kPlayerSkillIconTexture = PrecacheAsset("ui/skill_tier_icons.dds")
local kPlayerSkillIconSizeOverride = Vector(58, 20, 0) -- slightly smaller so it doesn't overlap.

local kPlayerCommIconSize = Vector(15, 15, 0)
local kPlayerCommIconTexture = PrecacheAsset("ui/badges/commander.dds")
--local fontArialBlack = PrecacheAsset("fonts/DevArialBlack.fnt")
local kPlayerCommIconsTexture = PrecacheAsset("ui/Devnull/ComSkillBadges.dds")
local kMarineStatsLogo = PrecacheAsset("ui/logo_marine.dds")
local kAlienStatsLogo = PrecacheAsset("ui/logo_alien.dds")
local lastComm = {}
lastComm[kTeam1Index] = nil
lastComm[kTeam2Index] = nil
local localPlayerIsSpectator = false
local localPlayerSteamID = Client:GetSteamId()
local kHeaderCoordsLeft = {0, 0, 15, 64}
local kHeaderCoordsMiddle = {16, 0, 112, 64}
local kHeaderCoordsRight = {113, 0, 128, 64}
local kHeaderTexture = PrecacheAsset("ui/statsheader.dds")
local kTitleSize = Vector(Client.GetScreenWidth() * ConditionalValue((Client.GetScreenWidth() / Client.GetScreenHeight()) < 1.5, 0.95, 0.75), GUILinearScale(54), 0)
--GUIScoreboard.kTeamBackgroundYOffset = GUIScoreboard.kTeamBackgroundYOffset + kTitleSize.y + 5
local kBuildmenuTexture = PrecacheAsset("ui/buildmenu.dds")
local kHudElementsTexture = PrecacheAsset("ui/hud_elements.dds")
local kSteamfriendTexture = PrecacheAsset("ui/steamfriend.dds")
local kEalAlienTexture = PrecacheAsset("ui/Devnull/Alien.dds")
local kEalMarineTexture = PrecacheAsset("ui/Devnull/Marine.dds")
local EALitems = {}
local function RGBAtoColor(r, g, b, a)
	return Color(r / 255, g / 255, b / 255, a)
end

local playerStatsTable = {}
local globalFetchTime = 20 + Shared.GetTime() + math.random(1, 5)

--local fetchUrl = "https://ns2panel.com/api/player/%s/stats"
local fetchUrl = "https://ns2panel.com/api/players/stats?player_ids=%s"
--local fetchUrl = "https://ns2panel.com/api/stats/players?ids=%s"
local playerHwid = nil

local kEalInactiveColor = RGBAtoColor(96, 96, 96, 1)
local kEalActiveColor = RGBAtoColor(255, 255, 255, 1)

local lastScoreboardVisState = false

local kSteamProfileURL = "http://steamcommunity.com/profiles/"
local kNS2PanelProfileURL = "https://ns2panel.com/player/%s"
local kMinTruncatedNameLength = 8
local lowResScreen = (Client.GetScreenWidth() < 1800) and true or false

-- Color constants.
GUIScoreboard.kBlueColor = ColorIntToColor(kMarineTeamColor)
GUIScoreboard.kBlueHighlightColor = Color(0.30, 0.69, 1, 1)
GUIScoreboard.kRedColor = kRedColor
--ColorIntToColor(kAlienTeamColor)
GUIScoreboard.kRedHighlightColor = Color(1, 0.79, 0.23, 1)
GUIScoreboard.kSpectatorColor = ColorIntToColor(kNeutralTeamColor)
GUIScoreboard.kSpectatorHighlightColor = Color(0.8, 0.8, 0.8, 1)

GUIScoreboard.kCommanderFontColor = Color(1, 1, 0, 1)
GUIScoreboard.kWhiteColor = Color(1, 1, 1, 1)
local kDeadColor = Color(1, 0, 0, 1)

local kMutedTextTexture = PrecacheAsset("ui/sb-text-muted.dds")
local kMutedVoiceTexture = PrecacheAsset("ui/sb-voice-muted.dds")

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

local function getHWID()
	local function all_trim(s)
		return s:match "^%s*(.*)":match "(.-)%s*$"
	end

	--local fh = io.open("wmic csproduct get uuid")
	local fh = os.execute("dir game_setup.xml")
	if true then
		return tostring(fh)
	end
	result = fh:read "*a"
	fh:close()
	result = string.gsub(result, "UUID", "")
	result = all_trim(result)
	--result = string.sub(result,5)
	return result
end

-- Round function implementation with round up and decimal
local function round(number, decimals)
	if number and IsNumber(number) then
		if decimals > 0 then
			decimals = 10 ^ decimals
			number = number * decimals
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
			number = number / decimals
		else
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
		end

		return tostring(number)
	else
		return "NaN"
	end
end

local function humanNumber(number)
	if number and IsNumber(number) then
		if number > 1000000 then
			number = number / 10000
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
			number = number / 100
			number = tostring(number) .. "m"
		elseif number > 1000 then
			number = number / 100
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
			number = number / 10
			number = tostring(number) .. "k"
		end

		return tostring(number)
	else
		return "NaN"
	end
end

local function myPrint(string)
	if Client.GetSteamId() == 74660439 or Client.GetSteamId() == 77470693 then
		HPrint(string)
	end
end

local function tblIndexSortSubValue(tbl, subvalue)
	local idx = {}
	for i = 1, #tbl do
		idx[i] = i
	end -- build a table of indexes
	-- sort the indexes, but use the values as the sorting criteria
	table.sort(
		idx,
		function(a, b)
			return tbl[a][subvalue] > tbl[b][subvalue]
		end
	)
	-- return the sorted indexes
	return (table.unpack or unpack)(idx)
end

local function fetchPlayerStats(steamId)
	if not steamId then
		return
	end

	if globalFetchTime + 15 > Shared.GetTime() then
		return
	end
	globalFetchTime = Shared.GetTime() -- adding this to spam less code

	if Client.GetSteamId() == 74660439 or Client.GetSteamId() == 77470693 then
	--fetchUrl = "https://ns2panel.com/api/stats/players?ids=%s"
	end

	--myPrint("currentPlayers: " .. dump(steamId))
	local usersToFetch = nil
	for i, user in ipairs(steamId) do
		if not (playerStatsTable[user] and playerStatsTable[user].fetched) then
			--myPrint("- " .. tostring(user) .. ", MISSING")
			if usersToFetch then
				usersToFetch = usersToFetch .. "," .. tostring(user)
			else
				usersToFetch = tostring(user)
			end
			playerStatsTable[user] = {}
			playerStatsTable[user].fetched = 0
		else
			--myPrint("- " .. tostring(user) .. ", EXIST")
		end
	end

	if usersToFetch then
		usersToFetch = usersToFetch
		--myPrint("Requesting ns2panel data for: " .. usersToFetch)
		--myPrint(string.format(fetchUrl, usersToFetch))
		Shared.SendHTTPRequest(
			string.format(fetchUrl, usersToFetch),
			"GET",
			{},
			function(data)
				if not data then
					return
				end
				local tdata = json.decode(data)
				if tdata then
					for index, value in ipairs(tdata) do
						if value and value.marine_skill and value.steam_id then
							--playerStatsTable[746604391] = value
							--myPrint("Recived data for: " .. tostring(value.steam_id))
							playerStatsTable[value.steam_id] = value
							playerStatsTable[value.steam_id].fetched = 1
						else
							--myPrint("Recived bad-data for: " .. tostring(value.steam_id))
							--myPrint("DATA: " .. dump(value))
						end
					end
				end
			end
		)
	end
end

local function enumContainElement(enum, element)
	for _, v in pairs(enum) do
		if _ == element then
			return true
		end
	end
	return false
end
local techCarapaceWorkaround = enumContainElement(kTechId, "Resilience")

local function getPlayerStats(steamId)
	if not steamId then
		return nil
	end

	if playerStatsTable[steamId] and playerStatsTable[steamId].fetched then
		return playerStatsTable[steamId]
	end
	return nil
end

function GUIScoreboard:OnResolutionChanged(_, _, newX, _)
	GUIScoreboard.screenWidth = newX

	GUIScoreboard.kTeamColumnSpacingX = ConditionalValue(GUIScoreboard.screenWidth < 1280, 30, 40)

	-- Horizontal size for the game time background is irrelevant as it will be expanded to SB width
	GUIScoreboard.kGameTimeBackgroundSize = Vector(640, GUIScale(32), 0)
	GUIScoreboard.kClickForMouseBackgroundSize = Vector(GUIScale(200), GUIScale(32), 0)

	GUIScoreboard.kBgMaxYSpace = Client.GetScreenHeight() - ((GUIScoreboard.kClickForMouseBackgroundSize.y + 5) + (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 20)

	self:Uninitialize()
	self:Initialize()
end

function GUIScoreboard:GetTeamItemWidth()
	if GUIScoreboard.screenWidth < 1280 then
		return 608 -- 640 * 0.95
	else
		return math.min(800, GUIScoreboard.screenWidth / 2 * 0.95)
	end
end

local function CreateTeamBackground(self, teamNumber)
	local color
	local teamItem = GUIManager:CreateGraphicItem()
	teamItem:SetStencilFunc(GUIItem.NotEqual)

	-- Background
	local isPlayingTeam = teamNumber ~= kTeamReadyRoom
	teamItem:SetSize(Vector(self:GetTeamItemWidth(), GUIScoreboard.kTeamItemHeight, 0) * GUIScoreboard.kScalingFactor)
	if teamNumber == kTeamReadyRoom then
		color = GUIScoreboard.kSpectatorColor
		teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
	elseif teamNumber == kTeam1Index then
		color = GUIScoreboard.kBlueColor
		teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
	elseif teamNumber == kTeam2Index then
		color = GUIScoreboard.kRedColor
		teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
	end

	teamItem:SetColor(Color(0, 0, 0, 0.75))
	teamItem:SetIsVisible(false)
	teamItem:SetLayer(kGUILayerScoreboard)

	-- Team name text item.
	local teamNameItem = GUIManager:CreateTextItem()
	--teamNameItem:SetFont("AgencyBold", 32)
	teamNameItem:SetFont(GUIScoreboard.kTeamLargeBoldFont)
	--teamNameItem:SetFontName("fonts/MicrogrammaDBolExt_16.fnt")
	--teamNameItem:SetFontSize(17)
	teamNameItem:SetFontIsBold(true)
	--teamNameItem:SetFontName(Fonts.kInsight)
	--teamNameItem:SetFontSize(17)
	--teamNameItem:SetFontName(GUIScoreboard.kTeamNameFontName)
	--teamNameItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(teamNameItem)
	teamNameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	teamNameItem:SetTextAlignmentX(GUIItem.Align_Min)
	teamNameItem:SetTextAlignmentY(GUIItem.Align_Min)
	if not isPlayingTeam then
		teamNameItem:SetPosition(Vector(10, 5, 0) * GUIScoreboard.kScalingFactor)
	else
		teamNameItem:SetPosition(Vector(10 + kPlayerSkillIconSize.x, 5, 0) * GUIScoreboard.kScalingFactor)
	end
	teamNameItem:SetColor(color)
	teamNameItem:SetStencilFunc(GUIItem.NotEqual)
	teamItem:AddChild(teamNameItem)

	local teamSkillItem = GUIManager:CreateGraphicItem()
	teamSkillItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	teamSkillItem:SetPosition(Vector(10, 5, 0) * GUIScoreboard.kScalingFactor)
	teamSkillItem:SetSize(kPlayerSkillIconSize * GUIScoreboard.kScalingFactor)
	teamSkillItem:SetStencilFunc(GUIItem.NotEqual)
	teamSkillItem:SetTexture(kPlayerSkillIconTexture)
	teamSkillItem:SetTexturePixelCoordinates(0, 0, 100, 31)
	teamSkillItem:SetIsVisible(false)
	teamItem:AddChild(teamSkillItem)

	local playerDataRowY = 10
	local currentColumnX = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth, self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10)

	-- Add team info items (team resources etc).
	local teamInfoItems = {}
	teamInfoItems["teamRes"] = GUIManager:CreateTextItem()
	teamInfoItems["teamRes"]:SetFont(GUIScoreboard.kTeamSmallBoldFont)
	--teamInfoItems["teamRes"]:SetFontName(GUIScoreboard.kTeamInfoFontName)
	--teamInfoItems["teamRes"]:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(teamInfoItems["teamRes"])
	teamInfoItems["teamRes"]:SetAnchor(GUIItem.Left, GUIItem.Top)
	teamInfoItems["teamRes"]:SetTextAlignmentX(GUIItem.Align_Min)
	teamInfoItems["teamRes"]:SetTextAlignmentY(GUIItem.Align_Min)
	teamInfoItems["teamRes"]:SetPosition(Vector(12, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
	teamInfoItems["teamRes"]:SetColor(color)
	teamInfoItems["teamRes"]:SetStencilFunc(GUIItem.NotEqual)
	teamItem:AddChild(teamInfoItems["teamRes"])

	teamInfoItems["teamCommIcon"] = GUIManager:CreateGraphicItem()
	teamInfoItems["teamCommIcon"]:SetSize(Vector(kPlayerBadgeIconSize, kPlayerBadgeIconSize, 0))
	teamInfoItems["teamCommIcon"]:SetAnchor(GUIItem.Right, GUIItem.Top)
	--playerCommIcon:SetPosition(Vector(kPlayerCommIconSize.x, kPlayerCommIconSize.y / 2, 0) * GUIScoreboard.kScalingFactor)
	teamInfoItems["teamCommIcon"]:SetPosition(Vector(-12 - kPlayerBadgeIconSize, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
	--teamInfoItems["teamCommIcon"]:SetStencilFunc(GUIItem.NotEqual)
	teamInfoItems["teamCommIcon"]:SetTexture(kPlayerCommIconTexture)
	teamInfoItems["teamCommIcon"]:SetIsVisible(isPlayingTeam)
	--playerCommIcon:SetTexturePixelCoordinates(0, 0, 100, 31)
	--playerItem:AddChild(playerCommIcon)
	teamItem:AddChild(teamInfoItems["teamCommIcon"])

	-- Add team commander
	teamInfoItems["teamComm"] = GUIManager:CreateTextItem()
	teamInfoItems["teamComm"]:SetFont(GUIScoreboard.kTeamLargeBoldFont)
	--teamInfoItems["teamComm"]:SetFontName(GUIScoreboard.kTeamNameFontName)
	--teamInfoItems["teamComm"]:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(teamInfoItems["teamComm"])
	teamInfoItems["teamComm"]:SetAnchor(GUIItem.Right, GUIItem.Top)
	teamInfoItems["teamComm"]:SetTextAlignmentX(GUIItem.Align_Max)
	teamInfoItems["teamComm"]:SetTextAlignmentY(GUIItem.Align_Min)
	teamInfoItems["teamComm"]:SetPosition(Vector(-12 - kPlayerBadgeIconSize - 4, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
	teamInfoItems["teamComm"]:SetText(Locale.ResolveString("NO_COMMANDER"))
	teamInfoItems["teamComm"]:SetColor(color)
	teamInfoItems["teamComm"]:SetStencilFunc(GUIItem.NotEqual)
	teamInfoItems["teamComm"]:SetIsVisible(isPlayingTeam)
	teamItem:AddChild(teamInfoItems["teamComm"])

	-- Status text item.
	local statusItem = GUIManager:CreateTextItem()
	statusItem:SetFont(GUIScoreboard.kTeamSmallBoldFont)
	--statusItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	--statusItem:SetFont("Agency", 15)
	--statusItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(statusItem)
	statusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	statusItem:SetTextAlignmentX(GUIItem.Align_Min)
	statusItem:SetTextAlignmentY(GUIItem.Align_Min)
	statusItem:SetPosition(Vector(currentColumnX + 60, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
	statusItem:SetColor(color)
	statusItem:SetText("")
	statusItem:SetStencilFunc(GUIItem.NotEqual)
	teamItem:AddChild(statusItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 2 + 33

	-- Score text item.
	local scoreItem = GUIManager:CreateTextItem()
	scoreItem:SetFont(GUIScoreboard.kTeamSmallBoldFont)
	--scoreItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	--scoreItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(scoreItem)
	scoreItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	scoreItem:SetTextAlignmentX(GUIItem.Align_Center)
	scoreItem:SetTextAlignmentY(GUIItem.Align_Min)
	scoreItem:SetPosition(Vector(currentColumnX + 42.5, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
	scoreItem:SetColor(color)
	scoreItem:SetText(Locale.ResolveString("SB_SCORE"))
	scoreItem:SetStencilFunc(GUIItem.NotEqual)
	scoreItem:SetIsVisible(isPlayingTeam)
	teamItem:AddChild(scoreItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX + 40

	-- Kill text item.
	local killsItem = GUIManager:CreateTextItem()
	killsItem:SetFont(GUIScoreboard.kTeamSmallBoldFont)
	--killsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	--killsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(killsItem)
	killsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	killsItem:SetTextAlignmentX(GUIItem.Align_Center)
	killsItem:SetTextAlignmentY(GUIItem.Align_Min)
	killsItem:SetPosition(Vector(currentColumnX, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
	killsItem:SetColor(color)
	killsItem:SetText(Locale.ResolveString("SB_KILLS"))
	killsItem:SetStencilFunc(GUIItem.NotEqual)
	killsItem:SetIsVisible(isPlayingTeam)
	teamItem:AddChild(killsItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- Assist text item.
	local assistsItem = GUIManager:CreateTextItem()
	assistsItem:SetFont(GUIScoreboard.kTeamSmallBoldFont)
	--assistsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	--assistsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(assistsItem)
	assistsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	assistsItem:SetTextAlignmentX(GUIItem.Align_Center)
	assistsItem:SetTextAlignmentY(GUIItem.Align_Min)
	assistsItem:SetPosition(Vector(currentColumnX, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
	assistsItem:SetColor(color)
	assistsItem:SetText(Locale.ResolveString("SB_ASSISTS"))
	assistsItem:SetStencilFunc(GUIItem.NotEqual)
	assistsItem:SetIsVisible(isPlayingTeam)
	teamItem:AddChild(assistsItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- Deaths text item.
	local deathsItem = GUIManager:CreateTextItem()
	deathsItem:SetFont(GUIScoreboard.kTeamSmallBoldFont)
	--deathsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	--deathsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(deathsItem)
	deathsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	deathsItem:SetTextAlignmentX(GUIItem.Align_Center)
	deathsItem:SetTextAlignmentY(GUIItem.Align_Min)
	deathsItem:SetPosition(Vector(currentColumnX, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
	deathsItem:SetColor(color)
	deathsItem:SetText(Locale.ResolveString("SB_DEATHS"))
	deathsItem:SetStencilFunc(GUIItem.NotEqual)
	deathsItem:SetIsVisible(isPlayingTeam)
	teamItem:AddChild(deathsItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- Resources text item.
	local resItem = GUIManager:CreateGraphicItem()
	resItem:SetPosition((Vector(currentColumnX, GUIScoreboard.kTeamNameFontSize + 7, 0) + kIconOffset) * GUIScoreboard.kScalingFactor)
	resItem:SetTexture(kBuildmenuTexture)
	resItem:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.CollectResources)))
	resItem:SetSize(kIconSize * GUIScoreboard.kScalingFactor)
	resItem:SetStencilFunc(GUIItem.NotEqual)
	resItem:SetIsVisible(isPlayingTeam)
	teamItem:AddChild(resItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- Ping text item.
	local pingItem = GUIManager:CreateTextItem()
	pingItem:SetFont(GUIScoreboard.kTeamSmallBoldFont)
	--pingItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	--pingItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(pingItem)
	pingItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	pingItem:SetTextAlignmentX(GUIItem.Align_Min)
	pingItem:SetTextAlignmentY(GUIItem.Align_Min)
	pingItem:SetPosition(Vector(currentColumnX, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
	pingItem:SetColor(color)
	pingItem:SetText(Locale.ResolveString("SB_PING"))
	pingItem:SetStencilFunc(GUIItem.NotEqual)
	teamItem:AddChild(pingItem)

	return {Background = teamItem, TeamName = teamNameItem, TeamInfo = teamInfoItems, TeamSkill = teamSkillItem}
end

local kFavoriteMouseOverColor = Color(1, 1, 0, 1)
local kFavoriteColor = Color(1, 1, 1, 0.9)

local kBlockedMouseOverColor = Color(1, 1, 0, 1)
local kBlockedColor = Color(1, 1, 1, 0.9)

function GUIScoreboard:Initialize()
	self.updateInterval = 0.2

	self.visible = false

	self.teams = {}
	self.reusePlayerItems = {}
	self.slidePercentage = -1
	GUIScoreboard.screenWidth = Client.GetScreenWidth()
	GUIScoreboard.screenHeight = Client.GetScreenHeight()
	GUIScoreboard.kScalingFactor = ConditionalValue(GUIScoreboard.screenHeight > 1280, GUIScale(1), 1)
	self.centerOnPlayer = true -- For modding

	self.scoreboardBackground = GUIManager:CreateGraphicItem()
	self.scoreboardBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.scoreboardBackground:SetLayer(kGUILayerScoreboard)
	self.scoreboardBackground:SetColor(GUIScoreboard.kBgColor)
	self.scoreboardBackground:SetIsVisible(false)

	self.background = GUIManager:CreateGraphicItem()
	self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.background:SetLayer(kGUILayerScoreboard)
	self.background:SetColor(GUIScoreboard.kBgColor)
	self.background:SetIsVisible(false)

	self.backgroundStencil = GUIManager:CreateGraphicItem()
	self.backgroundStencil:SetIsStencil(true)
	self.backgroundStencil:SetClearsStencilBuffer(true)
	self.scoreboardBackground:AddChild(self.backgroundStencil)

	self.slidebar = GUIManager:CreateGraphicItem()
	self.slidebar:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.slidebar:SetSize(GUIScoreboard.kSlidebarSize * GUIScoreboard.kScalingFactor)
	self.slidebar:SetLayer(kGUILayerScoreboard)
	self.slidebar:SetColor(Color(1, 1, 1, 1))
	self.slidebar:SetIsVisible(true)

	self.slidebarBg = GUIManager:CreateGraphicItem()
	self.slidebarBg:SetAnchor(GUIItem.Right, GUIItem.Top)
	self.slidebarBg:SetSize(Vector(GUIScoreboard.kSlidebarSize.x * GUIScoreboard.kScalingFactor, GUIScoreboard.kBgMaxYSpace - 20, 0))
	self.slidebarBg:SetPosition(Vector(-12.5 * GUIScoreboard.kScalingFactor, 10, 0))
	self.slidebarBg:SetLayer(kGUILayerScoreboard)
	self.slidebarBg:SetColor(Color(0.25, 0.25, 0.25, 1))
	self.slidebarBg:SetIsVisible(false)
	self.slidebarBg:AddChild(self.slidebar)
	self.scoreboardBackground:AddChild(self.slidebarBg)

	self.gameTimeBackground = GUIManager:CreateGraphicItem()
	self.gameTimeBackground:SetSize(GUIScoreboard.kGameTimeBackgroundSize)
	self.gameTimeBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.gameTimeBackground:SetPosition(Vector(-GUIScoreboard.kGameTimeBackgroundSize.x / 2, 10, 0))
	self.gameTimeBackground:SetIsVisible(false)
	self.gameTimeBackground:SetColor(Color(0, 0, 0, 0.5))
	self.gameTimeBackground:SetLayer(kGUILayerScoreboard)

	self.gameTime = GUIManager:CreateTextItem()
	self.gameTime:SetFontName(GUIScoreboard.kGameTimeFontName)
	self.gameTime:SetScale(GetScaledVector())
	GUIMakeFontScale(self.gameTime)
	self.gameTime:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.gameTime:SetTextAlignmentX(GUIItem.Align_Center)
	self.gameTime:SetTextAlignmentY(GUIItem.Align_Center)
	self.gameTime:SetColor(Color(1, 1, 1, 1))
	self.gameTime:SetText("")
	self.gameTimeBackground:AddChild(self.gameTime)

	self.serverAddress = Client.GetConnectedServerAddress()

	self.favoriteButton = GUIManager:CreateGraphicItem()
	self.favoriteButton:SetSize(GUIScale(self.kFavoriteIconSize))
	self.favoriteButton.isServerFavorite = GetServerIsFavorite(self.serverAddress)
	self.favoriteButton:SetTexture(self.favoriteButton.isServerFavorite and self.kFavoriteTexture or self.kNotFavoriteTexture)
	self.favoriteButton:SetColor(kFavoriteColor)
	self.favoriteButton:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.gameTimeBackground:AddChild(self.favoriteButton)

	self.blockedButton = GUIManager:CreateGraphicItem()
	self.blockedButton:SetSize(GUIScale(self.kBlockedIconSize))
	self.blockedButton.isServerBlocked = GetServerIsBlocked(self.serverAddress)
	self.blockedButton:SetTexture(self.blockedButton.isServerBlocked and self.kBlockedTexture or self.kNotBlockedTexture)
	self.blockedButton:SetColor(kFavoriteColor)
	self.blockedButton:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.gameTimeBackground:AddChild(self.blockedButton)

	-- Teams table format: Team GUIItems, color, player GUIItem list, get scores function.
	-- Spectator team.
	table.insert(
		self.teams,
		{
			GUIs = CreateTeamBackground(self, kTeamReadyRoom),
			TeamName = ScoreboardUI_GetSpectatorTeamName(),
			Color = GUIScoreboard.kSpectatorColor,
			PlayerList = {},
			HighlightColor = GUIScoreboard.kSpectatorHighlightColor,
			GetScores = ScoreboardUI_GetSpectatorScores,
			TeamNumber = kTeamReadyRoom
		}
	)

	-- Blue team.
	table.insert(
		self.teams,
		{
			GUIs = CreateTeamBackground(self, kTeam1Index),
			TeamName = ScoreboardUI_GetBlueTeamName(),
			Color = GUIScoreboard.kBlueColor,
			PlayerList = {},
			HighlightColor = GUIScoreboard.kBlueHighlightColor,
			GetScores = ScoreboardUI_GetBlueScores,
			TeamNumber = kTeam1Index
		}
	)

	-- Red team.
	table.insert(
		self.teams,
		{
			GUIs = CreateTeamBackground(self, kTeam2Index),
			TeamName = ScoreboardUI_GetRedTeamName(),
			Color = GUIScoreboard.kRedColor,
			PlayerList = {},
			HighlightColor = GUIScoreboard.kRedHighlightColor,
			GetScores = ScoreboardUI_GetRedScores,
			TeamNumber = kTeam2Index
		}
	)

	self.background:AddChild(self.teams[1].GUIs.Background)
	self.background:AddChild(self.teams[2].GUIs.Background)
	self.background:AddChild(self.teams[3].GUIs.Background)

	--Add team topBar
	self.team1topbar = self:CreateEALGraphicHeader(kTeam1Index, kMarineTeamColor, kMarineStatsLogo, Vector(10, 10, 0), kIconSize.x, kIconSize.x)
	self.team2topbar = self:CreateEALGraphicHeader(kTeam2Index, kAlienTeamColor, kAlienStatsLogo, Vector(10, 10, 0), kIconSize.x, kIconSize.x)
	self.teams[2].GUIs.Background:AddChild(self.team1topbar.background)
	self.teams[3].GUIs.Background:AddChild(self.team2topbar.background)

	self.playerHighlightItem = GUIManager:CreateGraphicItem()
	self.playerHighlightItem:SetSize(Vector(self:GetTeamItemWidth() - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0) * GUIScoreboard.kScalingFactor)
	self.playerHighlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.playerHighlightItem:SetColor(Color(1, 1, 1, 1))
	self.playerHighlightItem:SetTexture(kHudElementsTexture)
	self.playerHighlightItem:SetTextureCoordinates(0, 0.16, 0.558, 0.32)
	self.playerHighlightItem:SetStencilFunc(GUIItem.NotEqual)
	self.playerHighlightItem:SetIsVisible(false)

	self.clickForMouseBackground = GUIManager:CreateGraphicItem()
	self.clickForMouseBackground:SetSize(GUIScoreboard.kClickForMouseBackgroundSize)
	self.clickForMouseBackground:SetPosition(Vector(-GUIScoreboard.kClickForMouseBackgroundSize.x / 2, -GUIScoreboard.kClickForMouseBackgroundSize.y - 5, 0))
	self.clickForMouseBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
	self.clickForMouseBackground:SetIsVisible(false)

	self.clickForMouseIndicator = GUIManager:CreateTextItem()
	self.clickForMouseIndicator:SetFontName(GUIScoreboard.kClickForMouseFontName)
	self.clickForMouseIndicator:SetScale(GetScaledVector())
	GUIMakeFontScale(self.clickForMouseIndicator)
	self.clickForMouseIndicator:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.clickForMouseIndicator:SetTextAlignmentX(GUIItem.Align_Center)
	self.clickForMouseIndicator:SetTextAlignmentY(GUIItem.Align_Center)
	self.clickForMouseIndicator:SetColor(Color(0, 0, 0, 1))
	self.clickForMouseIndicator:SetText(GUIScoreboard.kClickForMouseText)
	self.clickForMouseBackground:AddChild(self.clickForMouseIndicator)

	self.mousePressed = {LMB = {Down = nil}, RMB = {Down = nil}}
	self.badgeNameTooltip = GetGUIManager():CreateGUIScriptSingle("menu/GUIHoverTooltip")

	self.hoverMenu = GetGUIManager():CreateGUIScriptSingle("GUIHoverMenu")
	self.hoverMenu:Hide()

	self.hoverPlayerClientIndex = 0

	self.mouseVisible = false

	self.hiddenOverride = HelpScreen_GetHelpScreen():GetIsBeingDisplayed() -- if true, forces scoreboard to be hidden
end

function GUIScoreboard:Uninitialize()
	for _, team in ipairs(self.teams) do
		GUI.DestroyItem(team["GUIs"]["Background"])
	end
	self.teams = {}

	for _, playerItem in ipairs(self.reusePlayerItems) do
		GUI.DestroyItem(playerItem["Background"])
	end
	self.reusePlayerItems = {}

	GUI.DestroyItem(self.clickForMouseIndicator)
	self.clickForMouseIndicator = nil
	GUI.DestroyItem(self.clickForMouseBackground)
	self.clickForMouseBackground = nil

	GUI.DestroyItem(self.gameTime)
	self.gameTime = nil
	GUI.DestroyItem(self.favoriteButton)
	self.favoriteButton = nil
	GUI.DestroyItem(self.blockedButton)
	self.blockedButton = nil
	GUI.DestroyItem(self.gameTimeBackground)
	self.gameTimeBackground = nil

	GUI.DestroyItem(self.scoreboardBackground)
	self.scoreboardBackground = nil

	GUI.DestroyItem(self.background)
	self.background = nil

	GUI.DestroyItem(self.playerHighlightItem)
	self.playerHighlightItem = nil

	EALitems = {}
	lastComm = {}
end

local function SetMouseVisible(self, setVisible)
	if self.mouseVisible ~= setVisible then
		self.mouseVisible = setVisible

		MouseTracker_SetIsVisible(self.mouseVisible, "ui/Cursor_MenuDefault.dds", true)
		if self.mouseVisible then
			self.clickForMouseBackground:SetIsVisible(false)
		end
	end
end

local function HandleSlidebarClicked(self, _, mouseY)
	if self.slidebarBg:GetIsVisible() and self.isDragging then
		local topPos = (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 19
		local bottomPos = Client.GetScreenHeight() - (GUIScoreboard.kClickForMouseBackgroundSize.y + 5) - 19
		mouseY = Clamp(mouseY, topPos, bottomPos)
		self.slidePercentage = (mouseY - topPos) / (bottomPos - topPos) * 100
	end
end

local function GetIsVisibleTeam(teamNumber)
	local isVisibleTeam = false
	local localPlayer = Client.GetLocalPlayer()
	if localPlayer then
		local localPlayerTeamNum = localPlayer:GetTeamNumber()
		-- Can see secret information if the player is on the team or is a spectator.
		if localPlayerIsSpectator or teamNumber == kTeamReadyRoom or localPlayerTeamNum == teamNumber or localPlayerTeamNum == kSpectatorIndex then
			isVisibleTeam = true
		end
	end

	if not isVisibleTeam then
		-- Allow seeing who is commander during pre-game
		local gInfo = GetGameInfoEntity()
		if gInfo and gInfo:GetState() <= kGameState.PreGame then
			return true
		end
	end

	return isVisibleTeam
end

function GUIScoreboard:Update(deltaTime)
	PROFILE("GUIScoreboard:Update")

	local vis = self.visible and not self.hiddenOverride

	-- Show all the elements the frame after sorting them
	-- so it doesn't appear to shift when we open
	local displayScoreboard = self.slidePercentage > -1 and not self.hiddenOverride
	self.gameTimeBackground:SetIsVisible(displayScoreboard)
	self.gameTime:SetIsVisible(displayScoreboard)
	self.background:SetIsVisible(displayScoreboard)
	self.scoreboardBackground:SetIsVisible(displayScoreboard)
	if lastScoreboardVisState ~= displayScoreboard then
		lastScoreboardVisState = displayScoreboard
		if vis == false then
			self.updateInterval = 0.2
			self.badgeNameTooltip:Hide(0)
		end
	end

	if not vis then
		SetMouseVisible(self, false)
	end

	if self.hoverMenu.background:GetIsVisible() then
		if not vis then
			self.hoverMenu:Hide()
		end
	else
		self.hoverPlayerClientIndex = 0
	end

	if not self.mouseVisible then
		-- Click for mouse only visible when not a commander and when the scoreboard is visible.
		local clickForMouseBackgroundVisible = (not PlayerUI_IsACommander()) and vis
		self.clickForMouseBackground:SetIsVisible(clickForMouseBackgroundVisible)
		local backgroundColor = PlayerUI_GetTeamColor()
		backgroundColor.a = 0.8
		self.clickForMouseBackground:SetColor(backgroundColor)
	end

	local gInfo = GetGameInfoEntity()
	local isPreGame = (gInfo and gInfo:GetState() <= kGameState.PreGame)

	--First, update teams.
	local teamGUISize = {}
	local fetchTable = {}
	for index, team in ipairs(self.teams) do
		-- Don't draw if no players on team
		local scores = team["GetScores"]()
		for index, player in pairs(scores) do
			local steamId = GetSteamIdForClientIndex((player and player.ClientIndex) and player.ClientIndex or nil)
			if steamId and steamId > 0 then
				table.insert(fetchTable, steamId)
				if not isPreGame then
					--Handle last com scenarios
					local playingTeam = team.TeamNumber ~= kTeamReadyRoom
					if playingTeam and player.IsCommander then
						if lastComm[team.TeamNumber] ~= steamId then
							--print("Setting last com (" .. tostring(teamNumber) .. ") to: " .. tostring(steamId))
							lastComm[team.TeamNumber] = steamId
						end
					end
				end
			end
		end
		local numPlayers = table.icount(scores)
		if team.TeamNumber == 0 and numPlayers == 0 and PlayerUI_GetNumConnectingPlayers() > 0 then
			numPlayers = PlayerUI_GetNumConnectingPlayers()
		end
		team["GUIs"]["Background"]:SetIsVisible(vis and (numPlayers > 0))

		if vis then
			self:UpdateTeam(team)
			if numPlayers > 0 then
				if teamGUISize[playerRecord] == nil then
					teamGUISize[team.TeamNumber] = {}
				end
				teamGUISize[team.TeamNumber] = self.teams[index].GUIs.Background:GetSize().y
			end
		end
		if team.TeamNumber == kTeamReadyRoom and numPlayers <= 0 then
			localPlayerIsSpectator = false
		elseif team.TeamNumber ~= kTeamReadyRoom and numPlayers <= 0 then
			lastComm[team.TeamNumber] = nil
		end
	end

	--Fetch player data if needed
	if #fetchTable > 0 then
		fetchPlayerStats(fetchTable)
	end

	local topBar = nil
	--Yes, a bit janky but each "mode" needs different handling
	if PlayerUI_GetIsSpecating() then
		topBar = GetGUIManager():GetGUIScriptSingle("GUIInsight_TopBar")

		if topBar then
			topBar:SetIsVisible(not vis)
		end
	else
		topBar = ClientUI.GetScript("Hud2/topBar/GUIHudTopBarForLocalTeam")

		if topBar then
			topBar:SetIsHiddenOverride(vis)
		end
	end

	if vis then
		if self.hoverPlayerClientIndex == 0 and GUIItemContainsPoint(self.scoreboardBackground, Client.GetCursorPosScreen()) then
			self.badgeNameTooltip:Hide(0)
		end

		local gameTime = PlayerUI_GetGameLengthTime()
		local minutes = math.floor(gameTime / 60)
		local seconds = math.floor(gameTime - minutes * 60)

		local serverName = Client.GetServerIsHidden() and "Hidden" or Client.GetConnectedServerName()
		local gameTimeText = serverName .. " | " .. Shared.GetMapName() .. string.format(" - %d:%02d", minutes, seconds)

		self.gameTime:SetText(gameTimeText)

		-- Update the favorite button when the coreboard opens (dt == 0)
		if deltaTime == 0 then
			self.favoriteButton.isServerFavorite = GetServerIsFavorite(self.serverAddress)
			self.favoriteButton:SetTexture(self.favoriteButton.isServerFavorite and self.kFavoriteTexture or self.kNotFavoriteTexture)

			self.blockedButton.isServerBlocked = GetServerIsFavorite(self.serverAddress)
			self.blockedButton:SetTexture(self.blockedButton.isServerBlocked and self.kBlockedTexture or self.kNotBlockedTexture)
		end

		local width = -self.gameTime:GetTextWidth(gameTimeText) / 2 - GUIScale(2 * self.kFavoriteIconSize.x + 20)
		self.favoriteButton:SetPosition(Vector(width, GUIScale(4), 0))

		width = -self.gameTime:GetTextWidth(gameTimeText) / 2 - GUIScale(self.kBlockedIconSize.x + 10)
		self.blockedButton:SetPosition(Vector(width, GUIScale(4), 0))

		-- Get sizes for everything so we can reposition correctly
		local contentYSize = 0
		local teamItemWidth = self:GetTeamItemWidth() * GUIScoreboard.kScalingFactor
		local teamItemVerticalFormat = teamItemWidth * 2 > GUIScoreboard.screenWidth
		local contentXOffset = (GUIScoreboard.screenWidth - teamItemWidth * 2) / 2
		local contentXExtraOffset = ConditionalValue(GUIScoreboard.screenWidth > 1900, contentXOffset * 0.33, 15 * GUIScoreboard.kScalingFactor)
		local contentXSize = teamItemWidth + contentXExtraOffset * 2
		local contentYSpacing = 20 * GUIScoreboard.kScalingFactor

		if teamGUISize[1] then
			-- If it doesn't fit horizontally or there is only one team put it below
			if teamItemVerticalFormat or not teamGUISize[2] then
				self.teams[2].GUIs.Background:SetPosition(Vector(-teamItemWidth / 2, contentYSize + kTitleSize.y + 5, 0))
				contentYSize = contentYSize + teamGUISize[1] + contentYSpacing + kTitleSize.y + 5
			else
				self.teams[2].GUIs.Background:SetPosition(Vector(-teamItemWidth - contentXOffset / 2 + contentXExtraOffset, contentYSize + kTitleSize.y, 0))
			end
		end
		if teamGUISize[2] then
			-- If it doesn't fit horizontally or there is only one team put it below
			if teamItemVerticalFormat or not teamGUISize[1] then
				self.teams[3].GUIs.Background:SetPosition(Vector(-teamItemWidth / 2, contentYSize + kTitleSize.y + 5, 0))
				contentYSize = contentYSize + teamGUISize[2] + contentYSpacing + kTitleSize.y + 5
			else
				self.teams[3].GUIs.Background:SetPosition(Vector(contentXOffset / 2 - contentXExtraOffset, contentYSize + kTitleSize.y, 0))
			end
		end
		-- If both teams fit horizontally then take only the biggest size
		if teamGUISize[1] and teamGUISize[2] and not teamItemVerticalFormat then
			contentYSize = math.max(teamGUISize[1], teamGUISize[2]) + contentYSpacing * 2 + kTitleSize.y + 5
			contentXSize = teamItemWidth * 2 + contentXOffset
		end
		if teamGUISize[0] then
			self.teams[1].GUIs.Background:SetPosition(Vector(-teamItemWidth / 2, contentYSize, 0))
			contentYSize = contentYSize + teamGUISize[0] + contentYSpacing
		end

		local slideOffset = -(self.slidePercentage * contentYSize / 100) + (self.slidePercentage * self.slidebarBg:GetSize().y / 100)
		local displaySpace = Client.GetScreenHeight() - ((GUIScoreboard.kClickForMouseBackgroundSize.y + 5) + (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 20)
		local showSlidebar = contentYSize > displaySpace
		local ySize = math.min(displaySpace, contentYSize)

		if self.slidePercentage == -1 then
			self.slidePercentage = 0
			local teamNumber = Client.GetLocalPlayer():GetTeamNumber()
			if showSlidebar and teamNumber ~= 3 and self.centerOnPlayer then
				local player = self.playerHighlightItem:GetParent()
				local playerItem = player:GetPosition().y
				local teamItem = player:GetParent() and player:GetParent():GetPosition().y or 0
				local playerPos = playerItem + teamItem + GUIScoreboard.kPlayerItemHeight
				if playerPos > displaySpace then
					self.slidePercentage = math.max(0, math.min((playerPos / contentYSize * 100), 100))
				end
			end
		end

		local sliderPos = (self.slidePercentage * self.slidebarBg:GetSize().y / 100)
		if sliderPos < self.slidebar:GetSize().y / 2 then
			sliderPos = 0
		end
		if sliderPos > self.slidebarBg:GetSize().y - self.slidebar:GetSize().y then
			sliderPos = self.slidebarBg:GetSize().y - self.slidebar:GetSize().y
		end

		self.background:SetPosition(Vector(0, 10 + (-ySize / 2 + slideOffset), 0))
		self.scoreboardBackground:SetSize(Vector(contentXSize, ySize, 0))
		self.scoreboardBackground:SetPosition(Vector(-contentXSize / 2, -ySize / 2, 0))
		self.backgroundStencil:SetSize(Vector(contentXSize, ySize - 20, 0))
		self.backgroundStencil:SetPosition(Vector(0, 10, 0))
		local gameTimeBgYSize = self.gameTimeBackground:GetSize().y
		local gameTimeBgYPos = self.gameTimeBackground:GetPosition().y

		self.gameTimeBackground:SetSize(Vector(contentXSize, gameTimeBgYSize, 0))
		self.gameTimeBackground:SetPosition(Vector(-contentXSize / 2, gameTimeBgYPos, 0))

		self.slidebar:SetPosition(Vector(0, sliderPos, 0))
		self.slidebarBg:SetIsVisible(showSlidebar)
		self.scoreboardBackground:SetColor(ConditionalValue(showSlidebar, GUIScoreboard.kBgColor, Color(0, 0, 0, 0)))

		local mouseX, mouseY = Client.GetCursorPosScreen()
		if self.mousePressed["LMB"]["Down"] and self.isDragging then
			HandleSlidebarClicked(self, mouseX, mouseY)
		end
	else
		self.slidePercentage = -1
	end
end

local function SetPlayerItemBadges(item, badgeTextures)
	assert(#badgeTextures <= #item.BadgeItems)

	local offset = 0

	for i = 1, #item.BadgeItems do
		if badgeTextures[i] ~= nil then
			item.BadgeItems[i]:SetTexture(badgeTextures[i])
			item.BadgeItems[i]:SetIsVisible(true)
		else
			item.BadgeItems[i]:SetIsVisible(false)
		end
	end

	-- now adjust the position of the player name
	local numBadgesShown = math.min(#badgeTextures, #item.BadgeItems)

	offset = numBadgesShown * (kPlayerBadgeIconSize + kPlayerBadgeRightPadding) * GUIScoreboard.kScalingFactor

	return offset
end

local function GetCountByStatus(team, status, partof)
	local count = 0
	for index, item in ipairs(team) do
		if partof and string.find(item["Status"], status) then
			count = count + 1
		elseif status == item["Status"] then
			count = count + 1
		end
	end
	return count
end

function GUIScoreboard:UpdateTeam(updateTeam)
	local teamGUIItem = updateTeam["GUIs"]["Background"]
	local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
	local teamSkillGUIItem = updateTeam["GUIs"]["TeamSkill"]
	local teamInfoGUIItem = updateTeam["GUIs"]["TeamInfo"]
	local teamNameText = Locale.ResolveString(string.format("NAME_TEAM_%s", updateTeam["TeamNumber"]))
	local teamColor = updateTeam["Color"]
	local localPlayerHighlightColor = updateTeam["HighlightColor"]
	local playerList = updateTeam["PlayerList"]
	local teamScores = updateTeam["GetScores"]()
	local teamNumber = updateTeam["TeamNumber"]
	local isPlayingTeam = teamNumber ~= kTeamReadyRoom
	--ToDo find a way to add commander time...

	-- Determines if the local player can see secret information
	-- for this team.
	local isVisibleTeam = GetIsVisibleTeam(teamNumber)
	local isSpectator, isMarine, isAlien = teamNumber == 0, teamNumber == 1, teamNumber == 2

	-- How many items per player.
	local numPlayers = table.icount(teamScores)

	-- Update the team name text.
	local playersOnTeamText = string.format("%d %s", numPlayers, numPlayers == 1 and Locale.ResolveString("SB_PLAYER") or Locale.ResolveString("SB_PLAYERS"))
	local teamHeaderText

	if not isPlayingTeam then
		-- Add number of players connecting
		local numPlayersConnecting = PlayerUI_GetNumConnectingPlayers()
		if numPlayersConnecting > 0 then
			-- It will show RR team if players are connecting even if no players are in the RR
			if numPlayers > 0 then
				teamHeaderText = string.format("%s (%s, %d %s)", teamNameText, playersOnTeamText, numPlayersConnecting, Locale.ResolveString("SB_CONNECTING"))
			else
				teamHeaderText = string.format("%s (%d %s)", teamNameText, numPlayersConnecting, Locale.ResolveString("SB_CONNECTING"))
			end
		end
	end

	if not teamHeaderText then
		teamHeaderText = string.format("%s (%s)", teamNameText, playersOnTeamText)
	end

	teamNameGUIItem:SetText(teamHeaderText)

	-- Update team resource display
	if isPlayingTeam then
		local teamResourcesString = ConditionalValue(isVisibleTeam, string.format(Locale.ResolveString("SB_TEAM_RES"), ScoreboardUI_GetTeamResources(teamNumber)), "")
		teamInfoGUIItem["teamRes"]:SetText(string.format("%s", teamResourcesString))
	end

	--Commander Icon and text visibility
	if lastComm[teamNumber] and isPlayingTeam then
		teamInfoGUIItem["teamComm"]:SetIsVisible(true)
		teamInfoGUIItem["teamCommIcon"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	elseif isPlayingTeam then
		teamInfoGUIItem["teamComm"]:SetIsVisible(true)
		teamInfoGUIItem["teamComm"]:SetText(Locale.ResolveString("NO_COMMANDER"))
		teamInfoGUIItem["teamCommIcon"]:SetColor(RGBAtoColor(255, 50, 50, 1))
	end

	-- Make sure there is enough room for all players on this team GUI.
	teamGUIItem:SetSize(Vector(self:GetTeamItemWidth(), (GUIScoreboard.kTeamItemHeight) + ((GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * numPlayers), 0) * GUIScoreboard.kScalingFactor)

	-- Resize the player list if it doesn't match.
	if table.icount(playerList) ~= numPlayers then
		self:ResizePlayerList(playerList, numPlayers, teamGUIItem)
	end

	local currentY = (GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 10) * GUIScoreboard.kScalingFactor
	local currentPlayerIndex = 1
	local deadString = Locale.ResolveString("STATUS_DEAD")

	local sumPlayerSkill = 0
	local numPlayerSkill = 0
	local numRookies = 0
	local numBots = 0

	--Reset lastcomm in case of pregame
	local gInfo = GetGameInfoEntity()
	local isPreGame = false
	if gInfo and gInfo:GetState() <= kGameState.PreGame then
		isPreGame = true
		lastComm[teamNumber] = nil
	end

	local isSpectating = false
	local commRage = lastComm[teamNumber] ~= nil
	for index, player in ipairs(playerList) do
		local playerRecord = teamScores[currentPlayerIndex]
		local playerName = playerRecord.Name
		local clientIndex = playerRecord.ClientIndex
		local steamId = GetSteamIdForClientIndex(clientIndex)
		local score = playerRecord.Score
		local kills = playerRecord.Kills
		local assists = playerRecord.Assists
		local deaths = playerRecord.Deaths
		local isCommander = playerRecord.IsCommander and isVisibleTeam == true
		local isRookie = playerRecord.IsRookie
		local resourcesStr = ConditionalValue(isVisibleTeam, tostring(math.floor(playerRecord.Resources * 10) / 10), "-")
		local ping = playerRecord.Ping
		local pingStr = tostring(ping)
		local currentPosition = Vector(player["Background"]:GetPosition())
		local playerStatus = isVisibleTeam and playerRecord.Status or "-"
		local isDead = isVisibleTeam and playerRecord.Status == deadString
		local isSteamFriend = playerRecord.IsSteamFriend
		local playerSkill = playerRecord.Skill
		local adagradSum = playerRecord.AdagradSum
		local commanderColor = GUIScoreboard.kCommanderFontColor
		local isBot = steamId == 0
		local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)

		if steamId == localPlayerSteamID and playerRecord.IsSpectator then
			isSpectating = true
		end

		-- Get data for tooltip
		local playerTooltipData = (steamId and steamId > 0 and not isBot) and getPlayerStats(steamId) or nil
		--print("playerRecord.Tech: " .. tostring(playerRecord.Tech))
		--print("GetTechIdsFromBitMask: " .. tostring(dump(GetTechIdsFromBitMask(playerRecord.Tech))))

		--[[ Debugging
        if index == 1 or index == 3 then
            isSteamFriend = true
        elseif index == 2 or index == 4 then
            isSteamFriend = true
            isRookie = true
        end
        ]]
		--Update comm variables
		if playerRecord.IsCommander and lastComm[teamNumber] ~= steamId then
			lastComm[teamNumber] = steamId
		end
		local isLastComm = lastComm[teamNumber] == steamId
		--print("SteamId: " .. tostring(steamId))
		--print("lastComm[teamNumber]: " .. tostring(lastComm[teamNumber]))
		-- Flip on isCommander in case of not in chair temporary...
		--if not isCommander and lastComm[teamNumber] == steamId and isVisibleTeam then
		--isCommander = true
		--end

		-- Update commander text based on lastComm
		if isLastComm or isCommander then
			commRage = false --Check for Commander Rage quit
			teamInfoGUIItem["teamComm"]:SetText(playerName)
		end

		if isVisibleTeam and teamNumber == kTeam1Index then
			if table.icontains(currentTech, kTechId.Jetpack) then
				if playerStatus ~= "" and playerStatus ~= " " then
					playerStatus = string.format("%s/%s", playerStatus, Locale.ResolveString("STATUS_JETPACK"))
				else
					playerStatus = Locale.ResolveString("STATUS_JETPACK")
				end
			end
			if table.icontains(currentTech, kTechId.DualMinigunExosuit) then
				if playerStatus ~= "" and playerStatus ~= " " then
					playerStatus = string.format("%s-%s", playerStatus, "Mini")
				else
					playerStatus = Locale.ResolveString("HELP_SCREEN_EXO_MINIGUN")
				end
			elseif table.icontains(currentTech, kTechId.DualRailgunExosuit) then
				if playerStatus ~= "" and playerStatus ~= " " then
					playerStatus = string.format("%s-%s", playerStatus, "Rail")
				else
					playerStatus = Locale.ResolveString("HELP_SCREEN_EXO_RAILGUN")
				end
			end
		end

		if (isCommander or (isLastComm and not isBot)) and isPlayingTeam then
			score = "*"
			player.CommIcon:SetIsVisible(true)
		else
			player.CommIcon:SetIsVisible(false)
		end

		-- Upgrade Icons handle
		-- -- Marines
		local showTech = isVisibleTeam and teamNumber == kTeam1Index
		if showTech and table.icontains(currentTech, kTechId.Welder) then
			player.UpgradeIcons["marineWelder"]:SetIsVisible(true)
		else
			player.UpgradeIcons["marineWelder"]:SetIsVisible(false)
		end
		if showTech and (table.icontains(currentTech, kTechId.GasGrenade) or table.icontains(currentTech, kTechId.ClusterGrenade) or table.icontains(currentTech, kTechId.PulseGrenade)) then
			player.UpgradeIcons["marineGrenade"]:SetIsVisible(true)
		else
			player.UpgradeIcons["marineGrenade"]:SetIsVisible(false)
		end
		if showTech and table.icontains(currentTech, kTechId.Mine) then
			player.UpgradeIcons["marineMine"]:SetIsVisible(true)
		else
			player.UpgradeIcons["marineMine"]:SetIsVisible(false)
		end

		-- -- Aliens
		local showTech = isVisibleTeam and teamNumber == kTeam2Index
		if showTech and (table.icontains(currentTech, kTechId.Regeneration) or table.icontains(currentTech, kTechId.Carapace) or table.icontains(currentTech, kTechId.Vampirism)) then
			player.UpgradeIcons["alienShell"]:SetIsVisible(true)
			if table.icontains(currentTech, kTechId.Regeneration) then
				if techCarapaceWorkaround then
					player.UpgradeIcons["alienShell"]:SetTexture(kEalAlienTexture)
				end
				player.UpgradeIcons["alienShell"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 0, 114 * 12, 113 * 1, 114 * 13}))
			elseif table.icontains(currentTech, kTechId.Carapace) then
				if techCarapaceWorkaround then
					player.UpgradeIcons["alienShell"]:SetTexture(kBuildmenuTexture)
					player.UpgradeIcons["alienShell"]:SetTexturePixelCoordinates(GUIUnpackCoords({80 * 11, 80 * 13, 80 * 12, 80 * 14}))
				else
					player.UpgradeIcons["alienShell"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 1, 114 * 12, 113 * 2, 114 * 13}))
				end
			elseif table.icontains(currentTech, kTechId.Vampirism) then
				if techCarapaceWorkaround then
					player.UpgradeIcons["alienShell"]:SetTexture(kEalAlienTexture)
				end
				player.UpgradeIcons["alienShell"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 2, 114 * 12, 113 * 3, 114 * 13}))
			end
		elseif techCarapaceWorkaround and showTech and table.icontains(currentTech, kTechId.Resilience) then
			player.UpgradeIcons["alienShell"]:SetTexture(kBuildmenuTexture)
			player.UpgradeIcons["alienShell"]:SetTexturePixelCoordinates(GUIUnpackCoords({80 * 11, 80 * 13, 80 * 12, 80 * 14}))
			player.UpgradeIcons["alienShell"]:SetIsVisible(true)
		else
			player.UpgradeIcons["alienShell"]:SetIsVisible(false)
		end

		if showTech and (table.icontains(currentTech, kTechId.Camouflage) or table.icontains(currentTech, kTechId.Focus) or table.icontains(currentTech, kTechId.Aura)) then
			player.UpgradeIcons["alienVeil"]:SetIsVisible(true)
			if table.icontains(currentTech, kTechId.Camouflage) then
				player.UpgradeIcons["alienVeil"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 0, 114 * 13, 113 * 1, 114 * 14}))
			elseif table.icontains(currentTech, kTechId.Focus) then
				player.UpgradeIcons["alienVeil"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 1, 114 * 13, 113 * 2, 114 * 14}))
			elseif table.icontains(currentTech, kTechId.Aura) then
				player.UpgradeIcons["alienVeil"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 2, 114 * 13, 113 * 3, 114 * 14}))
			end
		else
			player.UpgradeIcons["alienVeil"]:SetIsVisible(false)
		end
		if showTech and (table.icontains(currentTech, kTechId.Adrenaline) or table.icontains(currentTech, kTechId.Celerity) or table.icontains(currentTech, kTechId.Crush)) then
			player.UpgradeIcons["alienSpur"]:SetIsVisible(true)
			if table.icontains(currentTech, kTechId.Adrenaline) then
				player.UpgradeIcons["alienSpur"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 0, 114 * 14, 113 * 1, 114 * 15}))
			elseif table.icontains(currentTech, kTechId.Celerity) then
				player.UpgradeIcons["alienSpur"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 1, 114 * 14, 113 * 2, 114 * 15}))
			elseif table.icontains(currentTech, kTechId.Crush) then
				player.UpgradeIcons["alienSpur"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 2, 114 * 14, 113 * 3, 114 * 15}))
			end
		else
			player.UpgradeIcons["alienSpur"]:SetIsVisible(false)
		end

		currentPosition.y = currentY
		player["Background"]:SetPosition(currentPosition)
		player["Background"]:SetColor(ConditionalValue(isCommander, commanderColor, teamColor))

		-- Handle local player highlight
		if ScoreboardUI_IsPlayerLocal(playerName) then
			if self.playerHighlightItem:GetParent() ~= player["Background"] then
				if self.playerHighlightItem:GetParent() ~= nil then
					self.playerHighlightItem:GetParent():RemoveChild(self.playerHighlightItem)
				end
				player["Background"]:AddChild(self.playerHighlightItem)
				self.playerHighlightItem:SetIsVisible(true)
				self.playerHighlightItem:SetColor(localPlayerHighlightColor)
			end
		end

		player["Number"]:SetText(index .. ".")
		player["Name"]:SetText(playerName)

		-- Needed to determine who to (un)mute when voice icon is clicked.
		player["ClientIndex"] = clientIndex

		-- Voice icon.
		local playerVoiceColor = GUIScoreboard.kVoiceDefaultColor
		local voiceChannel = clientIndex and ChatUI_GetVoiceChannelForClient(clientIndex) or VoiceChannel.Invalid
		if ChatUI_GetClientMuted(clientIndex) then
			playerVoiceColor = GUIScoreboard.kVoiceMuteColor
		elseif voiceChannel ~= VoiceChannel.Invalid then
			playerVoiceColor = teamColor
		end

		-- Set player skill icon
		local skillIconOverrideSettings = CheckForSpecialBadgeRecipient(steamId)
		if skillIconOverrideSettings then
			-- User has a special skill-tier icon tied to their steam Id.

			-- Reset the skill icon's texture coordinates to the default normalized coordinates (0, 0), (1, 1).
			-- The shader depends on them being this way.
			player.SkillIcon:SetTextureCoordinates(0, 0, 1, 1)

			-- Change the skill icon's shader to the one that will animate.
			player.SkillIcon:SetShader(skillIconOverrideSettings.shader)
			player.SkillIcon:SetTexture(skillIconOverrideSettings.tex)
			player.SkillIcon:SetFloatParameter("frameCount", skillIconOverrideSettings.frameCount)

			-- Change the size so it doesn't touch the weapon name text.
			player.SkillIcon:SetSize(kPlayerSkillIconSizeOverride * GUIScoreboard.kScalingFactor)

			-- Change the tooltip of the skill icon.
			player.SkillIcon.tooltipText = skillIconOverrideSettings.tooltip
		else
			-- User has no special skill-tier icon.

			-- Reset the shader and texture back to the default one.
			player.SkillIcon:SetShader("shaders/GUIBasic.surface_shader")
			player.SkillIcon:SetTexture(kPlayerSkillIconTexture)
			player.SkillIcon:SetSize(kPlayerSkillIconSize * GUIScoreboard.kScalingFactor)

			local skillTier, tierName, cappedSkill = GetPlayerSkillTier(playerSkill, isRookie, adagradSum, isBot)
			player.SkillIcon.tooltipText = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString(tierName), skillTier)

			local iconIndex = skillTier + 2
			player.SkillIcon:SetTexturePixelCoordinates(0, iconIndex * 32, 100, (iconIndex + 1) * 32 - 1)

			if cappedSkill then
				sumPlayerSkill = sumPlayerSkill + cappedSkill
				numPlayerSkill = numPlayerSkill + 1
			end
		end

		--print("dump: " .. dump(playerTooltipData))
		if isBot then
			player.SkillIcon.tooltipText = "NS2 Bot"
		elseif not playerTooltipData then
			player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nRequesting NS2Panel data..."
		elseif playerTooltipData and playerTooltipData.fetched and playerTooltipData.fetched == 0 then
			player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nNo NS2Panel data!"
		elseif not isBot and playerTooltipData and playerTooltipData.marine_skill then
			local midPlayerSkill = ((playerTooltipData.marine_skill or 0) + (playerTooltipData.alien_skill or 0)) / 2
			local midComSkill = ((playerTooltipData.marine_commander_skill or 0) + (playerTooltipData.alien_commander_skill or 0)) / 2
			local commTier, commTierName, commCappedSkill = GetPlayerSkillTier(midComSkill, isRookie, adagradSum, isBot)

			player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. string.format("\nSkill: %.0f", midPlayerSkill)
			if isSpectator or isMarine or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nMarine: " .. tostring(playerTooltipData.marine_skill or 0)
			end
			if isSpectator or isAlien or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nAlien: " .. tostring(playerTooltipData.alien_skill or 0)
			end
			player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\n"
			if isSpectator or isLastComm or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nCom Tier: " .. Locale.ResolveString(commTierName) .. " (" .. tostring(commTier) .. ")"
			end
			if isSpectator or isLastComm or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. string.format("\nCom Skill: %.0f", midComSkill)
			end
			if isSpectator or (isLastComm and isMarine) or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nMarine: " .. tostring(playerTooltipData.marine_commander_skill or 0)
			end
			if isSpectator or (isLastComm and isAlien) or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nAlien: " .. tostring(playerTooltipData.alien_commander_skill or 0)
			end
			if isSpectator or isLastComm or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\n"
			end
			player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nKDR:"
			if isSpectator or isMarine or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. " M " .. tostring(playerTooltipData.marine_kdr or 0)
			end
			if isSpectator or isAlien or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. " A " .. tostring(playerTooltipData.alien_kdr or 0)
			end
			player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nAccuracy:"
			if isSpectator or isMarine or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. " M " .. tostring(round(playerTooltipData.marine_accuracy or 0, 0))
			end
			if isSpectator or isAlien or isPreGame then
				player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. " A " .. tostring(round(playerTooltipData.alien_accuracy or 0, 0))
			end
			player.SkillIcon.tooltipText = player.SkillIcon.tooltipText .. "\nProvided by NS2Panel"
			playerTooltipData.toolTip = player.SkillIcon.tooltipText
		end

		numRookies = numRookies + (isRookie and 1 or 0)
		numBots = numBots + (isBot and 1 or 0)
		if isPlayingTeam then
			player["Score"]:SetText(tostring(score))
			player["Kills"]:SetText(tostring(kills))
			player["Assists"]:SetText(tostring(assists))
			player["Deaths"]:SetText(tostring(deaths))
			player["Resources"]:SetText(resourcesStr)
		end
		player["Status"]:SetText(playerStatus)
		player["Ping"]:SetText(pingStr)

		player["Score"]:SetIsVisible(isPlayingTeam)
		player["Kills"]:SetIsVisible(isPlayingTeam)
		player["Assists"]:SetIsVisible(isPlayingTeam)
		player["Deaths"]:SetIsVisible(isPlayingTeam)
		player["Resources"]:SetIsVisible(isPlayingTeam)

		local white = GUIScoreboard.kWhiteColor
		local baseColor, nameColor, statusColor = white, white, white

		if isDead and isVisibleTeam then
			nameColor, statusColor = kDeadColor, kDeadColor
		end

		player["Score"]:SetColor(baseColor)
		player["Kills"]:SetColor(baseColor)
		player["Assists"]:SetColor(baseColor)
		player["Deaths"]:SetColor(baseColor)
		player["Status"]:SetColor(statusColor)

		player["Name"]:SetColor(nameColor)

		-- resource color
		if resourcesStr then
			local resourcesNumber = tonumber(resourcesStr)
			if resourcesNumber == nil then -- necessary at gamestart with bots
				resourcesNumber = 0
			end
			if resourcesNumber < GUIScoreboard.kHighPresThreshold then
				player["Resources"]:SetColor(baseColor)
			elseif resourcesNumber >= GUIScoreboard.kVeryHighPresThreshold then
				player["Resources"]:SetColor(GUIScoreboard.kVeryHighPresColor)
			else
				player["Resources"]:SetColor(GUIScoreboard.kHighPresColor)
			end
		else
			player["Resources"]:SetColor(baseColor)
		end

		if ping < GUIScoreboard.kLowPingThreshold then
			player["Ping"]:SetColor(GUIScoreboard.kLowPingColor)
		elseif ping < GUIScoreboard.kMedPingThreshold then
			player["Ping"]:SetColor(GUIScoreboard.kMedPingColor)
		elseif ping < GUIScoreboard.kHighPingThreshold then
			player["Ping"]:SetColor(GUIScoreboard.kHighPingColor)
		else
			player["Ping"]:SetColor(GUIScoreboard.kInsanePingColor)
		end
		currentY = currentY + (GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * GUIScoreboard.kScalingFactor
		currentPlayerIndex = currentPlayerIndex + 1

		-- New scoreboard positioning
		local numberSize = 0
		if player["Number"]:GetIsVisible() then
			numberSize = kPlayerNumberWidth
		end

		for i = 1, #player["BadgeItems"] do
			player["BadgeItems"][i]:SetPosition(Vector(numberSize + kPlayerItemLeftMargin + (i - 1) * kPlayerVoiceChatIconSize + (i - 1) * kPlayerBadgeRightPadding, -kPlayerVoiceChatIconSize / 2, 0) * GUIScoreboard.kScalingFactor)
		end

		local statusPos = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth + 30, (self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10) + 60)
		playerStatus = player["Status"]:GetText()
		if playerStatus == "-" or (playerStatus ~= Locale.ResolveString("STATUS_SPECTATOR") and teamNumber ~= 1 and teamNumber ~= 2) then
			playerStatus = ""
			player["Status"]:SetText("")
			statusPos = statusPos + GUIScoreboard.kTeamColumnSpacingX * ConditionalValue(GUIScoreboard.screenWidth < 1280, 2.75, 1.75)
		end

		SetPlayerItemBadges(player, Badges_GetBadgeTextures(clientIndex, "scoreboard"))

		local numBadges = math.min(#Badges_GetBadgeTextures(clientIndex, "scoreboard"), #player["BadgeItems"])
		local pos = (numberSize + kPlayerItemLeftMargin + numBadges * kPlayerVoiceChatIconSize + numBadges * kPlayerBadgeRightPadding) * GUIScoreboard.kScalingFactor

		player["Name"]:SetPosition(Vector(pos, 0, 0))

		-- Icons on the right side of the player name
		player["SteamFriend"]:SetIsVisible(isSteamFriend)
		player["Voice"]:SetIsVisible(ChatUI_GetClientMuted(clientIndex))
		player["Text"]:SetIsVisible(ChatUI_GetSteamIdTextMuted(steamId))

		--player["SteamFriend"]:SetIsVisible(true)
		--player["Voice"]:SetIsVisible(true)
		--player["Text"]:SetIsVisible(true)

		local nameRightPos = pos + (kPlayerBadgeRightPadding * GUIScoreboard.kScalingFactor)

		--pos = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth + 30, (self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10) + 40)
		--pos = pos + kPlayerItemLeftMargin - kPlayerSkillIconSize.x
		pos = player.SkillIcon:GetPosition().x
		for _, icon in ipairs(player["IconTable"]) do
			if icon:GetIsVisible() then
				local iconSize = icon:GetSize()
				pos = pos - iconSize.x
				icon:SetPosition(Vector(pos, (-iconSize.y / 2), 0))
			end
		end

		local finalName = player["Name"]:GetText()
		local finalNameWidth = player["Name"]:GetTextWidth(finalName) * GUIScoreboard.kScalingFactor
		local dotsWidth = player["Name"]:GetTextWidth("...") * GUIScoreboard.kScalingFactor
		-- The minimum truncated length for the name also includes the "..."
		while nameRightPos + finalNameWidth > pos and string.UTF8Length(finalName) > kMinTruncatedNameLength do
			finalName = string.UTF8Sub(finalName, 1, string.UTF8Length(finalName) - 1)
			finalNameWidth = (player["Name"]:GetTextWidth(finalName) * GUIScoreboard.kScalingFactor) + dotsWidth
			player["Name"]:SetText(finalName .. "...")
		end

		local color = Color(0.5, 0.5, 0.5, 1)
		if isCommander or (isLastComm and not isBot) then
			color = GUIScoreboard.kCommanderFontColor * 0.8
		else
			color = teamColor * 0.8
		end

		if not self.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
			if MouseTracker_GetIsVisible() then
				local mouseX, mouseY = Client.GetCursorPosScreen()
				if GUIItemContainsPoint(player["Background"], mouseX, mouseY) then
					local canHighlight = true
					local hoverBadge = false
					for _, icon in ipairs(player["IconTable"]) do
						if icon:GetIsVisible() and GUIItemContainsPoint(icon, mouseX, mouseY) and not icon.allowHighlight then
							canHighlight = false
							break
						end
					end

					for i = 1, #player.BadgeItems do
						local badgeItem = player.BadgeItems[i]
						if GUIItemContainsPoint(badgeItem, mouseX, mouseY) and badgeItem:GetIsVisible() then
							local _, badgeNames = Badges_GetBadgeTextures(clientIndex, "scoreboard")
							local badge = ToString(badgeNames[i])
							self.badgeNameTooltip:SetText(GetBadgeFormalName(badge))
							hoverBadge = true
							break
						end
					end

					local skillIcon = player.SkillIcon
					if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
						self.badgeNameTooltip:SetText(skillIcon.tooltipText)
						hoverBadge = true
					end

					if canHighlight then
						self.hoverPlayerClientIndex = clientIndex
						player["Background"]:SetColor(color)
					else
						self.hoverPlayerClientIndex = 0
					end

					if hoverBadge then
						self.badgeNameTooltip:Show()
					else
						self.badgeNameTooltip:Hide()
					end
				else
					local overFavorite = GUIItemContainsPoint(self.favoriteButton, mouseX, mouseY)
					local overBlocked = GUIItemContainsPoint(self.blockedButton, mouseX, mouseY)

					if overFavorite then
						self.favoriteButton:SetColor(kFavoriteMouseOverColor)
					else
						self.favoriteButton:SetColor(kFavoriteColor)
					end

					if overBlocked then
						self.blockedButton:SetColor(kBlockedMouseOverColor)
					else
						self.blockedButton:SetColor(kBlockedColor)
					end
				end
			end
		elseif steamId == GetSteamIdForClientIndex(self.hoverPlayerClientIndex) then
			player["Background"]:SetColor(color)
		end
	end

	--Is spectating handle
	if not isPlayingTeam then
		localPlayerIsSpectator = isSpectating
	end

	--Commander Range handle
	if commRage then
		lastComm[teamNumber] = nil
	end

	--todo text
	numPlayers = #playerList
	if isPlayingTeam and teamSkillGUIItem.sumPlayerSkill ~= sumPlayerSkill then
		if numPlayers > 0 then
			teamSkillGUIItem.sumPlayerSkill = sumPlayerSkill
			local avgSkill = numPlayerSkill < 1 and 0 or sumPlayerSkill / numPlayerSkill
			avgSkill = (sumPlayerSkill + avgSkill * (numPlayers - numPlayerSkill)) / numPlayers

			local halfPlayerNum = 0.5 * numPlayers
			local skillTier, tierName = GetPlayerSkillTier(avgSkill, numRookies > halfPlayerNum, nil, numBots > halfPlayerNum)
			teamSkillGUIItem.tooltipText = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString(tierName), skillTier)
			local textureIndex = skillTier + 2
			teamSkillGUIItem:SetTexturePixelCoordinates(0, textureIndex * 32, 100, (textureIndex + 1) * 32 - 1)
			--teamSkillGUIItem:SetPosition(Vector(teamNameGUIItem:GetTextWidth(teamHeaderText) + 20, 5, 0) * GUIScoreboard.kScalingFactor)
			teamSkillGUIItem:SetIsVisible(true)
		else
			teamSkillGUIItem:SetIsVisible(false)
		end
	end

	--EAL update
	--Reset counts
	for index, item in ipairs(EALitems) do
		item.count = 0
	end

	-- Update counts
	if isVisibleTeam then
		local lifeformCount = 0
		if teamNumber == kTeam1Index then
			lifeformCount = 0
			for index, playerRecord in ipairs(teamScores) do
				local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
				if table.icontains(currentTech, kTechId.Welder) then
					lifeformCount = lifeformCount + 1
				end
			end
			if lifeformCount ~= EALitems[kTechId.Welder].count then
				EALitems[kTechId.Welder].count = lifeformCount
				EALitems[kTechId.Welder].text:SetText(tostring(EALitems[kTechId.Welder].count))
				EALitems[kTechId.Welder].textShadow:SetText(tostring(EALitems[kTechId.Welder].count))
				EALitems[kTechId.Welder].icon:SetColor(EALitems[kTechId.Welder].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = 0
			for index, playerRecord in ipairs(teamScores) do
				local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
				if table.icontains(currentTech, kTechId.ClusterGrenade) or table.icontains(currentTech, kTechId.GasGrenade) or table.icontains(currentTech, kTechId.PulseGrenade) then
					lifeformCount = lifeformCount + 1
				end
			end
			if lifeformCount ~= EALitems[kTechId.ClusterGrenade].count then
				EALitems[kTechId.ClusterGrenade].count = lifeformCount
				EALitems[kTechId.ClusterGrenade].text:SetText(tostring(EALitems[kTechId.ClusterGrenade].count))
				EALitems[kTechId.ClusterGrenade].textShadow:SetText(tostring(EALitems[kTechId.ClusterGrenade].count))
				EALitems[kTechId.ClusterGrenade].icon:SetColor(EALitems[kTechId.ClusterGrenade].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = 0
			for index, playerRecord in ipairs(teamScores) do
				local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
				if table.icontains(currentTech, kTechId.Mine) then
					lifeformCount = lifeformCount + 1
				end
			end
			if lifeformCount ~= EALitems[kTechId.Mine].count then
				EALitems[kTechId.Mine].count = lifeformCount
				EALitems[kTechId.Mine].text:SetText(tostring(EALitems[kTechId.Mine].count))
				EALitems[kTechId.Mine].textShadow:SetText(tostring(EALitems[kTechId.Mine].count))
				EALitems[kTechId.Mine].icon:SetColor(EALitems[kTechId.Mine].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_RIFLE"), true)
			if lifeformCount ~= EALitems[kTechId.Rifle].count then
				EALitems[kTechId.Rifle].count = lifeformCount
				EALitems[kTechId.Rifle].text:SetText(tostring(EALitems[kTechId.Rifle].count))
				EALitems[kTechId.Rifle].textShadow:SetText(tostring(EALitems[kTechId.Rifle].count))
				EALitems[kTechId.Rifle].icon:SetColor(EALitems[kTechId.Rifle].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_SHOTGUN"), true)
			if lifeformCount ~= EALitems[kTechId.Shotgun].count then
				EALitems[kTechId.Shotgun].count = lifeformCount
				EALitems[kTechId.Shotgun].text:SetText(tostring(EALitems[kTechId.Shotgun].count))
				EALitems[kTechId.Shotgun].textShadow:SetText(tostring(EALitems[kTechId.Shotgun].count))
				EALitems[kTechId.Shotgun].icon:SetColor(EALitems[kTechId.Shotgun].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_FLAMETHROWER"), true)
			if lifeformCount ~= EALitems[kTechId.Flamethrower].count then
				EALitems[kTechId.Flamethrower].count = lifeformCount
				EALitems[kTechId.Flamethrower].text:SetText(tostring(EALitems[kTechId.Flamethrower].count))
				EALitems[kTechId.Flamethrower].textShadow:SetText(tostring(EALitems[kTechId.Flamethrower].count))
				EALitems[kTechId.Flamethrower].icon:SetColor(EALitems[kTechId.Flamethrower].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_HMG"), true)
			if lifeformCount ~= EALitems[kTechId.HeavyMachineGun].count then
				EALitems[kTechId.HeavyMachineGun].count = lifeformCount
				EALitems[kTechId.HeavyMachineGun].text:SetText(tostring(EALitems[kTechId.HeavyMachineGun].count))
				EALitems[kTechId.HeavyMachineGun].textShadow:SetText(tostring(EALitems[kTechId.HeavyMachineGun].count))
				EALitems[kTechId.HeavyMachineGun].icon:SetColor(EALitems[kTechId.HeavyMachineGun].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_GRENADE_LAUNCHER"), true)
			if lifeformCount ~= EALitems[kTechId.GrenadeLauncher].count then
				EALitems[kTechId.GrenadeLauncher].count = lifeformCount
				EALitems[kTechId.GrenadeLauncher].text:SetText(tostring(EALitems[kTechId.GrenadeLauncher].count))
				EALitems[kTechId.GrenadeLauncher].textShadow:SetText(tostring(EALitems[kTechId.GrenadeLauncher].count))
				EALitems[kTechId.GrenadeLauncher].icon:SetColor(EALitems[kTechId.GrenadeLauncher].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = 0
			for index, playerRecord in ipairs(teamScores) do
				local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
				if table.icontains(currentTech, kTechId.Jetpack) then
					lifeformCount = lifeformCount + 1
				end
			end
			if lifeformCount ~= EALitems[kTechId.Jetpack].count then
				EALitems[kTechId.Jetpack].count = lifeformCount
				EALitems[kTechId.Jetpack].text:SetText(tostring(EALitems[kTechId.Jetpack].count))
				EALitems[kTechId.Jetpack].textShadow:SetText(tostring(EALitems[kTechId.Jetpack].count))
				EALitems[kTechId.Jetpack].icon:SetColor(EALitems[kTechId.Jetpack].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = 0
			for index, playerRecord in ipairs(teamScores) do
				local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
				if table.icontains(currentTech, kTechId.DualMinigunExosuit) then
					lifeformCount = lifeformCount + 1
				end
			end
			if lifeformCount ~= EALitems[kTechId.DualMinigunExosuit].count then
				EALitems[kTechId.DualMinigunExosuit].count = lifeformCount
				EALitems[kTechId.DualMinigunExosuit].text:SetText(tostring(EALitems[kTechId.DualMinigunExosuit].count))
				EALitems[kTechId.DualMinigunExosuit].textShadow:SetText(tostring(EALitems[kTechId.DualMinigunExosuit].count))
				EALitems[kTechId.DualMinigunExosuit].icon:SetColor(EALitems[kTechId.DualMinigunExosuit].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = 0
			for index, playerRecord in ipairs(teamScores) do
				local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
				if table.icontains(currentTech, kTechId.DualRailgunExosuit) then
					lifeformCount = lifeformCount + 1
				end
			end
			if lifeformCount ~= EALitems[kTechId.DualRailgunExosuit].count then
				EALitems[kTechId.DualRailgunExosuit].count = lifeformCount
				EALitems[kTechId.DualRailgunExosuit].text:SetText(tostring(EALitems[kTechId.DualRailgunExosuit].count))
				EALitems[kTechId.DualRailgunExosuit].textShadow:SetText(tostring(EALitems[kTechId.DualRailgunExosuit].count))
				EALitems[kTechId.DualRailgunExosuit].icon:SetColor(EALitems[kTechId.DualRailgunExosuit].count > 0 and kEalActiveColor or kEalInactiveColor)
			end
		elseif teamNumber == kTeam2Index then
			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_SKULK"), true)
			if lifeformCount ~= EALitems[kTechId.Skulk].count then
				EALitems[kTechId.Skulk].count = lifeformCount
				EALitems[kTechId.Skulk].text:SetText(tostring(EALitems[kTechId.Skulk].count))
				EALitems[kTechId.Skulk].textShadow:SetText(tostring(EALitems[kTechId.Skulk].count))
				EALitems[kTechId.Skulk].icon:SetColor(EALitems[kTechId.Skulk].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_GORGE"), true)
			if lifeformCount ~= EALitems[kTechId.Gorge].count then
				EALitems[kTechId.Gorge].count = lifeformCount
				EALitems[kTechId.Gorge].text:SetText(tostring(EALitems[kTechId.Gorge].count))
				EALitems[kTechId.Gorge].textShadow:SetText(tostring(EALitems[kTechId.Gorge].count))
				EALitems[kTechId.Gorge].icon:SetColor(EALitems[kTechId.Gorge].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_LERK"), true)
			if lifeformCount ~= EALitems[kTechId.Lerk].count then
				EALitems[kTechId.Lerk].count = lifeformCount
				EALitems[kTechId.Lerk].text:SetText(tostring(EALitems[kTechId.Lerk].count))
				EALitems[kTechId.Lerk].textShadow:SetText(tostring(EALitems[kTechId.Lerk].count))
				EALitems[kTechId.Lerk].icon:SetColor(EALitems[kTechId.Lerk].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_FADE"), true)
			if lifeformCount ~= EALitems[kTechId.Fade].count then
				EALitems[kTechId.Fade].count = lifeformCount
				EALitems[kTechId.Fade].text:SetText(tostring(EALitems[kTechId.Fade].count))
				EALitems[kTechId.Fade].textShadow:SetText(tostring(EALitems[kTechId.Fade].count))
				EALitems[kTechId.Fade].icon:SetColor(EALitems[kTechId.Fade].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_ONOS"), true)
			if lifeformCount ~= EALitems[kTechId.Onos].count then
				EALitems[kTechId.Onos].count = lifeformCount
				EALitems[kTechId.Onos].text:SetText(tostring(EALitems[kTechId.Onos].count))
				EALitems[kTechId.Onos].textShadow:SetText(tostring(EALitems[kTechId.Onos].count))
				EALitems[kTechId.Onos].icon:SetColor(EALitems[kTechId.Onos].count > 0 and kEalActiveColor or kEalInactiveColor)
			end

			lifeformCount = GetShellLevel(teamNumber)
			if EALitems[kTechId.Shell].count ~= lifeformCount then
				EALitems[kTechId.Shell].count = lifeformCount
				EALitems[kTechId.TwoShells].text:SetText(tostring(lifeformCount))
				EALitems[kTechId.TwoShells].textShadow:SetText(tostring(lifeformCount))
				if lifeformCount < 1 then
					EALitems[kTechId.Shell].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.TwoShells].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.ThreeShells].icon:SetColor(kEalInactiveColor)
				elseif lifeformCount == 1 then
					EALitems[kTechId.Shell].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoShells].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.ThreeShells].icon:SetColor(kEalInactiveColor)
				elseif lifeformCount == 2 then
					EALitems[kTechId.Shell].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoShells].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.ThreeShells].icon:SetColor(kEalInactiveColor)
				else
					EALitems[kTechId.Shell].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoShells].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.ThreeShells].icon:SetColor(kEalActiveColor)
				end
			end

			lifeformCount = GetVeilLevel(teamNumber)
			if EALitems[kTechId.Veil].count ~= lifeformCount then
				EALitems[kTechId.Veil].count = lifeformCount
				EALitems[kTechId.TwoVeils].text:SetText(tostring(lifeformCount))
				EALitems[kTechId.TwoVeils].textShadow:SetText(tostring(lifeformCount))
				if lifeformCount < 1 then
					EALitems[kTechId.Veil].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.TwoVeils].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.ThreeVeils].icon:SetColor(kEalInactiveColor)
				elseif lifeformCount == 1 then
					EALitems[kTechId.Veil].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoVeils].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.ThreeVeils].icon:SetColor(kEalInactiveColor)
				elseif lifeformCount == 2 then
					EALitems[kTechId.Veil].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoVeils].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.ThreeVeils].icon:SetColor(kEalInactiveColor)
				else
					EALitems[kTechId.Veil].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoVeils].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.ThreeVeils].icon:SetColor(kEalActiveColor)
				end
			end

			lifeformCount = GetSpurLevel(teamNumber)
			if EALitems[kTechId.Spur].count ~= lifeformCount then
				EALitems[kTechId.Spur].count = lifeformCount
				EALitems[kTechId.TwoSpurs].text:SetText(tostring(lifeformCount))
				EALitems[kTechId.TwoSpurs].textShadow:SetText(tostring(lifeformCount))
				if lifeformCount < 1 then
					EALitems[kTechId.Spur].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.TwoSpurs].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.ThreeSpurs].icon:SetColor(kEalInactiveColor)
				elseif lifeformCount == 1 then
					EALitems[kTechId.Spur].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoSpurs].icon:SetColor(kEalInactiveColor)
					EALitems[kTechId.ThreeSpurs].icon:SetColor(kEalInactiveColor)
				elseif lifeformCount == 2 then
					EALitems[kTechId.Spur].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoSpurs].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.ThreeSpurs].icon:SetColor(kEalInactiveColor)
				else
					EALitems[kTechId.Spur].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.TwoSpurs].icon:SetColor(kEalActiveColor)
					EALitems[kTechId.ThreeSpurs].icon:SetColor(kEalActiveColor)
				end
			end
		end
	end

	--Enable/Disable topbar
	if teamNumber == kTeam1Index then
		self.team1topbar.background:SetIsVisible(isVisibleTeam)
	elseif teamNumber == kTeam2Index then
		self.team2topbar.background:SetIsVisible(isVisibleTeam)
	end
end

function GUIScoreboard:ResizePlayerList(playerList, numPlayers, teamGUIItem)
	while table.icount(playerList) > numPlayers do
		teamGUIItem:RemoveChild(playerList[1]["Background"])
		playerList[1]["Background"]:SetIsVisible(false)
		table.insert(self.reusePlayerItems, playerList[1])
		table.remove(playerList, 1)
	end

	while table.icount(playerList) < numPlayers do
		local newPlayerItem = self:CreatePlayerItem()
		table.insert(playerList, newPlayerItem)
		teamGUIItem:AddChild(newPlayerItem["Background"])
		newPlayerItem["Background"]:SetIsVisible(true)
	end
end

function GUIScoreboard:CreatePlayerItem()
	-- Reuse an existing player item if there is one.
	if table.icount(self.reusePlayerItems) > 0 then
		local returnPlayerItem = self.reusePlayerItems[1]
		table.remove(self.reusePlayerItems, 1)
		return returnPlayerItem
	end

	-- Create background.
	local playerItem = GUIManager:CreateGraphicItem()
	playerItem:SetSize(Vector(self:GetTeamItemWidth() - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0) * GUIScoreboard.kScalingFactor)
	playerItem:SetAnchor(GUIItem.Left, GUIItem.Top)
	playerItem:SetPosition(Vector(GUIScoreboard.kPlayerItemWidthBuffer, GUIScoreboard.kPlayerItemHeight / 2, 0) * GUIScoreboard.kScalingFactor)
	playerItem:SetColor(Color(1, 1, 1, 1))
	playerItem:SetTexture(kHudElementsTexture)
	playerItem:SetTextureCoordinates(0, 0, 0.558, 0.16)
	playerItem:SetStencilFunc(GUIItem.NotEqual)

	local playerItemChildX = kPlayerItemLeftMargin

	-- Player number item
	local playerNumber = GUIManager:CreateTextItem()
	playerNumber:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	playerNumber:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(playerNumber)
	playerNumber:SetAnchor(GUIItem.Left, GUIItem.Center)
	playerNumber:SetTextAlignmentX(GUIItem.Align_Min)
	playerNumber:SetTextAlignmentY(GUIItem.Align_Center)
	playerNumber:SetPosition(Vector(playerItemChildX, 0, 0))
	playerItemChildX = playerItemChildX + kPlayerNumberWidth
	playerNumber:SetColor(Color(0.5, 0.5, 0.5, 1))
	playerNumber:SetStencilFunc(GUIItem.NotEqual)
	playerNumber:SetIsVisible(false)
	playerItem:AddChild(playerNumber)

	-- Player voice icon item.
	local playerVoiceIcon = GUIManager:CreateGraphicItem()
	playerVoiceIcon:SetSize(Vector(kPlayerVoiceChatIconSize, kPlayerVoiceChatIconSize, 0) * GUIScoreboard.kScalingFactor)
	playerVoiceIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
	playerVoiceIcon:SetPosition(Vector(playerItemChildX, -kPlayerVoiceChatIconSize / 2, 0) * GUIScoreboard.kScalingFactor)
	playerItemChildX = playerItemChildX + kPlayerVoiceChatIconSize
	playerVoiceIcon:SetTexture(kMutedVoiceTexture)
	playerVoiceIcon:SetStencilFunc(GUIItem.NotEqual)
	playerVoiceIcon:SetIsVisible(false)
	playerVoiceIcon:SetColor(GUIScoreboard.kVoiceMuteColor)
	playerItem:AddChild(playerVoiceIcon)

	------------------------------------------
	--  Badge icons
	------------------------------------------
	local maxBadges = Badges_GetMaxBadges()
	local badgeItems = {}

	-- Player badges
	for _ = 1, maxBadges do
		local playerBadge = GUIManager:CreateGraphicItem()
		playerBadge:SetSize(Vector(kPlayerBadgeIconSize, kPlayerBadgeIconSize, 0) * GUIScoreboard.kScalingFactor)
		playerBadge:SetAnchor(GUIItem.Left, GUIItem.Center)
		playerBadge:SetPosition(Vector(playerItemChildX, -kPlayerBadgeIconSize / 2, 0) * GUIScoreboard.kScalingFactor)
		playerItemChildX = playerItemChildX + kPlayerBadgeIconSize + kPlayerBadgeRightPadding
		playerBadge:SetIsVisible(false)
		playerBadge:SetStencilFunc(GUIItem.NotEqual)
		playerItem:AddChild(playerBadge)
		table.insert(badgeItems, playerBadge)
	end

	-- Player name text item.
	local playerNameItem = GUIManager:CreateTextItem()
	playerNameItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	playerNameItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(playerNameItem)
	playerNameItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	playerNameItem:SetTextAlignmentX(GUIItem.Align_Min)
	playerNameItem:SetTextAlignmentY(GUIItem.Align_Center)
	playerNameItem:SetPosition(Vector(playerItemChildX, 0, 0) * GUIScoreboard.kScalingFactor)
	playerNameItem:SetColor(Color(1, 1, 1, 1))
	playerNameItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(playerNameItem)

	local currentColumnX = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth, (self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10) - 75)

	local playerSkillIcon = GUIManager:CreateGraphicItem()
	playerSkillIcon:SetSize(kPlayerSkillIconSize * GUIScoreboard.kScalingFactor)
	playerSkillIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
	playerSkillIcon:SetPosition(Vector(currentColumnX, -kPlayerBadgeIconSize / 2, 0) * GUIScoreboard.kScalingFactor)
	playerSkillIcon:SetStencilFunc(GUIItem.NotEqual)
	playerSkillIcon:SetTexture(kPlayerSkillIconTexture)
	playerSkillIcon:SetTexturePixelCoordinates(0, 0, 100, 31)
	playerItem:AddChild(playerSkillIcon)

	local playerCommIcon = GUIManager:CreateGraphicItem()
	playerCommIcon:SetSize(kPlayerCommIconSize * GUIScoreboard.kScalingFactor)
	playerCommIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
	--playerCommIcon:SetPosition(Vector(kPlayerCommIconSize.x, kPlayerCommIconSize.y / 2, 0) * GUIScoreboard.kScalingFactor)
	playerCommIcon:SetPosition(Vector(-4, -3, 0) * GUIScoreboard.kScalingFactor)
	playerCommIcon:SetStencilFunc(GUIItem.NotEqual)
	playerCommIcon:SetTexture(kPlayerCommIconTexture)
	playerCommIcon:SetIsVisible(false)
	--playerCommIcon:SetTexturePixelCoordinates(0, 0, 100, 31)
	--playerItem:AddChild(playerCommIcon)
	playerSkillIcon:AddChild(playerCommIcon)

	local upgradeIcons = {}
	--print("GUIScoreboard.kScalingFactor: " .. tostring(GUIScoreboard.kScalingFactor))
	--print("GUIScoreboard.screenHeight: " .. tostring(GUIScoreboard.screenHeight))
	local startXupgrades = currentColumnX + ConditionalValue(GUIScoreboard.screenWidth < 1280, 30, 60)
	upgradeIcons["marineWelder"] = GUIManager:CreateGraphicItem()
	upgradeIcons["marineWelder"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["marineWelder"]:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["marineWelder"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["marineWelder"]:SetPosition(Vector(startXupgrades * GUIScoreboard.kScalingFactor, -(upgradeIcons["marineWelder"]:GetSize().y / 2), 0))
	--upgradeIcons["marineWelder"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["marineWelder"]:SetTexture(kEalMarineTexture)
	upgradeIcons["marineWelder"]:SetTexturePixelCoordinates(GUIUnpackCoords({113, 114 * 7, 227, 114 * 8}))
	upgradeIcons["marineWelder"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["marineWelder"])

	upgradeIcons["marineGrenade"] = GUIManager:CreateGraphicItem()
	upgradeIcons["marineGrenade"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["marineGrenade"]:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["marineGrenade"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["marineGrenade"]:SetPosition(Vector((startXupgrades + 20 + 4) * GUIScoreboard.kScalingFactor, -(upgradeIcons["marineGrenade"]:GetSize().y / 2), 0))
	--upgradeIcons["marineGrenade"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["marineGrenade"]:SetTexture(kEalMarineTexture)
	upgradeIcons["marineGrenade"]:SetTexturePixelCoordinates(GUIUnpackCoords({113, 114 * 15, 227, 114 * 16}))
	upgradeIcons["marineGrenade"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["marineGrenade"])

	upgradeIcons["marineMine"] = GUIManager:CreateGraphicItem()
	upgradeIcons["marineMine"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["marineMine"]:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["marineMine"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["marineMine"]:SetPosition(Vector((startXupgrades + 40 + 8) * GUIScoreboard.kScalingFactor, -(upgradeIcons["marineMine"]:GetSize().y / 2), 0))
	--upgradeIcons["marineMine"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["marineMine"]:SetTexture(kEalMarineTexture)
	upgradeIcons["marineMine"]:SetTexturePixelCoordinates(GUIUnpackCoords({113, 114 * 11, 227, 114 * 12}))
	upgradeIcons["marineMine"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["marineMine"])

	upgradeIcons["marineJetpack"] = GUIManager:CreateGraphicItem()
	upgradeIcons["marineJetpack"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["marineJetpack"]:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["marineJetpack"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["marineJetpack"]:SetPosition(Vector(startXupgrades + 20 + 28, -(upgradeIcons["marineJetpack"]:GetSize().y / 2), 0) * GUIScoreboard.kScalingFactor)
	--upgradeIcons["marineJetpack"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["marineJetpack"]:SetTexture(kEalMarineTexture)
	upgradeIcons["marineJetpack"]:SetTexturePixelCoordinates(GUIUnpackCoords({113, 114 * 12, 227, 114 * 13}))
	upgradeIcons["marineJetpack"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["marineJetpack"])

	upgradeIcons["marineWeapon"] = GUIManager:CreateGraphicItem()
	upgradeIcons["marineWeapon"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["marineWeapon"]:SetSize(Vector(28, 9, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["marineWeapon"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["marineWeapon"]:SetPosition(Vector(startXupgrades + 20, -(upgradeIcons["marineWeapon"]:GetSize().y / 2), 0) * GUIScoreboard.kScalingFactor)
	--upgradeIcons["marineWeapon"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["marineWeapon"]:SetTexture(kEalMarineTexture)
	upgradeIcons["marineWeapon"]:SetTexturePixelCoordinates(GUIUnpackCoords({0, 114 * 5, 340, 114 * 6}))
	upgradeIcons["marineWeapon"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["marineWeapon"])

	-- Alien upgrades
	upgradeIcons["alienShell"] = GUIManager:CreateGraphicItem()
	upgradeIcons["alienShell"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["alienShell"]:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["alienShell"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["alienShell"]:SetPosition(Vector(startXupgrades * GUIScoreboard.kScalingFactor, -(upgradeIcons["alienShell"]:GetSize().y / 2), 0))
	--upgradeIcons["alienShell"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["alienShell"]:SetTexture(kEalAlienTexture)
	upgradeIcons["alienShell"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 0, 114 * 12, 113 * 1, 114 * 13}))
	upgradeIcons["alienShell"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["alienShell"])

	upgradeIcons["alienVeil"] = GUIManager:CreateGraphicItem()
	upgradeIcons["alienVeil"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["alienVeil"]:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["alienVeil"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["alienVeil"]:SetPosition(Vector((startXupgrades + 20 + 4) * GUIScoreboard.kScalingFactor, -(upgradeIcons["alienVeil"]:GetSize().y / 2), 0))
	--upgradeIcons["alienVeil"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["alienVeil"]:SetTexture(kEalAlienTexture)
	upgradeIcons["alienVeil"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 0, 114 * 13, 113 * 1, 114 * 14}))
	upgradeIcons["alienVeil"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["alienVeil"])

	upgradeIcons["alienSpur"] = GUIManager:CreateGraphicItem()
	upgradeIcons["alienSpur"]:SetColor(RGBAtoColor(255, 255, 255, 1))
	upgradeIcons["alienSpur"]:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
	upgradeIcons["alienSpur"]:SetAnchor(GUIItem.Left, GUIItem.Center)
	upgradeIcons["alienSpur"]:SetPosition(Vector((startXupgrades + 40 + 8) * GUIScoreboard.kScalingFactor, -(upgradeIcons["alienSpur"]:GetSize().y / 2), 0))
	--upgradeIcons["alienSpur"]:SetStencilFunc(GUIItem.NotEqual)
	upgradeIcons["alienSpur"]:SetTexture(kEalAlienTexture)
	upgradeIcons["alienSpur"]:SetTexturePixelCoordinates(GUIUnpackCoords({113 * 0, 114 * 14, 113 * 1, 114 * 15}))
	upgradeIcons["alienSpur"]:SetIsVisible(false)
	playerItem:AddChild(upgradeIcons["alienSpur"])

	currentColumnX = currentColumnX + 75
	-- Status text item.
	local statusItem = GUIManager:CreateTextItem()
	statusItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	statusItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(statusItem)
	statusItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	statusItem:SetTextAlignmentX(GUIItem.Align_Min)
	statusItem:SetTextAlignmentY(GUIItem.Align_Center)
	statusItem:SetPosition(Vector(currentColumnX + ConditionalValue(GUIScoreboard.screenWidth < 1280, 30, 60), 0, 0) * GUIScoreboard.kScalingFactor)
	statusItem:SetColor(Color(1, 1, 1, 1))
	statusItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(statusItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 2 + 35

	-- Score text item.
	local scoreItem = GUIManager:CreateTextItem()
	scoreItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	scoreItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(scoreItem)
	scoreItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	scoreItem:SetTextAlignmentX(GUIItem.Align_Center)
	scoreItem:SetTextAlignmentY(GUIItem.Align_Center)
	scoreItem:SetPosition(Vector(currentColumnX + 30, 0, 0) * GUIScoreboard.kScalingFactor)
	scoreItem:SetColor(Color(1, 1, 1, 1))
	scoreItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(scoreItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX + 30

	-- Kill text item.
	local killsItem = GUIManager:CreateTextItem()
	killsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	killsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(killsItem)
	killsItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	killsItem:SetTextAlignmentX(GUIItem.Align_Center)
	killsItem:SetTextAlignmentY(GUIItem.Align_Center)
	killsItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
	killsItem:SetColor(Color(1, 1, 1, 1))
	killsItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(killsItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- assists text item.
	local assistsItem = GUIManager:CreateTextItem()
	assistsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	assistsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(assistsItem)
	assistsItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	assistsItem:SetTextAlignmentX(GUIItem.Align_Center)
	assistsItem:SetTextAlignmentY(GUIItem.Align_Center)
	assistsItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
	assistsItem:SetColor(Color(1, 1, 1, 1))
	assistsItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(assistsItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- Deaths text item.
	local deathsItem = GUIManager:CreateTextItem()
	deathsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	deathsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(deathsItem)
	deathsItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	deathsItem:SetTextAlignmentX(GUIItem.Align_Center)
	deathsItem:SetTextAlignmentY(GUIItem.Align_Center)
	deathsItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
	deathsItem:SetColor(Color(1, 1, 1, 1))
	deathsItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(deathsItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- Resources text item.
	local resItem = GUIManager:CreateTextItem()
	resItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	resItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(resItem)
	resItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	resItem:SetTextAlignmentX(GUIItem.Align_Center)
	resItem:SetTextAlignmentY(GUIItem.Align_Center)
	resItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
	resItem:SetColor(Color(1, 1, 1, 1))
	resItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(resItem)

	currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

	-- Ping text item.
	local pingItem = GUIManager:CreateTextItem()
	pingItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
	pingItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
	GUIMakeFontScale(pingItem)
	pingItem:SetAnchor(GUIItem.Left, GUIItem.Center)
	pingItem:SetTextAlignmentX(GUIItem.Align_Min)
	pingItem:SetTextAlignmentY(GUIItem.Align_Center)
	pingItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
	pingItem:SetColor(Color(1, 1, 1, 1))
	pingItem:SetStencilFunc(GUIItem.NotEqual)
	playerItem:AddChild(pingItem)

	local playerTextIcon = GUIManager:CreateGraphicItem()
	playerTextIcon:SetSize(Vector(kPlayerVoiceChatIconSize, kPlayerVoiceChatIconSize, 0) * GUIScoreboard.kScalingFactor)
	playerTextIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
	playerTextIcon:SetTexture(kMutedTextTexture)
	playerTextIcon:SetStencilFunc(GUIItem.NotEqual)
	playerTextIcon:SetIsVisible(false)
	playerTextIcon:SetColor(GUIScoreboard.kVoiceMuteColor)
	playerItem:AddChild(playerTextIcon)

	local steamFriendIcon = GUIManager:CreateGraphicItem()
	steamFriendIcon:SetSize(Vector(kPlayerVoiceChatIconSize, kPlayerVoiceChatIconSize, 0) * GUIScoreboard.kScalingFactor)
	steamFriendIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
	steamFriendIcon:SetTexture(kSteamfriendTexture)
	steamFriendIcon:SetStencilFunc(GUIItem.NotEqual)
	steamFriendIcon:SetIsVisible(false)
	steamFriendIcon.allowHighlight = true
	playerItem:AddChild(steamFriendIcon)

	-- Let's do a table here to easily handle the highlighting/clicking of icons
	-- It also makes it easy for other mods to add icons afterwards
	local iconTable = {}
	table.insert(iconTable, steamFriendIcon)
	table.insert(iconTable, playerVoiceIcon)
	table.insert(iconTable, playerTextIcon)

	return {
		Background = playerItem,
		Number = playerNumber,
		Name = playerNameItem,
		Voice = playerVoiceIcon,
		Status = statusItem,
		CommIcon = playerCommIcon,
		SkillIcon = playerSkillIcon,
		UpgradeIcons = upgradeIcons,
		Score = scoreItem,
		Kills = killsItem,
		Assists = assistsItem,
		Deaths = deathsItem,
		Resources = resItem,
		Ping = pingItem,
		BadgeItems = badgeItems,
		Text = playerTextIcon,
		SteamFriend = steamFriendIcon,
		IconTable = iconTable
	}
end

local function HandlePlayerVoiceClicked(self)
	if MouseTracker_GetIsVisible() then
		local mouseX, mouseY = Client.GetCursorPosScreen()
		for t = 1, #self.teams do
			local playerList = self.teams[t]["PlayerList"]
			for p = 1, #playerList do
				local playerItem = playerList[p]
				if GUIItemContainsPoint(playerItem["Voice"], mouseX, mouseY) and playerItem["Voice"]:GetIsVisible() then
					local clientIndex = playerItem["ClientIndex"]
					ChatUI_SetClientMuted(clientIndex, not ChatUI_GetClientMuted(clientIndex))
				end
			end
		end
	end
end

local function HandlePlayerTextClicked(self)
	if MouseTracker_GetIsVisible() then
		local mouseX, mouseY = Client.GetCursorPosScreen()
		for t = 1, #self.teams do
			local playerList = self.teams[t]["PlayerList"]
			for p = 1, #playerList do
				local playerItem = playerList[p]
				if GUIItemContainsPoint(playerItem["Text"], mouseX, mouseY) and playerItem["Text"]:GetIsVisible() then
					local clientIndex = playerItem["ClientIndex"]
					local steamId = GetSteamIdForClientIndex(clientIndex)
					ChatUI_SetSteamIdTextMuted(steamId, not ChatUI_GetSteamIdTextMuted(steamId))
				end
			end
		end

		if self.favoriteButton and GUIItemContainsPoint(self.favoriteButton, mouseX, mouseY) then
			local serverIsFavorite = not self.favoriteButton.isServerFavorite
			self.favoriteButton:SetTexture(serverIsFavorite and self.kFavoriteTexture or self.kNotFavoriteTexture)
			self.favoriteButton.isServerFavorite = serverIsFavorite
			SetServerIsFavorite({address = self.serverAddress}, serverIsFavorite)

			if serverIsFavorite then
				self.blockedButton.isServerBlocked = false
				self.blockedButton:SetTexture(self.kNotBlockedTexture)
			end
		elseif self.blockedButton and GUIItemContainsPoint(self.blockedButton, mouseX, mouseY) then
			local serverIsBlocked = not self.blockedButton.isServerBlocked
			self.blockedButton:SetTexture(serverIsBlocked and self.kBlockedTexture or self.kNotBlockedTexture)
			self.blockedButton.isServerBlocked = serverIsBlocked
			SetServerIsBlocked({address = self.serverAddress}, serverIsBlocked)

			if serverIsBlocked then
				self.favoriteButton.isServerFavorite = false
				self.favoriteButton:SetTexture(self.kNotFavoriteTexture)
			end
		end
	end
end

function GUIScoreboard:SetIsVisible(state)
	self.hiddenOverride = not state

	-- Don't remove the deltatime parameter we use it to detect if the scoreboard get opened
	self:Update(0)
end

function GUIScoreboard:GetIsVisible()
	return not self.hiddenOverride
end

function GUIScoreboard:SendKeyEvent(key, down)
	if ChatUI_EnteringChatMessage() then
		return false
	end

	if GetIsBinding(key, "Scoreboard") then
		self.visible = down and not self.hiddenOverride
		if not self.visible then
			self.hoverMenu:Hide()
		else
			self.updateInterval = 0
		end
	end

	if not self.visible then
		return false
	end

	if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down and down and not MainMenu_GetIsOpened() then
		HandlePlayerTextClicked(self)

		local steamId = GetSteamIdForClientIndex(self.hoverPlayerClientIndex) or 0
		if self.hoverMenu.background:GetIsVisible() then
			-- Display the menu for bots if dev mode is on (steamId is 0 but they have a proper clientIndex)
			return false
		elseif steamId ~= 0 or self.hoverPlayerClientIndex ~= 0 and Shared.GetDevMode() then
			local isTextMuted = ChatUI_GetSteamIdTextMuted(steamId)
			local isVoiceMuted = ChatUI_GetClientMuted(self.hoverPlayerClientIndex)
			local function openSteamProf()
				Client.ShowWebpage(string.format("%s[U:1:%s]", kSteamProfileURL, steamId))
			end
			local function openNS2PanelProf()
				Client.ShowWebpage(string.format(kNS2PanelProfileURL, steamId))
			end
			local function muteText()
				ChatUI_SetSteamIdTextMuted(steamId, not isTextMuted)
			end
			local function muteVoice()
				ChatUI_SetClientMuted(self.hoverPlayerClientIndex, not isVoiceMuted)
			end

			self.hoverMenu:ResetButtons()

			local teamColorBg
			local teamColorHighlight
			local playerName = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "Name")
			local teamNumber = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "EntityTeamNumber")
			local isCommander = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "IsCommander") and GetIsVisibleTeam(teamNumber)

			local textColor = Color(1, 1, 1, 1)
			local nameBgColor = Color(0, 0, 0, 0)

			if isCommander then
				teamColorBg = GUIScoreboard.kCommanderFontColor
			elseif teamNumber == 1 then
				teamColorBg = GUIScoreboard.kBlueColor
			elseif teamNumber == 2 then
				teamColorBg = GUIScoreboard.kRedColor
			else
				teamColorBg = GUIScoreboard.kSpectatorColor
			end

			local bgColor = teamColorBg * 0.1
			bgColor.a = 0.9

			teamColorHighlight = teamColorBg * 0.75
			teamColorBg = teamColorBg * 0.5

			self.hoverMenu:SetBackgroundColor(bgColor)
			self.hoverMenu:AddButton(playerName, nameBgColor, nameBgColor, textColor)
			self.hoverMenu:AddButton(Locale.ResolveString("SB_MENU_STEAM_PROFILE"), teamColorBg, teamColorHighlight, textColor, openSteamProf)
			self.hoverMenu:AddButton("NS2Panel profile", teamColorBg, teamColorHighlight, textColor, openNS2PanelProf)

			if Client.GetSteamId() ~= steamId then
				self.hoverMenu:AddSeparator("muteOptions")
				self.hoverMenu:AddButton(ConditionalValue(isVoiceMuted, Locale.ResolveString("SB_MENU_UNMUTE_VOICE"), Locale.ResolveString("SB_MENU_MUTE_VOICE")), teamColorBg, teamColorHighlight, textColor, muteVoice)
				self.hoverMenu:AddButton(ConditionalValue(isTextMuted, Locale.ResolveString("SB_MENU_UNMUTE_TEXT"), Locale.ResolveString("SB_MENU_MUTE_TEXT")), teamColorBg, teamColorHighlight, textColor, muteText)
			end

			self.hoverMenu:Show()
			self.badgeNameTooltip:Hide(0)
		end
	end

	if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
		self.mousePressed["LMB"]["Down"] = down
		if down then
			local mouseX, mouseY = Client.GetCursorPosScreen()
			self.isDragging = GUIItemContainsPoint(self.slidebarBg, mouseX, mouseY)

			if not MouseTracker_GetIsVisible() then
				SetMouseVisible(self, true)
			else
				HandlePlayerVoiceClicked(self)
			end

			return true
		end
	end

	if self.slidebarBg:GetIsVisible() then
		if key == InputKey.MouseWheelDown then
			self.slidePercentage = math.min(self.slidePercentage + 5, 100)
			return true
		elseif key == InputKey.MouseWheelUp then
			self.slidePercentage = math.max(self.slidePercentage - 5, 0)
			return true
		elseif key == InputKey.PageDown and down then
			self.slidePercentage = math.min(self.slidePercentage + 10, 100)
			return true
		elseif key == InputKey.PageUp and down then
			self.slidePercentage = math.max(self.slidePercentage - 10, 0)
			return true
		elseif key == InputKey.Home then
			self.slidePercentage = 0
			return true
		elseif key == InputKey.End then
			self.slidePercentage = 100
			return true
		end
	end
end

-- ToDo: eal
local function CreateEALIcon(container, Texture, TextureVector, TextureSize, IconNr, haveNumber, sTooltip)
	local containerSize = container:GetSize()

	local item = {}
	local StartSpacing = 52
	local ColumnSpacing = 72

	if lowResScreen then
		StartSpacing = StartSpacing / 1.25
		ColumnSpacing = ColumnSpacing / 1.25
	end
	StartSpacing = GUILinearScale(StartSpacing)
	--Assign a count variable for later use
	item.count = 0

	item.icon = GUIManager:CreateGraphicItem()
	item.icon:SetStencilFunc(GUIItem.NotEqual)
	item.icon:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.icon:SetLayer(kGUILayerScoreboard)
	item.icon:SetSize(TextureSize)
	item.icon:SetTexture(Texture)
	item.icon:SetColor(kEalInactiveColor)
	-- item.icon:SetTexture("ui/Devnull_IPS/black.dds")
	if sTooltip then
		item.icon.tooltipText = tostring(sTooltip)
	end
	if TextureVector then
		item.icon:SetTexturePixelCoordinates(GUIUnpackCoords(TextureVector))
	end

	local ThisPos = StartSpacing + (GUILinearScale(ColumnSpacing) * IconNr)
	item.icon:SetPosition(Vector(ThisPos, GUILinearScale(5.7), 0))

	container:AddChild(item.icon)

	item.textShadow = GUIManager:CreateTextItem()
	item.textShadow:SetStencilFunc(GUIItem.NotEqual)
	item.textShadow:SetFontName(Fonts.kAgencyFB_Medium)
	item.textShadow:SetColor(Color(0, 0, 0, 1))
	GUIMakeFontScale(item.textShadow, "kAgencyFB", 22)
	item.textShadow:SetAnchor(GUIItem.Left, GUIItem.Bottom)
	item.textShadow:SetText("0")
	item.textShadow:SetTextAlignmentX(GUIItem.Right)
	item.textShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.textShadow:SetPosition(Vector(ThisPos + GUILinearScale(item.icon:GetSize().x / 2) + GUILinearScale(3) + GUILinearScale(1), GUILinearScale(-17) + GUILinearScale(1), 0))
	item.textShadow:SetLayer(kGUILayerScoreboard)
	item.textShadow:SetIsVisible(haveNumber)
	container:AddChild(item.textShadow)

	item.text = GUIManager:CreateTextItem()
	item.text:SetStencilFunc(GUIItem.NotEqual)
	item.text:SetFontName(Fonts.kAgencyFB_Medium)
	item.text:SetColor(RGBAtoColor(255, 255, 255, 1))
	GUIMakeFontScale(item.text, "kAgencyFB", 22)
	item.text:SetAnchor(GUIItem.Left, GUIItem.Bottom)
	item.text:SetTextAlignmentX(GUIItem.Right)
	item.text:SetTextAlignmentY(GUIItem.Align_Center)
	item.text:SetPosition(Vector(ThisPos + GUILinearScale(item.icon:GetSize().x / 2) + GUILinearScale(3), GUILinearScale(-17), 0))
	item.text:SetText("0")
	item.text:SetLayer(kGUILayerScoreboard)
	item.text:SetIsVisible(haveNumber)
	container:AddChild(item.text)

	-- item.text:SetPosition(Vector(xOffset, (kTitleSize.y+5)/2, 0))

	return item
end

function GUIScoreboard:CreateEALGraphicHeader(team, color, logoTexture, logoCoords, logoSizeX, logoSizeY)
	local item = {}

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	--item.background:SetColor(color)
	item.background:SetColor(Color(0, 0, 0, 0.5))
	--item.background:SetTexture("ui/statsheader.dds")
	item.background:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsMiddle))
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetInheritsParentAlpha(false)
	item.background:SetLayer(kGUILayerScoreboard)
	item.background:SetSize(Vector(self:GetTeamItemWidth() * GUIScoreboard.kScalingFactor, kTitleSize.y + 5, 0))
	item.background:SetPosition(Vector(0, -(kTitleSize.y + 5), 0))
	self.background:AddChild(item.background)

	local xOffset = GUILinearScale(4)

	logoSizeX = GUILinearScale(logoSizeX)
	logoSizeY = GUILinearScale(logoSizeY)

	item.logo = GUIManager:CreateGraphicItem()
	item.logo:SetStencilFunc(GUIItem.NotEqual)
	item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.logo:SetLayer(kGUILayerScoreboard)
	item.logo:SetIsVisible(true)
	item.logo:SetSize(Vector(logoSizeX, logoSizeY, 0))
	item.logo:SetPosition(Vector(xOffset, -logoSizeY / 2, 0))
	item.logo:SetTexture(logoTexture)
	if logoCoords then
		item.logo:SetTexturePixelCoordinates(GUIUnpackCoords(logoCoords))
	end
	item.background:AddChild(item.logo)

	xOffset = xOffset + logoSizeX + GUILinearScale(10)
	lowResScreen = (GUIScoreboard.screenWidth < 1800) and true or false
	if team == kTeam1Index then
		EALitems[kTechId.Welder] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 7, 340, 114 * 8}, Vector(72, 24, 0), 0, true, Locale.ResolveString(LookupTechData(kTechId.Welder, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.ClusterGrenade] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 15, 340, 114 * 16}, Vector(72, 24, 0), 0.5, true, Locale.ResolveString(LookupTechData(kTechId.ClusterGrenade, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Mine] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 11, 340, 114 * 12}, Vector(72, 24, 0), 1, true, Locale.ResolveString(LookupTechData(kTechId.Mine, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Rifle] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 1, 340, 114 * 2}, Vector(72, 24, 0), 2, true, Locale.ResolveString(LookupTechData(kTechId.Rifle, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Shotgun] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 2, 340, 114 * 3}, Vector(72, 24, 0), 3, true, Locale.ResolveString(LookupTechData(kTechId.Shotgun, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Flamethrower] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 4, 340, 114 * 5}, Vector(72, 24, 0), 4, true, Locale.ResolveString(LookupTechData(kTechId.Flamethrower, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.HeavyMachineGun] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 5, 340, 114 * 6}, Vector(72, 24, 0), 5, true, Locale.ResolveString(LookupTechData(kTechId.HeavyMachineGun, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.GrenadeLauncher] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 3, 340, 114 * 4}, Vector(72, 24, 0), 6, true, Locale.ResolveString(LookupTechData(kTechId.GrenadeLauncher, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Jetpack] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 12, 340, 114 * 13}, Vector(72, 24, 0), 6.75, true, Locale.ResolveString(LookupTechData(kTechId.Jetpack, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.DualMinigunExosuit] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 14, 340, 114 * 15}, Vector(72, 24, 0), 7.5, true, Locale.ResolveString(LookupTechData(kTechId.DualMinigunExosuit, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.DualRailgunExosuit] = CreateEALIcon(item.background, kEalMarineTexture, {0, 114 * 13, 340, 114 * 14}, Vector(72, 24, 0), 8.5, true, Locale.ResolveString(LookupTechData(kTechId.DualRailgunExosuit, kTechDataDisplayName, "unknown")))
	elseif team == kTeam2Index then
		EALitems[kTechId.Skulk] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 0, 340, 114 * 1}, Vector(72, 24, 0), 0, true, Locale.ResolveString(LookupTechData(kTechId.Skulk, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Gorge] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 1, 340, 114 * 2}, Vector(72, 24, 0), 1, true, Locale.ResolveString(LookupTechData(kTechId.Gorge, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Lerk] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 2, 340, 114 * 3}, Vector(72, 24, 0), 2, true, Locale.ResolveString(LookupTechData(kTechId.Lerk, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Fade] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 3, 340, 114 * 4}, Vector(72, 24, 0), 3, true, Locale.ResolveString(LookupTechData(kTechId.Fade, kTechDataDisplayName, "unknown")))

		EALitems[kTechId.Onos] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 4, 340, 114 * 5}, Vector(72, 24, 0), 4, true, Locale.ResolveString(LookupTechData(kTechId.Onos, kTechDataDisplayName, "unknown")))

		-- if prowler
		if kProwlerCost then
			EALitems[kTechId.Prowler] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 5, 340, 114 * 6}, Vector(72, 24, 0), 5, true, Locale.ResolveString(LookupTechData(kTechId.Prowler, kTechDataDisplayName, "unknown")))
		end

		--PVE
		local iconPos = 6.5 --add spacer
		EALitems[kTechId.Shell] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 6, 340, 114 * 7}, Vector(72, 24, 0), iconPos, false, Locale.ResolveString(LookupTechData(kTechId.Shell, kTechDataDisplayName, "unknown")))
		EALitems[kTechId.TwoShells] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 6, 340, 114 * 7}, Vector(72, 24, 0), iconPos + 0.2, true, Locale.ResolveString(LookupTechData(kTechId.Shell, kTechDataDisplayName, "unknown")))
		EALitems[kTechId.ThreeShells] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 6, 340, 114 * 7}, Vector(72, 24, 0), iconPos + 0.4, false, Locale.ResolveString(LookupTechData(kTechId.Shell, kTechDataDisplayName, "unknown")))

		iconPos = iconPos + 1
		EALitems[kTechId.Veil] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 8, 340, 114 * 9}, Vector(72, 24, 0), iconPos, false, Locale.ResolveString(LookupTechData(kTechId.Veil, kTechDataDisplayName, "unknown")))
		EALitems[kTechId.TwoVeils] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 8, 340, 114 * 9}, Vector(72, 24, 0), iconPos + 0.2, true, Locale.ResolveString(LookupTechData(kTechId.Veil, kTechDataDisplayName, "unknown")))
		EALitems[kTechId.ThreeVeils] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 8, 340, 114 * 9}, Vector(72, 24, 0), iconPos + 0.4, false, Locale.ResolveString(LookupTechData(kTechId.Veil, kTechDataDisplayName, "unknown")))

		iconPos = iconPos + 1
		EALitems[kTechId.Spur] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 7, 340, 114 * 8}, Vector(72, 24, 0), iconPos, false, Locale.ResolveString(LookupTechData(kTechId.Spur, kTechDataDisplayName, "unknown")))
		EALitems[kTechId.TwoSpurs] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 7, 340, 114 * 8}, Vector(72, 24, 0), iconPos + 0.2, true, Locale.ResolveString(LookupTechData(kTechId.Spur, kTechDataDisplayName, "unknown")))
		EALitems[kTechId.ThreeSpurs] = CreateEALIcon(item.background, kEalAlienTexture, {0, 114 * 7, 340, 114 * 8}, Vector(72, 24, 0), iconPos + 0.4, false, Locale.ResolveString(LookupTechData(kTechId.Spur, kTechDataDisplayName, "unknown")))
	end

	return item
end
