apt-get install jq # for parsing JSON


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


# Globals
# -------

START=2023-01-01T00:00:00+00:00
DURATION=P7D # 7 Days


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

# Asset = Building
curl \
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
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
    "name": "Battery",
    "generic_asset_type_id": 5,
    "account_id": 1,
    "parent_asset_id": 1,
    "latitude": 53.3498,
    "longitude": 6.2603,
    "attributes": "{\"capacity_in_mw\": 1.5, \"min_soc_in_mwh\": 0.15, \"max_soc_in_mwh\": 1.35}"
  }' \
  http://localhost:5000/api/v3_0/assets


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

# Sensor = ElectricityPrices
# Asset = TransmissionZone
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data '
  {
      "name": "night/day tarriff",
      "event_resolution": "PT15M",
      "unit": "EUR/MWh",
      "generic_asset_id": 4
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
      "event_resolution": "PT15M",
      "unit": "MW",
      "generic_asset_id": 3
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
    "event_resolution": "PT15M",
    "unit": "MW",
    "generic_asset_id": 2
  }' \
  http://localhost:5000/api/v3_0/sensors

# # Sensor = BuildingDemand
# # Asset = Building
# curl \
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


# Create DataSource
# -----------------

# Sensor = ElectricityPrices
flexmeasures add beliefs ./fixed_price_feed_in.csv \
  --sensor 1 \
  --source rowan \
  --unit EUR/MWh \
  --timezone Europe/Dublin \
  --do-not-resample \
  --date-format "%d/%m/%Y %H:%M"
# Plot ->
flexmeasures show beliefs \
  --sensor 1 \
  --start $START \
  --duration $DURATION

# Sensor = SolarGeneration
flexmeasures add beliefs ./mean_solar.csv \
  --sensor 3 \
  --source rowan \
  --unit MW \
  --timezone Europe/Dublin \
  --do-not-resample \
  --date-format "%d/%m/%Y %H:%M"
# Plot ->
flexmeasures show beliefs \
  --sensor 3 \
  --start $START \
  --duration $DURATION

# # Sensor = BuildingDemand
# flexmeasures add beliefs ./demand.csv \
#   --sensor 4 \
#   --source rowan \
#   --unit MW \
#   --timezone Europe/Dublin \
#   --do-not-resample \
#   --date-format "%d/%m/%Y %H:%M"
# # Plot ->
# flexmeasures show beliefs \
#   --sensor 2 \
#   --start $START \
#   --duration $DURATION


# Schedule the Battery
# --------------------

# --consumption-price-sensor = ElectricityPrices
# --inflexible-device-sensor = SolarGeneration
flexmeasures add schedule for-storage \
    --sensor 2 \
    --consumption-price-sensor 1 \
    --inflexible-device-sensor 3 \
    --start $START \
    --duration $DURATION \
    --soc-at-start 50% \
    --roundtrip-efficiency 90%
# Plot ->
flexmeasures show beliefs \
  --sensor 2 \
  --start $START \
  --duration $DURATION
