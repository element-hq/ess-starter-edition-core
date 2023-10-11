# Copyright 2023 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


class FilterModule(object):
  def filters(self): return {'drop_null_values': drop_null_values}

def drop_null_values(data):
  if isinstance(data, dict):
    data_copy = data.copy()
    for k, v in data_copy.items():
      if v == None:
        del data[k]
      elif isinstance(v, (dict, list)):
        drop_null_values(v)
  elif isinstance(data, list):
    for item in data:
      drop_null_values(item)
  return data
