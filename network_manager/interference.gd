extends Node
class_name Interference

const speed_of_light = 3e8  # м/с

# Функция для расчёта логарифма по основанию 10
func log10(value: float) -> float:
	return log(value) / log(10)

# Модель Лосево для расчёта затухания
func calculate_log_distance_path_loss(distance: float, frequency: float, path_loss_exponent: float = 3.5, reference_distance: float = 1.0) -> float:
	var wavelength = speed_of_light / frequency
	# Потери на референсном расстоянии (например, на 1 метр)
	var free_space_path_loss_ref = (4.0 * PI * reference_distance / wavelength)
	var path_loss_ref_db = 20.0 * log10(free_space_path_loss_ref)
	
	# Потери с учётом расстояния
	var path_loss_db = path_loss_ref_db + 10 * path_loss_exponent * log10(distance / reference_distance)
	return path_loss_db

# Функция для учёта интерференции
func calculate_interference(noise_figure: float) -> float:
	# Возвращаем случайное значение в диапазоне [0, noise_figure]
	return randf_range(0.0, noise_figure)

# Общая функция для расчёта уровня сигнала
func calculate_received_power(distance: float, transmit_power_dbm: float, frequency: float, noise_figure: float, path_loss_exponent: float = 3.5, reference_distance: float = 1.0) -> float:
	var path_loss = calculate_log_distance_path_loss(distance, frequency, path_loss_exponent, reference_distance)
	var interference = calculate_interference(noise_figure)
	
	# Вычисляем мощность на приёмнике (в дБм)
	var received_power_dbm = transmit_power_dbm - path_loss - interference
	return received_power_dbm
