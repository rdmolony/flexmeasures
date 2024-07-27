# Globals
# -------

START=2023-01-01T00:00:00+00:00
DURATION=P7D # 7 Days

BATTERY_CAPACITY_MW=0.5
BATTERY_MIN_SOC_MWH=0.15 # = 10% * 1.5MWh
BATTERY_MAX_SOC_MWH=1.35 # = 90% * 1.5MWh
FEED_IN_PRICE_EUR_PER_MWH=./fixed_price_feed_in.csv
FEED_OUT_PRICE_EUR_PER_MWH=./fixed_price_feed_out.csv
SOLAR_MW=./mean_solar.csv


# Create DataSource
# -----------------

# Sensor = FeedInElectricityPrices
flexmeasures add beliefs $FEED_IN_PRICE_EUR_PER_MWH \
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

# Sensor = FeedOutElectricityPrices
flexmeasures add beliefs $FEED_OUT_PRICE_EUR_PER_MWH \
  --sensor 2 \
  --source rowan \
  --unit EUR/MWh \
  --timezone Europe/Dublin \
  --do-not-resample \
  --date-format "%d/%m/%Y %H:%M"
# Plot ->
flexmeasures show beliefs \
  --sensor 2 \
  --start $START \
  --duration $DURATION

# Sensor = SolarGeneration
flexmeasures add beliefs $SOLAR_MW \
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


# Schedule the Battery
# --------------------

# --consumption-price-sensor = FeedInElectricityPrices
# --production-price-sensor = FeedOutElectricityPrices
# --inflexible-device-sensor = SolarGeneration
flexmeasures add schedule for-storage \
    --sensor 2 \
    --consumption-price-sensor 1 \
    --production-price-sensor 2 \
    --inflexible-device-sensor 3 \
    --site-power-capacity $BATTERY_CAPACITY_MW \
    --soc-min $BATTERY_SOC_MIN_MWH \
    --soc-max $BATTERY_SOC_MAX_MWH \
    --start $START \
    --duration $DURATION \
    --soc-at-start 50% \
    --roundtrip-efficiency 90%
# Plot ->
flexmeasures show beliefs \
  --sensor 2 \
  --start $START \
  --duration $DURATION
