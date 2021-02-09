This is the python package for the AMI Bakery service.

References:
    https://jira.sophos.net/browse/CPLAT-12231
    http://techblog.netflix.com/2016/03/how-we-build-code-at-netflix.html

COPYRIGHT

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.

REQUEST MANAGEMENT

Bakery service clients create requests as JSON files that are posted
to a request queue.  These JSON files contain information about the
request, such as:

  * What parent AMI should the new AMI derive from?
  * Where is the code that configures the new AMI?
  * What queue should the response be written to?

On receiving a new request notification, the bakery service reads
the request and processes it.  Processing consists of mounting a
copy of the parent AMI's root EBS volume, downloading bootstrap
code from S3 onto the newly mounted volume, then executing that
bootstrap code in a chroot jail.  Once the bootstrap code completes,
the volume is then unmounted, detached, and then registered as a
new AMI.  The volume and the image are shared with the appropriate
AWS accounts and tagged to make them easy to discover.

Once processing completes a JSON object describing the results
is posted to the response queue specified by the request object.
The request object is then deleted from the request queue.

QUEUE MANAGEMENT

There are two types of queues, request queues and response queues.

The request queue is used to hold requests from the bakery client
(i.e. Bamboo) to bake a new AMI in a specific region.  Each request
queue is associated with a single auto-scaling group of baker
instances.  The bakery service in each instance long-polls for
request messages.  When the service in an instance takes a message,
it sets the message's visibility timeout to some number of seconds
longer than the expected time needed to create the AMI, plus a large
margin of error.  It then processes the request.  Once processing
is done the message is deleted from the queue.

Response queues are used to hold response messages from the bakery
service back to the bakery client.  Response messages include log
messages, which can be used to report progress to the client, and
an end message used to report results -- e.g. the new AMI-ID, the
location of detailed logs in S3, whatever.

Request queues are created by a CloudFormation template.  Response
queues are created by the bakery client and referenced in the request
sent to the bakery service.

Amazon documentation says it reserves the right to delete queues
that have been inactive for more than 30 days.  Inactive means not
having GetQueueAttributes, SendMessage, ReceiveMessage, or other
actions applied to the queue.  Therefore the request queue will
remain active so long as there is at least one bakery instance
long-polling by calling ReceiveMessage every so often.  Response
queues that have not been explicitly deleted by the bakery client
should expire after 30 days, but to accelerate this process the
bakery service should periodically garbage collect any request queue
older than one or two days.

VOLUME MANAGEMENT

Each request to create a new AMI is handled by mounting a volume
which is a copy of the root volume of the parent AMI, then executing
an install script on that volume within a chroot jail.  Once the
script completes a snapshot is taken of the volume and that snapshot
becomes the basis of a new image.  This process has two advantages
over the standalone AMI build process.  First, by running as a
highly available service it eliminates the time needed to launch a
new instance.  Second, by running the service in parallel in each
region, it eliminates the cost of copying images across regions.

There is a third technique we can use to further reduce the time
needed to create a new AMI -- if we maintain a cache of volumes
copied from the root volume of common parent AMIs, then we can
eliminate the cost of creating the new volume.  If we can pre-warm
the volume we may be able to speed up the install script be speeding
up the underlying IO.

This third technique may be helpful but it is not a fundamental
requirement.  The first two should save 4 or 5 minutes each, or
8-10 minutes overall -- a significant improvement.  Therefore we
will defer implementation of volume caching until we have a working
system and can better assess the benefit.

When we DO implement volume caching, we will have to decide HOW to
decide what parent AMIs are worth caching.  One approach we might
think about is recording each request and then each night or each
week refreshing the volume pool with a new set of volumes copied
from the the most popular parent AMIs.
