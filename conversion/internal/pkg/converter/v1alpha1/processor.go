// Copyright 2023-2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package v1alpha1

import (

	"element.io/conversion-webhook/internal/pkg/converter/v1alpha1/starter"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

func Convert(Object *unstructured.Unstructured) (*unstructured.Unstructured, metav1.Status) {
	convertedObject := Object.DeepCopy()
	convertedObject.SetAPIVersion("matrix.element.io/v1alpha1")

	convertedObject, status := starter.Convert(convertedObject)

	return convertedObject, status
}
