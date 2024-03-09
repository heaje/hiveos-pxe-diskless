ARG ubuntu_version

FROM hiveos-kernel AS kernel

FROM ubuntu:${ubuntu_version}
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Setup APT
RUN apt update && \
    apt -y install curl netbase whois && \
    apt clean
RUN cc=$(whois $(curl -s ifconfig.me) | grep -iE ^country: | awk '{print tolower($2)}'|tr -d '\n') && \
    [[ ! -z $cc ]] && sed -i -r -e "s,^(.+)(archive.ubuntu.com/)(.+),\1${cc}.\2\3,g" /etc/apt/sources.list
RUN echo -e "APT::Install-Recommends "0";\nAPT::Install-Suggests "0";" > /etc/apt/apt.conf.d/99norecommend
COPY configs/hive.gpg /etc/apt/trusted.gpg.d/
ARG hive_repo=http://download.hiveos.farm/repo/binary
RUN echo "deb ${hive_repo} /" > /etc/apt/sources.list.d/hiverepo.list

# Setup users
ARG user_password="1"
ARG root_password="hunter2"
RUN useradd -m -p '${user_password}' -s /bin/bash user &&\
    echo 'root:${root_password}' | chpasswd -c SHA256

# Install packages / Locales
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections && \
    apt update && \
    apt -y upgrade && \
    apt -y install busybox-static cron dbus dmidecode file gettext-base hive isc-dhcp-common libnuma1 locales locales-all logrotate mc net-tools pciutils psmisc rsyslog ubuntu-minimal usbutils wget x11-xkb-utils && \
    apt clean
RUN locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN /hive/bin/repover-touch

# Install Kernel Modules
ARG kernel_src_path="./kernel"
COPY --from=kernel /kernel/linux-image-*.deb .
RUN dpkg -i linux-image-*.deb &&\
    rm linux-image-*.deb
ARG rtl_nic_tag="20240115"
RUN mkdir -p /lib/firmware/updates/rtl_nic/ &&\
    curl -sq https://kernel.googlesource.com/pub/scm/linux/kernel/git/firmware/linux-firmware.git/+archive/refs/tags/${rtl_nic_tag}/rtl_nic.tar.gz | tar -xzf - -C /lib/firmware/updates/rtl_nic/

# Miscellaneous system setup
COPY container/hiveos/root/ /.
RUN mkdir -p /hive-config &&\
    echo "/sbin/depmod" >> /lib/lsb/init-functions &&\
    echo "/sbin/ldconfig" >> /lib/lsb/init-functions &&\
    ln -sf /hive/etc/pci.ids /usr/share/misc/pci.ids

# Enable Systemd services
RUN systemctl enable hive ssh systemd-networkd systemd-resolved rsyslog

# Customizations
ARG extra_packages
RUN apt update && \
    apt -y install ${extra_packages} &&\
    apt clean
COPY --chmod=750 scripts/* /tmp/.
RUN for i in $(ls /tmp/*.sh); do ${i}; done;

# Disable Systemd services (if necessary)
ARG disable_services
RUN for i in getty@tty1; do systemctl disable ${i}; done;

# Remaining cleanup
RUN rm -rf ${DIR}/usr/share/locale/* &&\
    rm -rf ${DIR}/usr/share/doc/*
