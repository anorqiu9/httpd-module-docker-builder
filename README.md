Overview

	This project is designed to build an apache httpd module which can be adopted with different versions of httpd depending on a variant version of openssl.
	With this project, a docker image will be built to install a specific version of httpd from its source code basing on installation of a specified version of openssl

Prerequisites

	1. Docker Engine installed. For more information, please refer to https://docs.docker.com
		And also, you can use, https://msstash.morningstar.com/users/aqiu/repos/linux-script-tools/browse/install_docker_on_CentOS7.sh, to install Docker engine on CentOS 7 or above.
	2. openssl soruce pakcage uri. (ftp://ftp.openssl.org/source)
	3. version number of the soname of openssl shared libraries. you can get it by run the following command on the runtime host
	rpm -ql openssl | grep -Em 1 "\/libssl.so.[^.]+" | xargs readelf -d | grep -Eo "soname: \[[^]]+\]"
	4. httpd source package uri (for 2.3 or later, source package uris of pcre, apr, apr-util are required too) (http://apache.fayea.com, http://archive.apache.org/dist)

How to Use

	1. get your module source code to put it into the folder, ./src/httpd-modules. Here are git urls for awsfilter and epiprepro modules.

	2. Call ./bin/build.sh to a docker image and then run it to build the module. We can run the following command to get the help.
	
		./bin/build.sh --help	

Examples

	Here are some examples,
		a, by URIs
			./bin/build.sh \
				./src/httpd-modules/filter \
				ftp://ftp.openssl.org/source/old/1.0.1/openssl-1.0.1e.tar.gz \
				http://archive.apache.org/dist/httpd/httpd-2.4.18.tar.gz  \
				10 \
				http://apache.fayea.com//apr/apr-1.5.2.tar.gz \
				http://apache.fayea.com//apr/apr-util-1.5.4.tar.gz \
				http://nchc.dl.sourceforge.net/project/pcre/pcre/8.39/pcre-8.39.tar.gz

		b, by version numbers
		  	./bin/build.sh \
				./src/httpd-modules/filter \
				openssl-1.0.1e \
				httpd-2.4.18 \
				10 \
				apr-1.5.2 \
				apr-util-1.5.2 \
				pcre-3.38.tar.gz
	
Pre-Scripts

	build_httpd-2.2.3-15_ssl-0.9.8e-1.0.1e.sh

		httpd-2.2.3/openssl-0.9.8e
		httpd-2.2.15/openssl-1.0.1e

Note that

	If you have created a build image, you can use ./bin/build_module.sh only to build a http module. For example,

		./bin/build_module.sh ./src/httpd-modules/filter httpd-2.2.15_openssl-1.0.1e_ssl_so_version_10

