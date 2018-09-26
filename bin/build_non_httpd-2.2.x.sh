#!/bin/bash
set -x
set -e

############################
#
# This script is used to build a docker image installed httpd 2.3 or later
#
# $1 openssl src package uri
#
# $2 pcre src package uri
# 
# $3 apr src package uri
#
# $4 apr-util src package uri
#
# $5 httpd src package uri
#
# $6 httpd module src local path
#
# $7 docker image name

pkg_uri_openssl=$1
pkg_uri_pcre=$2
pkg_uri_apr=$3
pkg_uri_apr_util=$4
pkg_uri_httpd=$5

httpd_module_src_dir=$6
docker_image_name=$7 #awsfilter-builder-httpd-2.2

docker build \
	--rm \
	--tag anor/httpd_module_compiler_base \
	--file $(pwd)/Dockerfile.base \
	. \
&& \
docker build \
	--rm \
	--build-arg pkg_uri_openssl="$pkg_uri_openssl" \
	--build-arg pkg_uri_pcre="$pkg_uri_pcre" \
	--build-arg pkg_uri_apr="$pkg_uri_apr" \
	--build-arg pkg_uri_apr_util="$pkg_uri_apr_util" \
	--build-arg pkg_uri_httpd="$pkg_uri_httpd" \
	--tag $docker_image_name \
	--file	$(pwd)/Dockerfile \
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


