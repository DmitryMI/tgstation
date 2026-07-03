/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition
	name = "Expedition Navigation Computer"
	desc = "Used to designate a precise transit location for an expedition vessel."
	jump_to_ports = list("whiteship_away" = 1, "whiteship_home" = 0)
	/// Z-levels that this expedition computer may jump to directly.
	var/list/allowed_z_levels = list()
	/// Optional override for the shuttle's transit time in deciseconds.
	var/call_time_override = 10
	/// Optional override for the shuttle's ignition time in deciseconds.
	var/ignition_time_override = 10
	designate_time = 10

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/Initialize(mapload)
	. = ..()
	var/obj/docking_port/mobile/current_shuttle = SSshuttle.getShuttle(shuttleId)
	if(current_shuttle?.z)
		unlock_z_level(current_shuttle.z)
	apply_shuttle_timing_overrides(current_shuttle)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/post_machine_initialize()
	. = ..()
	sync_allowed_z_levels_from_jump_ports()
	var/obj/docking_port/mobile/current_shuttle = SSshuttle.getShuttle(shuttleId)
	if(current_shuttle?.z)
		unlock_z_level(current_shuttle.z)
	apply_shuttle_timing_overrides(current_shuttle)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/vv_edit_var(vname, vval)
	. = ..()
	if(vname in list(NAMEOF(src, call_time_override), NAMEOF(src, ignition_time_override)))
		apply_shuttle_timing_overrides()

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/apply_shuttle_timing_overrides(obj/docking_port/mobile/current_shuttle)
	current_shuttle ||= SSshuttle.getShuttle(shuttleId)
	if(!current_shuttle)
		return FALSE
	if(isnum(call_time_override) && call_time_override >= 0)
		current_shuttle.callTime = call_time_override
	if(isnum(ignition_time_override) && ignition_time_override >= 0)
		current_shuttle.ignitionTime = ignition_time_override
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/unlock_z_level(z_level)
	if(!isnum(z_level) || z_level <= 0)
		return FALSE
	if(z_level in allowed_z_levels)
		return FALSE
	allowed_z_levels += z_level
	rebuild_z_lock()
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/sync_allowed_z_levels_from_jump_ports()
	for(var/obj/docking_port/stationary/port as anything in SSshuttle.stationary_docking_ports)
		if(!port)
			continue
		if(isnull(port.z))
			continue
		if(!jump_to_ports[port.shuttle_id])
			continue
		unlock_z_level(port.z)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/get_space_graph_hop_counts_from_station()
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/list/hop_counts = list()
	var/list/to_visit = list()
	var/queue_index = 1

	for(var/station_level in station_levels)
		if(!isnum(station_level))
			continue
		hop_counts["[station_level]"] = 0
		to_visit += station_level

	while(queue_index <= length(to_visit))
		var/current_z = to_visit[queue_index]
		queue_index += 1

		var/datum/space_level/current_level = SSmapping.get_level(current_z)
		if(!current_level || current_level.linkage != CROSSLINKED)
			continue

		var/current_hop_count = hop_counts["[current_z]"]
		for(var/direction in current_level.neigbours)
			var/datum/space_level/neighbor = current_level.neigbours[direction]
			if(!neighbor || neighbor.linkage != CROSSLINKED)
				continue
			if(!isnull(hop_counts["[neighbor.z_value]"]))
				continue
			hop_counts["[neighbor.z_value]"] = current_hop_count + 1
			to_visit += neighbor.z_value

	return hop_counts

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/get_z_levels_sorted_by_station_hop_count_desc()
	var/list/hop_counts = get_space_graph_hop_counts_from_station()
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/list/sorted_levels = list()

	for(var/datum/space_level/level as anything in SSmapping.z_list)
		if(!level || level.linkage != CROSSLINKED)
			continue
		if(isnull(hop_counts["[level.z_value]"]))
			continue
		insert_z_level_by_station_hop_count(sorted_levels, level.z_value, hop_counts)

	for(var/station_level in station_levels)
		sorted_levels -= station_level
	for(var/station_level in station_levels)
		if(!isnull(hop_counts["[station_level]"]))
			sorted_levels += station_level

	return sorted_levels

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/insert_z_level_by_station_hop_count(list/sorted_levels, z_level, list/hop_counts)
	var/z_level_hop_count = hop_counts["[z_level]"]
	var/insert_at = length(sorted_levels) + 1

	for(var/index in 1 to length(sorted_levels))
		var/sorted_z_level = sorted_levels[index]
		var/sorted_hop_count = hop_counts["[sorted_z_level]"]
		if(z_level_hop_count > sorted_hop_count || (z_level_hop_count == sorted_hop_count && z_level < sorted_z_level))
			insert_at = index
			break

	sorted_levels.Insert(insert_at, z_level)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/allow_next_z_levels(levels_to_unlock_count, datum/callback/free_unlock_check, list/newly_unlocked_levels)
	if(!isnum(levels_to_unlock_count) || levels_to_unlock_count <= 0)
		return 0

	var/list/sorted_levels = get_z_levels_sorted_by_station_hop_count_desc()
	var/unlocked_count = 0

	for(var/z_level in sorted_levels)
		if(z_level in allowed_z_levels)
			continue
		var/is_free_unlock = !!free_unlock_check?.Invoke(z_level)
		if(!unlock_z_level(z_level))
			continue
		if(islist(newly_unlocked_levels))
			newly_unlocked_levels += z_level
		if(is_free_unlock)
			continue
		unlocked_count += 1
		if(unlocked_count >= levels_to_unlock_count)
			break

	return unlocked_count

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/debug
	name = "Expedition Navigation Computer (Debug)"
	desc = "Used to designate a precise transit location for an expedition vessel. A multitool pulse unlocks one more z-level."

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/debug/multitool_act(mob/living/user, obj/item/multitool/tool)
	var/unlocked_count = allow_next_z_levels(1)
	if(unlocked_count)
		balloon_alert(user, "unlocked next z-level")
	else
		balloon_alert(user, "no z-levels left")
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader
	name = "Expedition GPS Navigation Computer"
	desc = "Used to extract saved spaceruin coordinates from recovered GPS trackers and chart new expedition routes."
	/// Source z-levels that have already paid out their one unlock.
	var/list/used_source_z_levels = list()
	/// Spaceruin GPS devices whose saved coordinates this computer has already extracted.
	var/list/scanned_gps_refs = list()
	/// How many counted z-levels a completed source layer scan should unlock.
	var/levels_to_unlock_per_scan = 1

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/attackby(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	if(!istype(weapon, /obj/item/gps))
		return ..()
	if(!istype(weapon, /obj/item/gps/spaceruin))
		balloon_alert(user, "no saved coordinates")
		return TRUE

	var/obj/item/gps/spaceruin/scanned_gps = weapon
	try_scan_spaceruin_gps(scanned_gps, user)
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/try_scan_spaceruin_gps(obj/item/gps/spaceruin/scanned_gps, mob/user)
	var/turf/gps_turf = get_turf(scanned_gps)
	var/current_gps_z = gps_turf?.z
	if(!scanned_gps.origin_z)
		scanned_gps.refresh_origin_z()
	if(has_scanned_gps(scanned_gps))
		balloon_alert(user, "coordinates already extracted")
		return FALSE
	if(!isnum(scanned_gps.origin_z) || scanned_gps.origin_z <= 0)
		balloon_alert(user, "no saved coordinates")
		return FALSE
	if(current_gps_z != scanned_gps.origin_z)
		balloon_alert(user, "Failed to decode bluespace vector in current context")
		return FALSE
	if(scanned_gps.origin_z in used_source_z_levels)
		balloon_alert(user, "layer already processed")
		return FALSE

	mark_gps_scanned(scanned_gps)

	if(has_unscanned_spaceruin_gps_on_origin_z(scanned_gps.origin_z))
		log_gps_scan_admin_details(user, scanned_gps, list())
		balloon_alert(user, "coordinates copied")
		return TRUE

	used_source_z_levels += scanned_gps.origin_z
	var/allowed_levels_before = length(allowed_z_levels)
	var/list/newly_unlocked_levels = list()
	var/unlocked_count = allow_next_z_levels(levels_to_unlock_per_scan, CALLBACK(src, PROC_REF(should_free_unlock_z_level_for_gps_progression)), newly_unlocked_levels)
	log_gps_scan_admin_details(user, scanned_gps, newly_unlocked_levels)
	if(length(allowed_z_levels) > allowed_levels_before || unlocked_count)
		balloon_alert(user, "new destinations unlocked")
	else
		balloon_alert(user, "no z-levels left")
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/has_scanned_gps(obj/item/gps/spaceruin/scanned_gps)
	return REF(scanned_gps) in scanned_gps_refs

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/mark_gps_scanned(obj/item/gps/spaceruin/scanned_gps)
	var/gps_ref = REF(scanned_gps)
	if(!(gps_ref in scanned_gps_refs))
		scanned_gps_refs += gps_ref

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_unscanned_spaceruin_gps_on_origin_z(origin_z)
	var/list/unscanned_gps = list()
	for(var/datum/component/gps/item/gps_component as anything in GLOB.GPS_list)
		var/obj/item/gps/spaceruin/candidate_gps = gps_component.parent
		if(!istype(candidate_gps))
			continue
		if(!candidate_gps.origin_z)
			candidate_gps.refresh_origin_z()
		var/turf/candidate_turf = get_turf(candidate_gps)
		if(has_scanned_gps(candidate_gps))
			continue
		if(candidate_gps.origin_z != origin_z)
			continue
		if(candidate_turf?.z != candidate_gps.origin_z)
			continue
		unscanned_gps += candidate_gps

	return unscanned_gps

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/log_gps_scan_admin_details(mob/user, obj/item/gps/spaceruin/scanned_gps, list/newly_unlocked_levels)
	var/list/log_lines = list()
	log_lines += "[key_name(user)] scanned [scanned_gps] at [AREACOORD(scanned_gps)] on expedition nav computer [src] at [AREACOORD(src)]."
	log_lines += "Remaining unscanned spaceruin GPS trackers on source z-level [scanned_gps.origin_z]:"

	var/list/remaining_trackers = get_unscanned_spaceruin_gps_on_origin_z(scanned_gps.origin_z)
	if(!length(remaining_trackers))
		log_lines += "- none"
	else
		for(var/obj/item/gps/spaceruin/remaining_gps as anything in remaining_trackers)
			log_lines += "- [remaining_gps] at [AREACOORD(remaining_gps)]"

	log_lines += "Newly unlocked z-levels:"
	if(!length(newly_unlocked_levels))
		log_lines += "- none"
	else
		for(var/z_level in newly_unlocked_levels)
			var/remaining_on_level = length(get_unscanned_spaceruin_gps_on_origin_z(z_level))
			log_lines += "- z-level [z_level]: [remaining_on_level] unscanned spaceruin GPS tracker(s)"

	log_admin(log_lines.Join("\n"))

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/has_unscanned_spaceruin_gps_on_origin_z(origin_z)
	return !!length(get_unscanned_spaceruin_gps_on_origin_z(origin_z))

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/should_free_unlock_z_level_for_gps_progression(z_level)
	return !has_unscanned_spaceruin_gps_on_origin_z(z_level)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/rebuild_z_lock()
	..()
	for(var/z_level in allowed_z_levels)
		z_lock |= z_level

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/get_z_level_jump_target(z_level)
	var/center_x = round(world.maxx / 2)
	var/center_y = round(world.maxy / 2)
	return locate(center_x, center_y, z_level)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/get_jump_targets()
	var/list/targets = ..()
	var/entry_number = length(targets)

	for(var/z_level in allowed_z_levels)
		if(!isnum(z_level) || SSmapping.level_has_any_trait(z_level, locked_traits))
			continue
		var/turf/target_turf = get_z_level_jump_target(z_level)
		if(!target_turf)
			continue
		entry_number += 1
		targets["([entry_number]) Z-Level [z_level] Center"] = target_turf

	return targets

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition
	late = TRUE
	var/default_replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition/LateInitialize()
	for(var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/console in loc)
		var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/replacement = new default_replacement_type(loc)
		replacement.setDir(console.dir)
		replacement.shuttleId = console.shuttleId
		var/obj/docking_port/mobile/current_shuttle = SSshuttle.getShuttle(replacement.shuttleId)
		if(current_shuttle?.z && istype(replacement, /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition))
			var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_replacement = replacement
			expedition_replacement.unlock_z_level(current_shuttle.z)
		qdel(console)
		break
	qdel(src)

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition/debug
	default_replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/debug

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition/gps_reader
	default_replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader
