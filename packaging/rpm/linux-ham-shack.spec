Name:           linux-ham-shack
Version:        0.1.0
Release:        1%{?dist}
Summary:        Custom Quisk SDR station with Carla and PipeWire routing

License:        GPL-2.0-or-later
URL:            https://github.com

# Build dependencies for compiling Quisk C extensions
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  fftw-devel
BuildRequires:  alsa-lib-devel
BuildRequires:  pulseaudio-libs-devel
BuildRequires:  SoapySDR-devel

# Runtime dependencies for Quisk, Carla, and PipeWire
Requires:       python3
Requires:       python3-wxpython4
Requires:       python3-numpy
Requires:       python3-pyserial
Requires:       python3-pyusb
Requires:       pipewire
Requires:       pipewire-pulseaudio
Requires:       pipewire-jack-audio-connection-kit
Requires:       wireplumber
Requires:       carla
Requires:       lsp-plugins
Requires:       hamlib

Provides:       quisk = %{version}-%{release}
Conflicts:      quisk

%description
Builds and installs a custom Quisk fork along with pre-packaged
Carla audio processing, PipeWire virtual sinks, and udev rules.

%prep
# Assumes building directly from the checked-out repo with vendored subtrees

%build
cd %{_sourcedir}
%make_build

%install
cd %{_sourcedir}
%make_install

%post
udevadm control --reload-rules >/dev/null 2>&1 || :
udevadm trigger >/dev/null 2>&1 || :

%files
%{_bindir}/quisk
%{_bindir}/quisk_vna
%{_bindir}/quisk-station-init
%{python3_sitearch}/quisk*
%{_datadir}/linux-ham-shack/
%{_sysconfdir}/udev/rules.d/99-ham-radio.rules

%changelog
* Sat Nov 14 2026 Your Name <your.email@example.com> - 0.1.0
- Initial release with custom Quisk fork and PipeWire/Carla configs
