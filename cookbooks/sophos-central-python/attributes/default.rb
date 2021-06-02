#===========================================================================
#
# default.rb
#
#===========================================================================
#
# Default Attributes
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
#===========================================================================

# JSON data encoder and decoder.
# Can handle decoding JSON strings with unquoted keys, e.g. { a: 1 }.
default["pip3"]["demjson"]["version"] = "2.2.4"

# DNS client library.
# Used by pymongo to support SRV records for client seeding.
default["pip3"]["dnspython"]["version"] = "1.16.0"

# MongoDB client library.
default["pip3"]["pymongo"]["version"] = "3.7.2"

# Standard daemon process library.
# We can remove this once we retire the AMI bakery code for good.
default["pip3"]["python-daemon"]["version"] = "2.1.1"

# Timezone data.
default["pip3"]["pytz"]["version"] = "2018.7"

# Pretty-printer for tabular data.
# Use this instead of sophos.common.print_rows for portability.
default["pip3"]["tabulate"]["version"] = "0.8.3"
