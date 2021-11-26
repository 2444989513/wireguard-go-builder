#!/usr/bin/env bash
# ref: https://github.com/AlexanderOMara/wireguard-go-builds/blob/master/build.sh

set -e
set -u

version="${WGGO_VERSION}"

src_file="wireguard-go-${version}.zip"
src_filel="${version}.zip"
src_url="https://github.com/2444989513/wireguard-go/archive/refs/tags/${src_filel}"

base_dir="$PWD"
vendor_dir="$base_dir/vendor"
src_dir="$base_dir/src"
build_dir="$base_dir/build"
src_file_path="$vendor_dir/$src_file"

# Remove existing build directories (add write access to src directories to avoid permission issues).
chmod -R u+w "$src_dir" || true
rm -rf "$vendor_dir" "$src_dir" "$build_dir"
mkdir -p "$vendor_dir" "$src_dir" "$build_dir"

# Get and verify extract source file.
wget -O "$src_file_path" "$src_url"
unzip -qq "$src_file_path" -d "$base_dir"
mv "$base_dir"/wireguard-go-"${version}"/* "${src_dir}"
# && tar -Jcvf "$vendor_dir"/wireguard-go-"${version}".tar.xz "$base_dir"/wireguard-go-"${version}"
#tar --strip-components=1 -C "$src_dir" -xJf "$vendor_dir"/wireguard-go-"${version}".tar.xz

# Patch Makefile to remove building on Linux check.
sed -i.bak 's/$(wildcard .git),linux/$(wildcard .git),linux_check_disabled/g' "$src_dir/Makefile"

        #cd "${src_dir}"
        pushd "$src_dir" > /dev/null
        go get ./...
       # go get -u ./...
   #     go mod tidy
   #     go mod vendor
   #     go mod verify
   #     go mod download
       # go get ./...
       # go get -u ./...
   #     go mod tidy
   #     go mod vendor
   #     go mod verify
   #     go mod download


# Build all the targets.
targets=(
	'darwin amd64'

	'linux 386'
	'linux amd64'
	'linux arm'
	'linux arm64'
	'linux ppc64'
	'linux ppc64le'
	'linux mips'
	'linux mipsle'

	'freebsd 386'
	'freebsd amd64'
	'freebsd arm'

	'openbsd amd64'
)
for target in "${targets[@]}"; do
	target_=($target)
	target_os="${target_[0]}"
	target_arch="${target_[1]}"
	build_archive_file="wireguard-go-$target_os-$target_arch.tar.gz"
	build_archive_path="$build_dir/$build_archive_file"
	build_archive_file_sha256="$build_archive_file.sha256"

	echo '------------------------------------------------------------'
	echo "Building: $target_os $target_arch"
	echo '------------------------------------------------------------'

	export GOOS="$target_os"
	export GOARCH="$target_arch"
	export CGO_ENABLED=0

	pushd "$src_dir" > /dev/null
	make
	tar cfz "$build_archive_path" wireguard-go*

	pushd "$build_dir" > /dev/null
	shasum -a 256 "$build_archive_file" > "$build_archive_file_sha256"
	cat "$build_archive_file_sha256"
	popd > /dev/null

	make clean

	popd > /dev/null
done
