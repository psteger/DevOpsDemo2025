# --- Build & Test Stage ---
FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Run tests — fail build if any test fails
RUN go test ./... -v

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o fiberapp .

# --- Runtime Stage ---
FROM alpine:3.23

WORKDIR /root/

COPY --from=builder /app/fiberapp .

EXPOSE 8080

CMD ["./fiberapp"]
