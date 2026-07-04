/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition
	name = "Expedition Navigation Computer"
	desc = "Used to designate a precise transit location for an expedition vessel."
	jump_to_ports = list("whiteship_away" = 1)
	/// Whiteship stationary dock groups that expedition systems may expose when their sectors are unlocked.
	var/list/potential_destination_groups = list("whiteship_away", "whiteship_home", "whiteship_z4", "whiteship_waystation", "whiteship_lavaland", "whiteship_custom")
	/// If TRUE, player-facing expedition output uses the z-level's actual configured name.
	var/use_z_level_real_names = FALSE
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

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/get_unlocked_port_destination_groups()
	var/list/group_unlock_state = list()

	for(var/obj/docking_port/stationary/stationary_docking_port in SSshuttle.stationary_docking_ports)
		var/port_destination_group = stationary_docking_port.port_destinations
		if(!(port_destination_group in potential_destination_groups))
			continue

		if(isnull(group_unlock_state[port_destination_group]))
			group_unlock_state[port_destination_group] = TRUE

		if(!(stationary_docking_port.z in allowed_z_levels))
			group_unlock_state[port_destination_group] = FALSE

	var/list/unlocked_groups = list()
	for(var/port_destination_group in potential_destination_groups)
		if(group_unlock_state[port_destination_group])
			unlocked_groups += port_destination_group

	return unlocked_groups

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
	desc = "Used to designate a precise transit location for an expedition vessel. A multitool pulse unlocks one more Sector."

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/debug/multitool_act(mob/living/user, obj/item/multitool/tool)
	var/unlocked_count = allow_next_z_levels(1)
	if(unlocked_count)
		balloon_alert(user, "Unlocked next Sector")
	else
		balloon_alert(user, "No Sectors left")
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader
	name = "Expedition GPS Navigation Computer"
	desc = "Used to designate a precise transit location for the Ship. It has a digital interface to connect the console to GPS tracking devices."
	/// Spaceruin GPS devices whose saved coordinates this computer has already extracted.
	var/list/scanned_gps_refs = list()
	/// Assoc list of GPS ref -> z-level where this computer first scanned that tracker.
	var/list/scanned_gps_contexts = list()
	/// Assoc list of context z-level string -> TRUE once a newly scanned local GPS was processed in that context.
	var/list/context_has_new_local_scan = list()
	/// How many counted z-levels a completed source layer scan should unlock.
	var/levels_to_unlock_per_scan = 1
	/// Assoc list of source z-level string -> list of unlocked z-levels opened from that context.
	var/list/resolved_context_destinations = list()

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/examine(mob/user)
	. = ..()
	. += "The screen reads:"
	. += span_notice(get_current_context_screen_message())

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/attackby(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(weapon, /obj/item/card/id/advanced/debug))
		var/turf/computer_turf = get_turf(src)
		var/current_context_z = computer_turf?.z
		if(!isnum(current_context_z) || current_context_z <= 0)
			say("Unable to establish current bluespace context.")
			return TRUE

		var/list/gps_on_level = get_spaceruin_gps_on_z(current_context_z)
		var/obj/item/gps/spaceruin/scanned_gps = null
		for(var/obj/item/gps/spaceruin/candidate_gps as anything in gps_on_level)
			if(has_scanned_gps(candidate_gps))
				continue
			scanned_gps = candidate_gps
			break
		if(!scanned_gps && length(gps_on_level))
			scanned_gps = gps_on_level[1]

		message_admins("[key_name_admin(user)] used [weapon] to emulate an expedition GPS scan for context [current_context_z] on [src] at [AREACOORD(src)][scanned_gps ? ", selecting [scanned_gps] at [AREACOORD(scanned_gps)]" : ", with no local GPS available"].")
		if(!scanned_gps)
			say("No saved coordinates found in current context.")
			return TRUE

		try_scan_spaceruin_gps(scanned_gps, user)
		return TRUE

	if(!istype(weapon, /obj/item/gps))
		return ..()

	if(!istype(weapon, /obj/item/gps/spaceruin))
		say("No saved coordinates found in [weapon].")
		return TRUE

	var/obj/item/gps/spaceruin/scanned_gps = weapon
	try_scan_spaceruin_gps(scanned_gps, user)
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/try_scan_spaceruin_gps(obj/item/gps/spaceruin/scanned_gps, mob/user)
	var/turf/computer_turf = get_turf(src)
	var/turf/gps_turf = get_turf(scanned_gps)
	var/current_context_z = computer_turf?.z
	var/current_gps_z = gps_turf?.z
	var/obj/docking_port/mobile/current_shuttle = SSshuttle.getShuttle(shuttleId)
	if(!isnum(current_context_z) || current_context_z <= 0)
		say("Unable to establish current bluespace context.")
		return FALSE
	if(current_shuttle && current_shuttle.mode != SHUTTLE_IDLE && current_shuttle.mode != SHUTTLE_RECHARGING)
		say("Unable to decode bluespace vectors while in transit.")
		return FALSE
	if(current_gps_z != current_context_z)
		say("Failed to decode bluespace vector in current context.")
		return FALSE
	var/list/newly_unlocked_levels = list()
	var/is_new_scan = !has_scanned_gps(scanned_gps)
	if(is_new_scan)
		mark_gps_scanned(scanned_gps, current_context_z)
		context_has_new_local_scan["[current_context_z]"] = TRUE

	var/list/already_unlocked_from_context = resolved_context_destinations["[current_context_z]"]
	if(context_has_new_local_scan["[current_context_z]"] && !length(already_unlocked_from_context) && !length(get_unscanned_spaceruin_gps_on_z(current_context_z)))
		allow_next_z_levels(levels_to_unlock_per_scan, CALLBACK(src, PROC_REF(should_free_unlock_z_level_for_gps_progression)), newly_unlocked_levels)
		if(length(newly_unlocked_levels))
			resolved_context_destinations["[current_context_z]"] = newly_unlocked_levels.Copy()

	log_gps_scan_admin_details(user, scanned_gps, current_context_z, newly_unlocked_levels)
	say("[get_scan_result_message(is_new_scan)] [get_resolution_status_message(current_context_z)]")
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_scan_result_message(is_new_scan)
	if(is_new_scan)
		return "New bluespace vector components received."
	return "No new bluespace vector components found."

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_current_context_resolution_message()
	var/turf/computer_turf = get_turf(src)
	return get_resolution_status_message(computer_turf?.z)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_current_context_screen_message()
	var/turf/computer_turf = get_turf(src)
	var/current_context_z = computer_turf?.z
	if(!isnum(current_context_z) || current_context_z <= 0)
		return "Current context: unavailable. [get_resolution_status_message(current_context_z)]"
	return "Current context: [get_player_facing_z_level_name(current_context_z)]. [get_resolution_status_message(current_context_z)]"

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_resolution_status_message(current_context_z)
	if(!isnum(current_context_z) || current_context_z <= 0)
		return "Bluespace vector resolution for current context: unavailable."

	var/list/unlocked_from_context = resolved_context_destinations["[current_context_z]"]
	if(islist(unlocked_from_context))
		return "Bluespace vector resolved for current context. Available destinations: [english_list(get_sorted_player_facing_z_level_names(unlocked_from_context))]."

	var/total_gps = length(get_spaceruin_gps_relevant_to_z(current_context_z))
	var/scanned_gps = length(get_spaceruin_gps_scanned_on_z(current_context_z))
	var/scanned_percentage = total_gps ? round((scanned_gps / total_gps) * 100) : 100
	return "Bluespace vector resolution for current context: [scanned_percentage]%"

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/has_scanned_gps(obj/item/gps/spaceruin/scanned_gps)
	return REF(scanned_gps) in scanned_gps_refs

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/mark_gps_scanned(obj/item/gps/spaceruin/scanned_gps, scanned_context_z)
	var/gps_ref = REF(scanned_gps)
	if(!(gps_ref in scanned_gps_refs))
		scanned_gps_refs += gps_ref
	if(isnum(scanned_context_z) && scanned_context_z > 0 && isnull(scanned_gps_contexts[gps_ref]))
		scanned_gps_contexts[gps_ref] = scanned_context_z

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_spaceruin_gps_on_z(z_level)
	var/list/gps_on_level = list()
	for(var/datum/component/gps/item/gps_component as anything in GLOB.GPS_list)
		var/obj/item/gps/spaceruin/candidate_gps = gps_component.parent
		if(!istype(candidate_gps))
			continue
		var/turf/candidate_turf = get_turf(candidate_gps)
		if(candidate_turf?.z != z_level)
			continue
		gps_on_level += candidate_gps

	return gps_on_level

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_unscanned_spaceruin_gps_on_z(z_level)
	var/list/unscanned_gps = list()
	for(var/obj/item/gps/spaceruin/candidate_gps as anything in get_spaceruin_gps_on_z(z_level))
		if(has_scanned_gps(candidate_gps))
			continue
		unscanned_gps += candidate_gps

	return unscanned_gps

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_spaceruin_gps_scanned_on_z(z_level)
	var/list/scanned_gps = list()
	for(var/obj/item/gps/spaceruin/candidate_gps as anything in get_spaceruin_gps_on_z(z_level))
		var/gps_ref = REF(candidate_gps)
		if(scanned_gps_contexts[gps_ref] != z_level)
			continue
		scanned_gps += candidate_gps

	return scanned_gps

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_spaceruin_gps_relevant_to_z(z_level)
	var/list/relevant_gps = get_unscanned_spaceruin_gps_on_z(z_level)
	for(var/obj/item/gps/spaceruin/candidate_gps as anything in get_spaceruin_gps_scanned_on_z(z_level))
		relevant_gps |= candidate_gps

	return relevant_gps

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_player_facing_z_level_names(list/z_levels)
	var/list/z_level_names = list()
	for(var/z_level in z_levels)
		z_level_names += get_player_facing_z_level_name(z_level)

	return z_level_names

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/get_sorted_player_facing_z_level_names(list/z_levels)
	return sort_list(get_player_facing_z_level_names(z_levels))

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/log_gps_scan_admin_details(mob/user, obj/item/gps/spaceruin/scanned_gps, current_context_z, list/newly_unlocked_levels)
	var/list/log_lines = list()
	log_lines += "[key_name(user)] scanned [scanned_gps] at [AREACOORD(scanned_gps)] on expedition nav computer [src] at [AREACOORD(src)] using current context z-level [current_context_z]."
	log_lines += "Remaining unscanned spaceruin GPS trackers on current z-level [current_context_z]:"

	var/list/remaining_trackers = get_unscanned_spaceruin_gps_on_z(current_context_z)
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
			var/remaining_on_level = length(get_unscanned_spaceruin_gps_on_z(z_level))
			log_lines += "- z-level [z_level]: [remaining_on_level] unscanned spaceruin GPS tracker(s)"

	message_admins(log_lines.Join("\n"))

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/has_unscanned_spaceruin_gps_on_z(z_level)
	return !!length(get_unscanned_spaceruin_gps_on_z(z_level))

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader/proc/should_free_unlock_z_level_for_gps_progression(z_level)
	return !has_unscanned_spaceruin_gps_on_z(z_level)

/obj/machinery/computer/shuttle/white_ship/bridge/expedition
	name = "Expedition Bridge Console"
	desc = "Used to control an expedition vessel."

/obj/machinery/computer/shuttle/white_ship/bridge/expedition/proc/get_expedition_navigation_console()
	var/area/console_area = get_area(src)
	if(!console_area)
		return null
	for(var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/navigation_console in console_area)
		if(navigation_console.shuttleId != shuttleId)
			continue
		return navigation_console
	return null

/obj/machinery/computer/shuttle/white_ship/bridge/expedition/proc/get_unlocked_port_destination_groups()
	var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/navigation_console = get_expedition_navigation_console()
	if(!navigation_console)
		return list()

	return navigation_console.get_unlocked_port_destination_groups()

/obj/machinery/computer/shuttle/white_ship/bridge/expedition/get_valid_destinations()
	var/list/unlocked_destination_groups = get_unlocked_port_destination_groups()
	if(!length(unlocked_destination_groups))
		return list()

	var/obj/docking_port/mobile/mobile_docking_port = SSshuttle.getShuttle(shuttleId)
	var/obj/docking_port/stationary/current_destination = mobile_docking_port?.destination
	var/list/valid_destinations = list()

	for(var/obj/docking_port/stationary/stationary_docking_port in SSshuttle.stationary_docking_ports)
		if(!(stationary_docking_port.port_destinations in unlocked_destination_groups))
			continue
		if(!mobile_docking_port?.check_dock(stationary_docking_port, silent = TRUE))
			continue
		if(stationary_docking_port == current_destination)
			continue
		var/list/location_data = list(
			id = stationary_docking_port.shuttle_id,
			name = stationary_docking_port.name
		)
		valid_destinations += list(location_data)

	return valid_destinations

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/rebuild_z_lock()
	..()
	for(var/z_level in allowed_z_levels)
		z_lock |= z_level

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/get_player_facing_z_level_name(z_level)
	var/datum/space_level/level = SSmapping.get_level(z_level)
	if(use_z_level_real_names && level?.name)
		return level.name
	return "Sector [z_level]"

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/proc/get_z_level_jump_target(z_level)
	var/center_x = round(world.maxx / 2)
	var/center_y = round(world.maxy / 2)
	return locate(center_x, center_y, z_level)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/get_jump_targets()
	var/list/targets = list()
	var/entry_number = 0
	var/list/unlocked_destination_groups = get_unlocked_port_destination_groups()
	var/list/sorted_target_labels = list()
	var/list/target_turfs_by_label = list()

	for(var/obj/docking_port/stationary/port as anything in SSshuttle.stationary_docking_ports)
		if(!port)
			stack_trace("SSshuttle.stationary_docking_ports have null entry!")
			continue
		if(z_lock.len && !(port.z in z_lock))
			continue
		if(!(port.port_destinations in unlocked_destination_groups))
			continue
		entry_number += 1
		targets["([entry_number]) [port.name]"] = port

	for(var/obj/machinery/spaceship_navigation_beacon/nav_beacon as anything in SSshuttle.beacon_list)
		if(!nav_beacon)
			stack_trace("SSshuttle.beacon_list have null entry!")
			continue
		if(!nav_beacon.z || SSmapping.level_has_any_trait(nav_beacon.z, locked_traits))
			continue
		entry_number += 1
		if(!nav_beacon.locked)
			targets["([entry_number]) [nav_beacon.name] located: [nav_beacon.x] [nav_beacon.y] [nav_beacon.z]"] = nav_beacon
		else
			targets["([entry_number]) [nav_beacon.name] locked"] = null

	for(var/z_level in allowed_z_levels)
		if(!isnum(z_level) || SSmapping.level_has_any_trait(z_level, locked_traits))
			continue
		var/turf/target_turf = get_z_level_jump_target(z_level)
		if(!target_turf)
			continue
		var/target_label = "[get_player_facing_z_level_name(z_level)] Center"
		sorted_target_labels += target_label
		target_turfs_by_label[target_label] = target_turf

	sorted_target_labels = sort_list(sorted_target_labels)
	for(var/target_label in sorted_target_labels)
		entry_number += 1
		targets["([entry_number]) [target_label]"] = target_turfs_by_label[target_label]

	return targets

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition
	late = TRUE
	var/default_replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition
	var/bridge_replacement_type = /obj/machinery/computer/shuttle/white_ship/bridge/expedition

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition/LateInitialize()
	var/area/target_area = get_area(src)
	for(var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/console in target_area)
		var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/replacement = new default_replacement_type(console.loc)
		replacement.setDir(console.dir)
		replacement.shuttleId = console.shuttleId
		var/obj/docking_port/mobile/current_shuttle = SSshuttle.getShuttle(replacement.shuttleId)
		if(current_shuttle?.z && istype(replacement, /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition))
			var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_replacement = replacement
			expedition_replacement.unlock_z_level(current_shuttle.z)
		qdel(console)
	for(var/obj/machinery/computer/shuttle/white_ship/bridge/console in target_area)
		var/obj/machinery/computer/shuttle/white_ship/bridge/replacement = new bridge_replacement_type(console.loc)
		replacement.setDir(console.dir)
		replacement.shuttleId = console.shuttleId
		qdel(console)
	qdel(src)

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition/debug
	default_replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/debug

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition/gps_reader
	default_replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/gps_reader
