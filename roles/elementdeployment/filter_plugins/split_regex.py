# Copyright 2023 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


from ansible.errors import AnsibleError, AnsibleFilterError, AnsibleFilterTypeError
from ansible.module_utils.six import string_types
import re

class FilterModule(object):
    def filters(self): return {'split_regex': split_regex}

def split_regex(string_value, separator_pattern):
    if not isinstance(string_value, (string_types)):
        raise AnsibleFilterTypeError("The string value should be a string : %s" % type(string_value))
    if not isinstance(separator_pattern, (string_types)):
        raise AnsibleFilterTypeError("The separator pattern should be a string : %s" % type(separator_pattern))
    try:
        return re.split(separator_pattern, string_value, flags=re.MULTILINE)
    except Exception as e:
        raise errors.AnsibleFilterError('split_regex error : %s, provided string: "%s"' % str(e),str(string_value) )
