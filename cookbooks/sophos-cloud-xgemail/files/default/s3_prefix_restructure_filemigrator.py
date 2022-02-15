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
                    self.sourceFile.write("\n {}".format(oldlocationkey))
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
    else:
        print("Incorrect prefix location")
        exit()

v = get_method_visitor(prefix)
s3_accessor.for_each_object(bucket, prefix, v, maxkeys)