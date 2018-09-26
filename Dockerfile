FROM anor/httpd_module_compiler_base

MAINTAINER anorqiu@163.com

#declare arguments
ARG pkg_uri_openssl
ARG pkg_uri_pcre
ARG pkg_uri_apr
ARG pkg_uri_apr_util
ARG pkg_uri_httpd
ARG soname_ver_openssl

#install openssl
RUN \
cd /usr/src && \
pkg_suffix=.tar.gz && \
echo $pkg_uri_openssl && \
echo $soname_ver_openssl && \
pkg_name=${pkg_uri_openssl##*/} && \
folder_name=${pkg_name%$pkg_suffix} && \
project_name=openssl && \
sover=${soname_ver_openssl} && \
wget $pkg_uri_openssl && \
tar -xzf $pkg_name && ln -s $folder_name $project_name && \
cd $project_name && \
./config no-asm shared && \
if [ -n "$sover" ]; then \
	sed -i "s:-soname=\$\$SHLIB\$\$SHLIB_SOVER:-soname=\$\$SHLIB.$sover:g" ./Makefile.shared;  \
fi && \
make && make install_sw && \
if [ -n "$sover" ]; then \
	ln /usr/local/ssl/lib/libssl.so /usr/local/ssl/lib/libssl.so.$sover && \
	ln /usr/local/ssl/lib/libcrypto.so /usr/local/ssl/lib/libcrypto.so.$sover; \
fi && \
rm -rf /usr/src/${project_name}* && \
echo "Installing $folder_name done!"

#install pcre
RUN \
cd /usr/src && \
pkg_suffix=.tar.gz && \
pkg_name=${pkg_uri_pcre##*/} && \
folder_name=${pkg_name%$pkg_suffix} && \
project_name=pcre && \
wget $pkg_uri_pcre&& \
tar -xzf $pkg_name && ln -s $folder_name $project_name && \
cd $project_name && \
./configure --disable-cpp && make && make install && \
rm -rf /usr/src/${project_name}* && \
echo "Installing $folder_name done!"

#install apr
RUN \
cd /usr/src && \
pkg_suffix=.tar.gz && \
pkg_name=${pkg_uri_apr##*/} && \
folder_name=${pkg_name%$pkg_suffix} && \
project_name=apr && \
wget $pkg_uri_apr && \
tar -xzf $pkg_name && ln -s $folder_name $project_name && \
cd $project_name && \
./configure && make && make install && \
rm -rf /usr/src/${project_name}* && \
echo "Installing $folder_name done!"

#install apr-util
RUN \
cd /usr/src && \
pkg_suffix=.tar.gz && \
pkg_name=${pkg_uri_apr_util##*/} && \
folder_name=${pkg_name%$pkg_suffix} && \
project_name=apr-util && \
wget $pkg_uri_apr_util && \
tar -xzf $pkg_name && ln -s $folder_name $project_name && \
cd $project_name && \
./configure --with-apr=/usr/local/apr && make && make install && \
rm -rf /usr/src/${project_name}* && \
echo "Installing $folder_name done!"

#install httpd
RUN \
cd /usr/src && \
pkg_suffix=.tar.gz && \
pkg_name=${pkg_uri_httpd##*/} && \
folder_name=${pkg_name%$pkg_suffix} && \
project_name=httpd && \
wget $pkg_uri_httpd&& \
tar -xzf $pkg_name && ln -s $folder_name $project_name && \
cd $project_name && \
./configure  \
    --enable-ssl \
    --enable-so \
    --with-apr=/usr/local/apr \
    --with-apr-util=/usr/local/apr \
    --with-pcre=/usr/local \
    --with-ssl=/usr/local/ssl \
&& make && make install && \
rm -rf /usr/local/apache2/man && \
rm -rf /usr/local/apache2/manual && \
rm -rf /usr/local/apache2/logs && \
rm -rf /usr/local/apache2/icons && \
rm -rf /usr/local/apache2/htdocs && \
rm -rf /usr/local/apache2/cgi-bin && \
rm -rf /usr/local/apache2/error && \
rm -rf /usr/src/${project_name}* && \
echo "Installing $folder_name done!"

#install jansson installation
ADD ./src/jansson-2.7.tar.gz /usr/src/jansson
RUN \
cd /usr/src/jansson/jansson-2.7 && \
./configure --with-pic=yes && make && make install && \
rm -rf /usr/src/jansson && \
echo "Installing jasson done!"

#install jwt
ADD ./src/libjwt-1.3.1.tar.gz /usr/src/jwt/
RUN \
cd /usr/src/jwt/libjwt-1.3.1 && \
autoreconf -i && \
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:\
/usr/local/lib/pkgconfig:/usrl/local/lib64/pkgconfig:/usr/local/ssl/lib/pkgconfig && \
./configure --with-pic=yes && make && make install && \
rm -rf /usr/src/jwt && \
echo "Installing jwt done!"

#set environment variables
ENV APXS_PATH=/usr/local/apache2/bin/apxs
ENV PKG_CONFIG_PATH_OPENSSL=/usr/local/ssl/lib/pkgconfig
ENV PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PKG_CONFIG_PATH_OPENSSL
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/ssl/lib

VOLUME [ "/usr/src/httpd-module" ]

CMD ["/bin/bash", "-c", "cd /usr/src/httpd-module && ./configure && make && make dist && make clean && echo Done! || echo Failed!"]

