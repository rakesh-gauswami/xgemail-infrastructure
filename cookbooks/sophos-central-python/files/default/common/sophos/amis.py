#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Fun with AWS machine images.
"""

import boto3
import json
import re


def get_describe_images_filters(query):
    """
    Return a list of describe_images filters based on the given query dict.

    NOTE: We are NOT handling capitalized keys, e.g. "Name" and "ImageId"
    instead of "name" and "image-id".  That complicates the code without
    really adding any benefit.  Besides, this way we don't introduce a
    dependency on knowing what keys Amazon supports, and we don't have
    to update this code if Amazon adds support for additional keys.
    """

    filters = []

    for key, values in sorted(query.items()):
        if not isinstance(values, list):
            values = [values]
        filters.append({"Name": key, "Values": values})

    return filters


# List of image attributes which are omitted from the image signature.
IMAGE_DEPENDENT_IMAGE_ATTRIBUTES = [
    "Name",
    "Description",
    "CreationDate",
    "ImageId",
    "ImageLocation",
    # Tags may include branch information that varies for each image,
    # so don't include them in the signature.
    "Tags",
    # Block device attributes may also vary as a line of images evolves,
    # so don't include them either.
    "RootDeviceType",
    "RootDeviceName",
    "BlockDeviceMappings",
]


def _remove_keys(obj, keys):
    """
    Return a copy of ``obj``, removing all dict entries whose key is in ``keys``.
    """

    if isinstance(obj, list):
        return [_remove_keys(item, keys) for item in obj]

    if isinstance(obj, dict):
        return {k: _remove_keys(v, keys) for k, v in obj.items() if k not in keys}

    return obj


def get_image_signature(image):
    """
    Return a string describing all the image-independent attributes of the
    given image.  Image signatures can be compared to determine if two images
    represent different versions of the same image or genuinely different
    images.
    """

    # Collect attributes we care about.
    image_attributes = _remove_keys(image, IMAGE_DEPENDENT_IMAGE_ATTRIBUTES)

    # Generate initial signature.
    signature = json.dumps(image_attributes, sort_keys=True)

    return signature


def find_image_data(queries, ec2_client):
    """
    Find an AMI based on the given resource properties.

    ``queries`` should map to a list of dictionaries, each representing
    a set of filters to pass to the EC2 describe_images API.  Each query
    will be considered in turn.  This allows callers to provide fallback
    queries to handle different code branches or a simple default image
    by using the image-id filter.

    The matching algorithm is:

    If a query generates no matching images, proceed to the next query.

    If a query generates a single matching image, return that image.

    If a query generates multiple matches that all represent different
    versions of the same image, return the image with the latest CreationDate.

    If a query generates multiple matches, not all representing different
    versions of the same image, return an ambiguous-match error.

    If no query generates a match, return a no-match error.

    Return a 2-tuple containing the image object (or None)
    and an error message (or None).
    """

    try:
        for i, query in enumerate(queries):
            filters = get_describe_images_filters(query)
            response = ec2_client.describe_images(Filters=filters)
            images = response.get("Images", [])

            if len(images) == 0:
                continue

            signatures = set([get_image_signature(image) for image in images])

            if len(signatures) == 1:
                images.sort(key=lambda image: image["CreationDate"])
                image_data = images[-1]
                return image_data, None

            return (None, "ambiguous match for query %d: found %d variations:\n%s" % (i, len(signatures), "\n".join(signatures)))

        return (None, "no matches")

    except Exception as e:
        return (None, "%s: %s" % (e.__class__.__name__, e.message))
