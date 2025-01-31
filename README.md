# ENGLISH
Archive: https://github.com/quanuhs/VANET-old

# VANET 2.0.0
A system for simulating VANET, written in Godot.

**NOTE: THE README DESCRIPTION MAY BE UPDATED**

# Description
This project represents a VANET (Vehicular Ad-hoc Network) simulation system using the Godot game engine and GDScript language. The goal of the project is to simulate the behavior and interaction of vehicles equipped with onboard units (OBU) and roadside infrastructure (RSU) in a virtual environment. The simulation allows for testing various scenarios, such as accident simulation, traffic movement, and data exchange between network elements.

# Overview
The VANET simulation system was developed to study the interaction between vehicles and roadside infrastructure in a controlled environment. It enables analysis of data exchange, traffic management, and VANET network behavior under different conditions.
* Graph-based road network: Uses data from OpenStreetMap (OSM) to create realistic road maps;
* Vehicle simulation (OBU): Vehicles are equipped with onboard devices that interact with RSUs and follow predefined routes;
* Roadside units (RSU): Stationary infrastructure elements that exchange data with vehicles, other RSUs, and MEC;
* Support for various scenarios: Implementation of two primary scenarios for accident simulation and random traffic movement;
* Real-time data exchange: Simulation of message and data transmission between network elements.

# Technologies used
Godot Engine 4.0+ (GdScript)
Python with the osmnx library

# Current functionality
0. File generation. Install the osmnx library, modify the Python code to select the required location, and run the script. 
As output, you will get files describing the graph: "nodes.csv" and "edges.csv". For convenience, these files are also located in the "data" folder.
1. Loading the map. Choose the directory where the files from step 1 are located. **Important:** The directory must have files named "nodes.csv" and "edges.csv".
2. Placing elements. Once the map is loaded, an additional window will open where RSUs and MECs can be placed.
3. Scenario preparation. To prepare a scenario, modify the function in the VehicleSpawner.gd code (test_spawn) and describe the executable scenario, similar to "reroute_platoon()".
4. Running the scenario. Click the "Run" button in the interface of the compiled program.

# Interface and images
![User Interface](https://github.com/user-attachments/assets/1649118e-86c2-4538-bb4d-185dcbe2dd5b)
![Simulation (map) zoom-out](https://github.com/user-attachments/assets/cce73744-e5f1-4687-81b6-e39773452307)
![Simulation (map) zoom-in](https://github.com/user-attachments/assets/b73f5a68-2082-4421-89e8-4cdbeb289b61)

Video recording of utilized resources (compared to veins) can be found in link below:
https://disk.yandex.ru/i/BjgKzyutozigEA
[![Watch the video](https://github.com/user-attachments/assets/f20c95ba-6a7c-43f7-b9be-a82b3257e31d)](https://disk.yandex.ru/i/BjgKzyutozigEA)



Research funded by Russian Science Foundation
Contract number 24-29-00304
https://rscf.ru/en/project/24-29-00304


---
---
---

# RUSSIAN
Архив: https://github.com/quanuhs/VANET-old

# VANET 2.0.0
Система для моделирования VANET, написанная на Godot.

**ОБРАТИТЕ ВНИМАНИЕ: ОПИСАНИЕ README МОЖЕТ ДОПОЛНЯТЬСЯ**

# Описание
Данный проект представляет собой систему моделирования VANET (Vehicular Ad-hoc Network) с использованием игрового движка Godot и языка GDScript. Цель проекта – смоделировать поведение и взаимодействие транспортных средств, оснащенных бортовыми устройствами (OBU), и придорожной инфраструктуры (RSU) в виртуальной среде. Симуляция позволяет тестировать различные сценарии, такие как моделирование аварий, движение трафика и обмен данными между элементами сети.

# Краткий обзор
Система моделирования VANET была разработана для изучения взаимодействия между транспортными средствами и придорожной инфраструктурой в контролируемой среде. Она позволяет анализировать обмен данными, управление трафиком и поведение сети VANET в различных условиях.
* Сеть дорог на основе графа: Использование данных из OpenStreetMap (OSM) для создания реалистичных карт дорог;
* Моделирование транспортных средств (OBU): Транспортные средства оснащены бортовыми устройствами, которые взаимодействуют с RSU и следуют по заданным маршрутам;
* Придорожные устройства (RSU): Стационарные элементы инфраструктуры, которые обмениваются данными с транспортными средствами, другими RSU и MEC;
* Поддержка различных сценариев: Реализация двух основных сценариев для моделирования аварий и случайного движения трафика;
* Обмен данными в реальном времени: Моделирование передачи сообщений и данных между элементами сети.

# Используемые технологии
Godot Engine 4.0+ (GdScript)
Python с библиотекой osmnx


# Текущий функционал
0. Генерация файлов. Установите библиотеку osmnx, модифицируйте Python код, чтобы выбрать необходимую локацию и запустите скрипт.
На выходе, получатся файлы, описывающие граф: "nodes.csv" и "edges.csv". Для упрощения, эти файлы также находятся в папке "data".
1. Загрузка карты. Выберите директорию, где находятся файлы из пункта 1. **Важно:** директория должна иметь файлы с названиями: "nodes.csv", "edges.csv".
2. Расстановка элементов. После того как карта загружена, откроется дополнительное окно, в котором можно расставить RSU и MEC.
3. Подготовка сценария. Для подготовки сценария, необходимо модифицировать функцию в коде VehicleSpawner.gd (test_spawn) и описать исполняемый сценарий, по аналогии с "reroute_platoon()"
4. Запуск сценария. Нажмите на кнопку "Запустить" в интерфейсе скомпилированной программы.

# Интерфейс и изображения
![Интерфейс пользователя](https://github.com/user-attachments/assets/1649118e-86c2-4538-bb4d-185dcbe2dd5b)
![Моделирование (карта) zoom-out](https://github.com/user-attachments/assets/cce73744-e5f1-4687-81b6-e39773452307)
![Моделирование (карта) zoom-in](https://github.com/user-attachments/assets/b73f5a68-2082-4421-89e8-4cdbeb289b61)


Видеозапись потребляемых ресурсов, сравнение с Veins, доступно по ссылке:
https://disk.yandex.ru/i/BjgKzyutozigEA
[![Смотреть видео](https://github.com/user-attachments/assets/f20c95ba-6a7c-43f7-b9be-a82b3257e31d)](https://disk.yandex.ru/i/BjgKzyutozigEA)


Работа выполнена при финансовой поддержке Российского научного фонда по гранту No 24-29-00304
https://rscf.ru/en/project/24-29-00304/
