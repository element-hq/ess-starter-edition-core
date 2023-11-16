// Copyright 2023 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package operator

import (
	"bytes"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer/json"
)

func TestConverterYAML(t *testing.T) {
	cases := []struct {
		apiVersion     string
		contentType    string
		expected400Err string
	}{
		{
			apiVersion:     "apiextensions.k8s.io/v1beta1",
			contentType:    "application/json",
			expected400Err: "json parse error",
		},
		{
			apiVersion:  "apiextensions.k8s.io/v1beta1",
			contentType: "application/yaml",
		},
		{
			apiVersion:     "apiextensions.k8s.io/v1",
			contentType:    "application/json",
			expected400Err: "json parse error",
		},
		{
			apiVersion:  "apiextensions.k8s.io/v1",
			contentType: "application/yaml",
		},
	}
	sampleObjTemplate := `kind: ConversionReview
apiVersion: %s
request:
  uid: 0000-0000-0000-0000
  desiredAPIVersion: matrix.element.io/v1alpha2
  objects:
    - apiVersion: matrix.element.io/v1alpha1
      kind: Synapse
      metadata:
        name: host-aliases-object
      spec:
        config:
          additional: some value
          workers:
          - type: frontend-proxy
          - type: other-type
            additional: some value
`
	for _, tc := range cases {
		t.Run(tc.apiVersion+" "+tc.contentType, func(t *testing.T) {
			sampleObj := fmt.Sprintf(sampleObjTemplate, tc.apiVersion)
			// First try json, it should fail as the data is yaml
			response := httptest.NewRecorder()
			request, err := http.NewRequest("POST", "/convert", strings.NewReader(sampleObj))
			if err != nil {
				t.Fatal(err)
			}
			request.Header.Add("Content-Type", tc.contentType)
			ServeConvert(response, request)
			convertReview := apiextensionsv1.ConversionReview{}
			scheme := runtime.NewScheme()
			if len(tc.expected400Err) > 0 {
				body := response.Body.Bytes()
				if !bytes.Contains(body, []byte(tc.expected400Err)) {
					t.Fatalf("expected to fail on '%s', but it failed with: %s", tc.expected400Err, string(body))
				}
				return
			}

			yamlSerializer := json.NewSerializerWithOptions(json.DefaultMetaFactory, scheme, scheme, json.SerializerOptions{Yaml: true})
			if _, _, err := yamlSerializer.Decode(response.Body.Bytes(), nil, &convertReview); err != nil {
				t.Fatalf("cannot decode data: \n %v\n Error: %v", response.Body, err)
			}
			if convertReview.Response.Result.Status != v1.StatusSuccess {
				t.Fatalf("cr conversion failed: %v", convertReview.Response)
			}
		})
	}
}
