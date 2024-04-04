// Copyright 2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package starter

import (
	"element.io/conversion-webhook/internal/pkg/converter/kubernetes"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/klog"
)

func Convert(Object *unstructured.Unstructured) (*unstructured.Unstructured, metav1.Status) {
	convertedObject := Object.DeepCopy()
	switch Object.Object["kind"] {
	case "Synapse":
		klog.Info("Downgrading starter Synapse ")
		return ConvertSynapse(convertedObject)
	case "ElementDeployment":
		klog.Info("Downgrading starter ElementDeployment ")
		return ConvertElementDeployment(convertedObject)
	default:
		return nil, kubernetes.StatusErrorWithMessage("unexpected kind conversion %q", Object.Object["kind"])
	}
}
