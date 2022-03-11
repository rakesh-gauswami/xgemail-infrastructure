#!/bin/bash
REGIONS=('prod-us-east-2' 'prod-us-east-2-spare' 'prod-us-west-2' 'prod-us-west-2-spare' 'prod-eu-central-1' 'prod-eu-west-1' 'eml100yul-ca-central-1' 'eml100hnd-ap-northeast-1' 'eml100syd-ap-southeast-2' 'eml100bom-ap-south-1')
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
