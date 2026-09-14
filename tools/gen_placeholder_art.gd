extends SceneTree

const PALETTE: Dictionary[String, Color] = {
	"g": Color("5f9e46"), "G": Color("74b356"), "n": Color("538a3c"),
	"b": Color("8b5a2b"), "B": Color("a26a35"), "m": Color("74481f"),
	"D": Color("2e7d32"), "c": Color("43a047"), "L": Color("66bb6a"),
	"t": Color("5d4037"), "T": Color("795548"),
	"R": Color("9e9e9e"), "r": Color("cfcfcf"), "S": Color("616161"), "K": Color("424242"),
	"y": Color("7cb342"), "Y": Color("aed581"),
	"W": Color("4e4e4e"), "M": Color("2b2b2b"), "H": Color("6b6b6b"),
	"l": Color("8d6e63"), "d": Color("5d4037"), "e": Color("d7ccc8"),
	"q": Color("d4b24c"), "Q": Color("e8cf6e"),
	"f": Color("e0e0e0"),
	"h": Color("4e342e"), "s": Color("ffcc80"), "o": Color("ff9800"), "O": Color("e65100"),
	"p": Color("3f51b5"), "k": Color("212121"),
	"z": Color("8bc34a"), "Z": Color("558b2f"), "u": Color("6d4c41"), "P": Color("37474f"), "x": Color("b71c1c"),
}

const GRASS_FLOOR: PackedStringArray = [
	"gggggggggggggggg",
	"ggGgggggggnggggg",
	"gggggggggggggggg",
	"ggggggnggggggGgg",
	"gggggggggggggggg",
	"gGgggggggggggggg",
	"gggggggggGgggggg",
	"ggggnggggggggggg",
	"gggggggggggggngg",
	"gggggggggggggggg",
	"ggggGggggggggggg",
	"ggggggggggGggggg",
	"gngggggggggggggg",
	"gggggggngggggggg",
	"ggggggggggggggGg",
	"gggggggggggggggg",
]
const DIRT_FLOOR: PackedStringArray = [
	"bbbbbbbbbbbbbbbb",
	"bbBbbbbbbbmbbbbb",
	"bbbbbbbbbbbbbbbb",
	"bbbbbbmbbbbbbBbb",
	"bbbbbbbbbbbbbbbb",
	"bBbbbbbbbbbbbbbb",
	"bbbbbbbbbBbbbbbb",
	"bbbbmbbbbbbbbbbb",
	"bbbbbbbbbbbbbmbb",
	"bbbbbbbbbbbbbbbb",
	"bbbbBbbbbbbbbbbb",
	"bbbbbbbbbbBbbbbb",
	"bmbbbbbbbbbbbbbb",
	"bbbbbbbmbbbbbbbb",
	"bbbbbbbbbbbbbbBb",
	"bbbbbbbbbbbbbbbb",
]
const TREE: PackedStringArray = [
	"....DDDDDDD.....",
	"...DDcccccDD....",
	"..DDcccLLcccDD..",
	".DDccLLLLLcccDD.",
	".DccLLLLLLccccD.",
	".DcccLLLLcccccD.",
	".DDcccccccccDDD.",
	"..DDccccccccDD..",
	"...DDDccccDDD...",
	".....DDttDD.....",
	".......tT.......",
	".......tT.......",
	".......tT.......",
	"......ttTT......",
	"....DDDDDDDD....",
	"................",
]
const ROCK: PackedStringArray = [
	"................",
	"................",
	".....KKKKK......",
	"...KKRRrrRKK....",
	"..KRRrrrRRRRK...",
	".KRRrrRRRRRRSK..",
	".KRRRRRRRRRSSK..",
	".KRRRRRRRRSSSK..",
	".KSRRRRRRSSSSK..",
	"..KSSRRRSSSSK...",
	"...KKSSSSSKK....",
	".....KKKKK......",
	"................",
	"................",
	"................",
	"................",
]
const GRASS_TUFT: PackedStringArray = [
	"................",
	"................",
	"................",
	"......Y...y.....",
	"...y..Y..yY..y..",
	"...y.yY..yY.yY..",
	"..yY.yY.YyY.yY..",
	"..yY.yYyYyy.yY..",
	"..yyYyyyYyyyyY..",
	"...yyyyyyyyyy...",
	"....yyyyyyyy....",
	".....yyyyyy.....",
	"................",
	"................",
	"................",
	"................",
]
const WALL: PackedStringArray = [
	"MMMMMMMMMMMMMMMM",
	"MHWWWWWMHWWWWWWM",
	"MWWWWWWMWWWWWWWM",
	"MWWWWWWMWWWWWWWM",
	"MMMMMMMMMMMMMMMM",
	"MHWWWMHWWWWWMHWM",
	"MWWWWMWWWWWWMWWM",
	"MWWWWMWWWWWWMWWM",
	"MMMMMMMMMMMMMMMM",
	"MHWWWWWMHWWWWWWM",
	"MWWWWWWMWWWWWWWM",
	"MWWWWWWMWWWWWWWM",
	"MMMMMMMMMMMMMMMM",
	"MHWWWMHWWWWWMHWM",
	"MWWWWMWWWWWWMWWM",
	"MMMMMMMMMMMMMMMM",
]
const LOG: PackedStringArray = [
	"........",
	".dddddd.",
	"edllllld",
	"eellllld",
	"edllllld",
	".dddddd.",
	"........",
	"........",
]
const DRY_GRASS: PackedStringArray = [
	"........",
	"..q..Q..",
	".qQ.qQ.q",
	".qQ.qQ.q",
	"..qQqQq.",
	"...qqq..",
	"........",
	"........",
]
const FLINT: PackedStringArray = [
	"........",
	"...ff...",
	"..fRRS..",
	".fRRRSS.",
	".RRRRSS.",
	"..RSSS..",
	"...SS...",
	"........",
]
const PLAYER: PackedStringArray = [
	"....hhhh....",
	"...hhhhhh...",
	"...hsssss...",
	"...sksskss..",
	"...ssssss...",
	"....ssss....",
	"...ooooooo..",
	"..sooooooos.",
	"..sooOOooos.",
	"...ooooooo..",
	"...ooooooo..",
	"...pppppp...",
	"...pppppp...",
	"...pp..pp...",
	"...kk..kk...",
	"............",
]
const ZOMBIE: PackedStringArray = [
	"....ZZZZ....",
	"...ZzzzzZ...",
	"...zzzzzz...",
	"...zxzzxz...",
	"...zzzzzz...",
	"....zZZz....",
	"...uuuuuuu..",
	"..zuuuuuuuz.",
	"..zuuZuuuzz.",
	"...uuuuuu...",
	"...uuZuuu...",
	"...PPPPPP...",
	"...PPPPPP...",
	"...PP..PP...",
	"...ZZ..ZZ...",
	"............",
]
const CAMPFIRE: PackedStringArray = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"..........RRR......RRR..........",
	".........RrrRS....RrrRS.........",
	".........RRRSS....RRRSS.........",
	"....RRR...SSS......SSS...RRR....",
	"...RrrRS.......ddd......RrrRS...",
	"...RRRSS....ddddlllddd..RRRSS...",
	"....SSS...ddlllllllllldd.SSS....",
	".........ddlllllllllllldd.......",
	"........edllllllllllllllde......",
	"........eelllldddddllllee.......",
	".........ddddd.....ddddd........",
	"....RRR..................RRR....",
	"...RrrRS....RRR...RRR...RrrRS...",
	"...RRRSS...RrrRS.RrrRS..RRRSS...",
	"....SSS....RRRSS.RRRSS...SSS....",
	"............SSS...SSS...........",
	"................................",
	"................................",
]


func _init() -> void:
	_save_sheet("res://assets/sprites/ground.png", [GRASS_FLOOR, DIRT_FLOOR])
	_save_sheet("res://assets/sprites/blocks.png", [TREE, ROCK, GRASS_TUFT, WALL])
	_save_sheet("res://assets/sprites/items.png", [LOG, DRY_GRASS, FLINT])
	_save_sheet("res://assets/sprites/player.png", [PLAYER])
	_save_sheet("res://assets/sprites/zombie.png", [ZOMBIE])
	_save_sheet("res://assets/sprites/campfire.png", [CAMPFIRE])
	quit()


func _save_sheet(path: String, patterns: Array[PackedStringArray]) -> void:
	var height := patterns[0].size()
	var width := patterns[0][0].length()
	var image := Image.create_empty(width * patterns.size(), height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for index in patterns.size():
		var pattern := patterns[index]
		for y in height:
			for x in width:
				var key := pattern[y][x]
				if key != ".":
					image.set_pixel(index * width + x, y, PALETTE[key])
	image.save_png(path)
	print("saved ", path)
