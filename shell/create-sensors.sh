# Install
# -------

apt-get install jq # for parsing JSON


# Create Initial Database Structure
# ---------------------------------

flexmeasures db-ops reset


flexmeasures add account \
  --name "powerscopeit"


flexmeasures add user \
  --username rowan \
  --email rowan@powerscopeit.com \
  --account 1 \
  --timezone "Europe/Dublin" \
  --roles=admin


flexmeasures add initial-structure


# Authenticate
# ------------
TOKEN=$(curl \
  --request POST \
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

# Asset = Building
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Building",
    "generic_asset_type_id": 6,
    "account_id": 1,
    "latitude": 53.3498,
    "longitude": 6.2603
  }' \
  http://localhost:5000/api/v3_0/assets

# Asset = Solar
# Parent = Building
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Solar",
    "generic_asset_type_id": 1,
    "account_id": 1,
    "parent_asset_id": 1,
    "latitude": 53.3498,
    "longitude": 6.2603
  }' \
  http://localhost:5000/api/v3_0/assets

# Asset = Battery
# Parent = Building
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Battery",
    "generic_asset_type_id": 5,
    "account_id": 1,
    "parent_asset_id": 1,
    "latitude": 53.3498,
    "longitude": 6.2603
  }' \
  http://localhost:5000/api/v3_0/assets

# ********************************************************************
# capacity_in_mw is passed as a parameter to the battery schedule ...
# 
# min_soc_in_mwh
# ... on the Battery Sensor we're passing them instead as parameters
# to the schedule run!
# ********************************************************************


# Create TransmissionZone Asset
# -----------------------------

# ********************************************************************
# FlexMeasures doesn't ship with a 'TransmissionZone' Asset by default
# ********************************************************************

flexmeasures add asset-type \
  --name "name" \
  --description "A grid regulated & balanced as a whole, usually a national grid."

flexmeasures add asset \
  --name "IRL transmission zone" \
  --asset-type 8


# Create Sensors
# --------------

# ************************************************
# event_resolution = time interval between beliefs
# PT1H = hourly 
# ************************************************

# Sensor = FeedInElectricityPrices
# Asset = TransmissionZone
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
      "name": "feed-in price",
      "event_resolution": "PT15M",
      "unit": "EUR/MWh",
      "generic_asset_id": 4
  }' \
  http://localhost:5000/api/v3_0/sensors

# Sensor = FeedOutElectricityPrices
# Asset = TransmissionZone
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
      "name": "feed-out price",
      "event_resolution": "PT15M",
      "unit": "EUR/MWh",
      "generic_asset_id": 4
  }' \
  http://localhost:5000/api/v3_0/sensors

# Sensor = BatteryDischarge
# Asset = Battery
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
      "name": "discharging",
      "event_resolution": "PT15M",
      "unit": "MW",
      "generic_asset_id": 3
  }' \
  http://localhost:5000/api/v3_0/sensors

# Sensor = SolarGeneration
# Asset = Solar
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "power",
    "event_resolution": "PT15M",
    "unit": "MW",
    "generic_asset_id": 2
  }' \
  http://localhost:5000/api/v3_0/sensors

# # Sensor = BuildingDemand
# # Asset = Building
# curl \
#   --request POST \
#   --header "Content-Type: application/json" \
#   --header "Authorization: $TOKEN" \
#   --data '
#   {
#     "name": "power",
#     "event_resolution": "PT15M",
#     "unit": "MW",
#     "generic_asset_id": 1
#   }' \
#   http://localhost:5000/api/v3_0/sensors

