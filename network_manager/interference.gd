extends Node
class_name Interference

const speed_of_light = 3e8  # м/с

# Константы 3GPP
const FREQUENCY_GHZ = 5.9  # Частота (ГГц), например, для V2X
const HEIGHT_UT = 1.5  # Высота устройства в метрах (автомобиль)
const HEIGHT_RS = 10.0  # Высота RSU в метрах (дорожная инфраструктура)

# Функция для расчёта логарифма по основанию 10
func log10(value: float) -> float:
	return log(value) / log(10)

# Модель затухания 3GPP для прямой видимости (LOS)
func calculate_3gpp_path_loss_los(distance: float, frequency_ghz: float = FREQUENCY_GHZ) -> float:
	return 32.4 + 21.0 * log10(distance) + 20.0 * log10(frequency_ghz)


# Модель затухания 3GPP для непрямой видимости (NLOS)
func calculate_3gpp_path_loss_nlos(distance: float, frequency_ghz: float = FREQUENCY_GHZ, height_ut: float = HEIGHT_UT, height_rs: float = HEIGHT_RS) -> float:
	# Прямая видимость (LOS)
	var los_path_loss = calculate_3gpp_path_loss_los(distance, frequency_ghz)
	# Дополнительные потери из-за зданий в городской среде (примерный коэффициент)
	var additional_loss = 23.0  # Значение для UMi-Street Canyon
	return los_path_loss + additional_loss


# Функция для учёта интерференции
func calculate_interference(noise_figure: float) -> float:
	# Возвращаем случайное значение в диапазоне [0, noise_figure]
	return randf_range(0.0, noise_figure)


# Общая функция для расчёта уровня сигнала
func calculate_received_power(
		distance: float,
		transmit_power_dbm: float,
		frequency_ghz: float = FREQUENCY_GHZ,
		noise_figure: float = 0.0,  # Шумовая фигура в дБ
	) -> float:
	# Рассчитываем затухание по 3GPP
	var path_loss = calculate_3gpp_path_loss_los(distance, FREQUENCY_GHZ)
	
	# Учитываем интерференцию
	var interference = calculate_interference(noise_figure)
	
	# Вычисляем мощность на приёмнике (в дБм)
	var received_power_dbm = transmit_power_dbm - path_loss - interference
	return received_power_dbm

# Рассчёт радиуса покрытия
func calculate_coverage_radius(
		transmit_power_dbm: float,
		min_received_power_dbm: float,
		frequency_ghz: float = 5.9,
		los: bool = true,
		nlos_additional_loss: float = 23.0
	) -> float:
	var path_loss = transmit_power_dbm - min_received_power_dbm
	if not los:
		path_loss -= nlos_additional_loss  # Добавляем дополнительные потери для NLOS
	
	# Вычисляем расстояние
	var distance = pow(10, (path_loss - 32.4 - 20.0 * log10(frequency_ghz)) / 20.0) / 2
	return distance
