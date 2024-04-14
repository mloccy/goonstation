/*
	Construction mode RCD variants
*/

TYPEINFO(/obj/item/rcd/construction)
	mats = list("MET-3"=100, "CRY-2" = 50, "CON-2"=50, "POW-3"=50, "starstone"=10)

/// Construction mode RCD variant
/obj/item/rcd/construction
	name = "rapid construction device deluxe"
	desc = "Also known as an RCD, this is capable of rapidly constructing walls, flooring, windows, and doors. The deluxe edition features a much higher matter capacity and enhanced feature set."
	max_matter = 15000

	matter_remove_door = 3
	matter_remove_wall = 2
	matter_remove_floor = 2

	var/static/hangar_id_number = 1 //static isnt a real thing in byond????? why does this compile???
	var/hangar_id = null
	var/door_name = null
	var/door_access = 0
	var/door_access_name_cache = null
	var/door_type_name_cache = null
	var/static/list/access_names = list() //ditto the above????
	var/door_type = null

	afterattack(atom/A, mob/user as mob)
		..()
		if (mode == RCD_MODE_DECONSTRUCT)
			if (istype(A, /obj/machinery/door/poddoor/blast) && ammo_check(user, matter_remove_door, 500))
				var /obj/machinery/door/poddoor/blast/B = A
				if (findtext(B.id, "rcd_built") != 0)
					boutput(user, "Deconstructing \the [B] ([matter_remove_door])...")
					playsound(src, 'sound/machines/click.ogg', 50, TRUE)
					if(do_after(user, 5 SECONDS))
						if (ammo_check(user, matter_remove_door))
							playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
							src.sparkIfUnsafe()
							ammo_consume(user, matter_remove_door)
							logTheThing(LOG_STATION, user, "removes a pod door ([B]) using \the [src] in [user.loc.loc] ([log_loc(user)])")
							qdel(A)
							playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
				else
					boutput(user, SPAN_ALERT("You cannot deconstruct that!"))
					return
			else if (istype(A, /obj/machinery/r_door_control) && ammo_check(user, matter_remove_door, 500))
				var/obj/machinery/r_door_control/R = A
				if (findtext(R.id, "rcd_built") != 0)
					boutput(user, "Deconstructing \the [R] ([matter_remove_door])...")
					playsound(src, 'sound/machines/click.ogg', 50, TRUE)
					if(do_after(user, 5 SECONDS))
						if (ammo_check(user, matter_remove_door))
							playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
							src.sparkIfUnsafe()
							ammo_consume(user, matter_remove_door)
							logTheThing(LOG_STATION, user, "removes a Door Control ([A]) using \the [src] in [user.loc.loc] ([log_loc(user)])")
							qdel(A)
							playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
				else
					boutput(user, SPAN_ALERT("You cannot deconstruct that!"))
					return
		else if (mode == RCD_MODE_PODDOORCONTROL)
			if (istype(A, /obj/machinery/r_door_control))
				var/obj/machinery/r_door_control/R = A
				if (findtext(R.id, "rcd_built") != 0)
					boutput(user, SPAN_NOTICE("Selected."))
					hangar_id = R.id
					mode = RCD_MODE_PODDOOR
				else
					boutput(user, SPAN_ALERT("You cannot modify that!"))
			else if (istype(A, /turf/simulated/wall) && ammo_check(user, matter_create_door, 500))
				boutput(user, "Creating Door Control ([matter_create_door])")
				playsound(src, 'sound/machines/click.ogg', 50, TRUE)
				if(do_after(user, 5 SECONDS))
					if (ammo_check(user, matter_create_door))
						playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
						src.sparkIfUnsafe()
						var/idn = hangar_id_number
						hangar_id_number++
						hangar_id = "rcd_built_[idn]"
						mode = RCD_MODE_PODDOOR
						var/obj/machinery/r_door_control/R = new /obj/machinery/r_door_control(A)
						R.id="[hangar_id]"
						R.pass="[hangar_id]"
						R.name="Access code: [hangar_id]"
						ammo_consume(user, matter_create_door)
						logTheThing(LOG_STATION, user, "creates Door Control [hangar_id] using \the [src] in [user.loc.loc] ([log_loc(user)])")
						boutput(user, "Now creating pod bay blast doors linked to the new door control.")

		else if (mode == RCD_MODE_PODDOOR)
			if (istype(A, /turf/simulated/floor) && ammo_check(user, matter_create_door, 500))
				boutput(user, "Creating Pod Bay Door ([matter_create_door])")
				playsound(src, 'sound/machines/click.ogg', 50, TRUE)
				if(do_after(user, 5 SECONDS))
					if (ammo_check(user, matter_create_door))
						playsound(src, 'sound/items/Deconstruct.ogg', 50, TRUE)
						src.sparkIfUnsafe()
						var/stepdir = get_dir(src, A)
						var/poddir = turn(stepdir, 90)
						var/obj/machinery/door/poddoor/blast/B = new /obj/machinery/door/poddoor/blast(A)
						B.id = "[hangar_id]"
						B.set_dir(poddir)
						B.autoclose = TRUE
						ammo_consume(user, matter_create_door)
						logTheThing(LOG_STATION, user, "creates Blast Door [hangar_id] using \the [src] in [user.loc.loc] ([log_loc(user)])")

	create_door(var/turf/A, mob/user as mob)
		var/turf/L = get_turf(user)
		var/door_dir = user.dir
		var/set_data = 0

		if (A in src.working_on)
			return

		if (door_name)
			if (tgui_alert("Use current settings?\nName: [door_name]\nAccess: [door_access_name_cache]\nType: [door_type_name_cache]", "Settings", list("Yes", "No")) != "Yes")
				set_data = 1
		else
			set_data = 1

		if (set_data)
			if (!access_names.len)
				access_names["None"] = 0
				for (var/access in get_all_accesses())
					var/access_name = get_access_desc(access)
					access_names[access_name] = access
			var/door_types = get_airlock_types()

			door_name = copytext(adminscrub(input("Door name", "RCD", door_name) as text), 1, 512)
			door_access_name_cache = input("Required access", "RCD", door_access_name_cache) in access_names
			door_type_name_cache = input("Door type", "Yep", door_type_name_cache) in door_types

			if (!door_types[door_type_name_cache])
				boutput(user, "Something went fucky with this and it broke, sorry. Call a coder.")
				return

			door_access = access_names[door_access_name_cache]
			door_type = door_types[door_type_name_cache]

		if (user.loc != L)
			boutput(user, SPAN_ALERT("Airlock build cancelled - you moved."))
			return

		src.do_rcd_action(user, A, "building an airlock", matter_create_door, 5 SECONDS, PROC_REF(do_build_airlock), src, door_dir)

/obj/item/rcd/construction/do_build_airlock(atom/A, mob/user, door_dir)
	var/obj/machinery/door/airlock/T = new door_type(A)
	log_construction(user, null, "builds an airlock ([T], name: [door_name], access: [door_access], type: [door_type])")
	T.set_dir(door_dir)
	T.autoclose = TRUE
	T.name = door_name
	if (door_access)
		T.req_access = list(door_access)
		T.req_access_txt = "[door_access]"
	else
		T.req_access = null
		T.req_access_txt = null

	for (var/obj/window/auto/O in orange(1,T))
		O.UpdateIcon()
	for (var/obj/grille/G in orange(1,T))
		G.UpdateIcon()
	for (var/turf/simulated/wall/auto/W in orange(1,T))
		W.UpdateIcon()
	for (var/turf/simulated/wall/false_wall/F in orange(1,T))
		F.UpdateIcon()

/// Safe variants don't spew sparks everywhere
/obj/item/rcd/construction/safe
	unsafe = FALSE


TYPEINFO(/obj/item/rcd/construction/chiefEngineer)
	mats = list("MET-3"=20, "CRY-2" = 10, "CON-2" = 10, "POW-2" = 10)

/// Chief Engineer RCD has fancy door functions and a mild discount, but no capacity increase
/obj/item/rcd/construction/chiefEngineer
	name = "rapid construction device custom"
	desc = "Also known as an RCD, this is capable of rapidly constructing walls, flooring, windows, and doors. This device was customized by the Chief Engineer to have an enhanced feature set and work more efficiently."
	icon_state = "base_CE"

	max_matter = 50
	matter_create_wall = 1
	matter_create_door = 4
	matter_create_window = 1
	matter_remove_door = 10
	matter_remove_floor = 6
	matter_remove_wall = 6
	matter_remove_girder = 6
	matter_remove_window = 6
