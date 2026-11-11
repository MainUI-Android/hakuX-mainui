#!/usr/bin/env bash
# MainUI-Android CI: the native core's third-party sources (CMake NC_DEPS), at the revisions
# android/README.md names, into $1. Keep in step with that table.
set -euo pipefail
deps="${1:?dir}"
mkdir -p "$deps"

# at <dir> <url> <ref...>: a shallow checkout of the first ref that exists (tag or full sha).
at() {
  local dir="$deps/$1" url="$2"; shift 2
  [ -d "$dir/.git" ] && return 0
  git init -q "$dir"
  for ref in "$@"; do
    if git -C "$dir" fetch -q --depth 1 "$url" "$ref" 2>/dev/null; then
      git -C "$dir" checkout -q FETCH_HEAD
      echo "$(basename "$dir"): $ref"
      return 0
    fi
  done
  echo "::error::$1: none of $* in $url" >&2
  return 1
}

at volk https://github.com/zeux/volk.git 1.4.304 vulkan-sdk-1.4.304.0
at glslang https://github.com/KhronosGroup/glslang.git 16.1.0
at spirv_reflect https://github.com/KhronosGroup/SPIRV-Reflect.git vulkan-sdk-1.4.328.0
at vma https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git v3.3.0
at SDL3 https://github.com/libsdl-org/SDL.git release-3.4.18
at libslirp https://gitlab.freedesktop.org/slirp/libslirp.git v4.7.0

# adrenotools 8fae8ce, with the KGSL context priority hook patch.
if [ ! -d "$deps/adrenotools/.git" ]; then
  at adrenotools https://github.com/bylaws/libadrenotools.git 8fae8ce254dfc1344527e05301e43f37dea2df80
  git -C "$deps/adrenotools" submodule update -q --init --depth 1
  git -C "$deps/adrenotools" apply "$(pwd)/tools/native/adrenotools-kgsl-context-priority.patch"
fi

# nv2a_vsh_cpu 561fe80 (a short sha: a full clone, it is small).
if [ ! -d "$deps/root/subprojects/nv2a_vsh_cpu/.git" ]; then
  mkdir -p "$deps/root/subprojects"
  git clone -q https://github.com/abaire/nv2a_vsh_cpu.git "$deps/root/subprojects/nv2a_vsh_cpu"
  git -C "$deps/root/subprojects/nv2a_vsh_cpu" checkout -q 561fe80
  echo "nv2a_vsh_cpu: 561fe80"
fi
