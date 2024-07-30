# Globals
# -------

START=2023-04-01T00:00:00+00:00
DURATION=P7D # 7 Days

FEED_IN_PRICE_ID=1
SOLAR_ID=2
BATTERY_ID=3

FEED_IN_PRICE_EUR_PER_MWH=./data/fixed_price_feed_out.csv
SOLAR_MW=./data/low_solar.csv

SITE_POWER_CAPACITY_MW=0.25
SITE_PRODUCTION_CAPACITY_MW=0
SITE_CONSUMPTION_CAPACITY_MW=0.25
ROUNDTRIP_EFFICIENCY=90%
INITIAL_SOC=10%

BATTERY_POWER_MW=0.01
BATTERY_ENERGY_MWH=0.01
BATTERY_MIN_SOC_MWH=0.01 # = 10% * BATTERY_ENERGY_MWH
BATTERY_MAX_SOC_MWH=0.01 # = 90% * BATTERY_ENERGY_MWH


# Create DataSource
# -----------------

# Sensor = FeedInElectricityPrices
flexmeasures add beliefs $FEED_IN_PRICE_EUR_PER_MWH \
  --sensor $FEED_IN_PRICE_ID \
  --source rowan \
  --unit EUR/MWh \
  --timezone Europe/Dublin \
  --do-not-resample \
  --date-format "%d/%m/%Y %H:%M"
# Plot ->
flexmeasures show beliefs \
  --sensor $FEED_IN_PRICE_ID \
  --start $START \
  --duration $DURATION

# Sensor = SolarGeneration
flexmeasures add beliefs $SOLAR_MW \
  --sensor $SOLAR_ID \
  --source rowan \
  --unit MW \
  --timezone Europe/Dublin \
  --do-not-resample \
  --date-format "%d/%m/%Y %H:%M"
# Plot ->
flexmeasures show beliefs \
  --sensor $SOLAR_ID \
  --start $START \
  --duration $DURATION


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


# Update Battery SOC
# ------------------

# *********************************************************************
# Set device-level power
# on the Sensor
# https://flexmeasures.readthedocs.io/en/latest/features/scheduling.html
# *********************************************************************

CONTENT=$(jq \
  --arg capacity $BATTERY_POWER_MW \
  --arg min $BATTERY_MIN_SOC_MWH \
  --arg max $BATTERY_MAX_SOC_MWH \
  -n '{max_soc_in_mwh: $max|tonumber}'
)
JSON=$(jq \
  --arg attributes "$CONTENT" \
  -n '{attributes: $attributes}'
)
curl \
  --request PATCH \
  --header "Content-Type: application/json" \
  --header "Authorization: $TOKEN" \
  --data "$JSON" \
  "http://localhost:5000/api/v3_0/sensors/$BATTERY_ID"


# Schedule the Battery
# --------------------

flexmeasures add schedule for-storage \
    --sensor $BATTERY_ID \
    --consumption-price-sensor $FEED_IN_PRICE_ID \
    --inflexible-device-sensor $SOLAR_ID \
    --start $START \
    --duration $DURATION \
    --soc-at-start $INITIAL_SOC \
    --roundtrip-efficiency $ROUNDTRIP_EFFICIENCY 
# Plot ->
flexmeasures show beliefs \
  --sensor $BATTERY_ID \
  --start $START \
  --duration $DURATION
