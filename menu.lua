local PlayerData, CurrentActionData, HandcuffTimer, dragStatus, blipsCops, currentTask, spawnedVehicles = {}, {}, {}, {}, {}, {}, {}
local HasAlreadyEnteredMarker, isDead, isHandcuffed, hasAlreadyJoined, playerInService, isInShopMenu = false, false, false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg
dragStatus.isDragged = false
ESX = nil
locksound = false
onDuty = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

function OpenBillingMenu()

  ESX.UI.Menu.Open(
    'dialog', GetCurrentResourceName(), 'billing',
    {
      title = "Facture"
    },
    function(data, menu)
    
      local amount = tonumber(data.value)
      local player, distance = ESX.Game.GetClosestPlayer()

      if player ~= -1 and distance <= 3.0 then

        menu.close()
        if amount == nil then
            ESX.ShowColoredNotification("~r~ERREUR~s~: ~g~Montant invalide", 25)
        else
            TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_police', _U('billing'), amount)
			Citizen.Wait(100)
			ESX.ShowColoredNotification("Vous avez bien envoyer une facture", 25)
        end

      else
        ESX.ShowColoredNotification("~r~ERREUR~s~: ~g~Aucun joueur à proximitée", 25)
      end

    end,
    function(data, menu)
        menu.close()
    end
  )
end

RegisterNetEvent('esx_policejob:onDuty')
AddEventHandler('esx_policejob:onDuty', function()
	onDuty = true
end)

RegisterNetEvent('esx_policejob:offDuty')
AddEventHandler('esx_policejob:offDuty', function()
	onDuty = false
end)
---------- MENU VESTIAIRE-----
local MyMenus = {
	Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Vestiaire" },
	Data = { currentMenu = "Vos tenues", "Test" },
	Events = {
		onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
			PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
			local slide = btn.slidenum
			local btn = btn.name
			local check = btn.unkCheckbox
			if btn == "Reprendre vos affaires" then
				TriggerServerEvent("player:serviceOff", "police")
				TriggerEvent('esx_policejob:offDuty')
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                    TriggerEvent('skinchanger:loadSkin', skin)
				end)
				SetPedArmour(playerPed, 0)			
			elseif btn == "Tenue LSPD" then
				TriggerServerEvent("player:serviceOn", "police")
				TriggerEvent('esx_policejob:onDuty')
				if PlayerData.job.grade_name == 'recruit' then
					TriggerEvent('skinchanger:getSkin', function(skin)
						if skin.sex == 0 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.recruit_wear.male)
						elseif skin.sex == 1 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.recruit_wear.female)
						end
					end)
				elseif PlayerData.job.grade_name == 'officer' then 
					TriggerEvent('skinchanger:getSkin', function(skin)
						if skin.sex == 0 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.officer_wear.male)
						elseif skin.sex == 1 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.officer_wear.female)
						end
					end)
				elseif PlayerData.job.grade_name == 'sergeant' then
					TriggerEvent('skinchanger:getSkin', function(skin)
						if skin.sex == 0 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.sergeant_wear.male)
						elseif skin.sex == 1 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.sergeant_wear.female)
						end
				end)
				elseif PlayerData.job.grade_name == 'lieutenant' then
					TriggerEvent('skinchanger:getSkin', function(skin)
						if skin.sex == 0 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.lieutenant_wear.male)
						elseif skin.sex == 1 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.lieutenant_wear.female)
						end
					end)
				elseif PlayerData.job.grade_name == 'boss' then
					TriggerEvent('skinchanger:getSkin', function(skin)
						if skin.sex == 0 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.boss_wear.male)
						elseif skin.sex == 1 then
								TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.boss_wear.female)
						end
					end)
				end	
			elseif btn == "Gilet Par Balle" then
				TriggerEvent('skinchanger:getSkin', function(skin)
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.bullet_wear.male)
					elseif skin.sex == 1 then
						TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.bullet_wear.female)
					end
				end)
				SetPedArmour(playerPed, 100)		
			elseif btn == "Tenue Hélicoptaire" then
				ESX.ShowNotification("~r~Indisponible")

		end
	end,
},
	Menu = {
		["Vos tenues"] = {
			b = {
				{name = "Reprendre vos affaires", ask = ">", askX = true},
				{name = "----------------------------------------"},
				{name = "Tenue LSPD", ask = ">", askX = true},
				{name = "Tenue Hélicoptaire", ask = ">", askX = true},
				{name = "Gilet Par Balle", ask = ">", askX = true}
			}
		}
	}
}
------------ FIN MENU VESTAIRE ----------
---------------- UNIFORME LSPD -----------
function cleanPlayer(playerPed)
	SetPedArmour(playerPed, 0)
	ClearPedBloodDamage(playerPed)
	ResetPedVisibleDamage(playerPed)
	ClearPedLastWeaponDamage(playerPed)
	ResetPedMovementClipset(playerPed, 0)
end

function setUniform(job, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		if skin.sex == 0 then
			if Config.Uniforms[job].male then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].male)
			else
				ESX.ShowNotification(_U('no_outfit'))
			end

			if job == 'bullet_wear' then
				SetPedArmour(playerPed, 100)
			end
		else
			if Config.Uniforms[job].female then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].female)
			else
				ESX.ShowNotification(_U('no_outfit'))
			end

			if job == 'bullet_wear' then
				SetPedArmour(playerPed, 100)
			end
		end
	end)
end
--------------- UNIFORM LSPD ---------------------
--------------- ARME LSPD ------------------------
local ArmeMenu = {
	Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Armes LSPD" },
	Data = { currentMenu = "Armes de services", "Test" },
	Events = {
		onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
			PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
			local slide = btn.slidenum
			local btn = btn.name
			local check = btn.unkCheckbox
			if btn == "Déposer ces armes de services" then
				RemoveAllPedWeapons(GetPlayerPed(-1), true)
			elseif btn == "Tazer Volts x26 - LSPD" then	
				TriggerServerEvent('esx_policejob:AddTazer') 
			elseif btn == "Beretta 92 - LSPD" then	
				TriggerServerEvent('esx_policejob:AddPistol')
			elseif btn == "Glock 17 - LSPD" then
				TriggerServerEvent('esx_policejob:AddComPistol')
			elseif btn == "Fusil à pompe - LSPD" then
				TriggerServerEvent('esx_policejob:AddPump')
			elseif btn == "9mm - LSPD" then
				ESX.ShowNotification("~r~Error 401: Veuillez contacter un supérieur")

		end
	end,
},
	Menu = {
		["Armes de services"] = {
			b = {
				{name = "Déposer ces armes de services", ask = ">", askX = true},
				{name = "----------------------------------------"},
				{name = "Tazer Volts x26 - LSPD", ask = ">", askX = true},
				{name = "Beretta 92 - LSPD", ask = ">", askX = true},
				{name = "Glock 17 - LSPD", ask = ">", askX = true},
				{name = "Fusil à pompe - LSPD", ask = ">", askX = true},
				{name = "----------------------------------------"},
				{name = "9mm - LSPD", ask = ">", askX = true}
			}
		}
	}
}
----------------- ARME LSPD FINI ------------------
----------------- GARAGE LSPD ---------------------
local GarageLSPDMenu = {
	Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Garage LSPD - Véhicule" },
	Data = { currentMenu = "Garage LSPD", "Test" },
	Events = {
		onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
			PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
			local slide = btn.slidenum
			local btn = btn.name
			local check = btn.unkCheckbox
			if btn == "Police Cruiser" then
				SetVehicleWindowTint(vehicle, 5)
				ESX.ShowNotification('Vous avez sorti un vehicule de police')
				Citizen.Wait(1)
				spawnCar("police")
			elseif btn == "Buffalo de police" then	
				ESX.ShowNotification('Vous avez sorti un vehicule de police')
				Citizen.Wait(1)
				spawnCar("police2")
			elseif btn == "Interceptor" then	
				ESX.ShowNotification('Vous avez sorti un vehicule de police')
				Citizen.Wait(1)
				spawnCar("police3")
			elseif btn == "Blinder LSPD" then
				ESX.ShowNotification('Vous avez sorti un vehicule de police')
				Citizen.Wait(1)
				spawnCar("riot")
			elseif btn == "Fourgon antiémeute" then
				ESX.ShowNotification('Vous avez sorti un vehicule de police')
				Citizen.Wait(1)
				spawnCar("riot2")
			elseif btn == "Vehicule de formation" then
				ESX.ShowNotification('Vous avez sorti un vehicule de ~b~formation')
				Citizen.Wait(1)
				spawnCar("sultan")
			elseif btn == "Garage personnel" then 
				ESX.ShowNotification('~r~ERROR 401: Indisponible, veuillez contactez un développeur')
		end
	end,
},
	Menu = {
		["Garage LSPD"] = {
			b = {
				{name = "Garage personnel", ask = ">", askX = true},
				{name = "----------------------------------------"},
				{name = "Police Cruiser", ask = ">", askX = true},
				{name = "Buffalo de police", ask = ">", askX = true},
				{name = "Interceptor", ask = ">", askX = true},
				{name = "Blinder LSPD", ask = ">", askX = true},
				{name = "Fourgon antiémeute", ask = ">", askX = true},
				{name = "Vehicule de formation", ask = ">", askX = true}
			}
		}
	}
}

function notify(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(true, true)
end

function spawnCar(car)
    local car = GetHashKey(car)

    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(50)
    end

    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), false))
    local vehicle = CreateVehicle(car, 452.84, -1019.61, 28.24, 90.89, true, false)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    
    SetEntityAsNoLongerNeeded(vehicle)
	SetModelAsNoLongerNeeded(vehicleName)
	SetVehicleWindowTint(vehicle, 3)
	SetVehicleNumberPlateText(vehicle, "LSPD")
        
end

function StoreNearbyVehicle(playerCoords)
	local vehicles, vehiclePlates = ESX.Game.GetVehiclesInArea(playerCoords, 30.0), {}

	if #vehicles > 0 then
		for k,v in ipairs(vehicles) do

			-- Make sure the vehicle we're saving is empty, or else it wont be deleted
			if GetVehicleNumberOfPassengers(v) == 0 and IsVehicleSeatFree(v, -1) then
				table.insert(vehiclePlates, {
					vehicle = v,
					plate = ESX.Math.Trim(GetVehicleNumberPlateText(v))
				})
			end
		end
	else
		ESX.ShowNotification(_U('garage_store_nearby'))
		return
	end

	ESX.TriggerServerCallback('esx_policejob:storeNearbyVehicle', function(storeSuccess, foundNum)
		if storeSuccess then
			local vehicleId = vehiclePlates[foundNum]
			local attempts = 0
			ESX.Game.DeleteVehicle(vehicleId.vehicle)
			IsBusy = true

			Citizen.CreateThread(function()
				BeginTextCommandBusyString('STRING')
				AddTextComponentSubstringPlayerName(_U('garage_storing'))
				EndTextCommandBusyString(4)

				while IsBusy do
					Citizen.Wait(100)
				end

				RemoveLoadingPrompt()
			end)

			-- Workaround for vehicle not deleting when other players are near it.
			while DoesEntityExist(vehicleId.vehicle) do
				Citizen.Wait(500)
				attempts = attempts + 1

				-- Give up
				if attempts > 30 then
					break
				end

				vehicles = ESX.Game.GetVehiclesInArea(playerCoords, 30.0)
				if #vehicles > 0 then
					for k,v in ipairs(vehicles) do
						if ESX.Math.Trim(GetVehicleNumberPlateText(v)) == vehicleId.plate then
							ESX.Game.DeleteVehicle(v)
							break
						end
					end
				end
			end

			IsBusy = false
			ESX.ShowNotification(_U('garage_has_stored'))
		else
			ESX.ShowNotification(_U('garage_has_notstored'))
		end
	end, vehiclePlates)
end

function GetAvailableVehicleSpawnPoint(station, part, partNum)
	local spawnPoints = Config.PoliceStations[station][part][partNum].SpawnPoints
	local found, foundSpawnPoint = false, nil

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end

	if found then
		return true, foundSpawnPoint
	else
		ESX.ShowNotification(_U('vehicle_blocked'))
		return false
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isInShopMenu then
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		else
			Citizen.Wait(500)
		end
	end
end)

function DeleteSpawnedVehicles()
	while #spawnedVehicles > 0 do
		local vehicle = spawnedVehicles[1]
		ESX.Game.DeleteVehicle(vehicle)
		table.remove(spawnedVehicles, 1)
	end
end

function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyString('STRING')
		AddTextComponentSubstringPlayerName(_U('vehicleshop_awaiting_model'))
		EndTextCommandBusyString(4)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(0)
			DisableAllControlActions(0)
		end

		RemoveLoadingPrompt()
	end
end

local service = {
	"On",
	"Off"
}

local linked = {
	"ll",
	"oof"
}

local test = {
	false,
	true
}

--------------- GARAGE LSPD FINI-------------
--------------- MENU F6 LSPD ----------

function LoadingPrompt(loadingText, spinnerType)

    if IsLoadingPromptBeingDisplayed() then
        RemoveLoadingPrompt()
    end

    if (loadingText == nil) then
        BeginTextCommandBusyString(nil)
    else
        BeginTextCommandBusyString("STRING");
        AddTextComponentSubstringPlayerName(loadingText);
    end

    EndTextCommandBusyString(spinnerType)
end


local mobLSPDMenu = {
	Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Interaction" },
	Data = { currentMenu = "Interaction LSPD", "Test" },
	Events = {
		onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
			PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
			local slide = btn.slidenum
			local btn = btn.name
			local check = btn.unkCheckbox
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			local playerPed = PlayerPedId()
			local coords = GetEntityCoords(playerPed)
			if btn == "Intéraction LSPD" then
				OpenMenu('Intéraction(s) disponible:')
			elseif btn == "Intéraction Véhicule" then
				OpenMenu('Interaction(s) disponible: ')
			-------- MENU LSPD CITOYEN -----------
			elseif btn == "Fouiller l'individu" then
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					SetMenuVisible(false)
					TriggerServerEvent('esx_policejob:message', GetPlayerServerId(closestPlayer), _U('being_searched'))
					OpenBodySearchMenu(closestPlayer)
				end
			elseif btn == "Menotter l'individu" then
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					SetMenuVisible(false)
					TriggerServerEvent('esx_policejob:handcuff', GetPlayerServerId(closestPlayer))
				end
			elseif btn == "Déplacer l'individu" then 
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					SetMenuVisible(false)
					TriggerServerEvent('esx_policejob:drag', GetPlayerServerId(closestPlayer))
				end
			elseif btn == "Mettre une amande l'individu" then
				OpenBillingMenu()
			elseif btn == "Mettre l'individu dans le véhicule" then
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					SetMenuVisible(false)
					TriggerServerEvent('esx_policejob:putInVehicle', GetPlayerServerId(closestPlayer))
				end
				---------- Véhicule MENU ---
			elseif btn == "Sortir l'individu du véhicule" then
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					TriggerServerEvent('esx_policejob:OutVehicle', GetPlayerServerId(closestPlayer))
				end
			elseif btn == "Mettre le véhicule en fourrière" then
				if currentTask.busy then
					return
				end

				ESX.ShowHelpNotification(_U('impound_prompt'))
				TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)

				currentTask.busy = true
				currentTask.task = ESX.SetTimeout(10000, function()
					ClearPedTasks(playerPed)
					ImpoundVehicle(vehicle)
					Citizen.Wait(100) -- sleep the entire script to let stuff sink back to reality
				end)

				-- keep track of that vehicle!
				Citizen.CreateThread(function()
					while currentTask.busy do
						Citizen.Wait(1000)

						vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
						if not DoesEntityExist(vehicle) and currentTask.busy then
							ESX.ShowNotification(_U('impound_canceled_moved'))
							ESX.ClearTimeout(currentTask.task)
							ClearPedTasks(playerPed)
							currentTask.busy = false
							break
						end
					end
				end)
			elseif btn == "Crocheter le véhicule" then
				if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
					TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
					Citizen.Wait(20000)
					ClearPedTasksImmediately(playerPed)

					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					ESX.ShowNotification(_U('vehicle_unlocked'))
				end
			elseif btn == "Appel LSPD" then
				OpenMenu('Interaction(s) disponible:  ')
			elseif btn == "Appel Renfort" then
				local plyPos = GetEntityCoords(GetPlayerPed(-1), true)
				TriggerServerEvent("call:makeCall", "police", {x=plyPos.x,y=plyPos.y,z=plyPos.z}, "Renfort", GetPlayerServerId(player))
			elseif btn == "Demandes de toute les unités" then
				local plyPos = GetEntityCoords(GetPlayerPed(-1), true)
				TriggerServerEvent("call:makeCall", "police", {x=plyPos.x,y=plyPos.y,z=plyPos.z}, "Urgence", GetPlayerServerId(player))
			elseif slide == 1 and btn == "Mon service (Debug)" then
				TriggerServerEvent("player:serviceOn", "police")
				TriggerEvent('esx_policejob:onDuty')
				ESX.ShowNotification("~g~Vous êtes en service")
			elseif slide == 2 and btn == "Mon service (Debug)" then 
				TriggerEvent('esx_policejob:offDuty')
				TriggerServerEvent("player:serviceOff", "police")
				ESX.ShowNotification("~r~Vous n'êtes plus en service")
			elseif btn == "Faire les premiers soins" then
				local IsBusy = false
				if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification("~r~ERROR 401")
					else
						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(qtty)
							if qtty > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)
								
								if health == 0 then
									local playerPed = GetPlayerPed(-1)

									IsBusy = true
									ESX.ShowNotification(_U('revive_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)
									
									TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(closestPlayer))
									IsBusy = false

									-- Show revive award?
									if Config.ReviveReward > 0 then
										ESX.ShowNotification(_U('revive_complete_award', GetPlayerName(closestPlayer), Config.ReviveReward))
									else
										ESX.ShowNotification(_U('revive_complete', GetPlayerName(closestPlayer)))
									end
								else
									ESX.ShowNotification(_U('player_not_unconscious'))
								end
							else
								ESX.ShowNotification(_U('not_enough_medikit'))
							end
						end, 'medikit')
					end
		end
	end,
},
	Menu = {
		["Interaction LSPD"] = {
			b = {
				{name = "Intéraction LSPD", ask = ">", askX = true},
				{name = "Intéraction Véhicule", ask = ">", askX = true},
				{name = "Appel LSPD", ask = ">", askX = true},
				{name = "Historique des Appels", ask = ">", askX = true},
				{name = "Mon service (Debug)", slidemax = service}
			}
		},
		
		["Intéraction(s) disponible:"] = {
			b = {
				{name = "Fouiller l'individu", ask = ">", askX = true},
				{name = "Menotter l'individu", ask = ">", askX = true},
				{name = "Déplacer l'individu", ask = ">", askX = true},
				{name = "Mettre une amande à l'individu", ask = ">", askX = true},
				{name = "----------------------------------------"},
				{name = "Mettre l'individu dans le véhicule", ask = ">", askX = true},
				{name = "Sortir l'individu du véhicule", ask = ">", askX = true},
				{name = "----------------------------------------"},
				{name = "Faire les premiers soins", ask = ">", askX = true}
			}
		},
		
		["Interaction(s) disponible: "] = {
			b = {
				{name = "Mettre le véhicule en fourrière", ask = ">", askX = true},
				{name = "Crocheter le véhicule", ask = ">", askX = true}
			}
		},
		
		["Interaction(s) disponible:  "] = {
			b = {
				{name = "Appel Renfort", ask = ">", askX = true},
				{name = "Demandes de toute les unités", ask = ">", askX = true}
			}
		}
	}
}
---------------- FIN MENU F6 LSPD ---------------

function OpenBodySearchMenu(player)
	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
		local elements = {}

		for i=1, #data.accounts, 1 do
			if data.accounts[i].name == 'black_money' and data.accounts[i].money > 0 then
				table.insert(elements, {
					label    = _U('confiscate_dirty', ESX.Math.Round(data.accounts[i].money)),
					value    = 'black_money',
					itemType = 'item_account',
					amount   = data.accounts[i].money
				})

				break
			end
		end

		table.insert(elements, {label = _U('guns_label')})

		for i=1, #data.weapons, 1 do
			table.insert(elements, {
				label    = _U('confiscate_weapon', ESX.GetWeaponLabel(data.weapons[i].name), data.weapons[i].ammo),
				value    = data.weapons[i].name,
				itemType = 'item_weapon',
				amount   = data.weapons[i].ammo
			})
		end

		table.insert(elements, {label = _U('inventory_label')})

		for i=1, #data.inventory, 1 do
			if data.inventory[i].count > 0 then
				table.insert(elements, {
					label    = _U('confiscate_inv', data.inventory[i].count, data.inventory[i].label),
					value    = data.inventory[i].name,
					itemType = 'item_standard',
					amount   = data.inventory[i].count
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'body_search', {
			title    = _U('search'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			if data.current.value then
				TriggerServerEvent('esx_policejob:confiscatePlayerItem', GetPlayerServerId(player), data.current.itemType, data.current.value, data.current.amount)
				OpenBodySearchMenu(player)
			end
		end, function(data, menu)
			menu.close()
		end)
	end, GetPlayerServerId(player))
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('esx_policejob:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('police_stock'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_policejob:getStockItem', itemName, count)

					Citizen.Wait(300)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('esx_policejob:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_policejob:putStockItems', itemName, count)

					Citizen.Wait(300)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job

	Citizen.Wait(5000)
	isPlayerWhitelisted = refreshPlayerWhitelisted()
	TriggerServerEvent('esx_policejob:forceBlip')
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = _U('phone_police'),
		number     = 'police',
		base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDFGQTJDRkI0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NDFGQTJDRkM0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo0MUZBMkNGOTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo0MUZBMkNGQTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PoW66EYAAAjGSURBVHjapJcLcFTV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'
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

-- don't show dispatches if the player isn't in service
AddEventHandler('esx_phone:cancelMessage', function(dispatchNumber)
	if PlayerData.job and PlayerData.job.name == 'police' and PlayerData.job.name == dispatchNumber then
		-- if esx_service is enabled
		if Config.MaxInService ~= -1 and not onDuty then
			CancelEvent()
		end
	end
end)
-------------------- MENU BOSS ------------
local BossLSPDMenu = {
	Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "CM LSPD" },
	Data = { currentMenu = "Intéraction Patron", "Test" },
	Events = {
		onSelected = function(self, _, btn, PMenu, menuData, currentButton, currentBtn, currentSlt, result, slide)
			PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
			local slide = btn.slidenum
			local btn = btn.name
			local check = btn.unkCheckbox
			if btn == "Argent" then
				ESX.ShowAdvancedNotification("Police", "Entreprise Argent: ~g~$" ..societymoney, "", "CHAR_CALL911", 1)
			elseif btn == "Entreprise" then	
				TriggerEvent('esx_society:openBossMenu', 'police', function(data, menu)
					SetMenuVisible(false)
				end)

		end
	end,
},
	Menu = {
		["Intéraction Patron"] = {
			b = {
				{name = "Argent", ask = "~g~49$", askX = true},
				{name = "Entreprise", ask = ">", askX = true}
			}
		}
	}
}

------------ FIN MENU BOSS -----------------

AddEventHandler('esx_policejob:hasEnteredMarker', function(station, part, partNum)
	--if part == 'Cloakroom' then
		--CurrentAction     = 'menu_cloakroom'
		--CurrentActionMsg  = _U('open_cloackroom')
		--CurrentActionData = {}
	-- if part == 'Armory' then
	-- 	CurrentAction     = 'menu_armory'
	-- 	CurrentActionMsg  = _U('open_armory')
	-- 	CurrentActionData = {station = station}
	if part == 'Vehicles' then
		CurrentAction     = 'menu_vehicle_spawner'
		CurrentActionMsg  = _U('garage_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'Helicopters' then
		CurrentAction     = 'Helicopters'
		CurrentActionMsg  = _U('helicopter_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	end
end)

AddEventHandler('esx_policejob:hasExitedMarker', function(station, part, partNum)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

	CurrentAction = nil
end)

AddEventHandler('esx_policejob:hasEnteredEntityZone', function(entity)
	local playerPed = PlayerPedId()

	if PlayerData.job and PlayerData.job.name == 'police' and IsPedOnFoot(playerPed) then
		CurrentAction     = 'remove_entity'
		CurrentActionMsg  = _U('remove_prop')
		CurrentActionData = {entity = entity}
	end

	if GetEntityModel(entity) == GetHashKey('p_ld_stinger_s') then
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)

		if IsPedInAnyVehicle(playerPed, false) then
			local vehicle = GetVehiclePedIsIn(playerPed)

			for i=0, 7, 1 do
				SetVehicleTyreBurst(vehicle, i, true, 1000)
			end
		end
	end
end)

AddEventHandler('esx_policejob:hasExitedEntityZone', function(entity)
	if CurrentAction == 'remove_entity' then
		CurrentAction = nil
	end
end)

RegisterNetEvent('esx_policejob:handcuff')
AddEventHandler('esx_policejob:handcuff', function()
	isHandcuffed = not isHandcuffed
	local playerPed = PlayerPedId()

	Citizen.CreateThread(function()
		if isHandcuffed then

			RequestAnimDict('mp_arresting')
			while not HasAnimDictLoaded('mp_arresting') do
				Citizen.Wait(100)
			end

			TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)

			SetEnableHandcuffs(playerPed, true)
			DisablePlayerFiring(playerPed, true)
			SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true) -- unarm player
			SetPedCanPlayGestureAnims(playerPed, false)
			FreezeEntityPosition(playerPed, true)
			DisplayRadar(false)

			if Config.EnableHandcuffTimer then
				if handcuffTimer.active then
					ESX.ClearTimeout(handcuffTimer.task)
				end

				StartHandcuffTimer()
			end
		else
			if Config.EnableHandcuffTimer and handcuffTimer.active then
				ESX.ClearTimeout(handcuffTimer.task)
			end

			ClearPedSecondaryTask(playerPed)
			SetEnableHandcuffs(playerPed, false)
			DisablePlayerFiring(playerPed, false)
			SetPedCanPlayGestureAnims(playerPed, true)
			FreezeEntityPosition(playerPed, false)
			DisplayRadar(true)
		end
	end)
end)

RegisterNetEvent('esx_policejob:unrestrain')
AddEventHandler('esx_policejob:unrestrain', function()
	if isHandcuffed then
		local playerPed = PlayerPedId()
		isHandcuffed = false

		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)
		DisplayRadar(true)

		-- end timer
		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
	end
end)

RegisterNetEvent('esx_policejob:drag')
AddEventHandler('esx_policejob:drag', function(copId)
	if not isHandcuffed then
		return
	end

	dragStatus.isDragged = not dragStatus.isDragged
	dragStatus.CopId = copId
end)

Citizen.CreateThread(function()
	local playerPed
	local targetPed

	while true do
		Citizen.Wait(1)

		if isHandcuffed then
			playerPed = PlayerPedId()

			if dragStatus.isDragged then
				targetPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.CopId))

				-- undrag if target is in an vehicle
				if not IsPedSittingInAnyVehicle(targetPed) then
					AttachEntityToEntity(playerPed, targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
				else
					dragStatus.isDragged = false
					DetachEntity(playerPed, true, false)
				end

				if IsPedDeadOrDying(targetPed, true) then
					dragStatus.isDragged = false
					DetachEntity(playerPed, true, false)
				end

			else
				DetachEntity(playerPed, true, false)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('esx_policejob:putInVehicle')
AddEventHandler('esx_policejob:putInVehicle', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	if not isHandcuffed then
		return
	end

	if IsAnyVehicleNearPoint(GetEntityCoords(playerPed), 5.0) then
		local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

			for i=maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle, i) then
					freeSeat = i
					break
				end
			end

			if freeSeat then
				TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
				dragStatus.isDragged = false
			end
		end
	end
end)

RegisterNetEvent('esx_policejob:OutVehicle')
AddEventHandler('esx_policejob:OutVehicle', function()
	local playerPed = PlayerPedId()

	if not IsPedSittingInAnyVehicle(playerPed) then
		return
	end

	local vehicle = GetVehiclePedIsIn(playerPed, false)
	TaskLeaveVehicle(playerPed, vehicle, 16)
end)

-- Handcuff
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()

		if isHandcuffed then
			DisableControlAction(0, 1, true) -- Disable pan
			DisableControlAction(0, 2, true) -- Disable tilt
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			DisableControlAction(0, 32, true) -- W
			DisableControlAction(0, 34, true) -- A
			DisableControlAction(0, 31, true) -- S
			DisableControlAction(0, 30, true) -- D

			DisableControlAction(0, 45, true) -- Reload
			DisableControlAction(0, 22, true) -- Jump
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 23, true) -- Also 'enter'?

			DisableControlAction(0, 288,  true) -- Disable phone
			DisableControlAction(0, 289, true) -- Inventory
			DisableControlAction(0, 170, true) -- Animations
			DisableControlAction(0, 167, true) -- Job

			DisableControlAction(0, 0, true) -- Disable changing view
			DisableControlAction(0, 26, true) -- Disable looking behind
			DisableControlAction(0, 73, true) -- Disable clearing animation
			DisableControlAction(2, 199, true) -- Disable pause screen

			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle

			DisableControlAction(2, 36, true) -- Disable going stealth

			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle

			if IsEntityPlayingAnim(playerPed, 'mp_arresting', 'idle', 3) ~= 1 then
				ESX.Streaming.RequestAnimDict('mp_arresting', function()
					TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
				end)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

-- Create blips
Citizen.CreateThread(function()

	for k,v in pairs(Config.PoliceStations) do
		local blip = AddBlipForCoord(v.Blip.Coords)

		SetBlipSprite (blip, v.Blip.Sprite)
		SetBlipDisplay(blip, v.Blip.Display)
		SetBlipScale  (blip, v.Blip.Scale)
		SetBlipColour (blip, v.Blip.Colour)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString(_U('map_blip'))
		EndTextCommandSetBlipName(blip)
	end

end)


-- Enter / Exit entity zone events
Citizen.CreateThread(function()
	local trackedEntities = {
		'prop_roadcone02a',
		'prop_barrier_work05',
		'p_ld_stinger_s',
		'prop_boxpile_07d',
		'hei_prop_cash_crate_half_full'
	}

	while true do
		Citizen.Wait(500)

		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)

		local closestDistance = -1
		local closestEntity   = nil

		for i=1, #trackedEntities, 1 do
			local object = GetClosestObjectOfType(coords, 3.0, GetHashKey(trackedEntities[i]), false, false, false)

			if DoesEntityExist(object) then
				local objCoords = GetEntityCoords(object)
				local distance  = GetDistanceBetweenCoords(coords, objCoords, true)

				if closestDistance == -1 or closestDistance > distance then
					closestDistance = distance
					closestEntity   = object
				end
			end
		end

		if closestDistance ~= -1 and closestDistance <= 3.0 then
			if LastEntity ~= closestEntity then
				TriggerEvent('esx_policejob:hasEnteredEntityZone', closestEntity)
				LastEntity = closestEntity
			end
		else
			if LastEntity then
				TriggerEvent('esx_policejob:hasExitedEntityZone', LastEntity)
				LastEntity = nil
			end
		end
	end
end)

-- Create blip for colleagues
function createBlip(id)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)

	if not DoesBlipExist(blip) then -- Add blip and create head display on player
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 1)
		ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip indicator
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped))) -- update rotation
		SetBlipNameToPlayerName(blip, id) -- update blip name
		SetBlipScale(blip, 0.85) -- set scale
		SetBlipAsShortRange(blip, true)

		table.insert(blipsCops, blip) -- add blip to array so we can remove it later
	end
end

RegisterNetEvent('esx_policejob:updateBlip')
AddEventHandler('esx_policejob:updateBlip', function()

	-- Refresh all blips
	for k, existingBlip in pairs(blipsCops) do
		RemoveBlip(existingBlip)
	end

	-- Clean the blip table
	blipsCops = {}

	-- Enable blip?
	if Config.MaxInService ~= -1 and not onDuty then
		return
	end

	if not Config.EnableJobBlip then
		return
	end

	-- Is the player a cop? In that case show all the blips for other cops
	if PlayerData.job and PlayerData.job.name == 'police' then
		ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)
			for i=1, #players, 1 do
				if players[i].job.name == 'police' then
					local id = GetPlayerFromServerId(players[i].source)
					if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
						createBlip(id)
					end
				end
			end
		end)
	end

end)

AddEventHandler('playerSpawned', function(spawn)
	isDead = false
	TriggerEvent('esx_policejob:unrestrain')

	if not hasAlreadyJoined then
		TriggerServerEvent('esx_policejob:spawned')
	end
	hasAlreadyJoined = true
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_policejob:unrestrain')
		TriggerEvent('esx_phone:removeSpecialContact', 'police')

		if Config.MaxInService ~= -1 then
			TriggerServerEvent('esx_service:disableService', 'police')
		end

		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
	end
end)

-- handcuff timer, unrestrain the player after an certain amount of time
function StartHandcuffTimer()
	if Config.EnableHandcuffTimer and handcuffTimer.active then
		ESX.ClearTimeout(handcuffTimer.task)
	end

	handcuffTimer.active = true

	handcuffTimer.task = ESX.SetTimeout(Config.HandcuffTimer, function()
		ESX.ShowNotification(_U('unrestrained_timer'))
		TriggerEvent('esx_policejob:unrestrain')
		handcuffTimer.active = false
	end)
end

-- TODO
--   - return to garage if owned
--   - message owner that his vehicle has been impounded
function ImpoundVehicle(vehicle)
	--local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
	ESX.Game.DeleteVehicle(vehicle)
	ESX.ShowNotification(_U('impound_successful'))
	currentTask.busy = false
end

local arm = {
    {x = 451.7, y = -980.1, z = 30.6},
}

local cloak = {
    {x = 452.6, y = -992.8, z = 30.6},
}

local garage = {
    {x = 458.73165893555, y = -1017.2035522461, z = 27.188488006592}
}

local boss = {
    {x = 448.4, y = -973.2, z = 30.6}
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
		if IsControlJustPressed(1,167) and PlayerData.job and PlayerData.job.name == 'police' then
			CreateMenu(mobLSPDMenu)
		end

        for k in pairs(arm) do

            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, arm[k].x, arm[k].y, arm[k].z)

            if dist <= 1.2 and onDuty and PlayerData.job and  PlayerData.job.name == 'police' then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour accéder à ~b~l'armurie~s~")
				if IsControlJustPressed(1,38) then 
					CreateMenu(ArmeMenu)
				end
            end
		end
		for k in pairs(cloak) do

            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, cloak[k].x, cloak[k].y, cloak[k].z)

            if dist <= 1.2 and PlayerData.job and PlayerData.job.name == 'police' then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour accéder à votre ~b~casier~s~")
				if IsControlJustPressed(1,38) then 
					CreateMenu(MyMenus)
				end
            end
		end
		for k in pairs(garage) do

            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, garage[k].x, garage[k].y, garage[k].z)

            if dist <= 1.2 and onDuty and PlayerData.job and PlayerData.job.name == 'police' then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour accéder au ~b~garage~s~")
				if IsControlJustPressed(1,38) then 
					CreateMenu(GarageLSPDMenu)
				end
            end
		end
		for k in pairs(boss) do

            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, boss[k].x, boss[k].y, boss[k].z)

            if dist <= 1.2 and onDuty and PlayerData.job and PlayerData.job.name == 'police' and PlayerData.job.grade_name == 'boss' then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour accéder à l'ordinateur de ~b~l'entreprise~s~")
				if IsControlJustPressed(1,38) then 
					CreateMenu(BossLSPDMenu)
				end
            end
        end
    end
end)

local del = {
    {x = 462.4, y = -1014.7, z = 27.4}
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

		for k in pairs(del) do
			
            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, del[k].x, del[k].y, del[k].z)

            if dist <= 1.2 and onDuty and PlayerData.job and PlayerData.job.name == 'police' and IsPedInAnyVehicle(PlayerPedId(-1), false) then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour rentrer votre à ~b~vehicule~s~ dans le ~b~garage~s~")
				if IsControlJustPressed(1,38) then 			
					TriggerEvent('esx:deleteVehicle')
				end
            end
		end
	end
end)


local isPlayerWhitelisted = false

RegisterNetEvent('esx_outlawalert:gunshotInProgress')
AddEventHandler('esx_outlawalert:gunshotInProgress', function(targetCoords)
	if isPlayerWhitelisted and Config.GunshotAlert then
		local alpha = 250
		local gunshotBlip = AddBlipForRadius(targetCoords.x, targetCoords.y, targetCoords.z, Config.BlipGunRadius)
		local streetName, playerGender

		SetBlipHighDetail(gunshotBlip, true)
		SetBlipColour(gunshotBlip, 1)
		SetBlipAlpha(gunshotBlip, alpha)
		SetBlipAsShortRange(gunshotBlip, true)

		while alpha ~= 0 do
			Citizen.Wait(5 * 4)
			alpha = alpha - 1
			SetBlipAlpha(gunshotBlip, alpha)

			if alpha == 0 then
				RemoveBlip(gunshotBlip)
				return
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		if IsPedShooting(playerPed) and not IsPedCurrentWeaponSilenced(playerPed) then
			local plyPos = GetEntityCoords(GetPlayerPed(-1), true)
			TriggerServerEvent("call:makeCall", "police", {x=plyPos.x,y=plyPos.y,z=plyPos.z}, "Tir d'arme", GetPlayerServerId(player))
			Wait(5000)
		end
	end
end)

Citizen.CreateThread(function()
    local hash = GetHashKey("s_m_y_armymech_01")
    while not HasModelLoaded(hash) do
    RequestModel(hash)
    Wait(20)
    end
    ped = CreatePed("PED_TYPE_CIVFEMALE", "s_m_y_armymech_01", 458.73165893555, -1017.2035522461, 27.188488006592, 93.1554794, false, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
end)

print("^0======================================================================^7")
print("^0[^4Author^0] ^7:^0 ^0Linked^7")
print("^0======================================================================^7")
