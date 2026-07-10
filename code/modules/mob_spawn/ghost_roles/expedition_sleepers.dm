/obj/effect/mob_spawn/ghost_role/human/usable_sleeper
	name = "cryogenic sleeper"
	desc = "A sealed sleeper pod with an occupant still inside."
	prompt_name = "a sleeper crewmember"
	density = FALSE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	mob_species = /datum/species/human
	spawner_job_path = /datum/job/ghost_role
	allow_custom_character = GHOSTROLE_TAKE_PREFS_APPEARANCE
	/// The sleeper type that replaces this spawner after a ghost claims it.
	var/unlocked_sleeper_type = /obj/machinery/sleeper/expedition

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/create(mob/mob_possessor, newname, apply_prefs)
	var/mob/living/carbon/human/spawned_human = ..()
	if(!istype(spawned_human))
		return spawned_human

	var/turf/spawn_turf = get_turf(src)
	var/obj/machinery/sleeper/unlocked_sleeper = new unlocked_sleeper_type(spawn_turf)
	unlocked_sleeper.setDir(dir)
	unlocked_sleeper.state_open = FALSE
	unlocked_sleeper.set_density(TRUE)
	unlocked_sleeper.set_occupant(spawned_human)
	spawned_human.forceMove(unlocked_sleeper)
	unlocked_sleeper.update_appearance()
	if(spawned_human.stat != DEAD)
		to_chat(spawned_human, unlocked_sleeper.enter_message)
	return spawned_human

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/admin
	name = "administrative cryogenic sleeper"
	prompt_name = "an expedition administrator"
	outfit = /datum/outfit/admin

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/research_physician
	name = "expedition research physician sleeper"
	prompt_name = "an Expedition Research Physician"
	you_are_text = "You are an Expedition Research Physician."
	flavour_text = "You serve aboard the Nanotrasen Deep Space Exploration Vessel, which was caught in an ion storm that erased its navigation memory. Your mission is to keep the crew alive, study dangerous finds, and recover GPS tracking devices and bluespace navigation vectors from nearby ruins so the ship can locate Space Station 13, the nearest manned Nanotrasen facility, and request help."
	important_text = "DO NOT abandon your team and the ship"
	outfit = /datum/outfit/job/expedition/research_physician
	spawner_job_path = /datum/job/expedition_research_physician

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/engineer
	name = "expedition engineer sleeper"
	prompt_name = "an Expedition Engineer"
	you_are_text = "You are an Expedition Engineer."
	flavour_text = "You serve aboard the Nanotrasen Deep Space Exploration Vessel, which was caught in an ion storm that erased its navigation memory. Keep the ship powered, pressurized, and spaceworthy while the crew searches nearby ruins for GPS tracking devices and bluespace navigation vectors that can guide the vessel to Space Station 13, the nearest manned Nanotrasen facility."
	important_text = "DO NOT abandon your team and the ship"
	outfit = /datum/outfit/job/expedition/engineer
	spawner_job_path = /datum/job/expedition_engineer

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/marine
	name = "expedition marine sleeper"
	prompt_name = "an Expedition Marine"
	you_are_text = "You are an Expedition Marine."
	flavour_text = "You serve aboard the Nanotrasen Deep Space Exploration Vessel, which was caught in an ion storm that erased its navigation memory. Your duty is to protect the crew from hostile ruins, dangerous anomalies, and any threats to Nanotrasen while the team recovers GPS tracking devices and bluespace navigation vectors needed to reach Space Station 13."
	important_text = "DO NOT abandon your team and the ship"
	outfit = /datum/outfit/job/expedition/marine
	spawner_job_path = /datum/job/expedition_marine

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/commander
	name = "expedition commander sleeper"
	prompt_name = "an Expedition Commander"
	you_are_text = "You are the Expedition Commander."
	flavour_text = "You command the Nanotrasen Deep Space Exploration Vessel, which was caught in an ion storm that erased its navigation memory. Lead your crew through nearby space sectors, investigate ruins and dangerous objects, and coordinate the recovery of GPS tracking devices and bluespace navigation vectors so you can find Space Station 13, the nearest manned Nanotrasen facility, and ask it for help."
	important_text = "DO NOT abandon your team and the ship"
	outfit = /datum/outfit/job/expedition/commander
	spawner_job_path = /datum/job/expedition_commander

/datum/job/expedition_research_physician
	title = "Expedition Research Physician"
	policy_index = ROLE_GHOST_ROLE
	description = "Keep the crew alive, analyze dangerous discoveries, and help recover navigation data from ruins."

/datum/job/expedition_engineer
	title = "Expedition Engineer"
	policy_index = ROLE_GHOST_ROLE
	description = "Maintain the vessel and support field operations while the crew searches for navigation data that can lead them to Space Station 13."

/datum/job/expedition_marine
	title = "Expedition Marine"
	policy_index = ROLE_GHOST_ROLE
	description = "Protect the crew, secure hostile sites, and make sure recovered navigation data gets the vessel to Space Station 13."

/datum/job/expedition_commander
	title = "Expedition Commander"
	policy_index = ROLE_GHOST_ROLE
	description = "Lead the expedition, direct ruin exploration, and bring your crew to Space Station 13 for aid."

/obj/item/card/id/advanced/expedition
	name = "expedition identification card"
	desc = "A stripped-down identification card issued to expedition shuttle crew."

/obj/item/card/id/advanced/silver/expedition
	name = "expedition command identification card"
	desc = "A stripped-down command identification card issued to expedition shuttle leadership."

/datum/id_trim/expedition
	assignment = "Expedition Crew"
	trim_state = "trim_assistant"
	access = list(
		ACCESS_BAR,
		ACCESS_KITCHEN,
	)

/datum/id_trim/expedition/research_physician
	assignment = "Expedition Research Physician"
	trim_state = "trim_medicaldoctor"
	department_color = COLOR_MEDICAL_BLUE
	subdepartment_color = COLOR_SCIENCE_PINK
	sechud_icon_state = SECHUD_MEDICAL_DOCTOR
	access = list(
		ACCESS_BAR,
		ACCESS_KITCHEN,
		ACCESS_MEDICAL,
		ACCESS_MORGUE,
		ACCESS_PARAMEDIC,
		ACCESS_PHARMACY,
		ACCESS_RESEARCH,
		ACCESS_SCIENCE,
		ACCESS_SURGERY,
		ACCESS_VIROLOGY,
		ACCESS_XENOBIOLOGY,
	)

/datum/id_trim/expedition/engineer
	assignment = "Expedition Engineer"
	trim_state = "trim_stationengineer"
	department_color = COLOR_ENGINEERING_ORANGE
	subdepartment_color = COLOR_ENGINEERING_ORANGE
	sechud_icon_state = SECHUD_STATION_ENGINEER
	access = list(
		ACCESS_BAR,
		ACCESS_KITCHEN,
		ACCESS_ATMOSPHERICS,
		ACCESS_CONSTRUCTION,
		ACCESS_ENGINEERING,
		ACCESS_ENGINE_EQUIP,
		ACCESS_EXTERNAL_AIRLOCKS,
		ACCESS_MAINT_TUNNELS,
		ACCESS_TECH_STORAGE,
	)

/datum/id_trim/expedition/marine
	assignment = "Expedition Marine"
	trim_state = "trim_securityofficer"
	department_color = COLOR_SECURITY_RED
	subdepartment_color = COLOR_SECURITY_RED
	sechud_icon_state = SECHUD_SECURITY_OFFICER
	access = list(
		ACCESS_BAR,
		ACCESS_KITCHEN,
		ACCESS_ARMORY,
		ACCESS_BRIG,
		ACCESS_BRIG_ENTRANCE,
		ACCESS_COURT,
		ACCESS_SECURITY,
		ACCESS_WEAPONS,
	)

/datum/id_trim/expedition/commander
	assignment = "Expedition Commander"
	trim_state = "trim_captain"
	department_color = COLOR_COMMAND_BLUE
	subdepartment_color = COLOR_COMMAND_BLUE
	sechud_icon_state = SECHUD_CAPTAIN
	big_pointer = TRUE
	pointer_color = COLOR_COMMAND_BLUE
	access = list(
		ACCESS_ATMOSPHERICS,
		ACCESS_ARMORY,
		ACCESS_BAR,
		ACCESS_BRIG,
		ACCESS_BRIG_ENTRANCE,
		ACCESS_CARGO,
		ACCESS_CHAPEL_OFFICE,
		ACCESS_COMMAND,
		ACCESS_CONSTRUCTION,
		ACCESS_COURT,
		ACCESS_CREMATORIUM,
		ACCESS_ENGINEERING,
		ACCESS_ENGINE_EQUIP,
		ACCESS_EVA,
		ACCESS_EXTERNAL_AIRLOCKS,
		ACCESS_GATEWAY,
		ACCESS_HYDROPONICS,
		ACCESS_JANITOR,
		ACCESS_KITCHEN,
		ACCESS_LAWYER,
		ACCESS_LIBRARY,
		ACCESS_MAINT_TUNNELS,
		ACCESS_MEDICAL,
		ACCESS_MINERAL_STOREROOM,
		ACCESS_MORGUE,
		ACCESS_ORDNANCE,
		ACCESS_ORDNANCE_STORAGE,
		ACCESS_PARAMEDIC,
		ACCESS_PHARMACY,
		ACCESS_PLUMBING,
		ACCESS_PSYCHOLOGY,
		ACCESS_RESEARCH,
		ACCESS_SCIENCE,
		ACCESS_SECURITY,
		ACCESS_SERVICE,
		ACCESS_SHIPPING,
		ACCESS_SURGERY,
		ACCESS_TECH_STORAGE,
		ACCESS_THEATRE,
		ACCESS_VIROLOGY,
		ACCESS_WEAPONS,
		ACCESS_XENOBIOLOGY,
	)

/datum/outfit/job/expedition
	name = "Expedition Crew"
	id = /obj/item/card/id/advanced/expedition

/datum/outfit/job/expedition/research_physician
	name = "Expedition Research Physician"
	jobtype = /datum/job/expedition_research_physician

	id_trim = /datum/id_trim/expedition/research_physician
	uniform = /obj/item/clothing/under/rank/medical/doctor
	suit = /obj/item/clothing/suit/toggle/labcoat/science
	suit_store = /obj/item/flashlight/pen
	belt = /obj/item/modular_computer/pda/medical/expedition
	ears = /obj/item/radio/headset/headset_medsci
	shoes = /obj/item/clothing/shoes/sneakers/white
	l_hand = /obj/item/storage/medkit/surgery

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med
	messenger = /obj/item/storage/backpack/messenger/med

	box = /obj/item/storage/box/survival/medical
	skillchips = list(/obj/item/skillchip/entrails_reader)

/datum/outfit/job/expedition/engineer
	name = "Expedition Engineer"
	jobtype = /datum/job/expedition_engineer

	id_trim = /datum/id_trim/expedition/engineer
	uniform = /obj/item/clothing/under/rank/engineering/engineer
	belt = /obj/item/storage/belt/utility/full/engi
	ears = /obj/item/radio/headset/headset_eng
	head = /obj/item/clothing/head/utility/hardhat/welding/up
	shoes = /obj/item/clothing/shoes/workboots
	l_pocket = /obj/item/modular_computer/pda/engineering
	r_pocket = /obj/item/t_scanner

	backpack = /obj/item/storage/backpack/industrial
	satchel = /obj/item/storage/backpack/satchel/eng
	duffelbag = /obj/item/storage/backpack/duffelbag/engineering
	messenger = /obj/item/storage/backpack/messenger/eng

	backpack_contents = list(
		/obj/item/construction/rcd/loaded,
	)

	box = /obj/item/storage/box/survival/engineer
	pda_slot = ITEM_SLOT_LPOCKET
	skillchips = list(/obj/item/skillchip/job/engineer)

/datum/outfit/job/expedition/marine
	name = "Expedition Marine"
	jobtype = /datum/job/expedition_marine
	pda_slot = null

	id_trim = /datum/id_trim/expedition/marine
	uniform = /obj/item/clothing/under/rank/security/officer
	suit = /obj/item/clothing/suit/armor/vest/marine/security
	suit_store = /obj/item/gun/energy/laser/carbine
	belt = /obj/item/storage/belt/holster/energy/laser_pistol
	ears = /obj/item/radio/headset/headset_sec/alt
	gloves = /obj/item/clothing/gloves/tackler/combat
	head = /obj/item/clothing/head/helmet/marine/security
	shoes = /obj/item/clothing/shoes/combat/swat
	l_pocket = /obj/item/restraints/handcuffs
	r_pocket = /obj/item/knife/combat

	backpack = /obj/item/storage/backpack/security
	satchel = /obj/item/storage/backpack/satchel/sec
	duffelbag = /obj/item/storage/backpack/duffelbag/sec
	messenger = /obj/item/storage/backpack/messenger/sec

	backpack_contents = list(
		/obj/item/grenade/flashbang = 1,
		/obj/item/grenade/stingbang = 1,
	)

	box = /obj/item/storage/box/survival/security

/datum/outfit/job/expedition/commander
	name = "Expedition Commander"
	jobtype = /datum/job/expedition_commander
	id = /obj/item/card/id/advanced/silver/expedition

	id_trim = /datum/id_trim/expedition/commander
	uniform = /obj/item/clothing/under/rank/captain
	suit = /obj/item/clothing/suit/armor/vest/marine
	belt = /obj/item/modular_computer/pda/heads
	ears = /obj/item/radio/headset/heads
	glasses = /obj/item/clothing/glasses/sunglasses
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	head = /obj/item/clothing/head/caphat/beret
	shoes = /obj/item/clothing/shoes/combat/swat

	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	duffelbag = /obj/item/storage/backpack/duffelbag
	messenger = /obj/item/storage/backpack/messenger

	backpack_contents = list(
		/obj/item/melee/baton/telescopic = 1,
	)

	box = /obj/item/storage/box/survival
