/proc/find_expedition_navigation_console(z_level)
	for(var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/navigation_console as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition))
		if(QDELETED(navigation_console))
			continue
		if(isnum(z_level))
			var/obj/docking_port/mobile/expedition_shuttle = SSshuttle.getShuttle(navigation_console.shuttleId)
			if(expedition_shuttle?.z != z_level)
				continue
		return navigation_console
	return null

/// Navigation computer used by a Syndicate Chaser vessel.
/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser
	name = "Chaser Navigation Computer"
	desc = "Used to designate a precise transit location for a Syndicate pursuit vessel."
	shuttlePortId = "chaser_custom"
	jump_to_ports = list("chaser_start" = TRUE)
	// The Chaser dock is at x=8 on the north edge of its 25x17 template.
	// Center the navigation eye on the shuttle instead of using the generic
	// Syndicate console offset, which is for the infiltrator's layout.
	x_offset = 5
	y_offset = -8
	/// Chaser-specific destination designation time in deciseconds.
	var/targeting_time_override
	/// Delay before the Expedition is warned that this Chaser exists.
	var/spawn_warning_delay
	/// Number of delayed attempts made to locate an Expedition console for the spawn warning.
	var/spawn_warning_attempts
	/// Prevents this console from issuing its spawn warning more than once.
	var/spawn_warning_issued

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/Initialize(mapload)
	targeting_time_override = CONFIG_GET(number/chaser_designate_time)
	spawn_warning_delay = CONFIG_GET(number/chaser_spawn_warning_delay)
	. = ..()
	// The base navigation computer derives this from the source shuttle ID on mapload.
	// Chasers always use their own destination group regardless of the converted shuttle family.
	shuttlePortId = "chaser_custom"
	apply_chaser_navigation_timing_override()
	return .

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/post_machine_initialize()
	. = ..()
	SSticker.OnRoundstart(CALLBACK(src, PROC_REF(schedule_spawn_warning)))

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/proc/apply_chaser_navigation_timing_override()
	if(isnum(targeting_time_override) && targeting_time_override >= 0)
		designate_time = targeting_time_override

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/rebuild_z_lock()
	z_lock = list()
	var/obj/docking_port/mobile/chaser_shuttle = SSshuttle.getShuttle(shuttleId)
	if(chaser_shuttle?.z && !SSmapping.level_has_any_trait(chaser_shuttle.z, locked_traits))
		z_lock |= chaser_shuttle.z

	var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_console = find_expedition_navigation_console()
	var/obj/docking_port/mobile/expedition_shuttle = SSshuttle.getShuttle(expedition_console?.shuttleId)
	if(expedition_shuttle?.z && !SSmapping.level_has_any_trait(expedition_shuttle.z, locked_traits))
		z_lock |= expedition_shuttle.z

	var/obj/docking_port/stationary/picked/chaser/chaser_start = SSshuttle.getDock("chaser_start")
	if(chaser_start?.z && !SSmapping.level_has_any_trait(chaser_start.z, locked_traits))
		z_lock |= chaser_start.z

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/get_jump_targets()
	rebuild_z_lock()
	var/list/targets = list()
	var/obj/docking_port/stationary/picked/chaser/chaser_start = SSshuttle.getDock("chaser_start")
	if(chaser_start)
		targets["(1) Chaser Staging Area"] = chaser_start

	var/obj/docking_port/mobile/chaser_shuttle = SSshuttle.getShuttle(shuttleId)
	var/turf/current_center = get_chaser_z_level_center(chaser_shuttle?.z)
	if(current_center)
		targets["(2) Current Sector Center"] = current_center

	var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_console = find_expedition_navigation_console()
	var/obj/docking_port/mobile/expedition_shuttle = SSshuttle.getShuttle(expedition_console?.shuttleId)
	var/turf/expedition_center = get_chaser_z_level_center(expedition_shuttle?.z)
	if(expedition_center)
		targets["(3) [expedition_console.vessel_name] Sector Center"] = expedition_center
	return targets

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/proc/get_chaser_z_level_center(z_level)
	if(!isnum(z_level) || z_level <= 0 || SSmapping.level_has_any_trait(z_level, locked_traits))
		return null
	return locate(round(world.maxx / 2), round(world.maxy / 2), z_level)

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/proc/schedule_spawn_warning()
	addtimer(CALLBACK(src, PROC_REF(issue_spawn_warning)), spawn_warning_delay)

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/proc/issue_spawn_warning()
	if(spawn_warning_issued)
		return

	var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_console = find_expedition_navigation_console()
	if(!expedition_console)
		spawn_warning_attempts += 1
		if(spawn_warning_attempts < 10)
			addtimer(CALLBACK(src, PROC_REF(issue_spawn_warning)), 1 SECONDS)
		return

	spawn_warning_issued = TRUE
	expedition_console.issue_chaser_spawn_warning()

/// Bridge console used by a Syndicate Chaser vessel.
/obj/machinery/computer/shuttle/syndicate/chaser
	name = "Chaser Bridge Console"
	desc = "Used to control a Syndicate pursuit vessel."
	possible_destinations = "chaser_start;chaser_custom"
	/// Optional override for the Chaser's transit time in deciseconds.
	var/call_time_override
	/// Optional override for the Chaser's ignition time in deciseconds.
	var/ignition_time_override
	/// How long the Chaser prevents the Expedition from travelling.
	var/hostile_disruption_time
	/// How long disruptor feedback prevents the Chaser from travelling again.
	var/self_disruption_time
	/// Absolute world time until which disruptor feedback prevents Chaser travel.
	var/navigation_disrupted_until
	/// Prevents duplicate mission reports if machine initialization is re-entered.
	var/mission_report_printed

/obj/machinery/computer/shuttle/syndicate/chaser/Initialize(mapload, obj/item/circuitboard/C)
	call_time_override = CONFIG_GET(number/chaser_call_time)
	ignition_time_override = CONFIG_GET(number/chaser_ignition_time)
	hostile_disruption_time = CONFIG_GET(number/chaser_hostile_disruption_time)
	self_disruption_time = CONFIG_GET(number/chaser_self_disruption_time)
	. = ..()
	// Do not retain the normal Syndicate or Whiteship destination groups.
	possible_destinations = "chaser_start;chaser_custom"
	return .

/obj/machinery/computer/shuttle/syndicate/chaser/post_machine_initialize()
	. = ..()
	SSticker.OnRoundstart(CALLBACK(src, PROC_REF(print_chaser_mission_report)))

/obj/machinery/computer/shuttle/syndicate/chaser/proc/apply_chaser_shuttle_timing_overrides(obj/docking_port/mobile/chaser_shuttle)
	chaser_shuttle ||= SSshuttle.getShuttle(shuttleId)
	if(!chaser_shuttle)
		return FALSE
	if(isnum(call_time_override) && call_time_override >= 0)
		chaser_shuttle.callTime = call_time_override
	if(isnum(ignition_time_override) && ignition_time_override >= 0)
		chaser_shuttle.ignitionTime = ignition_time_override
	return TRUE

/obj/machinery/computer/shuttle/syndicate/chaser/send_shuttle(dest_id, mob/user)
	if(world.time < navigation_disrupted_until)
		say("Unable to depart: bluespace disruptor feedback will persist for [DisplayTimeText(navigation_disrupted_until - world.time)].")
		return "error"

	var/obj/docking_port/mobile/chaser_shuttle = SSshuttle.getShuttle(shuttleId)
	var/obj/docking_port/stationary/destination_port = SSshuttle.getDock(dest_id)
	var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_console
	if(chaser_shuttle?.mode == SHUTTLE_IDLE && destination_port?.z != chaser_shuttle.z)
		expedition_console = find_expedition_navigation_console(destination_port.z)

	apply_chaser_shuttle_timing_overrides(chaser_shuttle)
	. = ..()
	if(. != "success" || !expedition_console)
		return

	var/obj/docking_port/mobile/expedition_shuttle = SSshuttle.getShuttle(expedition_console.shuttleId)
	if(expedition_shuttle?.z != destination_port.z)
		return
	activate_bluespace_disruptor(expedition_console)

/obj/machinery/computer/shuttle/syndicate/chaser/proc/activate_bluespace_disruptor(obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_console)
	var/enemy_disruption_duration = max(0, hostile_disruption_time)
	var/own_disruption_duration = max(enemy_disruption_duration, self_disruption_time)
	if(!expedition_console.apply_hostile_bluespace_disruption(enemy_disruption_duration))
		return FALSE

	navigation_disrupted_until = max(navigation_disrupted_until, world.time + own_disruption_duration)
	say("Bluespace disruptor activated. Targeting Nanotrasen vessel [expedition_console.vessel_name] for [DisplayTimeText(enemy_disruption_duration)]. Chaser navigation will remain disrupted for [DisplayTimeText(own_disruption_duration)].")
	return TRUE

/obj/machinery/computer/shuttle/syndicate/chaser/ui_data(mob/user)
	. = ..()
	if(world.time >= navigation_disrupted_until)
		return
	.["locked"] = TRUE
	.["status"] = "Bluespace Disrupted ([DisplayTimeText(navigation_disrupted_until - world.time)])"

/obj/machinery/computer/shuttle/syndicate/chaser/proc/print_chaser_mission_report()
	if(mission_report_printed)
		return

	mission_report_printed = TRUE
	var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/expedition/expedition_console = find_expedition_navigation_console()
	var/target_vessel_name = expedition_console?.vessel_name || "Nanotrasen Vessel"
	var/datum/chaser_mission_report/report = new(target_vessel_name)
	var/obj/item/paper/mission_report = new /obj/item/paper(drop_location())
	mission_report.name = "paper - '[report.title]'"
	mission_report.add_raw_text(report.render_html(), advanced_html = TRUE)
	mission_report.color = "#8b0000"
	mission_report.update_appearance()

/// Simple orders delivered to a newly deployed Syndicate Chaser.
/datum/chaser_mission_report
	var/title = "Syndicate Chaser Mission Orders"
	var/target_vessel_name

/datum/chaser_mission_report/New(new_target_vessel_name)
	target_vessel_name = new_target_vessel_name || "Nanotrasen Vessel"

/datum/chaser_mission_report/proc/render_html()
	return {"
		<div style='background-color:#650000;color:#ffffff;padding:16px;'>
		<center><img src='[SSassets.transport.get_asset_url("syndicate-logo")]' width='50%'></center><hr>
		<center><h2>SYNDICATE CHASER COMMAND</h2></center><hr>
		<p><b>Primary Mission:</b> Intercept Nanotrasen vessel <b>[html_encode(target_vessel_name)]</b>.</p>
		</div>
	"}

/**
 * Replaces the regular whiteship or Syndicate shuttle consoles in this helper's
 * area with Chaser console subtypes.
 *
 * Source navigation geometry is copied so the helper can convert either
 * shuttle family without inheriting that family's destinations.
 */
/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser
	late = TRUE

/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser/LateInitialize()
	if(!CONFIG_GET(flag/expedition_enabled))
		qdel(src)
		return

	var/area/target_area = get_area(src)
	replace_whiteship_navigation_computers(target_area)
	replace_syndicate_navigation_computers(target_area)
	replace_whiteship_bridge_consoles(target_area)
	replace_syndicate_bridge_consoles(target_area)
	qdel(src)

/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser/proc/replace_whiteship_navigation_computers(area/target_area)
	for(var/obj/machinery/computer/camera_advanced/shuttle_docker/whiteship/console in target_area)
		if(console.type != /obj/machinery/computer/camera_advanced/shuttle_docker/whiteship)
			continue
		var/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/replacement = new(console.loc)
		copy_navigation_configuration(console, replacement)
		qdel(console)

/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser/proc/replace_syndicate_navigation_computers(area/target_area)
	for(var/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/console in target_area)
		if(console.type != /obj/machinery/computer/camera_advanced/shuttle_docker/syndicate)
			continue
		var/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/replacement = new(console.loc)
		copy_navigation_configuration(console, replacement)
		qdel(console)

/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser/proc/copy_navigation_configuration(
	obj/machinery/computer/camera_advanced/shuttle_docker/source,
	obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/chaser/replacement,
)
	replacement.setDir(source.dir)
	replacement.shuttleId = source.shuttleId
	replacement.shuttlePortName = source.shuttlePortName
	replacement.locked_traits = source.locked_traits.Copy()
	replacement.view_range = source.view_range
	replacement.x_offset = source.x_offset
	replacement.y_offset = source.y_offset
	replacement.whitelist_turfs = source.whitelist_turfs.Copy()
	replacement.see_hidden = source.see_hidden
	replacement.zlink_range = source.zlink_range
	replacement.rebuild_z_lock()
	replacement.apply_chaser_navigation_timing_override()

/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser/proc/replace_whiteship_bridge_consoles(area/target_area)
	for(var/obj/machinery/computer/shuttle/white_ship/bridge/console in target_area)
		if(console.type != /obj/machinery/computer/shuttle/white_ship/bridge)
			continue
		var/obj/machinery/computer/shuttle/syndicate/chaser/replacement = new(console.loc)
		copy_bridge_configuration(console, replacement)
		qdel(console)

/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser/proc/replace_syndicate_bridge_consoles(area/target_area)
	for(var/obj/machinery/computer/shuttle/syndicate/console in target_area)
		if(console.type != /obj/machinery/computer/shuttle/syndicate)
			continue
		var/obj/machinery/computer/shuttle/syndicate/chaser/replacement = new(console.loc)
		copy_bridge_configuration(console, replacement)
		qdel(console)

/obj/effect/mapping_helpers/replace_shuttle_consoles_with_chaser/proc/copy_bridge_configuration(
	obj/machinery/computer/shuttle/source,
	obj/machinery/computer/shuttle/replacement,
)
	replacement.setDir(source.dir)
	replacement.shuttleId = source.shuttleId
	replacement.admin_controlled = source.admin_controlled
	replacement.no_destination_swap = source.no_destination_swap
	replacement.may_be_remote_controlled = source.may_be_remote_controlled
/obj/item/uplink/nuclear/chaser
	name = "Syndicate Chaser uplink"
	desc = "A compact uplink assigned to a Syndicate Chaser boarding crew."
	/// Add /datum/uplink_item typepaths here to remove them from Chaser uplinks.
	var/list/blacklisted_uplink_items = list()

/obj/item/uplink/nuclear/chaser/Initialize(mapload, owner, tc_amount = 20, datum/uplink_handler/uplink_handler_override = null)
	. = ..()
	var/datum/component/uplink/hidden_uplink = GetComponent(/datum/component/uplink)
	hidden_uplink.uplink_handler.blacklisted_items = blacklisted_uplink_items.Copy()
