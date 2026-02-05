#!/bin/bash
CLICKHOUSE_HOST="localhost"
CLICKHOUSE_PORT="8123"
DB_NAME="demo"
TABLE_NAME="readings_local"

echo "Generating 10k VALID rows..."

FILE="data.csv"
> $FILE

for i in {1..10000}; do
  HOUR=$(printf "%02d" $(( (i / 3600) % 24 )))
  MIN=$(printf "%02d" $(( (i / 60) % 60 )))
  SEC=$(printf "%02d" $(( i % 60 )))
  TS="2026-02-05 ${HOUR}:${MIN}:${SEC}"
  SID=$(( (i % 100) + 1 ))
  TEMP=$(printf "25.%02d" $((i % 100)))
  HUM=$(printf "45.%02d" $((i % 100)))
  echo "$TS,$SID,$TEMP,$HUM" >> $FILE
done

echo "Inserting $(wc -l < $FILE) rows..."
curl -s -X POST "http://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/?query=INSERT%20INTO%20$DB_NAME.$TABLE_NAME%20FORMAT%20CSV" --data-binary @$FILE

echo "Row count:"
curl -s "http://$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/?query=SELECT%20count()%20FROM%20$DB_NAME.$TABLE_NAME"

rm $FILE
echo "✅ COMPLETE!"

