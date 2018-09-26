#/bin/bash
#set -x
set -e

SRC_PKG_BASE_URI_OPENSSL=ftp://ftp.openssl.org/source/old
SRC_PKG_BASE_URI_RELEASE=http://apache.fayea.com
SRC_PKG_BASE_URI_ARCHIVE=http://archive.apache.org/dist

g_src_pkg_uri_openssl=
g_src_pkg_uri_httpd=
g_src_pkg_uri_apr=
g_src_pkg_uri_apr_util=
g_src_pkg_uri_pcre=

#Try to get available uri for openssl src package
#
# $1 -- openssl version, such as 0.9.8e
#
function get_openssl_src_package_uri()
{
	local version=$1

	local major_no=$(echo ${version} | awk -F . '{print $1}')
	local minor_no=$(echo ${version} | awk -F . '{print $2}')
	local build_no=$(echo ${version} | awk -F . '{print $3}')
	build_no=$(echo $build_no | grep -oE \^[0-9]+)
	
	if [ ${major_no} -eq 0 ]; then
		g_src_pkg_uri_openssl="$SRC_PKG_BASE_URI_OPENSSL/0.9.x/openssl-$version.tar.gz"
	else
		g_src_pkg_uri_openssl="$SRC_PKG_BASE_URI_OPENSSL/$major_no.$minor_no.$build_no/openssl-$version.tar.gz"
	fi
	
	#check the uri variable
	if ! wget -q --spider "$g_src_pkg_uri_openssl"; then
		echo "No valiable resource ($g_src_pkg_uri_openssl)"
		g_src_pkg_uri_openssl=	
		return 1
	fi

	return 0
}

#Try to get available uri for a apache project src package
#
# $1 -- package name prefix, such as httpd, apr, arp-util
# $2 -- version, such as 2.2.15
# $3 -- project name, such as httpd, apr, arp-util
#
function get_apache_src_package_uri()
{
	local pkg_name_prefix=$1
	local version=$2
	local project_name=${3:-$pkg_name_prefix}

	local path_in_uri="$project_name/$pkg_name_prefix-$version.tar.gz"
	local uri="${SRC_PKG_BASE_URI_ARCHIVE}/${path_in_uri}"

	#check if the release resource is available
	if ! wget -q --spider "$uri" ; then
		echo "No valiable resource ($uri)"
		uri="${SRC_PKG_BASE_URI_RELEASE}/${path_in_uri}"
	fi 

	if ! wget -q --spider "$uri"; then
		echo "No valiable resource ($uri)"
		return 1
	fi

	if [ $pkg_name_prefix == "apr-util" ] ; then
		pkg_name_prefix=apr_util	
	fi
	eval g_src_pkg_uri_$pkg_name_prefix=$uri

	return 0
}

#openssl-1.0.1e-30.el6_5.2.x86_64
#apr-util-1.3.9-3.el6_0.1.x86_64
#apr-1.3.9-5.el6_2.x86_64
#httpd-2.2.15-31.el6.centos.x86_64

#get openssl src pakcage uri
if get_openssl_src_package_uri 1.0.1e ; then
	echo $g_src_pkg_uri_openssl
else
	echo "FAILED: get openssl src package uri"
fi

#get apr uri
#if get_apache_src_package_uri apr 1.3.9 ; then
if get_apache_src_package_uri apr 1.5.2 ; then
	echo $g_src_pkg_uri_apr
else
	echo "FAILED: get apr src package uri"
fi

#get apr-util uri
#if get_apache_src_package_uri apr-util 1.3.9 apr ; then
if get_apache_src_package_uri apr-util 1.5.4 apr ; then
	echo $g_src_pkg_uri_apr_util
else
	echo "FAILED: get apr_util src package uri"
fi

#get httpd uri
#if get_apache_src_package_uri httpd 2.2.15 ; then
if get_apache_src_package_uri httpd 2.4.23 ; then
	echo $g_src_pkg_uri_httpd
else
	echo "FAILED: get httpd src package uri"
fi
