PREFIX ?= /usr
SYSCONFDIR ?= /etc
PYTHON ?= python3
PY_INSTALL_ARGS ?=

.PHONY: build install clean

build:
	cd subtrees/quisk && $(PYTHON) setup.py build

install:
	# 1. Stage compiled Quisk fork
	cd subtrees/quisk && $(PYTHON) setup.py install \
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
	cd subtrees/quisk && $(PYTHON) setup.py clean --all
	rm -rf subtrees/quisk/build
