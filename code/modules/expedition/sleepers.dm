/obj/machinery/sleeper/expedition
	name = "expedition sleeper"
	desc = "A stripped-down sleeper pod meant for long-haul field work. It monitors and shelters patients, but its chemical systems are absent."
	deconstructable = TRUE
	circuit = /obj/item/circuitboard/machine/sleeper/expedition
	possible_chems = list()

/obj/machinery/sleeper/expedition/inject_chem(chem, mob/user)
	return FALSE

/obj/machinery/sleeper/expedition/chem_allowed(chem)
	return FALSE

/obj/item/circuitboard/machine/sleeper/expedition
	name = "Expedition Sleeper"
	build_path = /obj/machinery/sleeper/expedition
