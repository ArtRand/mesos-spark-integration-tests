############################################
#! /bin/bash
# Author: skonto
# date: 21/10/2015
# purpose:to be run on nodes to set hadoop..
#############################################


ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa > /dev/null

cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys

cat <<EOF > /root/.ssh/config
Host *
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  LogLevel quiet
  Port 2122
EOF

mkdir -p /root/data/datanode
mkdir -p /root/data/namenode

tar -zxf /var/tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /var/tmp/
cp -r /var/tmp/hadoop-${HADOOP_VERSION}/* /usr/local/
#echo "0.0.0.0" > /usr/local/etc/hadoop/slaves

files=( "core-site.xml" "hdfs-site.xml" )

for i in "${files[@]}"
do
  :
  cp /var/hadoop/config/$i /usr/local/etc/hadoop/$i
done

#Replacing the hostname of namenode with docker ip so its accessible outside
sed -i -- "s/REPLACE_WITH_DOCKER_IP/$DOCKER_IP/g" /usr/local/etc/hadoop/core-site.xml

if [ "$1" = "SLAVE" ]; then
  read -d '' rep_text <<EOF
  <property>
  <name>dfs.namenode.servicerpc-address</name>
  <value>$DOCKER_IP:8020</value>
  </property>

  <property>
  <name>dfs.datanode.address</name>
  <value>0.0.0.0:$IT_DFS_DATANODE_ADDRESS_PORT</value>
  </property>

  <property>
  <name>dfs.datanode.http.address</name>
  <value>0.0.0.0:$IT_DFS_DATANODE_HTTP_ADDRESS_PORT</value>
  </property>

  <property>
  <name>dfs.datanode.ipc.address</name>
  <value>0.0.0.0:$IT_DFS_DATANODE_IPC_ADDRESS_PORT</value>
  </property>
EOF
else
rep_text=""
fi

awk -v r="$rep_text" '{gsub(/REPLACE/,r)}1' /usr/local/etc/hadoop/hdfs-site.xml >  tmp_file && mv tmp_file /usr/local/etc/hadoop/hdfs-site.xml
