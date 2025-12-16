FROM golang:latest AS builder

COPY . /app

WORKDIR /app

# Download Go modules
RUN go get wh
# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /build/wh

FROM scratch

ENV PORT=3000

LABEL maintainer="Serhii Nesterenko <ser@nesterenko.net>"
LABEL version=0.1

WORKDIR /app
COPY --from=builder /build/wh wh
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE ${PORT}

# Run
CMD ["/app/wh"]
