/obj/item/modular_computer/pda/medical/expedition
	name = "expedition medical PDA"
	long_ranged = TRUE
	starting_programs = list(
		/datum/computer_file/program/records/medical,
		/datum/computer_file/program/robocontrol,
		/datum/computer_file/program/scipaper_program,
	)

/obj/structure/closet/secure_closet/tac/expeditionary
	name = "expeditionary tac locker"

/obj/structure/closet/secure_closet/tac/expeditionary/PopulateContents()
	new /obj/item/storage/belt/holster/energy(src)
	new /obj/item/knife/combat(src)
	new /obj/item/clothing/head/helmet/alt(src)
	new /obj/item/clothing/mask/gas/sechailer(src)
	new /obj/item/clothing/suit/armor/bulletproof(src)
	for(var/i in 1 to 2)
		new /obj/item/grenade/frag(src)
	for(var/i in 1 to 2)
		new /obj/item/grenade/flashbang(src)
		new /obj/item/grenade/stingbang(src)
