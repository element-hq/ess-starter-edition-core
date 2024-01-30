# Copyright 2023 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


# Anything not listed below gets sorted after Kinds that have been listed, maintaining the input order
components_order = [
  "synapse",
  "well_known_delegation",
  "element_web",
]

class FilterModule(object):
  def filters(self): return {'sort_apply_order': sort_apply_order}

def _component_order(c):
  try:
    return components_order.index(c)
  except ValueError:
    return len(components_order)

def sort_apply_order(data):
  if isinstance(data, list):
    data.sort(key=_component_order)
  return data

