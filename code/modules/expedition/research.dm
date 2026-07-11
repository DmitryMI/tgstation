/// Shared techweb used by expeditionary whiteship science wings.
/datum/techweb/expeditionary
	id = "EXPEDITIONARY"
	organization = "Nanotrasen"
	should_generate_points = TRUE

/datum/techweb/expeditionary/New()
	. = ..()
	hidden_nodes[TECHWEB_NODE_SHUTTLE_ENG] = TRUE
	hidden_nodes -= TECHWEB_NODE_EXP_LASER_PISTOLS
	hidden_nodes -= TECHWEB_NODE_EXP_LASER_CARBINES
	hidden_nodes -= TECHWEB_NODE_EXP_LASER_RIFLES

/proc/get_expeditionary_techweb()
	var/datum/techweb/expeditionary/web = locate(/datum/techweb/expeditionary) in SSresearch.techwebs
	if(!web)
		web = new /datum/techweb/expeditionary
	return web

/obj/machinery/rnd/server/master/expeditionary/Initialize(mapload)
	stored_research = get_expeditionary_techweb()
	return ..()

/obj/machinery/computer/rdconsole/unlocked/expeditionary/Initialize(mapload)
	stored_research = get_expeditionary_techweb()
	return ..()

/obj/machinery/computer/rdservercontrol/expeditionary/Initialize(mapload)
	stored_research = get_expeditionary_techweb()
	return ..()

/obj/machinery/rnd/production/techfab/expeditionary
	name = "expeditionary techfab"
	desc = "A special expeditionary technology fabricator that produces researched prototypes with raw materials and energy. It is more capable than the models commonly used on Nanotrasen stations."

/obj/machinery/rnd/production/techfab/expeditionary/Initialize(mapload)
	stored_research = get_expeditionary_techweb()
	return ..()

/obj/machinery/rnd/destructive_analyzer/expeditionary/Initialize(mapload)
	stored_research = get_expeditionary_techweb()
	return ..()
