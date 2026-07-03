/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition
	name = "Expedition Navigation Computer"
	desc = "Used to designate a precise transit location for an expedition vessel."
	camera_jump_action_type = /datum/action/innate/camera_jump/shuttle_docker/expedition
	/// Z-levels that this expedition computer may jump to directly.
	var/list/allowed_z_levels = list()
	/// Optional override for the shuttle's transit time in deciseconds.
	var/call_time_override = 10
	/// Optional override for the shuttle's ignition time in deciseconds.
	var/ignition_time_override = 10
	var/designate_time = 10

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/Initialize(mapload)
	. = ..()
	var/obj/docking_port/mobile/current_shuttle = SSshuttle.getShuttle(shuttleId)
	if(current_shuttle?.z)
		unlock_z_level(current_shuttle.z)
	apply_shuttle_timing_overrides(current_shuttle)

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/post_machine_initialize()
	. = ..()
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
	allowed_z_levels |= z_level
	rebuild_z_lock()
	return TRUE

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

/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/ruin/expedition
	shuttleId = "whiteship_ruin"

/datum/action/innate/camera_jump/shuttle_docker/expedition
	name = "Jump to Location"
	button_icon_state = "camera_jump"

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition
	late = TRUE

/obj/effect/mapping_helpers/replace_whiteship_navigation_with_expedition/LateInitialize()
	for(var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/console in loc)
		var/replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition
		if(istype(console, /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/ruin))
			replacement_type = /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/ruin/expedition
		var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/replacement = new replacement_type(loc)
		replacement.setDir(console.dir)
		var/obj/docking_port/mobile/current_shuttle = SSshuttle.getShuttle(replacement.shuttleId)
		if(current_shuttle?.z && istype(replacement, /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition))
			var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_replacement = replacement
			expedition_replacement.unlock_z_level(current_shuttle.z)
		qdel(console)
		break
	qdel(src)
