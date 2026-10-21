#!/bin/bash
set -euxo pipefail
shopt -s nullglob

# Workflow per https://fedoraproject.org/wiki/Building_a_custom_kernel/Source_RPM:
# fetch the rawhide kernel src.rpm from koji, unpack it, apply the external
# patch series on top of the Fedora-patched tree, build, install.
# koji: rawhide src.rpm - b4: fetches the lore patch series
dnf -y install koji b4 git rpm-build rpmdevtools dnf-plugins-core

# Resolves whatever is currently tagged into rawhide - always current, tag name doesn't change across releases
NVR=$(koji latest-build --quiet rawhide kernel | awk '{print $1}')
echo "Rawhide kernel: ${NVR}"

mkdir -p /tmp/kernel-srpm && cd /tmp/kernel-srpm
koji download-build --arch=src "${NVR}"

rpmdev-setuptree
# kojibuilder user/group warnings are expected and harmless
rpm -Uvh kernel-*.src.rpm

export PATH=/usr/sbin:$PATH  # modinfo lives in /usr/sbin

cd ~/rpmbuild/SPECS
dnf -y builddep kernel.spec

# Unique buildid so the custom kernel can't collide with the distro build
sed -i 's/# define buildid .local/%define buildid .parakeet/' kernel.spec
grep -q '%define buildid .parakeet' kernel.spec

# %prep only: unpack sources and apply all Fedora patches (no compilation)
rpmbuild -bp --target="$(uname -m)" kernel.spec

# BUILD layout (modern Fedora): BUILD/kernel-<ver>-build/kernel-<release>/linux-<full>/
SRC=$(find ~/rpmbuild/BUILD -mindepth 3 -maxdepth 3 -type d -name 'linux-*' | sort | head -n1)
[ -n "${SRC}" ] || { echo "kernel source tree not found in BUILD" >&2; exit 1; }
cd "${SRC}"

# Commit the Fedora tree, then git-am the external series on top of it
git init -q
git config user.name  "parakeet"
git config user.email "parakeet@localhost"
git add -A
git commit -q -m "Fedora ${NVR} sources"
BASE=$(git rev-parse HEAD)

b4 am -o - "https://lore.kernel.org/dri-devel/179182109533.3793653.8971698569867906952.b4-ty@b4/" > /tmp/kernel-srpm/series.mbx
git am /tmp/kernel-srpm/series.mbx

# linux-kernel-test.patch ships empty in the src.rpm and is applied last by
# kernel.spec, so exporting the delta there requires no spec edits
git diff "${BASE}" > ~/rpmbuild/SOURCES/linux-kernel-test.patch

# Hours-long build. --without debuginfo skips kernel-debuginfo;
# add --without debug to also skip the kernel-debug flavor.
rpmbuild -bb --target="$(uname -m)" --without debuginfo kernel.spec

# Install the freshly built kernel
cd ~/rpmbuild/RPMS/"$(uname -m)"
dnf -y remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra 2>/dev/null || true
rm -rf /usr/lib/modules/*
dnf -y install \
    ./kernel-core-*.rpm \
    ./kernel-modules-[0-9]*.rpm \
    ./kernel-modules-core-*.rpm \
    ./kernel-modules-extra-[0-9]*.rpm \
    ./kernel-[0-9]*.rpm

rm -rf /tmp/kernel-srpm
dnf -y remove koji

echo "custom rawhide kernel ${NVR}.parakeet installed"