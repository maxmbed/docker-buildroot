
set -x

# Root directory
rootdir=/

# Work directory
workdir=${rootdir}buildroot-home

# Container volumes
buildroot_dir=${workdir}/buildroot
cache_dir=${workdir}/cache
build_dir=${workdir}/target-builds

# Bind directory
materials_dir=${workdir}/materials

# Log
log_dir=${workdir}/logs
sdk_dir=${cache_dir}/sdk

# In/Out directory
image_dir=${materials_dir}/images
target_yaml=${materials_dir}/target.yaml

log_file() {
  local log_mesg=$1
  local log_file=$2

  echo "$(date +"%Y-%m-%d %H:%M:%S") ${log_mesg}" >> ${log_file}
}

log_shell() {
  echo $1
}

log_export() {
  cp -r ${log_dir} ${materials_dir}
  sleep 1
}

trap log_export SIGINT

# Build the sdk 
buildroot_build_sdk() {
  local target=$1
  local status_file=${log_dir}/buildroot_sdk.status
  local log_file_path=${log_dir}/buildroot_sdk.log
  local target_build_dir=${build_dir}/${target}

  local defconfig=$(yq -r ".$target.sdk.defconfig" ${target_yaml})
  local sdk_archive=$(yq -r ".$target.sdk.toolchain_archive" ${target_yaml})
  local num_proc=$(yq -r ".$target.nproc" ${target_yaml})
  cd ${workdir}

  # Clean logs
  rm -fv ${log_file_path}
  rm -fv ${status_file}

  log_file "build sdk start" ${status_file}

  # Set sdk config
  cp ${workdir}/${defconfig} ${buildroot_dir}/configs
  if [ $? -ne 0 ]; then
    log_file "set sdk config failure" ${status_file}
    return 1
  fi
  log_file "set sdk config success" ${status_file}

  # Set target build directory
  mkdir -p ${target_build_dir}
  cd ${target_build_dir}

  # Build sdk
  log_file "build running" ${status_file}

  if ! make O=${target_build_dir} -C ${buildroot_dir} $(basename ${defconfig}) &>> ${log_file_path}; then
    log_shell "set defconfig failure"
    log_file "set defconfig failure" ${status_file}
    return 1
  fi

  if ! make sdk -j${num_proc} &>> ${log_file_path}; then
    log_shell "build sdk failure"
    log_file "build failure" ${status_file}
    return 1
  fi
  log_file "build success" ${status_file}

  # Cache sdk archive
  mkdir -p ${sdk_dir}
  cp ${target_build_dir}/images/${sdk_archive} ${sdk_dir}
  if [ $? -ne 0 ]; then
    log_file "cache sdk failure" ${status_file}
    return 1
  fi
  log_file "cache sdk success" ${status_file}

  log_file "build sdk done" ${status_file}
  return 0
}

buildroot_build_image() {
  local target=$1
  local status_file=${log_dir}/buildroot_image.status
  local log_file_path=${log_dir}/buildroot_image.log
  local target_build_dir=${build_dir}/${target}

  local defconfig=$(yq -r ".$target.image.defconfig" ${target_yaml})
  local num_proc=$(yq -r ".$target.nproc" ${target_yaml})

  # Clean logs
  rm -fv ${log_file_path}
  rm -fv ${status_file}

  log_file "build image start" ${status_file}

  # Set image config
  cp ${workdir}/${defconfig} ${buildroot_dir}/configs
  if [ $? -ne 0 ]; then
    log_file "set image config failure" ${status_file}
    return 1
  fi
  log_file "set image config success" ${status_file}

  # Set target build directory
  mkdir -p ${target_build_dir}
  cd ${target_build_dir}

  # Build image
  log_file "build running" ${status_file}

  if ! make O=${target_build_dir} -C ${buildroot_dir} $(basename ${defconfig}) &>> ${log_file_path}; then
    log_shell "set defconfig failure"
    log_file "set defconfig failure" ${status_file}
    return 1
  fi

  if ! make -j${num_proc} &>> ${log_file_path}; then
    log_shell "build image failure"
    log_file "build failure" ${status_file}
    return 1
  fi

  # Exract images
  cp -r ${target_build_dir}/images ${materials_dir}
  if [ $? -ne 0 ]; then
    log_file "export images failure" ${status_file}
    return 1
  fi
  log_file "export images success" ${status_file}

  log_file "build image done" ${status_file}
  return 0
}

start_system() {
  log_shell "start system"
  local sdk_name=x86_64-buildroot-linux-gnu_sdk-buildroot
  local qemu_system=${sdk_dir}/${sdk_name}/bin/qemu-system-x86_64

  #${qemu_system} \
  #    -M pc \
  #    -kernel ${image_dir}/bzImage \
  #    -drive file=${image_dir}/rootfs.ext2,if=virtio,format=raw \
  #    -append "root=/dev/vda console=ttyS0" \
  #    -net user,hostfwd=tcp:127.0.0.1:3333-:22 \
  #    -net nic,model=virtio \
  #    -nographic

  ${qemu_system} \
      -machine q35 \
      -m 1G \
      -enable-kvm \
      -smp 4 \
      -cpu host,-kvm-pv-eoi,-kvm-pv-ipi,-kvm-asyncpf,-kvm-steal-time,-kvmclock \
      -kernel ${image_dir}/bzImage \
      -drive file=${image_dir}/rootfs.ext2,if=virtio,format=raw \
      -append "root=/dev/vda console=ttyS0 memmap=82M$0x3a000000 vmalloc=80M" \
      -netdev user,id=net -device e1000e,addr=2.0,netdev=net \
      -device pcie-pci-bridge \
      -nographic

  log_shell "exit system"
}

shell() {
  echo "entering shell"
  log_file  "entering shell" ${log_dir}/shell.log
  /bin/bash
  echo "exiting shell"
}

show_usage() {
  echo -e "Usage $0 -t <target-name> -b <build-type> [OPTION]"
  echo -e "\t -t: select target"
  echo -e "\t -b: select type of build"
  echo -e "\t -s: enter shell"
  echo -e "\t -x: execute target"
  echo -e "\t -k: keep container active after build"
}

target="qemu-x86_64"
build_type="all"
keep_session=0

while getopts ":st:b:xk" opt; do
case ${opt} in
  t)
    target=${OPTARG}
    ;;
  b)
    build_type=${OPTARG}
    ;;
  x)
    start_system
    exit 0
    ;;
  s)
    shell
    exit 0
    ;;
  k)
    keep_session=1
    ;;
  ?)
    show_usage
    exit 0
    ;;
esac
done

case ${build_type} in
  sdk)
    buildroot_build_sdk $target
    ;;
  image)
    buildroot_build_image $target
    ;;
  all)
    buildroot_build_sdk $target
    if [ $? -ne 0 ]; then
      log_export
      exit 1
    fi
    buildroot_build_image $target
    if [ $? -ne 0 ]; then
      log_export
      exit 2
    fi
    ;;
esac

if [ $keep_session -eq 1 ]; then
  echo "Keeping this session alive"
  shell
fi

log_export
