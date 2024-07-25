flexmeasures db-ops reset


# Setup
# -----

flexmeasures add toy-account --kind battery

TOMORROW=$(date --date="next day" '+%Y-%m-%d')
echo "Hour,Price
${TOMORROW}T00:00:00,10
${TOMORROW}T01:00:00,11
${TOMORROW}T02:00:00,12
${TOMORROW}T03:00:00,15
${TOMORROW}T04:00:00,18
${TOMORROW}T05:00:00,17
${TOMORROW}T06:00:00,10.5
${TOMORROW}T07:00:00,9
${TOMORROW}T08:00:00,9.5
${TOMORROW}T09:00:00,9
${TOMORROW}T10:00:00,8.5
${TOMORROW}T11:00:00,10
${TOMORROW}T12:00:00,8
${TOMORROW}T13:00:00,5
${TOMORROW}T14:00:00,4
${TOMORROW}T15:00:00,4
${TOMORROW}T16:00:00,5.5
${TOMORROW}T17:00:00,8
${TOMORROW}T18:00:00,12
${TOMORROW}T19:00:00,13
${TOMORROW}T20:00:00,14
${TOMORROW}T21:00:00,12.5
${TOMORROW}T22:00:00,10
${TOMORROW}T23:00:00,7" > prices-tomorrow.csv

flexmeasures add beliefs --sensor 1 --source toy-user prices-tomorrow.csv --timezone Europe/Amsterdam

flexmeasures show beliefs --sensor 1 --start ${TOMORROW}T00:00:00+01:00 --duration PT24H


# Schedule a Battery
# ------------------

flexmeasures add schedule for-storage --sensor 2 --consumption-price-sensor 1 \
    --start ${TOMORROW}T07:00+01:00 --duration PT12H \
    --soc-at-start 50% --roundtrip-efficiency 90%

flexmeasures show beliefs --sensor 2 --start ${TOMORROW}T07:00:00+01:00 --duration PT12H


# Schedule a Battery with Solar
# -----------------------------

export TOMORROW=$(date --date="next day" '+%Y-%m-%d')
echo "Hour,Price
${TOMORROW}T00:00:00,0.0
${TOMORROW}T01:00:00,0.0
${TOMORROW}T02:00:00,0.0
${TOMORROW}T03:00:00,0.0
${TOMORROW}T04:00:00,0.01
${TOMORROW}T05:00:00,0.03
${TOMORROW}T06:00:00,0.06
${TOMORROW}T07:00:00,0.1
${TOMORROW}T08:00:00,0.14
${TOMORROW}T09:00:00,0.17
${TOMORROW}T10:00:00,0.19
${TOMORROW}T11:00:00,0.21
${TOMORROW}T12:00:00,0.22
${TOMORROW}T13:00:00,0.21
${TOMORROW}T14:00:00,0.19
${TOMORROW}T15:00:00,0.17
${TOMORROW}T16:00:00,0.14
${TOMORROW}T17:00:00,0.1
${TOMORROW}T18:00:00,0.06
${TOMORROW}T19:00:00,0.03
${TOMORROW}T20:00:00,0.01
${TOMORROW}T21:00:00,0.0
${TOMORROW}T22:00:00,0.0
${TOMORROW}T23:00:00,0.0" > solar-tomorrow.csv

flexmeasures add source --name "toy-forecaster" --type forecaster
flexmeasures add beliefs --sensor 3 --source 4 solar-tomorrow.csv --timezone Europe/Amsterdam

flexmeasures add schedule for-storage --sensor 2 --consumption-price-sensor 1 \
    --inflexible-device-sensor 3 \
    --start ${TOMORROW}T07:00+02:00 --duration PT12H \
    --soc-at-start 50% --roundtrip-efficiency 90%

flexmeasures show beliefs --sensor 2 --start ${TOMORROW}T07:00:00+01:00 --duration PT12H


# Compute a Report
# ----------------

flexmeasures add toy-account --kind reporter

TOMORROW=$(date --date="next day" '+%Y-%m-%d')
flexmeasures show beliefs --sensor 7 --start ${TOMORROW}T00:00:00+02:00 --duration PT24H --resolution PT1H

flexmeasures show data-sources --show-attributes --id 6

echo "
{
   'weights' : {
       'grid connection capacity' : 1.0,
       'PV' : -1.0,
   }
}" > headroom-config.json

echo "
{
    'input' : [{'name' : 'grid connection capacity','sensor' : 7},
               {'name' : 'PV', 'sensor' : 3}],
    'output' : [{'sensor' : 8}]
}" > headroom-parameters.json

flexmeasures add report --reporter AggregatorReporter \
   --parameters headroom-parameters.json --config headroom-config.json \
   --start-offset DB,1D --end-offset DB,2D \
   --resolution PT15M
