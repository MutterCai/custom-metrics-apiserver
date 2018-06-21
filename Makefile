REGISTRY?=muttercai
IMAGE?=custom-metrics-apiserver
TEMP_DIR:=$(shell mktemp -d)

ARCH?=amd64
OUT_DIR?=./_output

VERSION?=latest
GOIMAGE=golang:1.8

.PHONY: all docker-build test verify-gofmt gofmt verify

all: build
build: vendor
	CGO_ENABLED=0 GOARCH=$(ARCH) go build -a -tags netgo -o $(OUT_DIR)/$(ARCH)/sample-adapter github.com/kubernetes-incubator/custom-metrics-apiserver

docker-build: vendor
	cp Dockerfile $(TEMP_DIR)
	cd $(TEMP_DIR)

	docker run -it -v $(TEMP_DIR):/build -v $(shell pwd):/go/src/github.com/kubernetes-incubator/custom-metrics-apiserver -e GOARCH=$(ARCH) $(GOIMAGE) /bin/bash -c "\
		CGO_ENABLED=0 go build -a -tags netgo -o /build/adapter github.com/kubernetes-incubator/custom-metrics-apiserver"

	docker build -t $(REGISTRY)/$(IMAGE)-$(ARCH):$(VERSION) $(TEMP_DIR)
	rm -rf $(TEMP_DIR)

vendor: glide.lock
	glide install -v

test: vendor
	CGO_ENABLED=0 go test ./pkg/...

verify-gofmt:
	./hack/gofmt-all.sh -v

gofmt:
	./hack/gofmt-all.sh

verify: verify-gofmt test
