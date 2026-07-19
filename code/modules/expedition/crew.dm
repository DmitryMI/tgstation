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
	/// Faction assigned to the sleeper's occupant when claimed.
	var/spawn_faction = FACTION_EXPEDITION

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/Initialize(mapload)
	if(!CONFIG_GET(flag/expedition_enabled))
		return INITIALIZE_HINT_QDEL
	return ..()

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/can_ghost_take(mob/dead/observer/user)
	if(!CONFIG_GET(flag/expedition_enabled))
		return FALSE
	return ..()

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/create(mob/mob_possessor, newname, apply_prefs)
	if(!CONFIG_GET(flag/expedition_enabled))
		return CANCEL_SPAWN
	var/mob/living/carbon/human/spawned_human = ..()
	if(!istype(spawned_human))
		return spawned_human
	spawned_human.add_faction(spawn_faction)

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
	flavour_text = "You serve aboard a Nanotrasen Deep Space Exploration Vessel on a military-research expedition. An ion storm has temporarily disrupted the vessel's navigation memory. Fulfill the mission report's assigned sector objectives, provide medical support, and assess recovered materials. Recover GPS navigation data to reconstruct the route to Space Station 13, where the expedition will report and integrate with the station crew."
	important_text = "Complete assigned expedition objectives before proceeding to Space Station 13."
	outfit = /datum/outfit/job/expedition/research_physician
	spawner_job_path = /datum/job/expedition_research_physician

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/engineer
	name = "expedition engineer sleeper"
	prompt_name = "an Expedition Engineer"
	you_are_text = "You are an Expedition Engineer."
	flavour_text = "You serve aboard a Nanotrasen Deep Space Exploration Vessel on a military-research expedition. An ion storm has temporarily disrupted the vessel's navigation memory. Keep the vessel powered, pressurized, and ready for field operations while the crew fulfills its assigned sector objectives. Support recovery of GPS navigation data so the expedition can reconstruct its route to Space Station 13 after completing its initial mission set."
	important_text = "Complete assigned expedition objectives before proceeding to Space Station 13."
	outfit = /datum/outfit/job/expedition/engineer
	spawner_job_path = /datum/job/expedition_engineer

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/marine
	name = "expedition marine sleeper"
	prompt_name = "an Expedition Marine"
	you_are_text = "You are an Expedition Marine."
	flavour_text = "You serve aboard a Nanotrasen Deep Space Exploration Vessel on a military-research expedition. An ion storm has temporarily disrupted the vessel's navigation memory. Secure assigned sector objectives, protect the crew and recovered assets, and contain hazards encountered during field operations. Recover GPS navigation data so the expedition can reconstruct its route to Space Station 13 after the initial mission set is complete."
	important_text = "Complete assigned expedition objectives before proceeding to Space Station 13."
	outfit = /datum/outfit/job/expedition/marine
	spawner_job_path = /datum/job/expedition_marine

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/commander
	name = "expedition commander sleeper"
	prompt_name = "an Expedition Commander"
	you_are_text = "You are the Expedition Commander."
	flavour_text = "You command a Nanotrasen Deep Space Exploration Vessel on a military-research expedition. An ion storm has temporarily disrupted the vessel's navigation memory. Direct the crew through the mission report's assigned sector objectives, authorize field operations, and coordinate recovery of GPS navigation data. Once the initial mission set is fulfilled, reconstruct the route to Space Station 13 and deliver the expedition for debriefing and integration."
	important_text = "Complete assigned expedition objectives before proceeding to Space Station 13."
	outfit = /datum/outfit/job/expedition/commander
	spawner_job_path = /datum/job/expedition_commander

/datum/job/expedition_research_physician
	title = "Expedition Research Physician"
	policy_index = ROLE_GHOST_ROLE
	description = "Provide medical and research support while the expedition fulfills assigned sector objectives."

/datum/job/expedition_engineer
	title = "Expedition Engineer"
	policy_index = ROLE_GHOST_ROLE
	description = "Maintain the vessel and support field operations through the expedition's assigned objectives."

/datum/job/expedition_marine
	title = "Expedition Marine"
	policy_index = ROLE_GHOST_ROLE
	description = "Protect the crew, secure field sites, and support completion of assigned expedition objectives."

/datum/job/expedition_commander
	title = "Expedition Commander"
	policy_index = ROLE_GHOST_ROLE
	description = "Lead the military-research expedition, fulfill assigned objectives, and rendezvous with Space Station 13."

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

/datum/id_trim/expedition/New()
	. = ..()
	if(istype(src, /datum/id_trim/expedition/commander))
		return
	if(CONFIG_GET(flag/expedition_bays_shared_access))
		access = list(
			ACCESS_ATMOSPHERICS,
			ACCESS_ARMORY,
			ACCESS_BAR,
			ACCESS_BRIG,
			ACCESS_BRIG_ENTRANCE,
			ACCESS_CARGO,
			ACCESS_CHAPEL_OFFICE,
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
	if(CONFIG_GET(flag/expedition_cockpit_all_access))
		access += ACCESS_COMMAND

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

/// Syndicate Chaser ghost-role sleepers. These intentionally use the same
/// usable-sleeper flow as expedition crew, but unlock syndicate sleepers and
/// combat-oriented outfits when claimed.
/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/chaser
	name = "syndicate chaser sleeper"
	spawn_faction = ROLE_SYNDICATE
	desc = "A sealed Syndicate sleeper pod with an occupant still inside."
	icon_state = "sleeper_s"
	prompt_name = "a Syndicate Chaser crew member"
	you_are_text = "You are a Syndicate Chaser crew member."
	flavour_text = "You serve aboard a Syndicate pursuit vessel tasked with intercepting and boarding a Nanotrasen expeditionary vessel."
	important_text = "Follow your Strike Leader's orders, capture the Expeditionary Vessel, and do not let the target escape."
	outfit = /datum/outfit/syndicatespace/chaser
	spawner_job_path = /datum/job/syndicate_chaser_boarder
	allow_custom_character = ALL
	role_ban = ROLE_SPACE_SYNDICATE
	unlocked_sleeper_type = /obj/machinery/sleeper/syndie

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/chaser/special(mob/living/new_spawn, mob/mob_possessor, apply_prefs)
	. = ..()
	new_spawn.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/chaser/strike_leader
	name = "Syndicate Chaser strike leader sleeper"
	prompt_name = "a Syndicate Chaser Strike Leader"
	you_are_text = "You are the Strike Leader of a Syndicate Chaser."
	flavour_text = "You command a hand-picked Syndicate boarding team. Coordinate the assault, seize the Nanotrasen vessel, and ensure the target is delivered intact."
	important_text = "Lead the Chaser crew and capture the Expeditionary Vessel."
	outfit = /datum/outfit/syndicatespace/chaser/strike_leader
	spawner_job_path = /datum/job/syndicate_chaser_strike_leader

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/chaser/boarder
	name = "Syndicate Chaser boarder sleeper"
	prompt_name = "a Syndicate Chaser Boarder"
	you_are_text = "You are a Boarder aboard a Syndicate Chaser."
	flavour_text = "You are the assault team's frontline operative. Breach the target, suppress resistance, and secure the Expeditionary Vessel for the Syndicate."
	important_text = "Board the Expeditionary Vessel and secure its crew and critical systems."
	outfit = /datum/outfit/syndicatespace/chaser/boarder
	spawner_job_path = /datum/job/syndicate_chaser_boarder

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/chaser/breacher
	name = "Syndicate Chaser breacher sleeper"
	prompt_name = "a Syndicate Chaser Breacher"
	you_are_text = "You are a Breacher aboard a Syndicate Chaser."
	flavour_text = "You are responsible for opening hostile compartments and keeping the boarding party supplied with tools, power, and demolition equipment."
	important_text = "Break through barriers and keep the boarding route open."
	outfit = /datum/outfit/syndicatespace/chaser/breacher
	spawner_job_path = /datum/job/syndicate_chaser_breacher

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/chaser/extraction_specialist
	name = "Syndicate Chaser extraction specialist sleeper"
	prompt_name = "a Syndicate Chaser Extraction Specialist"
	you_are_text = "You are an Extraction Specialist aboard a Syndicate Chaser."
	flavour_text = "You keep the boarding team alive and stabilize valuable captives. Recover personnel and assets before the target vessel can break away."
	important_text = "Treat wounded allies and extract the target's crew and research assets."
	outfit = /datum/outfit/syndicatespace/chaser/extraction_specialist
	spawner_job_path = /datum/job/syndicate_chaser_extraction_specialist

/datum/job/syndicate_chaser_strike_leader
	title = "Syndicate Chaser Strike Leader"
	policy_index = ROLE_SPACE_SYNDICATE
	description = "Command the Chaser's boarding operation and capture the Nanotrasen Expeditionary Vessel."

/datum/job/syndicate_chaser_boarder
	title = "Syndicate Chaser Boarder"
	policy_index = ROLE_SPACE_SYNDICATE
	description = "Board the Expeditionary Vessel and secure it for the Syndicate."

/datum/job/syndicate_chaser_breacher
	title = "Syndicate Chaser Breacher"
	policy_index = ROLE_SPACE_SYNDICATE
	description = "Open hostile compartments and support the Chaser boarding team with engineering expertise."

/datum/job/syndicate_chaser_extraction_specialist
	title = "Syndicate Chaser Extraction Specialist"
	policy_index = ROLE_SPACE_SYNDICATE
	description = "Keep the boarding team alive and extract captives and valuable assets."

/datum/outfit/syndicatespace/chaser
	name = "Syndicate Chaser Crew"
	box = /obj/item/storage/box/survival/syndie
	/// Each Chaser crewmember receives the same starting TC as a nuclear operative.
	var/uplink_telecrystals = 25
	var/uplink_type = /obj/item/uplink/nuclear/chaser

/datum/outfit/syndicatespace/chaser/post_equip(mob/living/carbon/human/chaser, visuals_only = FALSE)
	. = ..(chaser)
	if(visuals_only)
		return
	var/obj/item/uplink/uplink = new uplink_type(chaser, chaser.key, uplink_telecrystals)
	chaser.equip_to_storage(uplink, ITEM_SLOT_BACK, indirect_action = TRUE, del_on_fail = TRUE)

/datum/outfit/syndicatespace/chaser/strike_leader
	name = "Syndicate Chaser Strike Leader"
	id = /obj/item/card/id/advanced/black/syndicate_command/captain_id
	id_trim = /datum/id_trim/chameleon/operative/nuke_leader
	suit = /obj/item/clothing/suit/armor/vest/capcarapace/syndicate
	head = /obj/item/clothing/head/hats/hos/beret/syndicate
	glasses = /obj/item/clothing/glasses/thermal/eyepatch
	ears = /obj/item/radio/headset/syndicate/alt/leader
	back = /obj/item/storage/backpack/duffelbag/syndie
	l_hand = /obj/item/melee/energy/sword/saber/red
	r_hand = /obj/item/gun/ballistic/revolver/mateba
	r_pocket = /obj/item/melee/baton/telescopic
	backpack_contents = list(
		/obj/item/documents/syndicate/red,
		/obj/item/paper/fluff/ruins/forgottenship/password,
	)

/datum/outfit/syndicatespace/chaser/boarder
	name = "Syndicate Chaser Boarder"
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet/swat
	mask = /obj/item/clothing/mask/gas/syndicate
	back = /obj/item/storage/backpack/duffelbag/syndie
	r_hand = /obj/item/gun/ballistic/shotgun/bulldog
	l_hand = /obj/item/knife/combat/survival
	l_pocket = /obj/item/restraints/handcuffs
	r_pocket = /obj/item/grenade/flashbang
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m12g = 2,
		/obj/item/grenade/stingbang,
	)

/datum/outfit/syndicatespace/chaser/breacher
	name = "Syndicate Chaser Breacher"
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/utility/hardhat/welding/up
	mask = /obj/item/clothing/mask/gas/syndicate
	glasses = /obj/item/clothing/glasses/meson
	back = /obj/item/storage/backpack/duffelbag/syndie
	belt = /obj/item/storage/belt/utility/syndicate
	r_hand = /obj/item/gun/energy/laser/carbine
	l_hand = /obj/item/construction/rcd/loaded
	l_pocket = /obj/item/t_scanner
	r_pocket = /obj/item/grenade/empgrenade
	backpack_contents = list(
		/obj/item/weldingtool/largetank,
	)

/datum/outfit/syndicatespace/chaser/extraction_specialist
	name = "Syndicate Chaser Extraction Specialist"
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet/swat
	mask = /obj/item/clothing/mask/gas/syndicate
	glasses = /obj/item/clothing/glasses/hud/health
	back = /obj/item/storage/backpack/duffelbag/syndie/med
	belt = /obj/item/storage/belt/medical/paramedic
	r_hand = /obj/item/gun/energy/laser/carbine
	l_hand = /obj/item/storage/medkit/surgery_syndie
	r_pocket = /obj/item/defibrillator/compact/loaded
	l_pocket = /obj/item/knife/combat/survival
