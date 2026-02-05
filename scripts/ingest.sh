#!/bin/bash

set -e

HOST="localhost"
PORT="8123"
DB="demo"
TABLE="readings_local"

echo "Generating test data..."

cat > data.csv << 'EOF'
EOF

for i in {1..10000}; do
  if [[ "$OSTYPE" == "darwin"* ]]; then
    ts=$(date -v-$((RANDOM % 86400))S -u +'%Y-%m-%d %H:%M:%S')
  else
    ts=$(date -u -d "today -$((RANDOM % 86400)) seconds" +'%Y-%m-%d %H:%M:%S')
  fi
  
  sensor=$((RANDOM % 100 + 1))
  temp="$((RANDOM % 30 + 20)).$((RANDOM % 99))"
  humid="$((RANDOM % 50 + 30)).$((RANDOM % 99))"
  
  echo "$ts,$sensor,$temp,$humid" >> data.csv
done

echo "Inserting data..."

curl -sS -X POST \
  "http://$HOST:$PORT/?query=INSERT+INTO+$DB.$TABLE+FORMAT+CSV" \
  --data-binary @data.csv

echo ""
echo "Verifying..."

count=$(curl -sS "http://$HOST:$PORT/?query=SELECT+count()+FROM+$DB.$TABLE")
echo "Rows inserted: $count"

rm data.csv
echo "Done"
