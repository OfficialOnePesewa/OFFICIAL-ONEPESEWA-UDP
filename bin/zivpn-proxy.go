package main

import (
	"encoding/json"
	"flag"
	"io"
	"log"
	"net"
	"os"
	"strings"
)

type Binding struct {
	Password string `json:"password"`
	DeviceID string `json:"device_id"`
}

var bindings map[string]Binding

func loadBindings(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, &bindings)
}

func main() {
	listenAddr := flag.String("listen", ":5667", "Proxy listen address")
	backendAddr := flag.String("backend", ":5668", "Backend ZIVPN address")
	bindingsFile := flag.String("bindings", "/etc/zivpn/bindings.json", "Bindings JSON file")
	flag.Parse()

	err := loadBindings(*bindingsFile)
	if err != nil {
		log.Fatalf("Failed to load bindings: %v", err)
	}

	ln, err := net.Listen("udp", *listenAddr)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Proxy listening on %s, forwarding to %s", *listenAddr, *backendAddr)

	for {
		handleConnection(ln, *backendAddr)
	}
}

func handleConnection(ln net.PacketConn, backend string) {
	buf := make([]byte, 2048)
	n, clientAddr, err := ln.ReadFrom(buf)
	if err != nil {
		log.Printf("Read error: %v", err)
		return
	}

	// Extract password and device ID from ZIVPN handshake
	// Format (simplified): first bytes contain auth info; password:deviceID
	data := buf[:n]
	parts := strings.Split(string(data), ":")
	if len(parts) < 2 {
		log.Printf("Invalid handshake from %v", clientAddr)
		return
	}
	password := parts[0]
	deviceID := parts[1]

	binding, exists := bindings[password]
	if !exists || binding.DeviceID != deviceID {
		log.Printf("Rejected: password=%s device=%s from %v", password, deviceID, clientAddr)
		return
	}

	// Forward to real ZIVPN
	backendConn, err := net.Dial("udp", backend)
	if err != nil {
		log.Printf("Backend dial error: %v", err)
		return
	}
	defer backendConn.Close()

	_, err = backendConn.Write(data)
	if err != nil {
		log.Printf("Backend write error: %v", err)
		return
	}

	// Relay responses back to client
	go func() {
		io.Copy(ln.(net.Conn), backendConn) // Not exactly correct for UDP; need proper relay
	}()
}
