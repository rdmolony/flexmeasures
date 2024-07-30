# Globals
# -------

START=2023-01-01T00:00:00+00:00
DURATION=P7D # 7 Days

BATTERY_ID=3
FEED_IN_PRICE_ID=1
FEED_OUT_PRICE_ID=2
SOLAR_ID=4

FEED_IN_PRICE_EUR_PER_MWH=./data/fixed_price_feed_in.csv
FEED_OUT_PRICE_EUR_PER_MWH=./data/fixed_price_feed_out.csv
SOLAR_MW=./data/mean_solar.csv


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

# Sensor = FeedOutElectricityPrices
flexmeasures add beliefs $FEED_OUT_PRICE_EUR_PER_MWH \
  --sensor $FEED_OUT_PRICE_ID \
  --source rowan \
  --unit EUR/MWh \
  --timezone Europe/Dublin \
  --do-not-resample \
  --date-format "%d/%m/%Y %H:%M"
# Plot ->
flexmeasures show beliefs \
  --sensor $FEED_OUT_PRICE_ID \
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
