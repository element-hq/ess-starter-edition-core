// Copyright 2023-2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package converter

import (
	"fmt"

	"element.io/conversion-webhook/internal/pkg/converter/kubernetes"
	"element.io/conversion-webhook/internal/pkg/converter/v1alpha1"
	"element.io/conversion-webhook/internal/pkg/converter/v1alpha2"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/version"
	"k8s.io/klog"
)

func checkSupportedVersion(Object *unstructured.Unstructured, toVersion string) metav1.Status {
	fromVersionIsSupported := false
	toVersionIsSupported := false
	versions := []string{"v1alpha1", "v1alpha2"}

	for _, v := range versions {
		if Object.GetAPIVersion() == "matrix.element.io/"+v {
			fromVersionIsSupported = true
		}
		if toVersion == "matrix.element.io/"+v {
			toVersionIsSupported = true
		}
		if fromVersionIsSupported && toVersionIsSupported {
			return kubernetes.StatusSucceed()
		}
	}

	if !fromVersionIsSupported && !toVersionIsSupported {
		return kubernetes.StatusErrorWithMessage("unexpected conversion fromVersion %q, toVersion %q", Object.GetAPIVersion(), toVersion)
	} else if !fromVersionIsSupported {
		return kubernetes.StatusErrorWithMessage("unexpected conversion fromVersion %q", Object.GetAPIVersion())
	} else {
		return kubernetes.StatusErrorWithMessage("unexpected conversion toVersion %q", toVersion)
	}
}

func Process(Object *unstructured.Unstructured, toVersion string) (*unstructured.Unstructured, metav1.Status) {
	versionSupport := checkSupportedVersion(Object, toVersion)
	fromVersion := Object.GetAPIVersion()
	if versionSupport.Status == metav1.StatusSuccess {
		if toVersion == fromVersion {
			return Object, versionSupport
		} else if version.CompareKubeAwareVersionStrings(fromVersion, toVersion) > 0 {
			return upgrade(Object, toVersion)
		} else {
			return downgrade(Object, toVersion)
		}
	} else {
		return nil, versionSupport
	}
}

func upgrade(Object *unstructured.Unstructured, toVersion string) (*unstructured.Unstructured, metav1.Status) {
	fromVersion := Object.GetAPIVersion()
	klog.Info(fmt.Sprintf("Upgrading %q from %q to %q", Object.Object["kind"], fromVersion, toVersion))
	if toVersion == fromVersion {
		return Object, kubernetes.StatusSucceed()
	}
	switch fromVersion {
	case "matrix.element.io/v1alpha1":
		convertedObject, status := v1alpha2.Convert(Object)
		if status.Status == metav1.StatusSuccess {
			return upgrade(convertedObject, toVersion)
		} else {
			return nil, status
		}
	default:
		return nil, kubernetes.StatusErrorWithMessage("unexpected current version %q, target version is %q", fromVersion, toVersion)
	}
}

func downgrade(Object *unstructured.Unstructured, toVersion string) (*unstructured.Unstructured, metav1.Status) {
	fromVersion := Object.GetAPIVersion()
	klog.Info(fmt.Sprintf("Downgrading %q from %q to %q", Object.Object["kind"], fromVersion, toVersion))
	if toVersion == fromVersion {
		return Object, kubernetes.StatusSucceed()
	}
	switch fromVersion {
	case "matrix.element.io/v1alpha2":
		convertedObject, status := v1alpha1.Convert(Object)
		if status.Status == metav1.StatusSuccess {
			return downgrade(convertedObject, toVersion)
		} else {
			return nil, status
		}
	default:
		return nil, kubernetes.StatusErrorWithMessage("unexpected current version %q, target version is %q", fromVersion, toVersion)
	}
}
