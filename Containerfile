# Dockerfile for building a customized Fedora-based container image

ARG IMAGE_NAME="beblito-cachy"


FROM quay.io/fedora-ostree-desktops/kinoite:40


COPY system_files /

RUN curl -Lo /usr/bin/copr https://raw.githubusercontent.com/ublue-os/COPR-command/main/copr && \
    chmod +x /usr/bin/copr && \
    curl -Lo /etc/yum.repos.d/bieszczaders-kernel-cachyos-fedora-40.repo https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos/repo/fedora-40/bieszczaders-kernel-cachyos-fedora-40.repo && \
    curl -Lo /etc/yum.repos.d/bieszczaders-kernel-cachyos-addons-fedora-40.repo https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos-addons/repo/fedora-40/bieszczaders-kernel-cachyos-addons-fedora-40.repo && \
    curl -Lo /etc/yum.repos.d/tigro-better_fonts-fedora-40.repo \
        https://copr.fedorainfracloud.org/coprs/tigro/better_fonts/repo/fedora-40/tigro-better_fonts-fedora-40.repo && \
    curl -L https://negativo17.org/repos/fedora-nvidia.repo -o /etc/yum.repos.d/fedora-nvidia.repo && \
    ostree container commit

RUN rpm-ostree cliwrap install-to-root /

RUN rpm-ostree override remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra --install kernel-cachyos && \
    rpm-ostree install kernel-cachyos-core kernel-cachyos-modules && \
    rpm-ostree install libcap-ng-devel procps-ng-devel && \
    rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:bieszczaders:kernel-cachyos-addons libbpf && \
    rpm-ostree install uksmd sched-ext-scx && \
    ostree container commit

COPY *.sh /tmp/
COPY --from=ghcr.io/dantesieg/beblito-akmod-cachy:latest /rpms /tmp/akmods-rpms
RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit

RUN rpm-ostree install \
        fontconfig-font-replacements \
        fontconfig-enhanced-defaults \
        distrobox \
        jetbrains-mono-fonts && \
    ostree container commit

RUN rpm-ostree override remove \
        firefox \
        firefox-langpacks \
        krfb \
        krfb-libs \
        dnf5 \
        dnf-data \
        libdnf5 \
        libdnf5-cli \
        kde-connect \
        kde-connect-libs \
        sdbus-cpp && \
    ostree container commit

## NOTES:
# - /var/lib/alternatives is required to prevent failure with some RPM installs
# - All RUN commands must end with ostree container commit
#   see: https://coreos.github.io/rpm-ostree/container/#using-ostree-container-commit
