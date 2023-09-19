# SPDX-License-Identifier: MIT


# -*- coding: utf-8 -*-

"""
MIT License

Copyright (c) 2020 Marek Chmiel
Copyright (c) 2023 New Vector Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import re

from ansible.errors import AnsibleError, AnsibleFilterError, AnsibleFilterTypeError
from ansible.module_utils.six import string_types
import re

class FilterModule(object):
    def filters(self): return {'camel_case': camel_case}

def camel_case(string_value, lower_camel):
    if not isinstance(string_value, (string_types)):
        raise AnsibleFilterTypeError("The string value should be a string : %s" % type(string_value))
    if not isinstance(lower_camel, bool):
        raise AnsibleFilterTypeError("The lower_camel should be a boolean : %s" % type(lower_camel))
    try:
        if lower_camel:
          return to_lower_camel(string_value)
        else:
          return to_camel(string_value)
    except Exception as e:
        raise errors.AnsibleFilterError('camel_case error : %s, provided string: "%s"' % str(e),str(string_value) )

def _space_numbers(match):
    return f'{match.group(1)} {match.group(2)} {match.group(3)}'

def _add_word_boundaries_to_numbers(string):
    pattern = re.compile(r'([a-zA-Z])(\d+)([a-zA-Z]?)')
    return pattern.sub(_space_numbers, string)

def _to_camel_init_case(string, init_case):
    string = _add_word_boundaries_to_numbers(string)
    string = string.strip(" ")
    n = ""
    cap_next = init_case
    for v in string:
        if (v >= 'A' and v <= 'Z') or (v >= '0' and v <= '9'):
            n += v
        if v >= 'a' and v <= 'z':
            if cap_next:
                n += v.upper()
            else:
                n += v
        if v == '_' or v == ' ' or v == '-':
            cap_next = True
        else:
            cap_next = False
    return n

def to_camel(string):
    return _to_camel_init_case(string, True)

def to_lower_camel(string):
    if not string:
        return string
    if string[0] >= 'A' and string[0] <= 'Z':
        string = string[0].lower() + string[1:]
    return _to_camel_init_case(string, False)
