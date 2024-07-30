# Globals
# -------

START=2023-01-01T00:00:00+00:00
DURATION=P7D # 7 Days

BATTERY_ID=3
FEED_IN_PRICE_ID=1
FEED_OUT_PRICE_ID=2
SOLAR_ID=4

SITE_POWER_CAPACITY_MW=1.5
SITE_PRODUCTION_CAPACITY_MW=0
SITE_CONSUMPTION_CAPACITY_MW=1.1
ROUNDTRIP_EFFICIENCY=90%
INITIAL_SOC=10%

BATTERY_CAPACITY_MW=0.5
BATTERY_MIN_SOC_MWH=1.35 # = 10% * 1.5MWh
BATTERY_MAX_SOC_MWH=0.15 # = 90% * 1.5MWh


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

CONTENT=$(jq \
  --arg capacity 1.35 \
  --arg min $BATTERY_MIN_SOC_MWH \
  --arg max $BATTERY_MAX_SOC_MWH \
  -n '{capacity_in_mw: $capacity|tonumber, min_soc_in_mwh: $min|tonumber, max_soc_in_mwh: $max|tonumber}'
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
  "http://localhost:5000/api/v3_0/assets/$BATTERY_ID"


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
