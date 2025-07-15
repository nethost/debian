# nethost/debian

## Overview

**`nethost/debian`** is a minimal, production-ready container base image, fully compatible with [Google’s distroless static-debian](https://github.com/GoogleContainerTools/distroless) image.  
This image includes only the essential runtime environment (filesystem, root certificates, time zone data, etc.), and **excludes** any shell, package manager, or debugging tools.

It is designed for running statically compiled applications (such as Go or Rust binaries) in secure, lightweight, and modern cloud-native environments.

---

## Features

- **Ultra lightweight**: Image size is only a few MB, enabling fast pulls and startup.
- **Maximum security**: No shell, no package manager, no debugging tools – reduces attack surface and vulnerabilities.
- **Fully compatible**: Drop-in replacement for Google’s distroless static-debian image.
- **Cloud-native ready**: Suited for Kubernetes, serverless, CI/CD pipelines, and other production-grade deployments.

---

## Usage Example

Assuming you have a statically compiled Go application:

```dockerfile
# Stage 1: Build your app
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Stage 2: Minimal runtime
FROM nethost/debian:12
COPY --from=builder /app/myapp /myapp
CMD ["/myapp"]
```

- All application logs should be written to stdout/stderr for collection by your container platform.

---

## Notes

- This image **does not** include shell (`sh`/`bash`), package managers (`apt`/`yum`/`apk`), or debugging utilities.
- All dependencies (including dynamic libraries, certificates, config files, etc.) must be included via multi-stage builds.
- For troubleshooting, consider using a debug sidecar container or ephemeral containers with your orchestrator.

---

## Recommended Use Cases

- Production deployments of statically compiled binaries (Go, Rust, C, etc.)
- Microservices requiring minimal image size and high security
- Environments with strict compliance and supply chain security requirements

---

## References

- [GoogleContainerTools/distroless (GitHub)](https://github.com/GoogleContainerTools/distroless)
- [Distroless container images: best practices (Google Cloud Blog)](https://cloud.google.com/blog/products/containers-kubernetes/introducing-distroless-container-images)

---

## License

This image is fully compatible with and follows the licensing of [Google’s distroless static-debian](https://github.com/GoogleContainerTools/distroless).
