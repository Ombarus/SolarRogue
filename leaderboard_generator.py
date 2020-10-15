import random
import math

name_list = ["Moonrakers",
"Orion III",
"SSTO-TAV-37B",
"Churchill",
"Daedalus",
"Explorer",
"Excalibur",
"Intrepid",
"Odyssey",
"Pleiades",
"Roger",
"X-71",
"Armageddon",
"Aries Ib",
"Eagle Transporter",
"Friede",
"Mayflower One",
"Alexei Leonov",
"Anastasia",
"Bebop",
"Bilkis",
"Excelsior",
"Hermes",
"MAV",
"Hunter IV",
"F-302 Mongoose",
"Icarus I",
"Icarus II",
"Lewis & Clark",
"Mars I",
"Mars II",
"Messiah",
"Nightflyer",
"Odyssey",
"Orbit Jet",
"Rocinante",
"Ryvius",
"SA-43 Hammerhead Mk 1",
"Scorpio E-X-1",
"Serenity",
"USSC Discovery",
"USS Cygnus",
"Valley Forge",
"Zero-X",
"Thunderbirds",
"Amaterasu",
"Arcadia",
"Archangel",
"Argonaut",
"Ark",
"Aurora",
"Athena",
"Avalon",
"Axiom",
"Basroil",
"Basestar",
"Bellerophon",
"C-57D",
"Conquistador",
"Daban Urnud",
"Derelict",
"Darksyde",
"Hyperion",
"Event Horizon",
"UNSC Infinity",
"ISA Excalibur",
"Jupiter 2",
"Karrajor",
"Nautilus",
"Nemesis",
"Nirvana",
"Normandy SR-1",
"Normandy SR-2",
"Prometheus",
"Red Dwarf",
"SDF-1 Macross",
"SDF-3 Pioneer",
"Star Destroyer",
"Starship Tipton",
"USS Sulaco",
"Swordbreaker",
"USS Enterprise",
"USS Voyager",
"Yamato",
"Yggdrasil",
"Death glider",
"Needle Threader",
"Deucalion",
"Destiny",
"TARDIS"]

min_score = 20000
max_score = 700000

num_entry = 100

valid_states = {
	"destroyed": 0,
	"entropy": 1,
	"suicide": 2,
	"won": 3
}

if __name__ == '__main__':
	#random.randint(a, b)
	result = []
	random_scores = [random.randint(min_score, max_score) for i in range(num_entry)]
	random_scores.sort(reverse=True)
	#print(random_scores)
	for i in range(num_entry):
		victory_chance = 1.0 - math.log(i + 1) / 4.0
		if random.random() < victory_chance:
			status = valid_states["won"]
		else:
			status = random.randint(0,2)
		line = {}
		died_on = random.randint(0, 10)
		line["died_on"] = died_on
		line["final_score"] = random_scores[i]
		line["generated_levels"] = died_on + random.randint(0, 5)
		line["player_name"] = random.choice(name_list)
		line["status"] = status
		result.append(line)
		
	print(result)