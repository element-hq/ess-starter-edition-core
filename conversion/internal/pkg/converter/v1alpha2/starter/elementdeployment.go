// Copyright 2023 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package starter

import (
	"element.io/conversion-webhook/internal/pkg/converter/kubernetes"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

func ConvertElementDeployment(convertedObject *unstructured.Unstructured) (*unstructured.Unstructured, metav1.Status) {
	return convertedObject, kubernetes.StatusSucceed()
}
