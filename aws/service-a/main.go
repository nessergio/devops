package main

import (
	"errors"
	"github.com/charmbracelet/log"
	"golang.org/x/net/netutil"
	"io"
	"math/rand"
	"net"
	"net/http"
	"os"
	"strconv"
	"time"
)

var payload string

func getEnv(key, fallback string) string {
	value, exists := os.LookupEnv(key)
	if !exists {
		value = fallback
	}
	return value
}

func getHealth(w http.ResponseWriter, r *http.Request) {
	if _, err := io.WriteString(w, "Healthcheck OK\n"); err != nil {
		log.Errorf("can not write response")
	}
}
func getPayload(w http.ResponseWriter, r *http.Request) {
	delay := rand.Intn(10000)
	log.Infof("recieved payload request. Will process for %d ms", delay)
	time.Sleep(time.Duration(delay) * time.Millisecond)
	if _, err := io.WriteString(w, payload); err != nil {
		log.Errorf("can not write response")
	}
}

func main() {
	payload = getEnv("A_PAYLOAD", "Hello, World!")
	port := getEnv("PORT", "3000")
	// Specify endpoint handlers
	router := http.NewServeMux()
	router.HandleFunc("/health", getHealth)
	router.HandleFunc("/", getPayload)

	srv := http.Server{
		ReadHeaderTimeout: time.Second * 5,
		ReadTimeout:       time.Second * 10,
		Handler:           router,
	}

	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatal(err)
	}

	maxConn, err := strconv.Atoi(getEnv("MAX_CONN", "0"))
	if err != nil {
		log.Warnf("invalid MAX_CONN number")
		maxConn = 0
	}
	if maxConn > 0 {
		listener = netutil.LimitListener(listener, maxConn)
		log.Infof("max connections set to %d\n", maxConn)
	}

	defer func(listener net.Listener) {
		if listener.Close() != nil {
			log.Errorf("can not close Listener")
		}
	}(listener)

	log.Infof("starting server on port %s..", port)
	err = srv.Serve(listener)

	if errors.Is(err, http.ErrServerClosed) {
		log.Warnf("server closed: %v", err)
	} else if err != nil {
		log.Warnf("can`t start server: %v", err)
		os.Exit(1)
	}
}
