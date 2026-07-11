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
		"<p><b>Vessel Name:</b> [html_encode(vessel_name)]</p>",
		"<p><b>Situation:</b> The shuttle has entered an unstable sector with incomplete navigational telemetry. Onboard navigation is malfunctioning and may not reliably identify the route to Space Station 13 without field reconnaissance.</p>",
		"<p><b>Navigation Procedure:</b> The navigation failure prevents the shuttle from querying the local satellite navigation mesh directly. As a redundancy measure, nearby GPS devices cache encrypted bluespace vector components and the keys needed to decode them. Recover every GPS device in the current sector and scan it using the Expedition Navigation Console; the console will identify units carrying useful data. Once all components are recovered, it reconstructs a navigation vector leading to the next sector.</p>",
		"<p><b>Primary Objective:</b> Locate Space Station 13, establish contact with its command staff, and integrate Expedition personnel into station operations.</p>",
	)

	report_parts += "<hr><h3>Supplemental Mission Objectives</h3>"

	if(length(objectives))
		report_parts += "<ol>"
		for(var/datum/expedition_mission_objective/objective as anything in objectives)
			report_parts += objective.render_report_entry()
		report_parts += "</ol>"
	else
		report_parts += "<p>No supplemental objectives were available in this area. Proceed with reconnaissance, survival, and contact protocols.</p>"

	report_parts += render_policy_html()

	report_parts += "<p><i>This report is mission guidance only. Central Command has not enabled automated completion tracking for these objectives.</i></p>"
	return report_parts.Join("")

/datum/expedition_mission_report/proc/render_policy_html()
	var/list/policy_entries = list(
		"Until the Expeditionary Vessel docks with Space Station 13, the Expedition Commander retains full operational authority over Expedition personnel and assets.",
		"Upon docking, authority over the Expeditionary Vessel and its team transfers to the Space Station 13 Captain. The Captain may retain, dissolve, repurpose, or assign new operations to the Expeditionary command.",
		"If Space Station 13's chain of command is disrupted by hostile action or environmental emergency, the Expeditionary Team must prevent the vessel from falling into unauthorized hands. The Expedition Commander is authorized to assume station authority as necessary to restore order and return the Captain to command. If the Captain is dead or unable to resume command, the Expedition Commander may serve as Acting Captain until a lawful successor is established.",
		"If Space Station 13 is destroyed beyond reasonable repair, or conditions make docking unacceptably hazardous, withdraw the Expeditionary Vessel to deep space and request further orders from Central Command.",
		"At mission start, the Expedition Commander must designate individual successors to preserve continuity of command. If no valid successor has been designated, the surviving Expedition members will select a new Commander by dice roll.",
		"All Expedition personnel are combat-trained and authorized to carry weapons. Research and Engineering personnel should avoid direct combat while capable Expedition Marines are available; the Expedition Commander may override this restriction when operationally necessary.",
		"The Expeditionary Vessel is a high-value Nanotrasen asset. Do not abandon it while operational or leave it unsecured. Boarding is ordinarily limited to Expedition personnel, Central Command officials, restrained prisoners when necessary, and the Space Station 13 Captain or personnel expressly authorized by that Captain. The Expedition Commander may grant security-based exceptions.",
		"Expedition personnel are elite Nanotrasen assets, and every reasonable effort must be made to prevent loss of life. The Expedition Commander must balance operational necessity against risk to the team. Personnel in distress are to be rescued unless the expected risk to the remaining team substantially outweighs the likelihood of a successful recovery; the Commander has final authority in this assessment.",
		"The Expeditionary Team may establish contact with non-hostile humanoids encountered during operations. Assistance may be provided to persons in distress when the Expedition Commander determines that doing so benefits the expedition or Nanotrasen interests.",
		"The Expeditionary Team may use lethal force against any person or entity assessed as hostile or dangerous to Nanotrasen, including threats not presently directed at the vessel or other Nanotrasen assets. However, the mission's research and intelligence value requires that non-lethal neutralization and live capture be prioritized whenever practical.",
		"Scientific research aboard the Expeditionary Vessel is authorized when lawful in Nanotrasen-controlled space. If a proposed activity is known to be unlawful but may materially benefit expedition operations, the Expedition Commander must contact Central Command for guidance. Unauthorized unlawful research is prohibited.",
		"The Expeditionary Vessel's scientific systems include an authorized tactical development package. Analysis of recovered materials may unlock improved directed-energy armaments for Expedition security personnel. Such equipment is intended for mission protection and recovery operations; its deployment remains subject to the Expedition Commander's operational judgment.",
		"After docking and transfer of authority, the Expedition Commander is authorized to brief the Space Station 13 Captain on all Expeditionary operations and findings. Expedition personnel are immune from station discipline for policy-compliant actions performed aboard the vessel before docking.",
		"The Expedition Commander is responsible for maintaining order aboard the vessel. Executions are prohibited, and lethal force against Expedition personnel must be avoided except where immediately necessary to protect life. Personnel whose conduct cannot be safely controlled should be restrained and delivered to Space Station 13 as prisoners for disposition by the Station Captain.",
		"The Expeditionary Team may transport hazardous life forms and objects aboard the vessel when operationally justified. Take every possible precaution to prevent their release onto Space Station 13. After docking, custody and final disposition of such materials transfers to the Station Captain.",
		"Recover humanoid remains from explored sites whenever practical. The Expeditionary Vessel is equipped to transport forensic evidence for later Nanotrasen examination. Place remains in body bags and morgue storage, and take reasonable care to prevent damage during recovery and transport.",
		"This mission report is classified. Its contents are restricted to Expedition personnel and the Space Station 13 Captain. The Expedition Commander must deliver the report to the Station Captain at the earliest safe opportunity after docking.",
	)
	return "<hr><h3>Expedition Policy Clarifications</h3><ol><li>[policy_entries.Join("</li><li>")]</li></ol>"

/// Base report generator. Subtypes can replace the selection algorithm without changing the communications console printer.
/datum/expedition_mission_report_generator
	/// Maximum number of ruin-specific objectives to include in the report.
	var/max_objectives

/datum/expedition_mission_report_generator/New()
	max_objectives = CONFIG_GET(number/expedition_max_objectives)
	return ..()

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
