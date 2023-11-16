// Copyright 2023 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package v1alpha2

import (
	"element.io/conversion-webhook/internal/pkg/converter/kubernetes"
	"element.io/conversion-webhook/internal/pkg/converter/v1alpha2/enterprise"
	"element.io/conversion-webhook/internal/pkg/converter/v1alpha2/starter"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

func Convert(Object *unstructured.Unstructured) (*unstructured.Unstructured, metav1.Status) {
	convertedObject := Object.DeepCopy()
	convertedObject.SetAPIVersion("matrix.element.io/v1alpha2")
	starter.Convert(convertedObject)
	return convertedObject, kubernetes.StatusSucceed()
}
