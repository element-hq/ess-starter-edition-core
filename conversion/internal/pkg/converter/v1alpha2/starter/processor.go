// Copyright 2023 New Vector Ltd
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
	convertedObject.SetAPIVersion("matrix.element.io/v1alpha2")
	switch Object.Object["kind"] {
	case "Synapse":
		klog.Info("converting Synapse ")
		return ConvertSynapse(convertedObject)
	case "ElementDeployment":
		klog.Info("converting ElementDeployment ")
		return ConvertElementDeployment(convertedObject)
	default:
		return nil, kubernetes.StatusErrorWithMessage("unexpected kind conversion %q", Object.Object["kind"])
	}
}
