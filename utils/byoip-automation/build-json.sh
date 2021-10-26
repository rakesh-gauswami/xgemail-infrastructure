#!/bin/bash
REGIONS=('prod-us-east-2' 'prod-us-west-2' 'prod-eu-central-1' 'prod-eu-west-1' 'prod-eml-ca-central-1')
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
