# Fiber Application

A lightweight REST API built with Go and Fiber v2 framework for DevOps demonstration purposes.

## Features

- Health check endpoint for monitoring
- RESTful API with JSON responses
- Docker containerization with multi-stage builds
- Comprehensive unit test coverage

## API Endpoints

- `GET /healthz` - Health check endpoint
- `GET /api/message` - Returns a message with timestamp

## Quick Start

### Prerequisites

- Go 1.25 or later
- Docker (optional)

### Local Development

1. Install dependencies:
   ```bash
   go mod download
   ```

2. Run the application:
   ```bash
   go run .
   ```

3. Test the endpoints:
   ```bash
   curl http://localhost:8080/healthz
   curl http://localhost:8080/api/message
   ```

### Testing

Run unit tests:
```bash
go test ./... -v
```

### Building

Build the application binary:
```bash
go build -o fiberapp .
```

### Docker

Build and run with Docker:
```bash
docker build -t fiberapp .
docker run -p 8080:8080 fiberapp
```

## Project Structure

- `main.go` - Application entry point and routing
- `handlers.go` - HTTP request handlers
- `handlers_test.go` - Unit tests
- `Dockerfile` - Multi-stage Docker build configuration

## Dependencies

- [Fiber v2](https://github.com/gofiber/fiber) - Web framework
- [Testify](https://github.com/stretchr/testify) - Testing utilities