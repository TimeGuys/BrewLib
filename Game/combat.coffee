
combat = (cname,level,health,species,admin,donor,cweapon,type,fight,name,weapon,target,damage) ->
	alert "Name = "+cname
	alert "Level = "+level
	alert "Species = "+species
	if admin = (true)
		alert "He is an Admin"
		
	if donor = (true)
	    alert "Thanks"
	
	alert "What a shiny "+cweapon
	if fight == true
		alert "I use my "+name+" using a "+weapon+"to hit "+target+" and do "+damage+" damage"
		remain = health - damage
		alert "You have "+remain+" health"

combat("Doctor",111,580,"Time Lord",true,true,"Sonic Screwdriver","Time Traveller", true,"beep","Sonic Screwdriver","Doctor",580)