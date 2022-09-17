# Source user env flags
include .env
export $(shell sed 's/=.*//' .env)

.PHONY: help	
help:
	@echo Usage:
	@echo "  make [target]"
	@echo
	@echo Targets:
	@awk -F ':|##' \
		'/^[^\t].+?:.*?##/ {\
			printf "  %-30s %s\n", $$1, $$NF \
		 }' $(MAKEFILE_LIST)

.PHONY: all
all : build

.PHONY: setup
setup: ## setup snap build environment
	@printf "${OKB}Setting up build environment on ${OKG}${VENV} ${NC}\n";
	@if [[ "$(VENV)" == rpi ]]; then\
		./scripts/lxd-setup.sh; fi;
	@python3 -m pip install -r requirements.txt;
	@printf "${OKG} ✓ ${NC} Complete\n";

.PHONY: lint
lint: ## Lint .yaml, .py and .sh files using yamllint, flake8 and shellcheck tools
	@printf "${OKB} Linting ${OKG}.yaml ${OKB}filesystems ...${NC}\n";
	@(yamllint . && printf "${OKG} ✓ ${NC} Pass\n"|| printf "${FAIL} ✗ ${NC} Fail\n")
	@printf "${OKB} Linting ${OKG}.sh ${OKB}filesystems ...${NC}\n";
	@(shellcheck bin/* scripts/*.sh && printf "${OKG} ✓ ${NC} Pass\n"|| printf "${FAIL} ✗ ${NC} Fail\n")
	@printf "${OKB} Linting ${OKG}.py ${OKB}filesystems ...${NC}\n";
	@(flake8 app && printf "${OKG} ✓ ${NC} Pass\n"|| printf "${FAIL} ✗ ${NC} Fail\n")

.PHONY: build
build: ## Build snap in virtual environment
	
	@printf "${OKB}Parsing snapcraft buildspec injecting ${OKG}${SNAP_NAME} ${ARCH}${NC}\n";
	@python3 scripts/yaml_parser.py "./snap/snapcraft.yaml"
	@printf "${OKB}Building snap ${OKG}${SNAP_NAME}${OKB} on ${OKG}${VENV}${NC}\n";
	@if [[ "${VENV}" != rpi || "${SNAPCRAFT_BUILD_ENVIRONMENT}" == host ]]; then \
		snapcraft --debug; \
	else \
		snapcraft --use-lxd --debug; fi
	@printf "${OKG} ✓ ${NC} Complete\n";

.PHONY: dist
dist: ## Install python package using setup.py
	@printf "${OKB}Building python package ... ${NC}\n";
	@python3 -m pip install --upgrade pip;
	@python3 -m pip install .;
	@printf "${OKG} ✓ ${NC} Complete\n";

.PHONY: start
start: ## Restarts an inactive instance
	@if [[ "$(VENV)" == rpi ]]; then \
		lxc start ${BUILD_VM};\
	else \
		multipass start ${BUILD_VM}; fi
	@printf "${OKG} ✓ ${NC} Complete\n";

.PHONY: shell
shell: start ## Launch active snap build VM and drop into shell
	@if [[ "$(VENV)" == rpi ]]; then \
		lxc exec ${BUILD_VM} -- /bin/bash; \
	else \
		multipass exec ${BUILD_VM} -- /bin/bash; fi
	@printf "${OKG} ✓ ${NC} Complete\n";

.PHONY: clean
clean: ## Clean snap build artefacts and teardown VM components
	@printf "${OKB}Cleaning build artefacts ... ${NC}\n";
	@if [[ "$(VENV)" == rpi ]]; then \
		snapcraft clean --use-lxd; \
		lxc stop ${BUILD_VM}; \
		lxc unmount ${BUILD_VM};\
		lxc delete ${BUILD_VM};\
	else \
		multipass stop ${BUILD_VM} ${RUN_VM}; \
		multipass unmount ${BUILD_VM} ${RUN_VM}; \
		multipass delete ${BUILD_VM} ${RUN_VM}; \
		multipass purge; fi;
	@if [ -f *.snap ]; then \
		rm -v *.snap; \
	fi;
	@printf "${OKG} ✓ ${NC} Complete\n";