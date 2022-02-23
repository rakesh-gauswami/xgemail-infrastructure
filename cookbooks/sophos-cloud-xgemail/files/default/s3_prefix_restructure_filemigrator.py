# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python
#
# Usage:
# python3 filemigrator.py -r region -e env -l oldlocationfilepath -m keycount -d dryrun
#
import argparse
import boto3
import hashlib
import base64
from datetime import datetime
from botocore.errorfactory import ClientError
import logging
import sys

logging.basicConfig(
    datefmt="%Y-%m-%d %H:%M:%S",
    format="%(asctime)s " + " %(levelname)s %(message)s",
    level=logging.INFO,
    stream=sys.stdout)

class S3Accessor:
    current_datetime = datetime.now()
    sourceFile = open('ListOfMissingFiles.txt', 'a')
    sourceFile.write("\n"+str(current_datetime))
    sourceFile.write("\n If command executed using dryrun option then below given files not available in new prefix location.")
    sourceFile.write("\n If command executed without dryrun option then below given files are successfully created in new prefix location.")
    counter = 0
    def __init__(self, region, max_keys):
        self.s3 = boto3.client('s3', region_name=region)
        self.max_keys = max_keys

    def migrate_object(self, bucket, newlocationkey, oldlocationkey):
        try:
            self.s3.head_object(Bucket=bucket, Key=newlocationkey)
        except ClientError as e:
            if e.response['Error']['Code'] == "404":
                if dryrun:
                    self.counter += 1
                    self.sourceFile.write("\n {} >> {}".format(oldlocationkey, newlocationkey))
                else:
                    self.copy_and_replace_filename_to_newlocation(bucket,newlocationkey,oldlocationkey)
            else:
                logging.error("Error occurred -  %s", e.message, exc_info=1)
            pass
    def copy_and_replace_filename_to_newlocation(self,bucket,newlocationkey,oldlocationkey):
        try:
            self.counter += 1
            copy_source = {'Bucket': bucket, 'Key': oldlocationkey}
            self.s3.copy_object(CopySource = copy_source, Bucket = bucket, Key = newlocationkey)
            self.sourceFile.write("\n {}".format(oldlocationkey))
        except Exception as e:
            logging.error("An Exception occurred - %s",e.message, exc_info=1)

    def list_objects(self, bucket, prefix, continuation_token=None):
        if continuation_token:
            response = self.s3.list_objects_v2(Bucket=bucket, Prefix=prefix, MaxKeys=self.max_keys, ContinuationToken=continuation_token)
        else:
            response = self.s3.list_objects_v2(Bucket=bucket, Prefix=prefix, MaxKeys=self.max_keys)

        continuation_token = response['NextContinuationToken'] if 'NextContinuationToken' in response else None

        return (response['Contents'], continuation_token)

    def for_each_object(self, bucket, prefix, v, limit=None):
        continuation_token = None
        while True:
            (objs, continuation_token) = self.list_objects(bucket, prefix, continuation_token)
            for entry in objs:
                count = v.processor(entry)

                if count >= limit:
                    self.sourceFile.write("\n Total file count====>>>{} \n".format(self.counter))
                    self.sourceFile.close()
                    logging.info("Process completed, you can find log information in ListOfMissingFiles.txt ")
                    return
            if not continuation_token:
                self.sourceFile.write("\n Total file count====>>>{} \n".format(self.counter))
                self.sourceFile.close()
                logging.info("Process completed, you can find log information in ListOfMissingFiles.txt ")
                break;

class MethodVisitor(object):
    def __init__(self, action):
        self._count = 0
        self._action = action

    def reset(self):
        self._count = 0

    def processor(self, entry):
        self._count += 1
        self._action(entry['Key'], entry)
        return self._count

    def get_count(self):
        return self._count

#############################################################################################
# Startup stuff.
#############################################################################################

parser = argparse.ArgumentParser(description='Walk S3 folder and copy all files to new prefix location')

parser.add_argument("-e", "--environment", default="dev", help="One of dev, qa, prod")
parser.add_argument("-l", "--legacylocation", help="Old location for config files")
parser.add_argument("-m", "--maxkeys", type=int, default=10, help="Maximum number of keys to return from S3")
parser.add_argument("-r", "--region", required=True, help="AWS region name")
parser.add_argument("-d", "--dryrun", required=False, help="dry run to get the files to be created to the new prefix location")

args = parser.parse_args()
region = args.region.lower()
environment = args.environment.lower()
dryrun = args.dryrun
logging.info("Maximum keys to be processed: %s",args.maxkeys)
bucket = "private-cloud-{}-{}-cloudemail-xgemail-policy".format(environment, region)
maxkeys = args.maxkeys
prefix = args.legacylocation
s3_accessor = S3Accessor(region, maxkeys)

#############################################################################################
# Below method is to migrate Endpoint dlp policy object
# prefixoldlocation - config/policies/dlp/userid.POLICY
# prefixnewlocation - policies/dlp/hashvalue/base64ofuserid.POLICY
#############################################################################################

def migrate_endpointdlppolicy_object(key, entry):
    parts = key.split('/')
    if len(parts) > 3:
        userid_with_policy = parts[3]
        useridparts = userid_with_policy.split('.')
        if len(useridparts) == 2:
            userid = useridparts[0]
            message_bytes = userid.encode('utf-8')
            base64_bytes = base64.b64encode(message_bytes)
            base64userid = base64_bytes.decode('utf-8')
            hashvalue = get_hash(base64userid + '.POLICY')
            newlocationkey = "policies/dlp/{}/{}.POLICY".format(hashvalue, base64userid)
            s3_accessor.migrate_object(bucket, newlocationkey,key)

#############################################################################################
# Below method is to migrate Customer allow-block file objects
# prefixoldlocation - config/inbound-relay-control/allow-block/customers/customerid
# prefixnewlocation - inbound-relay-control/allow-block/customers/hashvalue/customerid
#############################################################################################
def migrate_customerallowblock_object(key, entry):
    parts = key.split('/')
    if len(parts) > 4:
        customerid = parts[4]
        hashvalue = get_hash(customerid)
        newlocationkey = "inbound-relay-control/allow-block/customers/{}/{}".format(hashvalue,customerid)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate User allow-block file objects
# prefixoldlocation -  config/inbound-relay-control/allow-block/users/userid
# prefixnewlocation - inbound-relay-control/allow-block/users/hashvalue/userid
#############################################################################################
def migrate_userallowblock_object(key, entry):
    parts = key.split('/')
    if len(parts) > 4:
        userid = parts[4]
        hashvalue = get_hash(userid)
        newlocationkey = "inbound-relay-control/allow-block/users/{}/{}".format(hashvalue,userid)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate Endpoint policy file objects
# prefixoldlocation - config/policies/endpoints/userid.POLICY
# prefixnewlocation - policies/endpoints/<hashchars>/<user-id>.POLICY
#############################################################################################
def migrate_endpointpolicy_object(key, entry):
    parts = key.split('/')
    if len(parts) > 3:
        userid_with_policy = parts[3]
        if len(userid_with_policy) > 36:
            return
        hashvalue = get_hash(userid_with_policy)
        newlocationkey = "policies/endpoints/{}/{}".format(hashvalue,userid_with_policy)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate Bulk sender action files objects
# prefixoldlocation - config/outbound-relay-control/bulksenders/<customer_id>/<userid>.<ACTION>
# prefixnewlocation - outbound-relay-control/bulksenders/<customer_id>/<hashchars>/<userid>.<ACTION>
#############################################################################################
def migrate_bulksendersaction_object(key, entry):
    parts = key.split('/')
    if len(parts) > 4:
        customer_id = parts[3]
        userid_with_action = parts[4]
        if len(userid_with_action.split('.')) != 2:
            return
        hashvalue = get_hash(userid_with_action)
        newlocationkey = "outbound-relay-control/bulksenders/{}/{}/{}".format(customer_id, hashvalue, userid_with_action)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate email address policy object
# prefixoldlocation - config/policies/domains/<domain>/<b64-encoded-localpart>
# prefixnewlocation - policies/domains/<hashchars>/<domain>/<b64-encoded-localpart>
#############################################################################################

def migrate_emailaddresspolicy_object(key, entry):
    parts = key.split('/')
    if len(parts) > 4:
        domain = parts[3]
        email_address_user_name_encoded_localpart = parts[4]
        hashvalue = get_hash(email_address_user_name_encoded_localpart)
        newlocationkey = "policies/domains/{}/{}/{}".format(hashvalue, domain, email_address_user_name_encoded_localpart)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate outbound gateway config file and localpart objects
# prefixoldlocation - config/outbound-relay-control/domains/<domain>/<b64-encoded-localpart>
# prefixnewlocation - outbound-relay-control/domains/<hashchars>/<domain>/<b64-encoded-localpart>

# prefixoldlocation - config/outbound-relay-control/domains/<domain>.CONFIG
# prefixnewlocation - outbound-relay-control/domains/<hashcars>/<domain>.CONFIG

#############################################################################################
def migrate_outboundgatewayconfigandlocalpart_object(key, entry):
    parts = key.split('/')
    if len(parts) > 4:
        domain = parts[3]
        email_address_user_name_encoded_localpart = parts[4]
        hashvalue = get_hash(email_address_user_name_encoded_localpart)
        newlocationkey = "outbound-relay-control/domains/{}/{}/{}".format(hashvalue, domain, email_address_user_name_encoded_localpart)
        s3_accessor.migrate_object(bucket, newlocationkey, key)
    elif len(parts) > 3:
        domain_with_config = parts[3]
        hashvalue = get_hash(domain_with_config)
        newlocationkey = "outbound-relay-control/domains/{}/{}".format(hashvalue, domain_with_config)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate impersonation vip file objects
# prefixoldlocation - config/inbound-relay-control/impersonation/vips/<customer_id>.VIP
# prefixnewlocation - inbound-relay-control/impersonation/vips/<hashcars>/<customer_id>.VIP
#############################################################################################
def migrate_impersonationvip_object(key, entry):
    parts = key.split('/')
    if len(parts) > 4:
        customerid_with_extension = parts[4]
        if len(customerid_with_extension.split('.')) != 2:
            return
        hashvalue = get_hash(customerid_with_extension)
        newlocationkey = "inbound-relay-control/impersonation/vips/{}/{}".format(hashvalue, customerid_with_extension)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate encryption setting config file objects
# prefixoldlocation - config/outbound-relay-control/encryption/<domain>.ENC_CONFIG
# prefixnewlocation - outbound-relay-control/encryption/<hashcars>/<domain>.ENC_CONFIG
#############################################################################################
def migrate_encryptionsettingconfig_object(key, entry):
    parts = key.split('/')
    if len(parts) > 3:
        domain_with_extension = parts[3]
        hashvalue = get_hash(domain_with_extension)
        newlocationkey = "outbound-relay-control/encryption/{}/{}".format(hashvalue, domain_with_extension)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate customer domain file objects
# prefixoldlocation - config/inbound-relay-control/domains/<customer_id>.DOMAINS
# prefixnewlocation - inbound-relay-control/domains/<hashchars>/<customer_id>.DOMAINS
#############################################################################################
def migrate_customerdomain_object(key, entry):
    parts = key.split('/')
    if len(parts) > 3:
        customerid_with_extension = parts[3]
        if len(customerid_with_extension.split('.')) != 2:
            return
        hashvalue = get_hash(customerid_with_extension)
        newlocationkey = "inbound-relay-control/domains/{}/{}".format(hashvalue, customerid_with_extension)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate customer delivery route file objects
# prefixoldlocation - config/inbound-relay-control/delivery-routes/<domain>.ROUTE
# prefixnewlocation - inbound-relay-control/delivery-routes/<hashcars>/<domain>.ROUTE
#############################################################################################
def migrate_deliveryroute_object(key, entry):
    parts = key.split('/')
    if len(parts) > 3:
        domain_with_extension = parts[3]
        hashvalue = get_hash(domain_with_extension)
        newlocationkey = "inbound-relay-control/delivery-routes/{}/{}".format(hashvalue, domain_with_extension)
        s3_accessor.migrate_object(bucket, newlocationkey, key)

#############################################################################################
# Below method is to migrate allow toc file objects
# prefixoldlocation - config/inbound-relay-control/toc/allow-list/customers/<customer_id>.ALLOWTOC
# prefixnewlocation - inbound-relay-control/toc/allow-list/customers/<hashcars>/<customer_id>.ALLOWTOC
#############################################################################################
def migrate_allowtoc_object(key, entry):
    parts = key.split('/')
    if len(parts) > 5:
        customerid_with_extension = parts[5]
        if len(customerid_with_extension.split('.')) != 2:
            return
        hashvalue = get_hash(customerid_with_extension)
        newlocationkey = "inbound-relay-control/toc/allow-list/customers/{}/{}".format(hashvalue, customerid_with_extension)
        s3_accessor.migrate_object(bucket, newlocationkey, key)


def get_hash(s):
    hasher = hashlib.md5()
    hasher.update(s.encode('utf-8'))
    digest = hasher.hexdigest()
    return digest[:4]

def get_method_visitor(prefix):
    if prefix == 'config/policies/dlp':
        return MethodVisitor(migrate_endpointdlppolicy_object)
    elif prefix == 'config/inbound-relay-control/allow-block/customers':
        return MethodVisitor(migrate_customerallowblock_object)
    elif prefix == 'config/inbound-relay-control/allow-block/users':
        return MethodVisitor(migrate_userallowblock_object)
    elif prefix == 'config/policies/endpoints':
        return MethodVisitor(migrate_endpointpolicy_object)
    elif prefix == 'config/outbound-relay-control/bulksenders':
        return MethodVisitor(migrate_bulksendersaction_object)
    elif prefix == 'config/policies/domains':
        return MethodVisitor(migrate_emailaddresspolicy_object)
    elif prefix == 'config/outbound-relay-control/domains':
        return MethodVisitor(migrate_outboundgatewayconfigandlocalpart_object)
    elif prefix == 'config/inbound-relay-control/impersonation/vips':
        return MethodVisitor(migrate_impersonationvip_object)
    elif prefix == 'config/outbound-relay-control/encryption':
        return MethodVisitor(migrate_encryptionsettingconfig_object)
    elif prefix == 'config/inbound-relay-control/domains':
        return MethodVisitor(migrate_customerdomain_object)
    elif prefix == 'config/inbound-relay-control/delivery-routes':
        return MethodVisitor(migrate_deliveryroute_object)
    elif prefix == 'config/inbound-relay-control/toc/allow-list/customers':
        return MethodVisitor(migrate_allowtoc_object)
    else:
        print("Incorrect prefix location")
        exit()

v = get_method_visitor(prefix)
s3_accessor.for_each_object(bucket, prefix, v, maxkeys)