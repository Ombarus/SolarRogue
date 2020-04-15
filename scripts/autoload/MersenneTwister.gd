extends Node

const GENERATOR_ARRAY_SIZE : int = 623
const RNG_MAX = 0xFFFFFFFF

var _generator := PoolIntArray()
var _index : int = 0

class GeneratorState:
	var cur_generator = PoolIntArray()
	var cur_index = 0
	
	func _init(gen, i):
		cur_generator = str2var(var2str(gen))
		cur_index = i
		
func _ready():
	_generator.resize(GENERATOR_ARRAY_SIZE)
	randomize_seed()
	#set_seed(3176250367)
	
	#RUN_TEST()
		
func RUN_TEST():
	print("--- TEST RNG ---")
	var x : int
	var y : int
	for i in range(1000):
		#randomize_seed()
		x = rand(80)
		y = rand(80)
		print("%d,%d" % [x,y])
	print("----------------")
	
func randomize_seed():
	randomize()
	var s : int = int(randf() * RNG_MAX)
	print("SEED : %d" % s)
	set_non_critical_seed(s)
	set_seed(s)
	return s
	
func set_seed(newSeed : int):
	seed( newSeed )
	
	_index = 0
	_generator[0] = newSeed
	for i in range(1, GENERATOR_ARRAY_SIZE):
		_generator[i] = _cap(0x6c078965 * (_cap(_generator[i-1] ^ (_cap(_generator[i-1] >> 30)))) + i); # 0x6c078965

func set_non_critical_seed(newSeed):
	seed( newSeed )
	
func reset_to_state(newState):
	_generator = str2var(var2str(newState.cur_generator))
	_index = newState.cur_index
	
func get_current_state():
	return GeneratorState.new(_generator, _index)
	
var first_ten = 0
	
func rand(upper : int, is_critical:=true) -> int:
	if upper <= 1:
		return 0
	
	if not is_critical:
		return int(randf() * upper)
		
	if _index == 0:
		_generate_numbers()
		
	var y : int = _generator[_index]
	y = _cap(y ^ (_cap(y << 11)))
	y = _cap(y ^ ((y << 7) & 0x9d2c5680)); # these weird numbers are part of a Mersenne Prime (hence the name of the RNG)
	y = _cap(y ^ ((_cap(y << 15)) & 0xefc60000));
	y = _cap(y ^ (_cap(y >> 18)));
	
	_index = (_index + 1) % GENERATOR_ARRAY_SIZE
	
	#if first_ten < 10:
	#	#print(y)
	#	first_ten += 1
	#	var myprint := "y = %d, RNG_MAX = %d, upper = %d, RNG_MAX / upper + 1 = %d, result = %d" % [y, RNG_MAX, upper, RNG_MAX / upper + 1, y / (RNG_MAX / upper + 1)]
	#	print(myprint)
		
	y = y / (RNG_MAX / upper + 1)
	
		
	return int(y)
	
func rand_float():
	return float(rand(10000000, true) / float(10000000))
	
func _generate_numbers():
	for i in range(0, GENERATOR_ARRAY_SIZE):
		var y : int = (_generator[i] & 0x80000000) + \
			(_generator[(i + 1) % GENERATOR_ARRAY_SIZE] & 0x7fffffff)
		_generator[i] = _cap(_generator[(i + 397) % GENERATOR_ARRAY_SIZE] ^ (y >> 1))
		if y % 2 != 0:
			_generator[i] = _cap(_generator[i] ^ (0x9908b0df))
	
func _cap(v : int) -> int:
	return v & RNG_MAX
