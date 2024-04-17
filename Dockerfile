# Build the manager binary
FROM golang:1.21 as builder

WORKDIR /go/src/github.com/argoproj-labs/argocd-operator
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY build/redis /append/var/lib/redis
COPY grafana /append/var/lib/grafana
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY common/ common/
COPY controllers/ controllers/
COPY version/ version/

# Build
ARG LD_FLAGS
RUN echo IyEvYmluL3NoCnNldCAtZXgKZ3JlcCBSdW5Bc05vblJvb3Q6IC1ybCB8IGdyZXAgLmdvJCB8IHhhcmdzIFwKICBzZWQgLWkgLUUgJ3N+KFJ1bkFzTm9uUm9vdDouK2Jvb2xQdHIpLissflwxKGZhbHNlKSx+ZycKZ3JlcCBFbXB0eURpclZvbHVtZVNvdXJjZSAtcmwgfCBncmVwIC5nbyQgfCB4YXJncyBcCiAgc2VkIC1pIC1FICdzfkVtcHR5RGlyVm9sdW1lU291cmNlXHtcfX5FbXB0eURpclZvbHVtZVNvdXJjZVx7TWVkaXVtOiBjb3JldjEuU3RvcmFnZU1lZGl1bU1lbW9yeVx9fmcnCmdyZXAgSW1hZ2VQdWxsUG9saWN5OiAtcmwgfCBncmVwIC5nbyQgfCB4YXJncyBcCiAgc2VkIC1pIC1FICdzfkltYWdlUHVsbFBvbGljeTouKyx+SW1hZ2VQdWxsUG9saWN5OiBjb3JldjEuUHVsbElmTm90UHJlc2VudCx+ZycK | base64 -d | sh
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="$LD_FLAGS" -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM alpine:3.16
COPY --from=builder /go/src/github.com/argoproj-labs/argocd-operator/manager /append /
USER 999:999
ENTRYPOINT ["/manager"]
