extends AudioPool

const BUS := &"SFX"
const POOL_SIZE := 16


func _ready() -> void:
	_init_pool(BUS, POOL_SIZE)
