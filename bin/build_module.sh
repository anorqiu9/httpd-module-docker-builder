#!/bin/bash
#set -x
set -e

usage()
{

cat <<EOF
Usage:
	`basename $0` 
		<httpd module src path> <builder_docker_image>

Purpose:
	build a httpd module with a specified builder image

Description:
	Try to run a container with a specified builder image and then to build a httpd module in the container.

Parameters:

	httpd module src path -- a local path for a httpd module source code
	builder_docker_image -- the name of builder docker image
	
Author:
	anor.qiu@morningstar.com

Revision:
	2016-11-10 Anor Initial Versiona

EOF
	exit 1
}

g_httpd_mod_src_path=
g_builder_image_name=

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
	
	#parse openssl src identity
	g_builder_image_name=$2
	if	[ -z $g_builder_image_name ]; then
		log "Empty builder imagh name!"
		usage
		#g_builder_image_name=anor/${g_httpd_mod_src_path##*/}:${httpd_ver}_${openssl_ver}
	fi
	
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
	log "builder image is : $g_builder_image_name"
	
	#local docker_image_name=anor/${g_httpd_mod_src_path##*/}:${httpd_ver}_${openssl_ver}
	docker run \
		--rm \
		--volume "$g_httpd_mod_src_path":/usr/src/httpd-module \
		$g_builder_image_name \
	&& \
	ls -talR "$g_httpd_mod_src_path"/dist \
	&& \
	return 0

	return 1;
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

