# Copyright 2023-2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


class FilterModule(object):
  def filters(self):
    return { 'mapattributes': self.mapattributes }

  def mapattributes(self, list_of_dicts, list_of_keys):
    l = []
    for di in list_of_dicts:
      newdi = { }
      for key in list_of_keys:
        newdi[key] = di[key]
      l.append(newdi)
    return l
