/// A single possible Expedition mission for a generated ruin.
/datum/expedition_mission
	/// Ruin template this mission can be selected for.
	var/ruin_type
	/// Relative selection chance among missions for the same ruin.
	var/weight = 1
	/// Whether the mission report may reveal the ruin's sector.
	var/disclose_location = FALSE
	/// Player-facing mission title.
	var/name = "Survey Site"
	/// Player-facing mission briefing. This is currently RP-only, but can later be paired with fulfillment checks.
	var/briefing = "Survey the site and report any findings to Central Command."

/datum/expedition_mission/proc/render_report_entry(datum/map_template/ruin/ruin)
	return "<b>[html_encode(name)]</b><br>[html_encode(briefing)]"

/datum/expedition_mission/oldstation/recover_survivors
	ruin_type = /datum/map_template/ruin/space/oldstation
	weight = 100
	name = "Silent Station Recovery"
	disclose_location = TRUE
	briefing = "Shortly before contact was lost, Nanotrasen received a distress burst from a secret deep-space research station. Investigate the silent installation, locate any surviving personnel, and help them salvage the station's remaining assets."

/datum/expedition_mission/thederelict/recover_records
	ruin_type = /datum/map_template/ruin/space/thederelict
	weight = 50
	name = "Operation Unwritten History"
	briefing = "Central Command's archives contain no record of Kosmicheskaya Stantsiya 13, yet its signal profile continues to surface in old navigation logs. Search the bridge and command offices for crew manifests, station records, and proof of who authorized its construction. Preserve anything that may clarify the fate of its missing crew."

/datum/expedition_mission/thederelict/prepare_survey
	ruin_type = /datum/map_template/ruin/space/thederelict
	weight = 50
	name = "Operation First Light"
	briefing = "A weak power signature has been detected aboard the long-denied Kosmicheskaya Stantsiya 13. Trace it through the station's engineering systems, restore power where practical, and establish one habitable refuge for a formal Nanotrasen survey team. Do not speculate on the station's history over public channels."

/datum/expedition_mission/forgottenship/capture_or_destroy
	ruin_type = /datum/map_template/ruin/space/forgottenship
	weight = 100
	disclose_location = FALSE
	name = "Operation Closed Circuit"
	briefing = "Nanotrasen intelligence has confirmed that a Syndicate vessel is active, but its present location is unknown. Locate and capture the ship if possible; deny it to the Syndicate if not. Take Syndicate agents alive whenever the tactical situation permits, as their testimony and equipment may prove valuable. Lethal force is authorized."

/datum/expedition_mission/listeningstation/secure_intercepts
	ruin_type = /datum/map_template/ruin/space/listeningstation
	weight = 100
	disclose_location = FALSE
	name = "Operation Quiet Line"
	briefing = "Nanotrasen counterintelligence believes a concealed Syndicate listening post is monitoring corporate communications, but its location is unknown. Locate and secure the station, seize its intercept equipment and communication archives, and prevent further surveillance. Take Syndicate agents alive whenever the tactical situation permits; lethal force is authorized."

/datum/expedition_mission/infested_frigate/secure_wreckage
	ruin_type = /datum/map_template/ruin/space/infested_frigate
	weight = 100
	disclose_location = TRUE
	name = "Operation Cinder Vault"
	briefing = "Nanotrasen sensors recorded a major explosion at the listed coordinates, leaving behind the wreckage of a Syndicate frigate. Board and secure the wreck for salvage, with priority given to recovering Syndicate intelligence, technology, and command records. Exercise extreme caution: sensor data indicates that an unidentified hazard may still be present aboard."

/datum/expedition_mission/derelict_sulaco/secure_documents
	ruin_type = /datum/map_template/ruin/space/derelict_sulaco
	weight = 50
	name = "Operation Silent Archive"
	disclose_location = TRUE
	briefing = "Nanotrasen lost contact with the secret military vessel Sulaco shortly before it vanished from deep-space telemetry. A faint GPS beacon still reaches us intermittently from its last known position. Trace the signal, investigate the vessel, and destroy any classified documents you recover."

/datum/expedition_mission/derelict_sulaco/prepare_salvage
	ruin_type = /datum/map_template/ruin/space/derelict_sulaco
	weight = 50
	name = "Operation Beaconlight"
	disclose_location = TRUE
	briefing = "Central Command has received unexplained transmissions from the sector where the military vessel Sulaco was last deployed. The ship is presumed lost, but its experimental technology remains valuable. Find the bridge, restore power and atmosphere, and prepare the vessel for a future salvage crew."
