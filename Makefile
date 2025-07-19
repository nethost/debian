# Makefile for syncing, signing, and attesting distroless images (digest+tag)

VERSIONS = 10 11 12
SRC_PREFIX = gcr.io/distroless/base-nossl-debian
DST_REGISTRIES = \
    registry.cn-shanghai.aliyuncs.com/nethost/debian \
    docker.io/nethost/debian \
    quay.io/nethost/debian \
    ghcr.io/nethost/debian

COSIGN_KEY = ../cosign.key
VERIFY_KEY = ./cosign.pub

.PHONY: all process verify

all: process

process:
	@for ver in $(VERSIONS); do \
	  src_img="$(SRC_PREFIX)$$ver"; \
	  for dst in $(DST_REGISTRIES); do \
	    dst_img="$$dst:$$ver"; \
	    echo "==> Copy $$src_img to $$dst_img"; \
	    regctl image copy "$$src_img" "$$dst_img"; \
	    echo "==> Get digest for $$dst_img"; \
	    digest=$$(regctl image digest "$$dst_img"); \
	    full_img="$$dst_img@$$digest"; \
	    echo "==> Cosign sign $$full_img (digest mode)"; \
	    COSIGN_PASSWORD="" cosign sign --yes --key $(COSIGN_KEY) "$$full_img"; \
	    echo "==> Cosign sign $$dst_img (tag mode)"; \
	    COSIGN_PASSWORD="" cosign sign --yes --key $(COSIGN_KEY) "$$dst_img"; \
	    echo "==> Generate SPDX SBOM for $$full_img"; \
	    syft "$$full_img" -o spdx-json > sbom.spdx.json; \
	    echo "==> Cosign SPDX attestation for $$full_img (digest mode)"; \
	    COSIGN_PASSWORD="" cosign attest --yes --predicate sbom.spdx.json --type spdx --key $(COSIGN_KEY) "$$full_img"; \
	    echo "==> Cosign SPDX attestation for $$dst_img (tag mode)"; \
	    COSIGN_PASSWORD="" cosign attest --yes --predicate sbom.spdx.json --type spdx --key $(COSIGN_KEY) "$$dst_img"; \
	    rm -f sbom.spdx.json; \
	    echo "==> Generate CycloneDX SBOM for $$full_img"; \
	    syft "$$full_img" -o cyclonedx-json > sbom.cdx.json; \
	    echo "==> Cosign CycloneDX attestation for $$full_img (digest mode)"; \
	    COSIGN_PASSWORD="" cosign attest --yes --predicate sbom.cdx.json --type cyclonedx --key $(COSIGN_KEY) "$$full_img"; \
	    echo "==> Cosign CycloneDX attestation for $$dst_img (tag mode)"; \
	    COSIGN_PASSWORD="" cosign attest --yes --predicate sbom.cdx.json --type cyclonedx --key $(COSIGN_KEY) "$$dst_img"; \
	    rm -f sbom.cdx.json; \
	    echo "==> Done for $$full_img and $$dst_img"; \
	    echo "-------------------------------------------"; \
	  done \
	done

verify:
	@pubkey="$(VERIFY_KEY)"; \
	if [ -z "$$pubkey" ]; then pubkey="cosign.pub"; fi; \
	for ver in $(VERSIONS); do \
	  for dst in $(DST_REGISTRIES); do \
	    img="$$dst:$$ver"; \
	    echo "==> Verifying signature for $$img"; \
	    cosign verify --key $$pubkey $$img; \
	    echo "==> Verifying attestation for $$img (spdx type)"; \
	    cosign verify-attestation --type spdx --key $$pubkey $$img; \
	    echo "-------------------------------------------"; \
	  done \
	done