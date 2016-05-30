#!/bin/bash
ADMIN_EMAIL=""
# type can be jre or jdk
JAVA_TYPE="jdk"
JAVA_VERSION="8"
EXT="tar.gz"

# set base download location
URL="http://www.oracle.com"
DOWNLOAD_URL1="${URL}/technetwork/java/javase/downloads/index.html"
DOWNLOAD_URL2=$(curl -s $DOWNLOAD_URL1 | egrep -o "\/technetwork\/java/\javase\/downloads\/${JAVA_TYPE}${JAVA_VERSION}-downloads-.*\.html" | head -1)

# check to make sure we got to oracle
if [[ -z "$DOWNLOAD_URL2" ]]; then
  echo "Could not to oracle - $DOWNLOAD_URL1"
  exit 1
fi

# set download url
DOWNLOAD_URL3="$(echo ${URL}${DOWNLOAD_URL2}|awk -F\" {'print $1'})"
DOWNLOAD_URL4=$(curl -s "$DOWNLOAD_URL3" | egrep -o "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[7-8]u[0-9]+\-(.*)+\/${JAVA_TYPE}-[7-8]u[0-9]+(.*)linux-i586.${EXT}"|tail -n1)

# check to make sure url exists
if [[ -z "$DOWNLOAD_URL4" ]]; then
  echo "Could not get ${JAVA_TYPE} download url - $DOWNLOAD_URL4"
  exit 1
fi
# set download file name
JAVA_INSTALL=$(echo $DOWNLOAD_URL4|cut -d "/" -f 8)

# download java
echo -e "\n\e[32mDownloading\e[0m: $DOWNLOAD_URL4"
while true;
do echo -n .;sleep 1;done &
cd /opt; wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" $DOWNLOAD_URL4 > /dev/null 2>&1
kill $!; trap 'kill $!' SIGTERM;


# get dirname
JAVA_DIR=$(ls -tr /opt/|grep ${JAVA_TYPE}|head -n 1)
# set default java
alternatives --install /usr/bin/java java /opt/${JAVA_DIR}/bin/java 1
alternatives --install /usr/bin/javac javac /opt/${JAVA_DIR}/bin/javac 1
alternatives --install /usr/bin/jar jar /opt/${JAVA_DIR}/bin/jar 1
# set temp env vars
export JAVA_HOME=/opt/${JAVA_DIR}
export PATH=$PATH:/opt/${JAVA_DIR}/bin:/opt/${JAVA_DIR}/${JAVA_TYPE}/bin
# set perm env vars
echo "export JAVA_HOME=/opt/${JAVA_DIR}" >> /etc/environment
echo "export PATH=$PATH:/opt/${JAVA_DIR}/bin:/opt/${JAVA_DIR}/${JAVA_TYPE}/bin" >> /etc/environment
# set if jdk is used
if [[ "$JAVA_TYPE" = "jdk" ]]; then
        # set temp env var
        export JRE_HOME=/opt/${JAVA_DIR}/${JAVA_TYPE}
        # set perm env var
        echo "export JRE_HOME=/opt/${JAVA_DIR}/${JAVA_TYPE}" >> /etc/environment
fi
# make sure java installed
ls /opt/${JAVA_DIR} > /dev/null 2>&1
if [[ "$?" != 0  ]]; then
        echo -e "\n\e[31mError\e[0m: Java does not seem to be installed correctly,\nPlease try again or email admin: ${ADMIN_EMAIL}\n"
        exit 1
fi

apt-get install -y firefox:i386
apt-get install -y stoken
cd /usr/lib/mozilla/plugins
ln -s $JAVA_HOME/jre/lib/i386/libnpjp2.so
