extends Node2D


func reroute_mrsu():
	var rsus = get_tree().get_nodes_in_group("rsu")
	var mrsus = get_tree().get_nodes_in_group("vehicle_rsu")
	
	var _range = []
	for rsu:RSU in rsus:
		#if rsu.network_manager
		var count_active = rsu.count_active()
		_range.append([rsu, count_active])
	
	_range.sort_custom(_sort_rsu_by_connections)
	
	
	for rsu_amount in _range:
		var rsu = rsu_amount[0]
		var amount = rsu_amount[1]
		#
		#for mrsu:VehicleRSU in mrsus:
			#mrsu.get_summed_path_weight()
		if len(mrsus) == 0:
			return
			
		var mrsu: VehicleRSU = get_closest_mrsu(rsu, mrsus)
		mrsus.erase(mrsu)
		mrsu.move_to_node(rsu)
	

func get_closest_mrsu(node, mrsus):
	
	if len(mrsus) == 0:
		return
	
	
	var closest_mrsu:VehicleRSU = mrsus[0]
	var closest = closest_mrsu.get_summed_path_weight(closest_mrsu.get_my_path_to_node(node))
	
	for mrsu: VehicleRSU in mrsus:
		var possible = closest_mrsu.get_summed_path_weight(closest_mrsu.get_my_path_to_node(node))
		if closest > possible:
			closest_mrsu = mrsu
			closest = possible
	
	return closest_mrsu
	

func _sort_rsu_by_connections(a, b) -> int:
	return b[1] > a[1]  # Сортировка в порядке убывания
	

func _on_timer_timeout() -> void:
	reroute_mrsu()
