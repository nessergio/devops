FROM golang:latest AS builder

COPY . /app

WORKDIR /app

# Download Go modules
RUN go get service-a
# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /build/service-a

FROM scratch

ENV PORT=3000

LABEL maintainer="Serhii Nesterenko <ser@nesterenko.net>"
LABEL version=0.1

WORKDIR /app
COPY --from=builder /build/service-a service-a

EXPOSE ${PORT}

# Run
CMD ["/app/service-a"]
