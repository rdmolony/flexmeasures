apt-get install jq # for parsing JSON


flexmeasures db-ops reset


flexmeasures add account --name "powerscopeit"


flexmeasures add user --username rowan --email rowan@powerscopeit.com --account-id 1 --roles=admin


flexmeasures add initial-structure


# Globals
# -------

START=2023-01-01T00:00:00+00:00
DURATION=PT24H


# Authenticate
# ------------
TOKEN=$(curl \
  --header "Content-Type: application/json" \
  --data '
  {
    "email": "rowan@powerscopeit.com",
    "password": "123"
  }' \
  http://localhost:5000/api/requestAuthToken \
  | jq '.auth_token' \
  | sed 's|"||g' \
  )


# Create Assets
# -------------

flexmeasures show asset-types

flexmeasures add asset-type --name "site"

# Asset = Site
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Site",
    "generic_asset_type_id": 8,
    "account_id": 1,
    "latitude": 53.3498,
    "longitude": 6.2603
  }' \
  http://localhost:5000/api/v3_0/assets

# Asset = Building
# Parent = Site
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Building",
    "generic_asset_type_id": 6,
    "account_id": 1,
    "parent_asset_id": 1,
    "latitude": 53.3498,
    "longitude": 6.2603
  }' \
  http://localhost:5000/api/v3_0/assets

# Asset = Solar
# Parent = Building
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Solar",
    "generic_asset_type_id": 1,
    "account_id": 1,
    "parent_asset_id": 2,
    "latitude": 53.3498,
    "longitude": 6.2603
  }' \
  http://localhost:5000/api/v3_0/assets

# Asset = Battery
# Parent = Building
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Battery",
    "generic_asset_type_id": 5,
    "account_id": 1,
    "parent_asset_id": 2,
    "latitude": 53.3498,
    "longitude": 6.2603,
    "attributes": "{\"capacity_in_mw\": 1.5, \"min_soc_in_mwh\": 0.15, \"max_soc_in_mwh\": 1.35}"
  }' \
  http://localhost:5000/api/v3_0/assets


# Create Sensors
# --------------

# Sensor = ElectricityPrices
# Asset = Site
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
      "name": "price",
      "unit": "EUR/MWh",
      "generic_asset_id": 1
  }' \
  http://localhost:5000/api/v3_0/sensors

# Sensor = BuildingDemand
# Asset = Building
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "power",
    "event_resolution": "PT24H",
    "unit": "MW",
    "generic_asset_id": 2
  }' \
  http://localhost:5000/api/v3_0/sensors

# Sensor = SolarGeneration
# Asset = Solar
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "power",
    "event_resolution": "PT24H",
    "unit": "MW",
    "generic_asset_id": 3
  }' \
  http://localhost:5000/api/v3_0/sensors

# Sensor = BatteryDischarge
# Asset = Battery
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
      "name": "discharging",
      "event_resolution": "PT24H",
      "unit": "MW",
      "generic_asset_id": 1,
      "event_resolution": "P1D"
  }' \
  http://localhost:5000/api/v3_0/sensors


# Create DataSource
# -----------------

# Sensor = ElectricityPrices
flexmeasures add beliefs ./fixed_price_feed_in.csv --sensor 1 --source rowan --unit EUR/MWh --timezone Europe/Dublin
# Plot ->
flexmeasures show beliefs --sensor 1 --start $START --duration $DURATION

# Sensor = BuildingDemand
flexmeasures add beliefs ./demand.csv --sensor 2 --source rowan --unit MW --timezone Europe/Dublin 
# Plot ->
flexmeasures show beliefs --sensor 2 --start $START --duration $DURATION

# Sensor = SolarGeneration
flexmeasures add beliefs ./mean_solar.csv --sensor 3 --source rowan --unit MW --timezone Europe/Dublin 
# Plot ->
flexmeasures show beliefs --sensor 3 --start $START --duration $DURATION