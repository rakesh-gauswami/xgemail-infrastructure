#!/bin/bash
REGIONS=('us-east-2.csv' 'us-west-2.csv' 'eu-central-1.csv' 'eu-west-1.csv')
for region in "${REGIONS[@]}"
do
  OUTPUT=xgemail-byoip-address-config-$region.json
  echo "$region"
  echo '[' > "$OUTPUT"
  while IFS=, read -r ip dns tag || [ -n "$tag" ]
  do
    echo "    {" >> "$OUTPUT"
    echo "      \"IpAddress\": \"$ip\"," >> "$OUTPUT"
    echo "      \"DnsRecord\": \"$dns\"," >> "$OUTPUT"
    echo "      \"EipName\": \"$tag\"" | tr -d '\r' >> "$OUTPUT"
    echo "    }," >> "$OUTPUT"
  done < "$region"
  sed -i '' '$ s/.$//' "$OUTPUT"
  echo ']' >> "$OUTPUT"
done
