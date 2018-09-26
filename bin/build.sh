#!/bin/bash
set -x
set -e

usage()
{

cat <<EOF
Usage:
	`basename $0` 
		<httpd module src path> 
		<openssl src identity> 
		<httpd src identity> 
		[openssl lib soname version] 
		[apr src identity] 
		[apr-util src identity] 
		[pcre src identity]  

Purpose:
	Build a docker image and then build a httpd module 

Description:
	Build a docker image with openssl and httpd of specified verions and then build a httpd module by running the images.

Parameters:

	httpd module src path -- a local path for a httpd module source code
	openssl src path -- openssl source code path identity
	httpd src path -- Apache httpd source code path identity
	
	[OPTIONS]

	The following parameters are optional, just required with httpd 2.3 or later versions

	openssl lib soname version -- the soname version of libssl.so and libcrypto.so
	apr src path -- Apache Portable Runtime source code path identity
	apr-util src path -- Apache Portable Runtime Utility source code path identity
	pcre src path -- Perl Compatible Regular Expression source code path identity. It must be a valid URI, if not set, the following uri will be used.
		
		http://nchc.dl.sourceforge.net/project/pcre/pcre/8.39/pcre-8.39.tar.gz
	
	****Please Note****
	
	a source code identity above should be one of these,
	
		a. An URI
		
			The URIs must be refered to tar zip resources, 
			
			For example, 
			
				ftp://ftp.openssl.org/source/old/0.9.x/openssl-0.9.8e.tar.gz
				http://archive.apache.org/dist/httpd/httpd-2.2.3.tar.gz
				ftp://ftp.openssl.org/source/old/1.0.1/openssl-1.0.1e.tar.gz
				http://archive.apache.org/dist/httpd/httpd-2.2.15.tar.gz
				http://nchc.dl.sourceforge.net/project/pcre/pcre/8.39/pcre-8.39.tar.gz
				http://apache.fayea.com//apr/apr-1.5.2.tar.gz
				http://apache.fayea.com//apr/apr-util-1.5.4.tar.gz

		b. A version number
			A format of a version number must be as follows,
			
				[project name-]<Major No>.<Minor No>.<Build/Fixing No>[-suffix].  
				
			For example, 2.2.15, or httpd-2.2.15, 1.0.1e, openssl-1.0.1e
	
Author:
	anorqiu@163.com

Revision:
	2016-09-12 Anor Initial Versiona

EOF
	exit 1
}

declare -r SRC_PKG_BASE_URI_OPENSSL=ftp://ftp.openssl.org/source/old
declare -r SRC_PKG_BASE_URI_RELEASE=http://apache.fayea.com
declare -r SRC_PKG_BASE_URI_ARCHIVE=http://archive.apache.org/dist

g_httpd_mod_src_path=
g_src_pkg_uri_openssl=
g_src_pkg_uri_httpd=
g_src_pkg_uri_apr=
g_src_pkg_uri_apr_util=
g_src_pkg_uri_pcre=
g_httpd_is_22=


############################################
#declare options string including optional 
#argument names separated from withsapce.
#g_opt_name includs optional arg names
#g_opt_<g_opt_name>, just holds optional arg value
#for example, 
#	Given optional args, -i, -p, 
#	the option arg variables respectivly should be as,
#	g_opt_i
#	g_opt_p
############################################
#declare -a g_opt_names=(i: p:)

############################################
#init_args()
#initialize arguments before set them with 
#command line values
############################################
init_args()
{
	#g_opt_i="registry:2" # the registry image from hub.docker.com
	#g_opt_p=5000
	
	return 0;
}

############################################
#parse_non_option_args()
#parse non option arguments here
############################################
parse_non_option_args()
{
	#position parameter index at the first mandatory parameter 
    shift $(($OPTIND-1))

	#//TODD add your code to parse non-option arguments here.

	g_httpd_mod_src_path=$1
	if [ -z $g_httpd_mod_src_path ] || \
	  ! [ -d $g_httpd_mod_src_path ]; then
		log "Invalid httpd module src path, $g_httpd_mod_src_path"
		usage	
	fi
	g_httpd_mod_src_path=$(realpath $g_httpd_mod_src_path)
	
	g_tmp_version=''
	local RE_URI_SCHEMA='[a-zA-Z]+://'

	#parse openssl src identity
	local pkg_uri_openssl=$2 #'ftp://ftp.openssl.org/source/old/1.0.1/openssl-1.0.1e.tar.gz'
	if echo $pkg_uri_openssl | grep -oE $RE_URI_SCHEMA 2>&1>/dev/null; then
		g_src_pkg_uri_openssl=$pkg_uri_openssl
	else 
		if get_src_package_version g_tmp_version $pkg_uri_openssl; then
			if ! get_openssl_src_package_uri $g_tmp_version; then return 1; fi
		else
			log "invalid openssl src identity, $pkg_uri_openssl"
			usage
		fi
	fi 

	#parse httpd src identity
	local pkg_uri_httpd=$3 #'http://archive.apache.org/dist/httpd/httpd-2.4.18.tar.gz'
	if ! get_src_package_version g_tmp_version $pkg_uri_httpd; then
		log "invalid httpd src identity, $pkg_uri_httpd"
		usage
	fi
	local httpd_major_no=$(echo ${g_tmp_version} | awk -F . '{print $1}')
	local httpd_minor_no=$(echo ${g_tmp_version} | awk -F . '{print $2}')

	if [ ${httpd_major_no} -eq 2 ]; then
		if  [ $httpd_minor_no -lt 3 ]; then
			g_httpd_is_22='yes'
		else
			g_httpd_is_22='no'
		fi
	else		
		log "Not support httpd version, $g_tmp_version"	
		return 1;
	fi 

	if echo $pkg_uri_httpd | grep -oE $RE_URI_SCHEMA 2>&1>/dev/null; then
		g_src_pkg_uri_httpd=$pkg_uri_httpd
	else 
		if ! get_apache_src_package_uri httpd $g_tmp_version; then return 1; fi
	fi

	#get openssl lib soname
	g_openssl_lib_soname_ver=$4

	#no need to directly install apr, apr-util and pcre for httpd 2.2.x
	if [ "$g_httpd_is_22" == "yes" ]; then return 0; fi

	#parse apr src identity
	local pkg_uri_apr=$5 
	if echo $pkg_uri_apr | grep -oE $RE_URI_SCHEMA 2>&1>/dev/null; then
		g_src_pkg_uri_apr=$pkg_uri_apr
	else 
		if get_src_package_version g_tmp_version $pkg_uri_apr; then
			if ! get_apache_src_package_uri apr $g_tmp_version; then return 1; fi
		else
			log "invalid apr src identity, $pkg_uri_apr"
			usage
		fi
	fi

	#parse apr-util src identity
	local pkg_uri_apr_util=$6 
	if echo $pkg_uri_apr_util | grep -oE $RE_URI_SCHEMA 2>&1>/dev/null; then
		g_src_pkg_uri_apr_util=$pkg_uri_apr_util
	else 
		if get_src_package_version g_tmp_version $pkg_uri_apr_util; then
			if ! get_apache_src_package_uri apr-util $g_tmp_version apr; then return 1; fi
		else
			log "invalid apr-util src identity, $pkg_uri_apr_util"
			usage
		fi
	fi

	g_src_pkg_uri_pcre=${7:-'http://nchc.dl.sourceforge.net/project/pcre/pcre/8.39/pcre-8.39.tar.gz'}

	return 0;
}

############################################
#main()
#add business logics in this [main] function
############################################
main()
{
	#//TODD add your bussiness code here

	log "httpd module src path : $g_httpd_mod_src_path"
	log "openssl uri : $g_src_pkg_uri_openssl"
	log "httpd uri : $g_src_pkg_uri_httpd"
	log "apr uri : $g_src_pkg_uri_apr"
	log "apr util : $g_src_pkg_uri_apr_util"
	log "pcre uri : $g_src_pkg_uri_pcre"
	log "Is httpd 2.2 : $g_httpd_is_22"

	local tar_gz_suffix=.tar.gz
	local openssl_ver=${g_src_pkg_uri_openssl##*/} && \
	openssl_ver=${openssl_ver%$tar_gz_suffix}
	local httpd_ver=${g_src_pkg_uri_httpd##*/} && \
	httpd_ver=${httpd_ver%$tar_gz_suffix}

	local docker_image_name=anor/${g_httpd_mod_src_path##*/}:${httpd_ver}_${openssl_ver}
	if [ -n "g_openssl_lib_soname_ver" ]; then
		docker_image_name="${docker_image_name}_ssl_so_version_$g_openssl_lib_soname_ver"
	fi
	
	local docker_build_args="\
			--build-arg pkg_uri_openssl=$g_src_pkg_uri_openssl \
            --build-arg pkg_uri_httpd=$g_src_pkg_uri_httpd"
 
	
	local docker_file_name=Dockerfile.httpd-2.2

	#httpd 2.3.x or 2.4.x
	if [ "$g_httpd_is_22" == "no" ]; then

		docker_build_args="$docker_build_args \
		--build-arg pkg_uri_pcre=$g_src_pkg_uri_pcre \
		--build-arg pkg_uri_apr=$g_src_pkg_uri_apr \
		--build-arg pkg_uri_apr_util=$g_src_pkg_uri_apr_util"

		docker_file_name=Dockerfile
	fi
	
	#set so name
	if [ -n "g_openssl_lib_soname_ver" ]; then
		docker_build_args="$docker_build_args \
		--build-arg soname_ver_openssl=$g_openssl_lib_soname_ver"
	fi

	docker build \
		--rm \
		--tag anor/httpd_module_compiler_base \
		--file $(pwd)/Dockerfile.base \
		. \
	&& \
	docker build \
		--rm \
		$docker_build_args \
		--tag $docker_image_name \
		--file	$(pwd)/$docker_file_name \
		. \
	&& \
	docker run \
		--rm \
		--volume "$g_httpd_mod_src_path":/usr/src/httpd-module \
		$docker_image_name \
	&& \
	ls -alR "$g_httpd_mod_src_path"/dist \
	&& \
	return 0

	return 1;
}


############################################
#get_src_package_version()
#$1 output, src uri variable
#$2 src identity
############################################
get_src_package_version()
{
	local src_identity=$2

	local RE_VERSION='[0-9]+.[0-9]+(.[0-9]+[a-zA-Z]*)*'

	local version=${src_identity##*/}
	version=$(echo $version | grep -oE "${RE_VERSION}(.tar.gz)?")
	version=$(echo $version | grep -oE "$RE_VERSION")
	
	#return version
	eval "$1=$version"
}

############################################
#get_openssl_src_package_uri()
#Try to get available uri for openssl src package
#
# $1 -- openssl version, such as 0.9.8e
#
############################################
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
	if ! wget --spider "$g_src_pkg_uri_openssl"; then
		log "No valiable resource ($g_src_pkg_uri_openssl)"
		g_src_pkg_uri_openssl=	
		return 1
	fi

	return 0
}

############################################
#get_apache_src_package_uri()
#Try to get available uri for a apache project src package
#
# $1 -- package name prefix, such as httpd, apr, arp-util
# $2 -- version, such as 2.2.15
# $3 -- project name, such as httpd, apr, arp-util
#
############################################
function get_apache_src_package_uri()
{
	local pkg_name_prefix=$1
	local version=$2
	local project_name=${3:-$pkg_name_prefix}

	local path_in_uri="$project_name/$pkg_name_prefix-$version.tar.gz"
	local uri="${SRC_PKG_BASE_URI_ARCHIVE}/${path_in_uri}"

	#check if the release resource is available
	if ! wget --spider "$uri" ; then
		log "No valiable resource ($uri)"
		uri="${SRC_PKG_BASE_URI_RELEASE}/${path_in_uri}"
	fi 

	if ! wget --spider "$uri"; then
		log "No valiable resource ($uri)"
		return 1
	fi

	if [ $pkg_name_prefix == "apr-util" ] ; then
		pkg_name_prefix=apr_util	
	fi
	eval g_src_pkg_uri_$pkg_name_prefix=$uri

	return 0
}


#*******************************************************
########################################################
### Common functions here
########################################################
#*******************************************************
parse_args()
{

	#check if showing usage
	if [ "$1" ==  "--help" ]; then usage; fi
	
	init_args

	parse_options "$@"

	parse_non_option_args "$@"
}

parse_options()
{
	local opt_names="${g_opt_names[@]}"
	
	local opt_string="$(echo -e "$opt_names" | tr -d '[[:space:]]')"

	log "opt_string=$opt_string"

	if [ -n "$opt_names" ]; then
		while getopts $opt_string opt
		do
			for i in "${g_opt_names[@]}" 
			do 
				local opt_name=${i:0:1} 
				local opt_var_name=g_opt_$opt_name
				case $opt in
					$opt_name ) 
						if [ -z "$OPTARG" ]
						then
							eval $opt_var_name=1
						else
							eval $opt_var_name=\"$OPTARG\" 
						fi
						log "$opt_var_name=${!opt_var_name}"
						;; 
					h ) usage ;;
					\?) usage ;;
				esac
			done
		done	
	fi
}

#Purpose:
#	echo log message	
#	
#Parameters:
#	@1.... -- log messages 
#
log()
{
	echo "[`date +'%Y-%m-%d %H:%M:%S'` $0]" "${@:1}"	
}

_main()
{

	#parse optional
	parse_args "$@"

	#main routine
	main "$@"

	#successful log
	log "Done!"
}

_main "$@"


