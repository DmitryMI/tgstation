/obj/machinery/computer/communications/expedition
	name = "expedition communications console"
	desc = "A communications console configured for direct Central Command traffic."
	circuit = null

/obj/machinery/computer/communications/expedition/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/ui_state)
	switch (action)
		if ("callShuttle", "changeSecurityLevel", "makePriorityAnnouncement", "purchaseShuttle", "recallShuttle", "requestNukeCodes", "restoreBackupRoutingData", "sendToOtherSector")
			return TRUE
	return ..()

/obj/machinery/computer/communications/expedition/ui_data(mob/user)
	var/list/data = ..()
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

/obj/machinery/computer/communications/expedition/authenticated_as_silicon_or_captain(mob/user)
	return FALSE

/obj/machinery/computer/communications/expedition/receives_message(datum/comm_message/message)
	return message.message_source == COMM_MESSAGE_SOURCE_CENTCOM
