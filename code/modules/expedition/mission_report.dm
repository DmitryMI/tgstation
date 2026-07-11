/// A mission chosen for a specific generated ruin.
/datum/expedition_mission_objective
	var/datum/map_template/ruin/ruin
	var/datum/expedition_mission/mission
	/// Z-level where this ruin was generated.
	var/z_level

/datum/expedition_mission_objective/New(datum/map_template/ruin/new_ruin, datum/expedition_mission/new_mission, new_z_level)
	ruin = new_ruin
	mission = new_mission
	z_level = new_z_level

/datum/expedition_mission_objective/proc/render_report_entry()
	var/location = "Unknown"
	if(mission.disclose_location && isnum(z_level) && z_level > 0)
		location = "Sector [z_level]"
	return "<li>[mission.render_report_entry(ruin)]<br><b>Location:</b> [html_encode(location)]</li>"

/// Generated Expedition mission report data. Consoles print this; they do not decide its contents.
/datum/expedition_mission_report
	var/title = "Expedition Mission Report"
	var/list/datum/expedition_mission_objective/objectives = list()

/datum/expedition_mission_report/New(list/new_objectives)
	objectives = new_objectives || list()

/datum/expedition_mission_report/proc/render_html(vessel_name = "Expedition Shuttle")
	vessel_name ||= "Expedition Shuttle"
	var/list/report_parts = list(
		"<center><img src='[SSassets.transport.get_asset_url("nanotrasen-logo")]' width='50%'></center><hr>",
		"<center><h2>Nanotrasen Expeditionary Command, TCD [time2text(world.realtime, "DDD, MMM DD")], [CURRENT_STATION_YEAR]</h2></center><hr>",
		"<center><h2>[html_encode(title)]</h2></center><hr>",
		"<p><b>Vessel:</b> [html_encode(vessel_name)]</p>",
		"<p><b>Situation:</b> The shuttle has entered an unstable sector with incomplete navigational telemetry. Onboard navigation is malfunctioning and may not reliably identify the route to Space Station 13 without field reconnaissance.</p>",
		"<p><b>Navigation Procedure:</b> The navigation failure prevents the shuttle from querying the local satellite navigation mesh directly. As a redundancy measure, nearby GPS devices cache encrypted bluespace vector components and the keys needed to decode them. Recover every GPS device in the current sector and scan it using the Expedition Navigation Console; the console will identify units carrying useful data. Once all components are recovered, it reconstructs a navigation vector leading to the next sector.</p>",
		"<p><b>Primary Objective:</b> Locate Space Station 13, establish contact with its command staff, and integrate Expedition personnel into station operations.</p>",
		"<hr><h3>Supplemental Mission Objectives</h3>",
	)

	if(length(objectives))
		report_parts += "<ol>"
		for(var/datum/expedition_mission_objective/objective as anything in objectives)
			report_parts += objective.render_report_entry()
		report_parts += "</ol>"
	else
		report_parts += "<p>No ruin-specific supplemental objectives were available in this sector. Proceed with reconnaissance, survival, and contact protocols.</p>"

	report_parts += "<p><i>This report is mission guidance only. Central Command has not enabled automated completion tracking for these objectives.</i></p>"
	return report_parts.Join("")

/// Base report generator. Subtypes can replace the selection algorithm without changing the communications console printer.
/datum/expedition_mission_report_generator
	/// Maximum number of ruin-specific objectives to include in the report.
	var/max_objectives = 5

/datum/expedition_mission_report_generator/proc/generate()
	return new /datum/expedition_mission_report(list())

/// Selects generated space ruins that have weighted mission definitions.
/datum/expedition_mission_report_generator/weighted_ruins

/datum/expedition_mission_report_generator/weighted_ruins/generate()
	var/list/candidate_ruins = get_candidate_ruins()
	var/list/datum/expedition_mission_objective/objectives = list()

	for(var/i in 1 to min(max_objectives, length(candidate_ruins)))
		var/datum/map_template/ruin/ruin = pick_n_take(candidate_ruins)
		var/datum/expedition_mission/mission = pick_mission_for_ruin(ruin)
		if(!mission)
			continue
		objectives += new /datum/expedition_mission_objective(ruin, mission, get_generated_space_ruin_z_level(ruin))

	return new /datum/expedition_mission_report(objectives)

/datum/expedition_mission_report_generator/weighted_ruins/proc/get_candidate_ruins()
	var/list/candidates = list()
	for(var/datum/map_template/ruin/ruin as anything in get_generated_space_ruins())
		if(get_mission_weights_for_ruin(ruin))
			candidates += ruin
	return candidates

/datum/expedition_mission_report_generator/weighted_ruins/proc/get_generated_space_ruins()
	var/list/space_ruins = list()
	for(var/ruin_location in SSmapping.active_ruins)
		var/datum/map_template/ruin/ruin = SSmapping.active_ruins[ruin_location]
		if(ruin?.ruin_type != ZTRAIT_SPACE_RUINS)
			continue
		space_ruins += ruin
	return space_ruins

/datum/expedition_mission_report_generator/weighted_ruins/proc/get_generated_space_ruin_z_level(datum/map_template/ruin/ruin)
	for(var/turf/ruin_location as anything in SSmapping.active_ruins)
		if(SSmapping.active_ruins[ruin_location] == ruin)
			return ruin_location.z
	return null

/datum/expedition_mission_report_generator/weighted_ruins/proc/pick_mission_for_ruin(datum/map_template/ruin/ruin)
	var/list/mission_weights = get_mission_weights_for_ruin(ruin)
	var/mission_type = pick_weight(mission_weights)
	if(!mission_type)
		return null
	return new mission_type()

/datum/expedition_mission_report_generator/weighted_ruins/proc/get_mission_weights_for_ruin(datum/map_template/ruin/ruin)
	var/static/list/mission_types = subtypesof(/datum/expedition_mission)
	var/list/mission_weights = list()

	for(var/mission_type as anything in mission_types)
		var/datum/expedition_mission/mission = new mission_type
		if(!mission.ruin_type || !istype(ruin, mission.ruin_type))
			continue
		mission_weights[mission_type] = mission.weight

	return length(mission_weights) ? mission_weights : null
