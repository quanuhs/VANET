extends DefaultPlaceElement

#func _after_ready():
	#place_handler.connect("element_placed", self.place_selected)
	#place_handler.connect("element_removed", self.remove)
	#
	#
## Обновляет все соединения между RSU и MEC глобально
#func update_all_rsu_connections():
	## Получаем список всех RSU и MEC в глобальной области
	#var rsu_list = get_tree().get_nodes_in_group("rsu")
	#var mec_list = get_tree().get_nodes_in_group("mec")
	#
	## Сначала отключаем все соединения RSU от MEC
	#for rsu_network: NetworkManager in rsu_list:
		#for mec_network: NetworkManager in mec_list:
			#if rsu_network.has_connection_with_node(mec_network):
				#rsu_network.disconnect_node(mec_network)
				#mec_network.disconnect_node(rsu_network)
#
	## Устанавливаем новые соединения между RSU и MEC
	#for rsu_network: NetworkManager in rsu_list:
		#if not rsu_network.has_connection_with_group("MEC"):
			#var closest_mec = find_closest_mec(rsu_network, mec_list)
			##if closest_mec:
				##rsu_network.connect_to_node(closest_mec, CONFIG["bandwidth"], "MEC")
				##closest_mec.connect_to_node(rsu_network, CONFIG["bandwidth"], "RSU")
#
## Функция для поиска ближайшего MEC к данному RSU
#func find_closest_mec(rsu_network: NetworkManager, mec_list: Array) -> NetworkManager:
	#var closest_mec = null
	#var min_distance = INF  # или другое очень большое значение
#
	#for mec_network: NetworkManager in mec_list:
		#var distance = rsu_network.global_position.distance_to(mec_network.global_position)
		#if distance < min_distance:
			#min_distance = distance
			#closest_mec = mec_network
			#
	#return closest_mec
#
## Функция вызывается при каждом добавлении или удалении RSU с карты
#func on_rsu_added_or_removed():
	#update_all_rsu_connections()
