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

# Create non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

WORKDIR /app

COPY --from=builder /app/fiberapp .

# Set ownership and permissions
RUN chown appuser:appgroup /app/fiberapp && \
    chmod +x /app/fiberapp

USER 1001

EXPOSE 8080

CMD ["./fiberapp"]
