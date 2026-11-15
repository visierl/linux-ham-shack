#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -f "subtrees/quisk/setup.py" ]]; then
    echo "Error: subtrees/quisk/setup.py not found."
    echo "Ensure the Quisk subtree has been added to subtrees/quisk before building."
    exit 1
fi

cleanup() {
    rm -rf "${REPO_ROOT}/debian" "${REPO_ROOT}/rpmbuild"
}
trap cleanup EXIT

source /etc/os-release

if [[ "${ID:-}" == "debian" || "${ID_LIKE:-}" == *"debian"* ]]; then
    echo "==> Detected Debian-based system. Installing build tools..."
    sudo apt-get update
    sudo apt-get install -y devscripts debhelper equivs
    sudo mk-build-deps -i -r -t "apt-get -y" packaging/debian/control

    echo "==> Staging packaging/debian and building .deb package..."
    rm -rf "${REPO_ROOT}/debian"
    cp -a packaging/debian "${REPO_ROOT}/debian"
    dpkg-buildpackage -us -uc -b

    echo "==> Installing linux-ham-shack..."
    sudo apt-get install -y ../linux-ham-shack_*.deb

elif [[ "${ID:-}" == "fedora" || "${ID_LIKE:-}" == *"rhel"* || "${ID_LIKE:-}" == *"fedora"* ]]; then
    echo "==> Detected RedHat/Fedora-based system. Installing build tools..."
    sudo dnf install -y rpm-build rpmdevtools dnf-plugins-core
    sudo dnf builddep -y packaging/rpm/linux-ham-shack.spec

    echo "==> Building .rpm package..."
    rpmbuild -bb --define "_topdir ${REPO_ROOT}/rpmbuild" \
                 --define "_sourcedir ${REPO_ROOT}" \
                 --build-in-place \
                 packaging/rpm/linux-ham-shack.spec

    echo "==> Installing linux-ham-shack..."
    sudo dnf install -y "${REPO_ROOT}"/rpmbuild/RPMS/*/linux-ham-shack-*.rpm
else
    echo "Unsupported distribution: ${ID:-unknown}"
    exit 1
fi

echo "==> Configuring user environment..."
quisk-station-init
