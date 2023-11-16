// Copyright 2023 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-or-later


package main

import (
	"fmt"
	"net/http"
	"os"

	"element.io/conversion-webhook/internal/pkg/operator"
	"element.io/conversion-webhook/internal/pkg/webhook"
	"github.com/spf13/cobra"
	"k8s.io/klog"
)

var (
	certFile string
	keyFile  string
	port     int
)

// CmdCrdConversionWebhook is used by Cobra.
var CmdCrdConversionWebhook = &cobra.Command{
	Use:   "crd-conversion-webhook",
	Short: "Starts HTTP server on port 443 to run the element operator CustomResourceConversionWebhook",
	Long: `The subcommand tests "CustomResourceConversionWebhook".

After deploying it to Kubernetes cluster, the administrator needs to create a "CustomResourceConversion.Webhook" in Kubernetes cluster to use remote webhook for conversions.

The subcommand starts a HTTP server, listening on port 443, and creating the "/convert" endpoint.`,
	Args: cobra.MaximumNArgs(0),
	Run:  run,
}

func init() {
	CmdCrdConversionWebhook.Flags().StringVar(&certFile, "tls-cert-file", "",
		"File containing the default x509 Certificate for HTTPS. (CA cert, if any, concatenated "+
			"after server cert.")
	CmdCrdConversionWebhook.Flags().StringVar(&keyFile, "tls-private-key-file", "",
		"File containing the default x509 private key matching --tls-cert-file.")
	CmdCrdConversionWebhook.Flags().IntVar(&port, "port", 443,
		"Secure port that the webhook listens on")
}

func main() {
	Execute()
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.run(). It only needs to happen once to the rootCmd.
func Execute() {
	err := CmdCrdConversionWebhook.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func run(cmd *cobra.Command, args []string) {
	config := webhook.Config{CertFile: certFile, KeyFile: keyFile}

	http.HandleFunc("/convert", operator.ServeConvert)
	http.HandleFunc("/readyz", func(w http.ResponseWriter, req *http.Request) { klog.Info("/readyz 200"); w.Write([]byte("ok")) })
	clientset := webhook.GetClient()
	server := &http.Server{
		Addr:      fmt.Sprintf(":%d", port),
		TLSConfig: webhook.ConfigTLS(config, clientset),
	}
	klog.Info("Server ready, listening on port ", port)
	err := server.ListenAndServeTLS("", "")
	if err != nil {
		panic(err)
	}
}
