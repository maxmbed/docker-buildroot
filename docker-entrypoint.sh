#!/bin/bash

if [ -f materials/debug_enable ]; then
  set -x
fi

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
  mkdir -p ${materials_dir}/logs
  cp -r ${log_dir}/ ${materials_dir}/
  sleep 1
}

interupt_sigint() {
  log_file "program interupted by signal SIGINT" ${status_file}
  log_shell "program interupted by signal SIGINT"
  log_export
}

trap interupt_sigint SIGINT

# Build buildroot image or sdk
buildroot_build() {
  if [ -z $1 ]; then
    log_shell "build type not defined"
    exit 1
  fi

  if [ -z $2 ]; then
    log_shell "target not defined"
    exit 1
  fi

  local build_type=$1
  local target=$2
  local target_log_dir=${log_dir}/${target%_defconfig}
  local status_file=${target_log_dir}/buildroot_${build_type}.status
  local log_file_path=${target_log_dir}/buildroot_${build_type}.log
  local target_build_dir=${build_dir}/${target}

  # Clean logs
  mkdir -p ${target_log_dir}
  rm -fv ${log_file_path}
  rm -fv ${status_file}
  cd ${workdir}

  # Test target is in yaml or inside buildroot
  if yq -e ".$target" "${target_yaml}" > /dev/null 2>&1; then
    # Target is defined in yaml
    local defconfig=$(yq -r ".$target.$build_type.defconfig" ${target_yaml})
    if [ $defconfig = null ]; then
      log_file "target $target defconfig could not be found in ${target_yaml}" ${status_file}
      return 1
    fi
      # Set config
      cp ${workdir}/${defconfig} ${buildroot_dir}/configs
      if [ $? -ne 0 ]; then
        log_file "set $build_type config failure" ${status_file}
        return 1
      fi
      log_file "set $build_type config success" ${status_file}
  else
    if [ -f $buildroot_dir/configs/$target ]; then
      # Target comes from Buildroot
      defconfig=$buildroot_dir/configs/$target
      target_build_dir=$(echo ${target_build_dir%_defconfig})
    else
      log_file "target $target could not be neither found in ${target_yaml} nor in ${buildroot_dir}/configs" ${status_file}
      return 1
    fi
  fi

  local num_proc=$(yq -r ".$target.nproc" ${target_yaml})
  if [ $num_proc = null ]; then
    # default 1 cpu
    num_proc=1
  fi

  log_file "build $build_type start" ${status_file}

  # Set target build directory
  mkdir -p ${target_build_dir}
  cd ${target_build_dir}

  # Build
  log_file "build running" ${status_file}

  make O=${target_build_dir} -C ${buildroot_dir} $(basename ${defconfig}) 2>&1 | tee --append ${log_file_path}
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_shell "set defconfig failure"
    log_file "set defconfig failure" ${status_file}
    return 1
  fi

  local make_cmd=(make)
  if [ "$build_type" = sdk ]; then
    make_cmd+=(sdk)
  fi

  "${make_cmd[@]}" -j${num_proc} 2>&1 | tee --append ${log_file_path}
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_shell "build $build_type failure"
    log_file "build $build_type failure" ${status_file}
    return 1
  fi
  log_file "build $build_type success" ${status_file}

  if [ "$build_type" = sdk ]; then
    # Cache sdk archive
    local sdk_archive=$(yq -r ".$target.sdk.toolchain_archive" ${target_yaml})

    mkdir -p ${sdk_dir}
    cp ${target_build_dir}/images/${sdk_archive} ${sdk_dir}
    if [ $? -ne 0 ]; then
      log_file "cache sdk failure" ${status_file}
      return 1
    fi
    log_file "cache sdk success" ${status_file}

  elif [ "$build_type" = image ]; then
    # Exract images
    cp -r ${target_build_dir}/images ${materials_dir}
    if [ $? -ne 0 ]; then
      log_file "export images failure" ${status_file}
      return 1
    fi
    log_file "export images success" ${status_file}
  fi

  log_file "build $build_type done" ${status_file}
  return 0
}

buildroot_cmd() {
  local build_cmd=$1
  local target=$2
  local target_log_dir=${log_dir}/${target%_defconfig}
  local status_file=${target_log_dir}/buildroot_${build_type}.status
  local log_file_path=${target_log_dir}/buildroot_${build_type}.log
  local target_build_dir=${build_dir}/${target}

  # Clean logs
  mkdir -p ${target_log_dir}
  rm -fv ${log_file_path}
  rm -fv ${status_file}
  cd ${workdir}

  case "$build_cmd" in
    menuconfig | linux-menuconfig)
      # Interactive command (ncurses): stdin/stdout must stay TTY
      # No pipe, no redirection and so no poissble log
      make O=${target_build_dir} -C ${buildroot_dir} $build_cmd
      rc=$?
      ;;
    *)
      make O=${target_build_dir} -C ${buildroot_dir} $build_cmd 2>&1 | tee --append ${log_file_path}
      rc=${PIPESTATUS[0]}
      ;;
  esac

  if [ $rc -ne 0 ]; then
    log_shell "build command $build_cmd failed"
    log_file "build command $build_cmd failed" ${status_file}
    return 1
  fi

  return 0
}

run_target() {
  log_shell "running target"
  local target=$1
  mapfile -t run_list < <(yq -r ".$target.run[]" ${target_yaml})

  for run_cmd in "${run_list[@]}"
  do
    eval $run_cmd
  done
  log_shell "ending run target"
}

shell() {
  local target=$1

  log_shell "entering shell"
  log_file  "entering shell" ${log_dir}/shell.log

  if [[ -n $target && -d "${build_dir}/${target}" ]]; then
    cd ${build_dir}/$target
  else
    cd ${workdir}
  fi
  /bin/bash
  echo "exiting shell"
}

show_usage() {
  echo -e "Usage $0 -t <target-name> -b <build-type> [OPTION]"
  echo -e "\t -t: select target"
  echo -e "\t -b: select type of build"
  echo -e "\t -s: enter shell"
  echo -e "\t -x: run target"
  echo -e "\t -k: keep container active after build"
}

target=""
build_type="all"
keep_session=0
enter_shell=0

while getopts ":st:b:x:k" opt; do
case ${opt} in
  t)
    target=${OPTARG}
    ;;
  b)
    build_type=${OPTARG}
    ;;
  x)
    run_target ${OPTARG}
    exit 0
    ;;
  s)
    enter_shell=1
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

if [ $enter_shell -eq 1 ]; then
  shell $target
  exit 0
fi

case ${build_type} in
  sdk | image)
    buildroot_build $build_type $target
    ;;
  *)
    buildroot_cmd $build_type $target
    ;;
  all)
    buildroot_build sdk $target
    if [ $? -ne 0 ]; then
      log_export
      exit 1
    fi
    buildroot_build image $target
    if [ $? -ne 0 ]; then
      log_export
      exit 2
    fi
    ;;
  ?)
    echo "Unknown build type"
    exit 1
    ;;
esac

if [ $keep_session -eq 1 ]; then
  echo "Keeping this session alive"
  shell $target
fi

log_export
