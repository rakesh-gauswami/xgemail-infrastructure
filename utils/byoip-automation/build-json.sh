#!/bin/bash
REGIONS=('us-east-2' 'us-west-2' 'eu-central-1' 'eu-west-1')
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
  done < "$region.csv"
  sed -i '' '$ s/.$//' "$OUTPUT"
  echo ']' >> "$OUTPUT"
done
