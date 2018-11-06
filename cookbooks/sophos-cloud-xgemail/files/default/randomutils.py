#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail diskutils utility.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import random

# Returns true or false based on whether or not the given probability
# is less than or equal to a randomly generated value.
# For more info, see: https://docs.python.org/3/library/random.html#random.random
#
# Particularly useful for when you want to perform some task x
# percent of the time. Passing a float value between 0.00 and 0.99
# as your probability will yield a true/false value which equates
# to whether or not that task should be performed.
def roll_the_dice(probability):

    chance = random.random()

    if probability <= chance:
        return True, chance
    else:
        return False, chance


