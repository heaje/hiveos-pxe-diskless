#!/bin/bash

work_dir=$1
nvidia_version=$2

driver_dir="${work_dir}/nvidia-${nvidia_version}"
pkg_dir="${work_dir}/pkg"
kernel_version=$(find /usr/src/linux-headers-* -maxdepth 0 -type d | sed -r 's/.+linux-headers-//') 

[ ! -d "${work_dir}" ] && mkdir -p "${work_dir}"
[ ! -d "${pkg_dir}" ] && mkdir -p "${pkg_dir}"
[ ! -d "${driver_dir}" ] && echo "Driver directory does not exist" && exit 
cd "${work_dir}"

# Build temporary packaging directories
mkdir -p "${pkg_dir}/usr/lib/modules/${kernel_version}/kernel/drivers/video"
mkdir -p "${pkg_dir}/usr/local/lib/nvidia"
mkdir -p "${pkg_dir}/usr/local/lib/xorg/modules/drivers"
mkdir -p "${pkg_dir}/usr/local/bin"
mkdir -p "${pkg_dir}"/etc/{ld.so.conf.d,modprobe.d}
mkdir -p "${pkg_dir}/usr/lib/firmware/nvidia/${nvidia_version}"
mkdir -p "${pkg_dir}/etc/OpenCL/vendors"

# Copy files to packaging directories
find "${driver_dir}/kernel" -type f -name '*.ko' -exec cp -r '{}' "${pkg_dir}/usr/lib/modules/${kernel_version}/kernel/drivers/video/" \; 
for i in libcuda.so libnvidia-opencl.so libnvidia-ml.so libnvidia-allocator.so libnvidia-cfg.so libnvidia-fbc.so libnvidia-gtk2.so libnvidia-gtk3.so libnvidia-ptxjitcompiler.so libnvidia-nvvm.so; do 
    file_name="${i}.${nvidia_version}"
    cp "${driver_dir}/${file_name}" "${pkg_dir}/usr/local/lib/nvidia/."
    ln -s "${pkg_dir}/usr/local/lib/nvidia/${file_name}" "${pkg_dir}/usr/local/lib/nvidia/${i}"
    ln -s "${pkg_dir}/usr/local/lib/nvidia/${file_name}" "${pkg_dir}/usr/local/lib/nvidia/${i}.1"
done
for i in nvidia-persistenced nvidia-settings nvidia-smi; do
    cp "${driver_dir}/${i}" "${pkg_dir}/usr/local/bin/"
done
cp "${driver_dir}/nvidia.icd" "${pkg_dir}/etc/OpenCL/vendors/"
cp "${driver_dir}"/firmware/*.bin "${pkg_dir}/usr/lib/firmware/nvidia/${nvidia_version}/"
cp "${driver_dir}/nvidia_drv.so" "${pkg_dir}/usr/local/lib/xorg/modules/drivers/"

# Build configuration
echo "options nvidia_drm modeset=1" > "${pkg_dir}/etc/modprobe.d/nvidia.conf"
echo "/usr/local/lib/nvidia" > "${pkg_dir}/etc/ld.so.conf.d/nvidia.conf"

# Create tarball
tar -C "${pkg_dir}" -cvpf - . | pixz -9 -e > "${work_dir}/nvidia-${nvidia_version}.tar.xz"