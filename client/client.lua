local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('QBCore:Client:UpdateObject', function() QBCore = exports['qb-core']:GetCoreObject() end)

PlayerJob = {}
onDuty = false
Peds = {}
Targets = {}
searchProps = {}
Props = {}
local TrollyProp = nil

scrapPool = {
	--{ model = ``, xPos = , yPos = , zPos = , xRot = , yRot = , zRot = },
	--{ model = `sf_prop_sf_art_box_cig_01a`, xPos = 0.16, yPos = -0.06, zPos = 0.21, xRot = 52.0, yRot = 288.0, zRot = 175.0},
	{ model = `hei_prop_drug_statue_box_01`, xPos = 0.08, yPos = 0.05, zPos = 0.06, xRot = 7.0, yRot = 198.0, zRot = 145.0},
	{ model = `prop_mat_box`, xPos = 0.0, yPos = 0.28, zPos = 0.36, xRot = 136.0, yRot = 114.0, zRot = 181.0},
	{ model = `prop_box_ammo03a`, xPos = -0.08, yPos = 0.04, zPos = 0.32, xRot = 76.0, yRot = 110.0, zRot = 185.0},
	{ model = `prop_rub_scrap_06`, xPos = 0.01, yPos = 0.02, zPos = 0.27, xRot = 85.0, yRot = 371.0, zRot = 177.0 },
	{ model = `prop_cs_cardbox_01`, xPos = 0.04, yPos = 0.04, zPos = 0.28, xRot = 52.0, yRot = 294.0, zRot = 177.0 },
	{ model = `v_ret_gc_bag01`, xPos = 0.16, yPos = 0.08, zPos = 0.24, xRot = 68.0, yRot = 394.0, zRot = 141.0 },
	{ model = `prop_ld_suitcase_01`, xPos = -0.04, yPos = 0.06, zPos = 0.31, xRot = -2.0, yRot = 21.0, zRot = 155.0 },
	{ model = `v_ind_cs_toolbox2`, xPos = 0.04, yPos = 0.12, zPos = 0.29, xRot = 56.0, yRot = 287.0, zRot = 169.0 },
}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job if PlayerData.job.name == Config.JobRole then onDuty = PlayerJob.onduty end end)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty) if Config.JobRole then if PlayerJob.name == Config.JobRole then onDuty = duty end end end)

AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
	QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job if PlayerData.job.name == Config.JobRole then onDuty = PlayerJob.onduty end end)
end)

--- Blips + Peds
CreateThread(function()
	JobLocation = PolyZone:Create({
		vector2(992.39141845703, -3113.3854980469),
		vector2(1028.5169677734, -3113.1450195312),
		vector2(1027.978515625, -3088.9782714844),
		vector2(992.19049072266, -3089.8234863281)
	},
	{ name = "Recycling", debugPoly = Config.Debug })
	JobLocation:onPlayerInOut(function(isPointInside)
		if not isPointInside then
			EndJob() ClearProps()
			if Config.Debug then print("^5Debug^7: ^3PolyZone^7: ^2Leaving Area^7. ^2Clocking out and cleaning up^7") end
			if Config.JobRole then
				if onDuty then TriggerServerEvent("QBCore:ToggleDuty") end
			elseif onDuty == true then
				onDuty = false
			end
		else MakeProps()
		end
	end)

	for _, v in pairs(Config.Locations) do
		for i = 1, #v do
			local v = v[i]
			if Config.Blips and v.blipTrue then blip = makeBlip({coords = v.coords, sprite = v.sprite, col = v.col, name = v.name})	end
			if Config.Pedspawn then
				if not Peds[v.name..i] then
					loadModel(v.model)
					Peds[v.name..i] = makePed(v.model, v.coords, true, false, v.scenario, nil)
				end
			end
		end
	end
	--Make Targets
	local price = "" if Config.PayAtDoor then price = " ($"..Config.PayAtDoor..")" end
	Targets["RecyclingEnter"] =
		exports['qb-target']:AddBoxZone("RecyclingEnter", vector3(746.82, -1398.93, 26.55), 0.4, 1.6, { name="RecyclingEnter", debugPoly=Config.Debug, minZ=25.2, maxZ=28.0 },
			{ options = { { event = "jim-recycle:TeleWareHouse", icon = "fas fa-recycle", label = Loc[Config.Lan].target["enter"]..price, enter = true, job = Config.JobRole }, },
			distance = 1.5 })

	Targets["RecyclingExit"] =
		exports['qb-target']:AddBoxZone("RecyclingExit", vector3(991.97, -3097.81, -39.0), 1.6, 0.4, { name="RecyclingExit", debugPoly=Config.Debug, useZ=true, },
			{ options = { { event = "jim-recycle:TeleWareHouse", icon = "fas fa-recycle", label = Loc[Config.Lan].target["exit"], enter =  false }, },
			distance = 1.5 })

	Targets["RecycleDuty"] =
		exports['qb-target']:AddCircleZone("RecycleDuty", vector3(995.36, -3099.91, -39.2), 0.45, { name="RecycleDuty", debugPoly=Config.Debug, useZ=true, },
			{ options = { { event = "jim-recycle:dutytoggle", icon = "fas fa-hard-hat", label = Loc[Config.Lan].target["duty"], job = Config.JobRole }, },
			distance = 1.5 })
	--Recyclable Material Trader
	for i = 1, #Config.Locations["Trade"] do
		Targets["Trade"..i] =
			exports['qb-target']:AddCircleZone("Trade"..i, Config.Locations["Trade"][i].coords.xyz, 1.1, { name="Trade"..i, debugPoly=Config.Debug, useZ=true, },
				{ options = { { event = "jim-recycle:Trade:Menu", icon = "fas fa-box", label = Loc[Config.Lan].target["trade"]  }, },
				distance = 1.5 })
	end
	--Sell Materials
	for i = 1, #Config.Locations["Recycle"] do
		Targets["Recycle"..i] =
			exports['qb-target']:AddCircleZone("Recycle"..i, Config.Locations["Recycle"][i].coords.xyz, 1.1, { name="Recycle"..i, debugPoly=Config.Debug, useZ=true, },
				{ options = { { event = "jim-recycle:Selling:Menu", icon = "fas fa-box", label = Loc[Config.Lan].target["sell"] }, },
				distance = 2.5 })
	end
	--Bottle Selling Third Eyes
	for i = 1, #Config.Locations["BottleBanks"] do
		Targets["BottleBank"..i] =
			exports['qb-target']:AddCircleZone("BottleBank"..i, Config.Locations["BottleBanks"][i].coords.xyz, 1.2,	{ name="BottleBank"..i, debugPoly=Config.Debug, useZ=true, },
				{ options = { { event = "jim-recycle:Bottle:Menu", icon = "fas fa-certificate", label = Loc[Config.Lan].target["sell_bottles"], job = Config.JobRole  }, },
				distance = 1.5 })
	end
end)
---- Render Props -------
function MakeProps()
	--Floor Level Props (Using these for the selection pool)
	if Config.Debug then print("^5Debug^7: ^3MakeProps^7() ^2Spawning props") end
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_SC_02`,		coords = vector4(1003.63, -3108.50, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_prop_crate_wlife_bc`,		coords = vector4(1018.18, -3102.80, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_watch`,			coords = vector4(1013.33, -3102.80, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_SHide`,			coords = vector4(1018.18, -3096.95, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Oegg`,			coords = vector4(1006.05, -3091.60, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_MiniG`,			coords = vector4(1018.18, -3108.50, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_FReel`,			coords = vector4(1008.48, -3102.80, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,		coords = vector4(1015.75, -3102.80, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Jewels_BC`,		coords = vector4(1018.18, -3091.60, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Jewels_BC`,		coords = vector4(1003.63, -3091.60, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Art_02_SC`,		coords = vector4(1010.90, -3108.50, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_SC_02`,		coords = vector4(1010.90, -3096.95, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_clothing_BC`,		coords = vector4(1008.48, -3096.95, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_biohazard_BC`,	coords = vector4(1010.90, -3102.80, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_BC_02`,		coords = vector4(1006.05, -3108.50, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Art_BC`,			coords = vector4(1015.75, -3108.50, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Money_BC`,		coords = vector4(1003.63, -3096.95, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_clothing_SC`,		coords = vector4(1013.33, -3091.60, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Art_02_BC`,		coords = vector4(1013.33, -3108.50, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Money_SC`,		coords = vector4(1010.90, -3091.60, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Med_SC`,			coords = vector4(1008.48, -3091.60, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_SC_02`,		coords = vector4(1008.48, -3108.50, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Jewels_racks_BC`,	coords = vector4(1003.63, -3102.80, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Money_SC`,		coords = vector4(1006.05, -3096.95, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Money_SC`,		coords = vector4(1015.75, -3091.60, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_SC_02`,		coords = vector4(1015.75, -3096.95, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Jewels_SC`,		coords = vector4(1006.05, -3102.80, -39.99, 0.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_BC_02`,		coords = vector4(1013.33, -3096.95, -39.99, 0.0)}, 1, 0)
	--These needed headings adjusting
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_BC_02`,		coords = vector4(1026.75, -3096.43, -39.99, -90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Jewels_BC`,		coords = vector4(1026.75, -3106.52, -39.99, -90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Bull_BC_02`,		coords = vector4(1026.75, -3091.59, -39.99, -90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Jewels_racks_SC`,	coords = vector4(1026.75, -3111.38, -39.99, -90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Jewels_BC`,		coords = vector4(1026.75, -3108.88, -39.99, -90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_XLDiam`,			coords = vector4(1026.75, -3094.01, -39.99, -90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Art_02_BC`,		coords = vector4(993.355, -3106.60, -39.99, 90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Art_SC`,			coords = vector4(993.355, -3111.30, -39.99, 90.0)}, 1, 0)
	searchProps[#searchProps+1] = makeProp({prop = `ex_Prop_Crate_Art_BC`,			coords = vector4(993.355, -3108.95, -39.99, 90.0)}, 1, 0)

	--Second Level
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1006.05, -3096.95, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_prop_crate_wlife_sc`,			coords = vector4(1003.63, -3102.80, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_prop_crate_jewels_racks_sc`,		coords = vector4(1003.63, -3091.60, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_SC`,				coords = vector4(1013.33, -3096.95, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_SC`,				coords = vector4(1008.48, -3108.50, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Tob_SC`,				coords = vector4(1018.18, -3096.95, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_SC`,				coords = vector4(1013.33, -3108.50, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_biohazard_BC`,		coords = vector4(1003.63, -3108.50, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_RW`,			coords = vector4(1013.33, -3091.60, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Ammo_BC`,				coords = vector4(1013.33, -3102.80, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_BC`,				coords = vector4(1003.63, -3096.95, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_biohazard_SC`,		coords = vector4(1006.05, -3108.50, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1015.75, -3096.95, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_HighEnd_pharma_SC`,	coords = vector4(1015.75, -3091.60, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_SC`,				coords = vector4(1018.18, -3102.80, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_BC`,				coords = vector4(1018.18, -3108.50, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1008.48, -3102.80, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_HighEnd_pharma_BC`,	coords = vector4(1018.18, -3091.60, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_BC`,				coords = vector4(1015.75, -3102.80, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_furJacket_SC`,		coords = vector4(1006.05, -3102.80, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Expl_bc`,				coords = vector4(1010.90, -3102.80, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(1010.90, -3108.50, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_BC`,				coords = vector4(1010.90, -3096.95, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Tob_SC`,				coords = vector4(1010.90, -3091.60, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_SC`,				coords = vector4(1015.75, -3108.50, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1008.48, -3091.60, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1008.48, -3096.60, -37.81, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_SC`,			coords = vector4(1006.05, -3091.60, -37.81, 0.0)}, 1, 0)
	--These needed headings adjusting
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Med_BC`,				coords = vector4(1026.75, -3106.52, -37.81, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1026.75, -3111.38, -37.81, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Narc_BC`,				coords = vector4(1026.75, -3091.59, -37.81, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Narc_SC`,				coords = vector4(1026.75, -3094.01, -37.81, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Med_SC`,				coords = vector4(1026.75, -3108.88, -37.81, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_pharma_SC`,			coords = vector4(1026.75, -3096.43, -37.81, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Bull_BC_02`,			coords = vector4(993.355, -3106.60, -37.81, 90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Bull_BC_02`,			coords = vector4(993.355, -3111.30, -37.81, 90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Bull_SC_02`,			coords = vector4(993.355, -3108.95, -37.81, 90.0)}, 1, 0)

	--Third Level
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1013.33, -3102.80, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1015.75, -3102.80, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Art_BC`,				coords = vector4(1013.33, -3108.50, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Art_BC`,				coords = vector4(1015.75, -3108.50, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_clothing_BC`,			coords = vector4(1018.18, -3096.95, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Gems_BC`,				coords = vector4(1003.63, -3108.50, -35.61, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Wlife_BC`,			coords = vector4(1018.18, -3091.60, -35.74, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Med_BC`,				coords = vector4(1008.48, -3091.60, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Wlife_BC`,			coords = vector4(1015.75, -3091.60, -35.74, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(1008.48, -3096.95, -35.60, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(1010.90, -3096.95, -35.60, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1010.90, -3091.60, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_furJacket_BC`,		coords = vector4(1013.33, -3091.60, -35.74, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_HighEnd_pharma_BC`,	coords = vector4(1003.63, -3091.60, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Art_02_BC`,			coords = vector4(1013.33, -3096.95, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Tob_BC`,				coords = vector4(1010.90, -3108.50, -35.75, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Art_02_BC`,			coords = vector4(1018.18, -3108.50, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1003.63, -3096.95, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(1006.05, -3096.95, -35.60, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(1006.05, -3102.80, -35.60, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Art_BC`,				coords = vector4(1015.75, -3096.95, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(1010.90, -3102.80, -35.60, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(1008.48, -3102.80, -35.60, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1006.05, -3091.60, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1006.05, -3108.50, -35.62, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Tob_BC`,				coords = vector4(1018.18, -3102.80, -35.75, 0.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Tob_BC`,				coords = vector4(1008.48, -3108.50, -35.75, 0.0)}, 1, 0)
	--These needed headings adjusting
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1026.75, -3106.52, -35.62, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1026.75, -3108.88, -35.62, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Closed_BC`,			coords = vector4(1026.75, -3111.38, -35.62, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_furJacket_BC`,		coords = vector4(1026.75, -3091.59, -35.74, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_furJacket_BC`,		coords = vector4(1026.75, -3094.01, -35.74, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_furJacket_BC`,		coords = vector4(1026.75, -3096.43, -35.74, -90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(993.355, -3106.60, -35.60, 90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_BC`,				coords = vector4(993.355, -3111.30, -35.60, 90.0)}, 1, 0)
	Props[#Props+1] = makeProp({prop = `ex_Prop_Crate_Elec_SC`,				coords = vector4(993.355, -3108.95, -35.62, 90.0)}, 1, 0)

	for k in pairs(scrapPool) do loadModel(scrapPool[k].model) end
end
function EndJob()
	if Targets["Package"] then exports["qb-target"]:RemoveTargetEntity(randPackage) end
	destroyProp(TrollyProp) TrollyProp = nil
	for i = 1, #searchProps do SetEntityDrawOutline(searchProps[i], false) end
	randPackage = nil
	if scrapProp then
		destroyProp(scrapProp)
		scrapProp = nil
	end
end

function ClearProps()
	if Config.Debug then print("^5Debug^7: ^3ClearProps^7() ^2Exiting building^7, ^2clearing previous props ^7(^2if any^7)") end
	for _, v in pairs(searchProps) do unloadModel(GetEntityModel(v)) DeleteObject(v) end searchProps = {}
	for _, v in pairs(Props) do unloadModel(GetEntityModel(v)) DeleteObject(v) end Props = {}
	for k in pairs(scrapPool) do unloadModel(scrapPool[k].model) end
	if Targets["DropOff"] then exports["qb-target"]:RemoveTargetEntity(TrollyProp) end
	unloadModel(GetEntityModel(TrollyProp)) DeleteObject(TrollyProp)
end

--Pick one of the crates for the player to choose, generate outline + target
function PickRandomPackage()
	if not TrollyProp then
		loadModel(`ex_Prop_Crate_Closed_BC`)
		TrollyProp = CreateObject(`ex_Prop_Crate_Closed_BC`, 999.32, -3093.2, -39.78, 0, 0, 0) FreezeEntityPosition(TrollyProp, true) SetEntityHeading(TrollyProp, 166.38)
	end
	--If somehow already exists, remove target
	if Targets["Package"] then exports["qb-target"]:RemoveTargetEntity(randPackage, "Search") end
	--Pick random prop to use
	randPackage = searchProps[math.random(1, #searchProps)]
	SetEntityDrawOutline(randPackage, true)
	SetEntityDrawOutlineColor(255, 255, 255, 1.0)
	SetEntityDrawOutlineShader(1)
	--Generate Target Location on the selected package
	Targets["Package"] =
		exports['qb-target']:AddTargetEntity(randPackage,
			{ options = { { event = "jim-recycle:PickupPackage:Start", icon = 'fas fa-magnifying-glass', label = Loc[Config.Lan].target["search"], } },
			distance = 2.5,	})
end
--Event to enter and exit warehouse
RegisterNetEvent("jim-recycle:TeleWareHouse", function(data)
	if data.enter then
		if Config.EnableOpeningHours then
			local ClockTime = GetClockHours()
			if ClockTime >= Config.OpenHour and ClockTime <= Config.CloseHour - 1 then
				if (ClockTime >= Config.OpenHour and ClockTime < 24) or (ClockTime <= Config.CloseHour -1 and ClockTime > 0) then
					if Config.PayAtDoor then
						local p = promise.new()	QBCore.Functions.TriggerCallback("jim-recycle:GetCash", function(cb) p:resolve(cb) end)
						if Citizen.Await(p) >= Config.PayAtDoor then TriggerServerEvent("jim-recycle:DoorCharge")
						else TriggerEvent("QBCore:Notify", Loc[Config.Lan].error["no_money"], "error") return end
					end
					DoScreenFadeOut(500)
					while not IsScreenFadedOut() do	Citizen.Wait(10) end
					SetEntityCoords(PlayerPedId(), Config.InsideTele)
					DoScreenFadeIn(500)
				else
					TriggerEvent("QBCore:Notify", Loc[Config.Lan].error["wrong_time"]..Config.OpenHour..":00am"..Loc[Config.Lan].error["till"]..Config.CloseHour..":00pm", "error")
				end
			else
				TriggerEvent("QBCore:Notify", Loc[Config.Lan].error["wrong_time"]..Config.OpenHour..":00"..Loc[Config.Lan].error["till"]..Config.CloseHour..":00pm", "error")
			end
		else
			DoScreenFadeOut(500)
			while not IsScreenFadedOut() do	Citizen.Wait(10) end
			SetEntityCoords(PlayerPedId(), Config.InsideTele)
			DoScreenFadeIn(500)
		end
	else
		EndJob() -- Resets outlines + targets if needed
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do	Citizen.Wait(10) end
		if onDuty then TriggerEvent('jim-recycle:dutytoggle') end
		SetEntityCoords(PlayerPedId(), Config.OutsideTele)
		DoScreenFadeIn(500)
	end
end)

RegisterNetEvent("jim-recycle:PickupPackage:Start", function()
	TaskStartScenarioInPlace(PlayerPedId(), "CODE_HUMAN_MEDIC_KNEEL", 0, true)
	QBCore.Functions.Progressbar("open_locker_drill", Loc[Config.Lan].progressbar["search"], 5000, false, true, {
		disableMovement = true,	disableCarMovement = true, disableMouse = false, disableCombat = true, }, {}, {}, {}, function() -- Done
		ClearPedTasksImmediately(PlayerPedId())
		TriggerEvent("jim-recycle:PickupPackage:Hold")
	end, function() -- Cancel
	end, "fas fa-magnifying-glass")
end)
RegisterNetEvent("jim-recycle:PickupPackage:Hold", function()
	--Clear current target info
	exports["qb-target"]:RemoveTargetEntity(randPackage, "Search")
	SetEntityDrawOutline(randPackage, false)
	randPackage = nil

	--Make prop to put in hands
	loadAnimDict("anim@heists@box_carry@")
    TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
	v = scrapPool[math.random(1, #scrapPool)]
    loadModel(v.model)
    scrapProp = CreateObject(v.model, GetEntityCoords(PlayerPedId(), true), true, true, true)
    AttachEntityToEntity(scrapProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 18905), v.xPos, v.yPos, v.zPos, v.xRot, v.yRot, v.zRot, 20.0, true, true, false, true, 1, true)
	--Create target for drop off location
	SetEntityDrawOutline(TrollyProp, true)
	SetEntityDrawOutlineColor(255, 255, 255, 1.0)
	SetEntityDrawOutlineShader(1)
	Targets["DropOff"] =
		exports['qb-target']:AddTargetEntity(TrollyProp,
		{ options = { { event = "jim-recycle:PickupPackage:Finish", icon = 'fas fa-recycle', label = Loc[Config.Lan].target["drop_off"], } },
		distance = 2.5,	})

end)

RegisterNetEvent("jim-recycle:PickupPackage:Finish", function()
	--Once this is triggered it can't be stopped, so remove the target and prop
	if Targets["DropOff"] then exports["qb-target"]:RemoveTargetEntity(TrollyProp, "Drop Off") Targets["DropOff"] = nil end
	SetEntityDrawOutline(TrollyProp, false) destroyProp(TrollyProp) TrollyProp = nil
	--Remove target and the whole prop, seen as how no ones qb-target works and its my fault 😊
	TrollyProp = CreateObject(`ex_Prop_Crate_Closed_BC`, 999.32, -3093.2, -39.78, 0, 0, 0) FreezeEntityPosition(TrollyProp, true) SetEntityHeading(TrollyProp, 166.38)

	--Load and Start animation
	local dict = "mp_car_bomb" loadAnimDict("mp_car_bomb")
	local anim = "car_bomb_mechanic"
    local isScrapping = true
	FreezeEntityPosition(PlayerPedId(), true)
	Wait(100)
	TaskPlayAnim(PlayerPedId(), dict, anim, 3.0, 3.0, -1, 2.0, 0, 0, 0, 0)
	Wait(3000)
	--When animation is complete
	--Empty hands
	destroyProp(scrapProp)
    scrapProp = nil
	ClearPedTasks(PlayerPedId())
	FreezeEntityPosition(PlayerPedId(), false)
	TriggerServerEvent('jim-recycle:getrecyclablematerial') -- Give rewards
	PickRandomPackage()
end)

RegisterNetEvent('jim-recycle:dutytoggle', function()
	if Config.JobRole then
		if onDuty then EndJob() else PickRandomPackage() end
		TriggerServerEvent("QBCore:ToggleDuty")
	else
		onDuty = not onDuty
		if onDuty then TriggerEvent('QBCore:Notify', Loc[Config.Lan].success["on_duty"], 'success') PickRandomPackage()
		else TriggerEvent('QBCore:Notify', Loc[Config.Lan].error["off_duty"], 'error') EndJob() end
	end
end)

local Selling = false
RegisterNetEvent('jim-recycle:SellAnim', function(item)
	for _, v in pairs (Peds) do
		if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(v)) < 3 then
			Selling = true
			loadAnimDict("mp_common")
			loadAnimDict("amb@prop_human_atm@male@enter")
			if bag == nil then bag = makeProp({prop = `prop_paper_bag_small`, coords = vector4(0,0,0,0)}, 0, 1) end
			AttachEntityToEntity(bag, v, GetPedBoneIndex(v, 57005), 0.1, -0.0, 0.0, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
			--Calculate if you're facing the ped--
			ClearPedTasksImmediately(v)
			lookEnt(v)
			TaskPlayAnim(PlayerPedId(), "amb@prop_human_atm@male@enter", "enter", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)	--Start animations
            TaskPlayAnim(v, "mp_common", "givetake2_b", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)
			Wait(1000)
			AttachEntityToEntity(bag, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.1, -0.0, 0.0, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
            Wait(1000)
            StopAnimTask(PlayerPedId(), "amb@prop_human_atm@male@enter", "enter", 1.0)
			StopAnimTask(v, "mp_common", "givetake2_b", 1.0)
			TaskStartScenarioInPlace(v, "WORLD_HUMAN_CLIPBOARD", -1, true)
			unloadAnimDict("mp_common")
			unloadAnimDict("amb@prop_human_atm@male@enter")
			destroyProp(bag) unloadModel(`prop_paper_bag_small`)
			bag = nil
			for k in pairs(Config.Prices) do
				if k == item then TriggerServerEvent('jim-recycle:Selling:Mat', item) Selling = false return end
			end
			TriggerServerEvent("jim-recycle:TradeItems", item)
			Selling = false
		end
	end
end)

RegisterNetEvent('jim-recycle:Selling:Menu', function()
	if Selling then return end
	local sellMenu = {
		{ icon = "recyclablematerial", header = Loc[Config.Lan].menu["sell_mats"], txt = Loc[Config.Lan].menu["sell_mats_txt"], isMenuHeader = true },
		{ icon = "fas fa-circle-xmark", header = "", txt = Loc[Config.Lan].menu["close"], params = { event = "jim-recycle:CloseMenu" } } }
	for k, v in pairsByKeys(Config.Prices) do
		sellMenu[#sellMenu+1] = {
			disabled = not HasItem(k, 1),
			icon = k,
			header = "<img src=nui://"..Config.img..QBCore.Shared.Items[k].image.." width=30px onerror='this.onerror=null; this.remove();'> "..QBCore.Shared.Items[k].label,
			txt = Loc[Config.Lan].menu["sell_all"]..v..Loc[Config.Lan].menu["each"],
			params = { event = "jim-recycle:SellAnim", args = k } }
	end
    exports['qb-menu']:openMenu(sellMenu)
end)

--Recyclable Trader
RegisterNetEvent('jim-recycle:Trade:Menu', function()
	if Selling then return end
	local p = promise.new() QBCore.Functions.TriggerCallback("jim-recycle:GetRecyclable", function(cb) p:resolve(cb) end) local amount = Citizen.Await(p)
	local tradeMenu = {
		{ icon = "recyclablematerial", header = Loc[Config.Lan].menu["mats_trade"], txt = Loc[Config.Lan].menu["trade_amount"]..amount, isMenuHeader = true },
		{ icon = "fas fa-circle-xmark", header = "", txt = Loc[Config.Lan].menu["close"], params = { event = "jim-recycle:CloseMenu" } } }
	if amount >= 1 then tradeMenu[#tradeMenu+1] = { icon = "recyclablematerial", header = Loc[Config.Lan].menu["trade1"], params = { event = "jim-recycle:SellAnim", args = 1 } } end
	if amount >= 10 then tradeMenu[#tradeMenu+1] = { icon = "recyclablematerial", header = Loc[Config.Lan].menu["trade10"], params = { event = "jim-recycle:SellAnim", args = 2 } } end
	if amount >= 100 then tradeMenu[#tradeMenu+1] = { icon = "recyclablematerial", header = Loc[Config.Lan].menu["trade100"], params = { event = "jim-recycle:SellAnim", args = 3 } } end
	if amount >= 1000 then tradeMenu[#tradeMenu+1] = { icon = "recyclablematerial", header = Loc[Config.Lan].menu["trade1000"], params = { event = "jim-recycle:SellAnim", args = 4 } } end
	if #tradeMenu > 2 then exports['qb-menu']:openMenu(tradeMenu)
	else TriggerEvent("QBCore:Notify", Loc[Config.Lan].error["no_mats"], "error") end
end)

--Recyclable Trader
RegisterNetEvent('jim-recycle:Bottle:Menu', function()
	if Selling then return end
	local tradeMenu = {
		{ icon = "recyclablematerial", header = Loc[Config.Lan].menu["sell_mats"], txt = Loc[Config.Lan].menu["sell_mats_txt"], isMenuHeader = true },
		{ icon = "fas fa-circle-xmark", header = "", txt = Loc[Config.Lan].menu["close"], params = { event = "jim-recycle:CloseMenu" } } }

	tradeMenu[#tradeMenu+1] = { disabled = not HasItem("can", 1), icon = "can", header = "<img src=nui://"..Config.img..QBCore.Shared.Items["can"].image.." width=30px onerror='this.onerror=null; this.remove();'> "..QBCore.Shared.Items["can"].label, params = { event = "jim-recycle:SellAnim", args = 'can' } }
	tradeMenu[#tradeMenu+1] = { disabled = not HasItem("bottle", 1), icon = "bottle", header = "<img src=nui://"..Config.img..QBCore.Shared.Items["bottle"].image.." width=30px onerror='this.onerror=null; this.remove();'> "..QBCore.Shared.Items["bottle"].label, params = { event = "jim-recycle:SellAnim", args = 'bottle' } }

	if #tradeMenu > 2 then exports['qb-menu']:openMenu(tradeMenu)
	else TriggerEvent("QBCore:Notify", Loc[Config.Lan].error["no_bottles"], "error") end
end)

AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
	for k in pairs(Targets) do exports['qb-target']:RemoveZone(k) end
	for _, v in pairs(Peds) do unloadModel(GetEntityModel(v)) DeletePed(v) end
	for _, v in pairs(Props) do unloadModel(GetEntityModel(v)) DeleteObject(v) end
	for _, v in pairs(searchProps) do unloadModel(GetEntityModel(v)) DeleteObject(v) end
	unloadModel(GetEntityModel(TrollyProp)) DeleteObject(TrollyProp)
	unloadModel(GetEntityModel(scrapProp)) DeleteObject(scrapProp)
	for _, v in pairs(searchProps) do unloadModel(GetEntityModel(v)) DeleteObject(v) end
end)
