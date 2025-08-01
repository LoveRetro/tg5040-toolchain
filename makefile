.PHONY: shell
.PHONY: clean

TOOLCHAIN_NAME=tg5040-modernize
IMAGE_REPO=ghcr.io/loveretro
IMAGE_NAME=${IMAGE_REPO}/${TOOLCHAIN_NAME}
WORKSPACE_DIR := $(shell pwd)/workspace

CONTAINER_NAME=$(shell docker ps -f "ancestor=$(IMAGE_NAME)" --format "{{.Names}}")
BOLD=$(shell tput bold)
NORM=$(shell tput sgr0)

.build: Dockerfile
	$(info $(BOLD)Building $(IMAGE_NAME)...$(NORM))
	mkdir -p ./workspace
	docker build -t ${IMAGE_NAME} .
	touch .build

ifeq ($(CONTAINER_NAME),)
shell: .build
	$(info $(BOLD)Starting $(IMAGE_NAME)...$(NORM))
	docker run -it --rm -v "$(WORKSPACE_DIR)":/root/workspace $(IMAGE_NAME) /bin/bash
else
shell:
	$(info $(BOLD)Connecting to running $(IMAGE_NAME)...$(NORM))
	docker exec -it $(CONTAINER_NAME) /bin/bash  
endif

clean:
	$(info $(BOLD)Removing $(IMAGE_NAME)...$(NORM))
	docker rmi $(IMAGE_NAME)
	rm -f .build
