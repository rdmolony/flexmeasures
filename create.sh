apt-get install jq # for parsing JSON


flexmeasures db-ops reset


flexmeasures add account --name "powerscopeit"


flexmeasures add user --username rowan --email rowan@powerscopeit.com --account-id 1 --roles=admin


flexmeasures add initial-structure


# Authenticate
# ------------
TOKEN=$(curl \
  --header "Content-Type: application/json" \
  --data '
  {
    "email": "rowan@powerscopeit.com",
    "password": "thisisakey"
  }' \
  http://localhost:5000/api/requestAuthToken \
  | jq '.auth_token' \
  | sed 's|"||g' \
  )


# Create Assets
# -------------

flexmeasures show asset-types

flexmeasures add asset-type --name "site"

curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Site",
    "generic_asset_type_id": 8,
    "account_id": 1
  }' \
  http://localhost:5000/api/v3_0/assets

# Parent = Site
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Building",
    "generic_asset_type_id": 6,
    "account_id": 1,
    "parent_asset_id": 1
  }' \
  http://localhost:5000/api/v3_0/assets

# Parent = Building
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Solar",
    "generic_asset_type_id": 1,
    "account_id": 1,
    "parent_asset_id": 2
  }' \
  http://localhost:5000/api/v3_0/assets

# Parent = Building
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Battery",
    "generic_asset_type_id": 5,
    "account_id": 1,
    "parent_asset_id": 2
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
      "event_resolution": "PT24H",
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


# Create DataSource
# -----------------

# Sensor = Solar
flexmeasures add beliefs --sensor 3 --source rowan --unit MW --timezone Europe/Dublin ./24-07-24/demand.csv

flexmeasures add beliefs --sensor 3 --source rowan --unit MW --timezone Europe/Dublin ./24-07-24/solar.csv

flexmeasures add beliefs --sensor 3 --source rowan --unit MW --timezone Europe/Dublin ./24-07-24/demand.csv
