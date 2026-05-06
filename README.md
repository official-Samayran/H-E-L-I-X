# H E L I X

---

# Overview

H E L I X is a cross-device personal AI assistant designed to work seamlessly between phone and PC.

Unlike traditional AI chat applications, H E L I X acts as a persistent AI operating layer capable of:

* Local AI inference using Ollama
* System telemetry monitoring
* Local PC automation
* Hybrid cloud fallback using Gemini
* Real-time device communication
* Offline conversation continuity
* Backend memory synchronization

---

# Core Architecture

```txt
Phone App (HELIX)
        ↓
    Tailscale
        ↓
 HELIX Node (PC Agent)
        ↓
 Ollama + Local Services
        ↓
Telemetry / Actions / Memory
```

When the PC is offline:

```txt
HELIX Mobile
      ↓
 Gemini API Fallback
      ↓
 Cloud Processing
      ↓
 Deferred Sync Queue
```

Once the PC reconnects:

* Conversations sync automatically
* Context gets restored
* Pending actions update locally
* Memory/state rebuilds

---

# Features

## AI Routing

* Local Ollama inference
* Gemini fallback system
* Automatic AI switching
* Context continuity

## System Telemetry

* CPU usage
* GPU usage
* RAM monitoring
* Storage details
* Network monitoring
* Device/peripheral detection

## Local PC Actions

* Open applications
* Launch workflows
* Take notes
* Execute local commands
* Media/system controls

## Persistent Sync

* Offline conversation storage
* Automatic backend synchronization
* Cross-device continuity

## Connectivity

* Secure communication using Tailscale
* Auto-connect on PC startup
* Persistent HELIX node availability

---

# Tech Stack

## Frontend

* Flutter

## AI

* Ollama
* Gemini API

## Networking

* Tailscale

## Planned Backend

* FastAPI
* WebSockets
* SQLite

---

# Vision

H E L I X is not intended to be just another chatbot.

The goal is to create:

> A persistent hybrid AI ecosystem that lives across devices.

A personal intelligence layer capable of:

* understanding context
* controlling systems
* syncing memory
* adapting dynamically
* operating locally and remotely

---

# Current Status

Early development stage.

Core infrastructure and hybrid architecture are actively being built.

---

# Roadmap

* [ ] Real-time telemetry dashboard
* [ ] Voice interaction
* [ ] Smart memory system
* [ ] Intent routing engine
* [ ] Local AI orchestration
* [ ] Cross-device notifications
* [ ] Plugin/action framework
* [ ] PC filesystem integration
* [ ] Wake-word support
* [ ] Multi-node support

---

# Security

H E L I X is designed with a local-first approach.

* Secure Tailscale networking
* No exposed local endpoints
* Controlled command execution
* Planned authentication layer
* Planned permission-based actions

---

# Repository Structure

```txt
lib/
 ├── ai/
 ├── core/
 ├── telemetry/
 ├── actions/
 ├── memory/
 ├── sync/
 ├── services/
 ├── widgets/
 ├── models/
 └── main.dart
```

---

# Philosophy

Most assistants are chatbots.

H E L I X aims to become an operating system layer for personal intelligence.

---

# Author

Samayran
Founder of H E L I X
