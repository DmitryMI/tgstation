/// Subtype for escape pod ports so that we can give them trait behaviour
/obj/docking_port/stationary/escape_pod
	name = "escape pod loader"
	height = 5
	width = 3
	dwidth = 1
	roundstart_template = /datum/map_template/shuttle/escape_pod/default
	/// Set to true if you have a snowflake escape pod dock which needs to always have the normal pod or some other one
	var/enforce_specific_pod = FALSE

/obj/docking_port/stationary/escape_pod/Initialize(mapload)
	. = ..()
	if (enforce_specific_pod)
		return

	if (HAS_TRAIT(SSstation, STATION_TRAIT_SMALLER_PODS))
		roundstart_template = /datum/map_template/shuttle/escape_pod/cramped
		return
	if (HAS_TRAIT(SSstation, STATION_TRAIT_BIGGER_PODS))
		roundstart_template = /datum/map_template/shuttle/escape_pod/luxury

// should fit the syndicate infiltrator, and smaller ships like the battlecruiser corvettes and fighters
/obj/docking_port/stationary/syndicate
	name = "near the station"
	dheight = 1
	dwidth = 12
	height = 17
	width = 23
	shuttle_id = "syndicate_nearby"

/obj/docking_port/stationary/syndicate/northwest
	name = "northwest of station"
	shuttle_id = "syndicate_nw"

/obj/docking_port/stationary/syndicate/northeast
	name = "northeast of station"
	shuttle_id = "syndicate_ne"

/obj/docking_port/stationary/transit
	name = "In Transit"
	override_can_dock_checks = TRUE
	/// The turf reservation returned by the transit area request
	var/datum/turf_reservation/reserved_area
	/// The area created during the transit area reservation
	var/area/shuttle/transit/assigned_area
	/// The mobile port that owns this transit port
	var/obj/docking_port/mobile/owner

/obj/docking_port/stationary/transit/Initialize(mapload)
	. = ..()
	SSshuttle.transit_docking_ports += src

/obj/docking_port/stationary/transit/Destroy(force=FALSE)
	if(force)
		if(get_docked())
			log_world("A transit dock was destroyed while something was docked to it.")
		SSshuttle.transit_docking_ports -= src
		if(owner)
			if(owner.assigned_transit == src)
				owner.assigned_transit = null
			owner = null
		if(!QDELETED(reserved_area))
			qdel(reserved_area)
		reserved_area = null
	return ..()

/obj/docking_port/stationary/picked
	///Holds a list of map name strings for the port to pick from
	var/list/shuttlekeys

/obj/docking_port/stationary/picked/proc/get_weighted_shuttles()
	return get_deepspace_whiteship_weights_for_map(SSmapping.current_map?.map_name, shuttlekeys)

/proc/get_deepspace_whiteship_spawn_weight_entries()
	var/static/list/cached_entries
	var/static/cache_loaded = FALSE

	if(cache_loaded)
		return cached_entries

	cache_loaded = TRUE
	cached_entries = list()

	var/filename = "[global.config.directory]/whiteship_spawn_weights.json"
	if(!fexists(filename))
		return cached_entries

	var/raw_json = file2text(filename)
	if(!raw_json)
		log_world("Unable to read whiteship spawn weights config: [filename]")
		return cached_entries

	var/list/decoded = safe_json_decode(raw_json)
	if(!islist(decoded))
		log_world("Invalid whiteship spawn weights config: [filename] must contain a JSON list.")
		return cached_entries

	for(var/entry in decoded)
		if(!islist(entry))
			log_world("Ignoring malformed whiteship spawn weights entry in [filename]: expected object.")
			continue
		cached_entries += list(entry)

	return cached_entries

/proc/get_deepspace_whiteship_weights_for_map(map_name, list/eligible_whiteships)
	var/list/entries = get_deepspace_whiteship_spawn_weight_entries()
	if(!length(entries) || !length(eligible_whiteships))
		return

	var/list/global_entry
	var/list/map_entry
	var/lower_map_name = LOWER_TEXT("[map_name]")

	for(var/list/entry as anything in entries)
		var/entry_map = entry["map"]
		if(istext(entry_map))
			if(LOWER_TEXT(entry_map) == lower_map_name)
				map_entry = entry
		else if(isnull(entry_map) && !global_entry)
			global_entry = entry

	var/list/selected_entry = map_entry || global_entry
	if(!islist(selected_entry))
		return

	var/list/weights = selected_entry["weights"]
	if(!islist(weights))
		log_world("Ignoring whiteship spawn weights entry for [map_name || "global"] because it has no valid weights object.")
		return

	var/list/eligible_lookup = list()
	for(var/whiteship_id in eligible_whiteships)
		eligible_lookup[LOWER_TEXT("[whiteship_id]")] = whiteship_id

	var/list/final_weights = list()
	var/explicit_total = 0
	var/valid_explicit_entries = 0

	for(var/raw_id in weights)
		var/normalized_id = LOWER_TEXT("[raw_id]")
		var/actual_id = eligible_lookup[normalized_id]
		if(isnull(actual_id))
			log_world("Ignoring unknown deep-space whiteship id '[raw_id]' in whiteship spawn weights for [map_name || "global"].")
			continue

		var/value = weights[raw_id]
		if(!isnum(value) || value < 0 || value > 1)
			log_world("Ignoring invalid whiteship spawn weight '[value]' for '[raw_id]' in [map_name || "global"]. Expected a number between 0 and 1.")
			continue

		final_weights[actual_id] = value
		explicit_total += value
		valid_explicit_entries++

	if(explicit_total > 1)
		log_world("Ignoring whiteship spawn weights for [map_name || "global"] because explicit weights sum to more than 1.")
		return

	if(!valid_explicit_entries)
		return

	var/list/unspecified = list()
	for(var/whiteship_id in eligible_whiteships)
		if(isnull(final_weights[whiteship_id]))
			unspecified += whiteship_id

	if(length(unspecified))
		var/remaining_weight = 1 - explicit_total
		var/distributed_weight = remaining_weight / length(unspecified)
		for(var/whiteship_id in unspecified)
			final_weights[whiteship_id] = distributed_weight

	return final_weights

/proc/get_chaser_spawn_weights(list/eligible_chasers)
	var/static/list/cached_weights
	var/static/cache_loaded = FALSE

	if(!cache_loaded)
		cache_loaded = TRUE
		cached_weights = list()
		var/filename = "[global.config.directory]/chaser_spawn_weights.json"
		if(fexists(filename))
			var/raw_json = file2text(filename)
			var/list/decoded
			if(raw_json)
				decoded = safe_json_decode(raw_json)
			if(islist(decoded))
				cached_weights = decoded
			else
				log_world("Invalid Chaser spawn weights config: [filename] must contain a JSON object.")

	if(!length(cached_weights) || !length(eligible_chasers))
		return

	var/list/eligible_lookup = list()
	for(var/chaser_id in eligible_chasers)
		eligible_lookup[LOWER_TEXT("[chaser_id]")] = chaser_id

	var/list/final_weights = list()
	var/total_weight = 0
	for(var/raw_id in cached_weights)
		var/actual_id = eligible_lookup[LOWER_TEXT("[raw_id]")]
		if(isnull(actual_id))
			log_world("Ignoring unknown Chaser shuttle id '[raw_id]' in chaser_spawn_weights.json.")
			continue

		var/value = cached_weights[raw_id]
		if(!isnum(value) || value < 0)
			log_world("Ignoring invalid Chaser spawn weight '[value]' for '[raw_id]'. Expected a non-negative number.")
			continue

		final_weights[actual_id] = value
		total_weight += value

	if(total_weight <= 0)
		return
	return final_weights

/proc/get_expedition_spawn_weights(list/eligible_vessels)
	var/static/list/cached_weights
	var/static/cache_loaded = FALSE

	if(!cache_loaded)
		cache_loaded = TRUE
		cached_weights = list()
		var/filename = "[global.config.directory]/expedition_spawn_weights.json"
		if(fexists(filename))
			var/raw_json = file2text(filename)
			var/list/decoded
			if(raw_json)
				decoded = safe_json_decode(raw_json)
			if(islist(decoded))
				cached_weights = decoded
			else
				log_world("Invalid Expedition vessel spawn weights config: [filename] must contain a JSON object.")

	if(!length(cached_weights) || !length(eligible_vessels))
		return

	var/list/eligible_lookup = list()
	for(var/vessel_id in eligible_vessels)
		eligible_lookup[LOWER_TEXT("[vessel_id]")] = vessel_id

	var/list/final_weights = list()
	var/total_weight = 0
	for(var/raw_id in cached_weights)
		var/actual_id = eligible_lookup[LOWER_TEXT("[raw_id]")]
		if(isnull(actual_id))
			log_world("Ignoring unknown Expedition vessel id '[raw_id]' in expedition_spawn_weights.json.")
			continue

		var/value = cached_weights[raw_id]
		if(!isnum(value) || value < 0)
			log_world("Ignoring invalid Expedition vessel spawn weight '[value]' for '[raw_id]'. Expected a non-negative number.")
			continue

		final_weights[actual_id] = value
		total_weight += value

	if(total_weight <= 0)
		return
	return final_weights

/obj/docking_port/stationary/picked/Initialize(mapload)
	. = ..()
	if(!LAZYLEN(shuttlekeys))
		WARNING("Random docking port [shuttle_id] loaded with no shuttle keys")
		return
	var/list/weighted_shuttles = get_weighted_shuttles()
	var/selectedid = length(weighted_shuttles) ? pick_weight(weighted_shuttles) : pick(shuttlekeys)
	roundstart_template = SSmapping.shuttle_templates[selectedid]

/obj/docking_port/stationary/picked/whiteship
	name = "Deep Space"
	shuttle_id = "whiteship_away"
	height = 45 //Width and height need to remain in sync with the size of whiteshipdock.dmm, otherwise we'll get overflow
	width = 45
	dheight = 14
	dwidth = 18
	dir = 2
	shuttlekeys = list(
		"whiteship_meta",
		"whiteship_meta_expedition",
		"whiteship_pubby",
		"whiteship_box",
		"whiteship_cere",
		"whiteship_kilo",
		"whiteship_donut",
		"whiteship_delta",
		"whiteship_tram",
		"whiteship_personalshuttle",
		"whiteship_obelisk",
		"whiteship_birdshot",
	)

/// Dedicated starting dock for the Syndicate Chaser.
/obj/docking_port/stationary/picked/chaser
	name = "Chaser Staging Area"
	shuttle_id = "chaser_start"
	height = 45 // Must remain in sync with chaserdock.dmm.
	width = 45
	dheight = 14
	dwidth = 18
	dir = SOUTH
	shuttlekeys = list("whiteship_chaser")

/obj/docking_port/stationary/picked/chaser/get_weighted_shuttles()
	return get_chaser_spawn_weights(shuttlekeys)

/// Dedicated starting dock for an Expedition vessel.
/obj/docking_port/stationary/picked/expedition
	name = "Expedition Vessel Dock"
	shuttle_id = "expedition_away"
	// The Kestrel is 42 by 21 with its port at (28, 21). The larger dock
	// preserves clearance ahead of the vessel for future Expedition templates.
	width = 50
	height = 25
	dwidth = 22
	dheight = 4
	dir = SOUTH
	shuttlekeys = list("expedition_kestrel")

/obj/docking_port/stationary/picked/expedition/get_weighted_shuttles()
	return get_expedition_spawn_weights(shuttlekeys)
