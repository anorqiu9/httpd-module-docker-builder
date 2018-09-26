#!/bin/bash
set -e
set -x

###########################################
#
# This script is used to create some docker images as follows:
# 
# 1. ms/awsfilter_builder:httpd-2.2.3_ssl-0.9.8e 
#	-- to build awsfilter with httpd 2.2.3 depending on openssl-0.9.8e
# 2. ms/epiprepro_builder:httpd-2.2.3_ssl-0.9.8e
# 	-- to build epiprepro with httpd 2.2.3 depdeing on openssl-0.9.8e
# 3. ms/awsfilter_builder:httpd-2.2.15_ssl-1.0.1e 
#	-- to build awsfilter with httpd 2.2.15 depending on openssl-1.0.1e
# 4. ms/epiprepro_builder:httpd-2.2.15_ssl-1.0.1e
# 	-- to build epiprepro with httpd 2.2.15 depdeing on openssl-1.0.1e

echo "building with httpd-2.2.3, openssl-0.9.8e"
#pkg_uri_openssl=ftp://ftp.openssl.org/source/old/0.9.x/openssl-0.9.8e.tar.gz
pkg_uri_openssl=http://ftp.nluug.nl/security/openssl/openssl-0.9.8e.tar.gz 
pkg_uri_httpd=http://archive.apache.org/dist/httpd/httpd-2.2.3.tar.gz
#get soname of openssl lib with the following command,
#	rpm -ql openssl | grep -Em 1 "\/libssl.so.[^.]+" | xargs readelf -d | grep -Eo "soname: \[[^]]+\]"	
#
soname_ver_openssl=6 

#to build awsfilter
./bin/build.sh \
	"$(pwd)/src/httpd-modules/filter" \
	"$pkg_uri_openssl" \
	"$pkg_uri_httpd" \
	"$soname_ver_openssl"
	
echo "building with httpd-2.2.15, openssl-1.0.1e"

#pkg_uri_openssl=ftp://ftp.openssl.org/source/old/1.0.1/openssl-1.0.1e.tar.gz
pkg_uri_openssl=http://ftp.nluug.nl/security/openssl/openssl-1.0.1e.tar.gz 
pkg_uri_httpd=http://archive.apache.org/dist/httpd/httpd-2.2.15.tar.gz
soname_ver_openssl=10 

#to build awsfilter
./bin/build.sh \
	"$(pwd)/src/httpd-modules/filter" \
	"$pkg_uri_openssl" \
	"$pkg_uri_httpd" \
