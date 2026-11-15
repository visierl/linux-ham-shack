PREFIX ?= /usr
SYSCONFDIR ?= /etc
SYSTEM_PYTHON ?= python3
VENV_DIR ?= $(CURDIR)/.build-venv
VENV_PYTHON := $(VENV_DIR)/bin/python
PY_INSTALL_ARGS ?=

.PHONY: venv build install clean

venv:
	@if [ ! -x "$(VENV_PYTHON)" ]; then \
		$(SYSTEM_PYTHON) -m venv --system-site-packages "$(VENV_DIR)"; \
		"$(VENV_PYTHON)" -m pip install --upgrade "setuptools>=77.0.0" "packaging>=24.2" wheel; \
	fi

build: venv
	cd subtrees/quisk && "$(VENV_PYTHON)" setup.py build

install: venv
	# 1. Stage compiled Quisk fork
	cd subtrees/quisk && "$(VENV_PYTHON)" setup.py install \
		--root=$(DESTDIR) \
		--prefix=$(PREFIX) \
		--no-compile \
		$(PY_INSTALL_ARGS)

	# 2. Stage station configuration templates
	install -d $(DESTDIR)$(PREFIX)/share/linux-ham-shack/configs
	cp -r configs/* $(DESTDIR)$(PREFIX)/share/linux-ham-shack/configs/

	# 3. Stage user setup script and udev rules
	install -Dm755 scripts/setup-user.sh $(DESTDIR)$(PREFIX)/bin/quisk-station-init
	install -Dm644 udev/99-ham-radio.rules $(DESTDIR)$(SYSCONFDIR)/udev/rules.d/99-ham-radio.rules

clean:
	rm -rf subtrees/quisk/build subtrees/quisk/*.egg-info "$(VENV_DIR)"
