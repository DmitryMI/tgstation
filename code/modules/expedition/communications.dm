/obj/machinery/computer/communications/expedition
	name = "expedition communications console"
	desc = "A communications console configured for direct Central Command traffic."
	// Expedition Commander ID cards carry ACCESS_COMMAND.
	req_access = list(ACCESS_COMMAND)
	circuit = null
	/// Vessel name rendered on this console's Expedition mission report.
	var/vessel_name = "Expedition Shuttle"
	/// Report generator algorithm used to prepare the round-start Expedition mission report.
	var/mission_report_generator_type = /datum/expedition_mission_report_generator/weighted_ruins
	/// Prevents one console from printing duplicate reports if machinery initialization is re-entered.
	var/mission_report_printed = FALSE

/obj/machinery/computer/communications/expedition/post_machine_initialize()
	. = ..()
	SSticker.OnRoundstart(CALLBACK(src, PROC_REF(print_expedition_mission_report)))

/obj/machinery/computer/communications/expedition/proc/get_expedition_mission_report()
	var/static/list/generated_reports_by_generator_type = list()
	var/datum/expedition_mission_report/generated_report = generated_reports_by_generator_type[mission_report_generator_type]
	if(!generated_report)
		var/datum/expedition_mission_report_generator/generator = new mission_report_generator_type()
		generated_report = generator.generate()
		generated_reports_by_generator_type[mission_report_generator_type] = generated_report
	return generated_report

/obj/machinery/computer/communications/expedition/proc/print_expedition_mission_report()
	if(mission_report_printed)
		return

	mission_report_printed = TRUE
	var/datum/expedition_mission_report/report = get_expedition_mission_report()
	var/obj/item/paper/mission_report = new /obj/item/paper(drop_location())
	mission_report.name = "paper - '[report.title]'"
	mission_report.add_raw_text(report.render_html(vessel_name), advanced_html = TRUE)
	mission_report.color = "#deebff"
	mission_report.update_appearance()

/obj/machinery/computer/communications/expedition/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/ui_state)
	switch (action)
		if ("callShuttle", "changeSecurityLevel", "makePriorityAnnouncement", "purchaseShuttle", "recallShuttle", "requestNukeCodes", "requestSafeCodes", "restoreBackupRoutingData", "sendToOtherSector", "setStatusMessage", "setStatusPicture", "toggleEmergencyAccess")
			return TRUE
		if ("setState")
			if(!(params["state"] in list("main", "messages")))
				return TRUE
	return ..()

/obj/machinery/computer/communications/expedition/ui_data(mob/user)
	var/list/data = ..()
	data["canRequestSafeCode"] = FALSE
	data["safeCodeDeliveryWait"] = 0
	data["showEmergencyShuttleControls"] = FALSE
	data["showStatusDisplayControls"] = FALSE
	if (!data["authenticated"] || data["page"] != "main")
		return data

	data["canBuyShuttles"] = FALSE
	data["canMakeAnnouncement"] = FALSE
	data["canRecallShuttles"] = FALSE
	data["canRequestNuke"] = FALSE
	data["canSendToSectors"] = FALSE
	data["canSetAlertLevel"] = FALSE
	data["canToggleEmergencyAccess"] = FALSE
	data["shuttleCanEvacOrFailReason"] = "You cannot summon the shuttle from this console!"
	if (data["shuttleCalled"])
		data["shuttleRecallable"] = FALSE
	return data

/obj/machinery/computer/communications/expedition/can_buy_shuttles(mob/user)
	return FALSE

/obj/machinery/computer/communications/expedition/can_send_messages_to_other_sectors(mob/user)
	return FALSE

/obj/machinery/computer/communications/expedition/authenticated_as_non_silicon_captain(mob/user)
	if(HAS_SILICON_ACCESS(user))
		return FALSE
	return authenticated(user) && ACCESS_COMMAND in authorize_access

/obj/machinery/computer/communications/expedition/has_communication()
	// This console uses its own direct Central Command link rather than station telecommunications.
	return TRUE

/obj/machinery/computer/communications/expedition/authenticated_as_silicon_or_captain(mob/user)
	return FALSE

/obj/machinery/computer/communications/expedition/receives_message(datum/comm_message/message)
	return message.message_source == COMM_MESSAGE_SOURCE_CENTCOM && !message.is_roundstart_status_summary
