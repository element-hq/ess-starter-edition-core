# Copyright 2023 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


# Anything not listed below gets sorted after Kinds that have been listed, maintaining the input order
resources_order = [
  "Secret",
  "ConfigMap",
  "PersistentVolumeClaim",
  "Pod",
  "Deployment",
  "StatefulSet",
  "Ingress",
  "Service",
  # We deploy Synapse here because
  # we want to deploy it before every other resources
  "Synapse"
]

class FilterModule(object):
  def filters(self): return {'sort_apply_order': sort_apply_order}

def _res_order(o):
  try:
    return resources_order.index(o['kind'])
  except ValueError:
    return len(resources_order)

def sort_apply_order(data):
  if isinstance(data, list):
    data.sort(key=_res_order)
  return data

