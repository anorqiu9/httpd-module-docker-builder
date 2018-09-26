
#!/bin/bash
set -x
set -e

############################
#
# This script is used to create a docker images installed httpd 2.2.x
#
# $1 openssl src package uri
#
# $2 httpd src package uri
#
# $3 httpd module src local path
#
# $4 docker image name

pkg_uri_openssl=$1
pkg_uri_httpd=$2
httpd_module_src_dir=$3
docker_image_name=$4 #awsfilter-builder-httpd-2.2

docker build \
	--rm \
	--tag anor/httpd_module_compiler_base \
	--file $(pwd)/Dockerfile.base \
	. \
&& \
docker build \
	--rm \
	--build-arg pkg_uri_openssl="$pkg_uri_openssl" \
	--build-arg pkg_uri_httpd="$pkg_uri_httpd" \
	--tag $docker_image_name \
	--file	$(pwd)/Dockerfile.httpd-2.2 \
	. \
&& \
docker run \
	--rm \
	--volume "$httpd_module_src_dir":/usr/src/httpd-module \
	$docker_image_name \
&& \
ls -alR "$httpd_module_src_dir"/dist \
&& \
echo Done!

	

