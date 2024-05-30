# VANET

This is an introductory guide to the "VANET" program.

## Download
Go to the [releases page](https://github.com/quanuhs/VANET/releases) and download the compiled version.
Inside the respective .zip archive, you will find a file called "VANET.exe".
Extract the file to your preferred location and open it.

## Usage
### Interacting with the Map
While in VANET.exe, you can use your mouse scroll on the map area to **ZOOM IN** or **ZOOM OUT**.
Use the arrow keys (left or right) to change the drawable tile. There are five tiles:
1. ![bicycle sign](https://github.com/quanuhs/VANET/assets/37934662/67612bb4-2558-4a5f-8c59-238d1e5ecdca) - Represents the place where vehicles will spawn.
2. ![parking sign](https://github.com/quanuhs/VANET/assets/37934662/c3e95272-de7d-4158-b6f5-57d5b0baedf4) - Represents the place where vehicles will reach their final destination.
3. ![blue box](https://github.com/quanuhs/VANET/assets/37934662/ae4a965f-f2c3-4ed1-8d9d-83947293ff51) - Represents the RSU (Roadside Unit).
4. <img width="67" alt="orange_box" src="https://github.com/quanuhs/VANET/assets/37934662/08c368c0-9343-4b0e-ba2b-0ac06db6ee39"> - Represents unoptimal RSUs (Roadside Units).
5. ![gray tile](https://github.com/quanuhs/VANET/assets/37934662/dfd1e4d1-9843-455d-a54b-f97614b94a6e) - Represents the road.


Use the left mouse button to draw tiles.
Use the right mouse button to delete tiles.
Use middle mouse button to move around the map.

### Settings
![top settings panel](https://github.com/quanuhs/VANET/assets/37934662/c00470ff-1293-4c29-bb24-4d395ce3e106)

#### Save results
By clicking on "choose directory", you can select a preferred directory to save .csv files.
Inside the .csv files, you will find information regarding:
1. Vehicles: id, speed, total requests made, unsolved requests.
2. RSUs: id, energy consumption per requests for vehicles, cluster server, total in ms dealing with vehicles, cluster, server.

#### Save/Load configuration
You can save your configuration by clicking on "save" and selecting a preferred directory.
You can load configuration by clicking on "load" and selecting a preferred configuration.
