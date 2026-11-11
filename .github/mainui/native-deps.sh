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

# libslirp 26be815b: after the v4.7.0 tag (it has slirp_ssize_t, which native/net/nat.c uses).
# A short sha: a full clone, it is small. v4.8.0 if that commit is gone.
if [ ! -d "$deps/libslirp/.git" ]; then
  git clone -q https://gitlab.freedesktop.org/slirp/libslirp.git "$deps/libslirp"
  for rev in 26be815b v4.8.0; do
    if git -C "$deps/libslirp" checkout -q "$rev" 2>/dev/null; then echo "libslirp: $rev"; break; fi
  done
fi

# adrenotools 8fae8ce, with the KGSL context priority hook patch.
if [ ! -d "$deps/adrenotools/.git" ]; then
  at adrenotools https://github.com/bylaws/libadrenotools.git 8fae8ce254dfc1344527e05301e43f37dea2df80
  git -C "$deps/adrenotools" submodule update -q --init --depth 1
  git -C "$deps/adrenotools" apply "$(pwd)/tools/native/adrenotools-kgsl-context-priority.patch"
fi

# nv2a_vsh_cpu: README's 561fe80 is from the author's local tree (not in any public repository);
# else the revision xemu's own wrap pins (subprojects/nv2a_vsh_cpu.wrap). A full clone: it is small.
if [ ! -d "$deps/root/subprojects/nv2a_vsh_cpu/.git" ]; then
  mkdir -p "$deps/root/subprojects"
  vsh="$deps/root/subprojects/nv2a_vsh_cpu"
  git clone -q https://github.com/xemu-project/nv2a_vsh_cpu.git "$vsh"
  for rev in 561fe80 89315e8eff62605d2a96fe14429ebeac1dacaa8c; do
    if git -C "$vsh" checkout -q "$rev" 2>/dev/null; then echo "nv2a_vsh_cpu: $rev"; break; fi
  done
fi
