// Copyright 2023 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package operator

import (
	"net/http"

	"element.io/conversion-webhook/internal/pkg/converter"
	"element.io/conversion-webhook/internal/pkg/converter/kubernetes"
)

func ServeConvert(w http.ResponseWriter, r *http.Request) {
	kubernetes.Serve(w, r, converter.Process)
}
