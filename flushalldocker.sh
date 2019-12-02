#!/bin/sh

echo "docker stop"
docker stop $(docker ps -a -q)
sudo docker stop $(sudo docker ps -a -q)

echo "docker rm"
docker rm $(docker ps -a -q)
sudo docker rm $(sudo docker ps -a -q)

echo "docker rmi"
docker rmi $(docker images -q)
sudo docker rmi $(sudo docker images -q)

echo "docker volume rm"
docker volume rm $(docker volume ls -qf dangling=true)
sudo docker volume rm $(sudo docker volume ls -qf dangling=true)

echo "rm ..."
rm -rf /etc/ceph \
       /etc/cni \
       /etc/kubernetes \
       /opt/cni \
       /opt/rke \
       /run/secrets/kubernetes.io \
       /run/calico \
       /run/flannel \
       /var/lib/calico \
       /var/lib/etcd \
       /var/lib/cni \
       /var/lib/kubelet \
       /var/lib/rancher/rke/log \
       /var/log/containers \
       /var/log/pods \
       /var/run/calico

for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done

echo "rm -f /var/lib/containerd/io.containerd.metadata.v1.bolt/meta.db"
rm -f /var/lib/containerd/io.containerd.metadata.v1.bolt/meta.db

cleanupinterfaces="flannel.1 cni0 tunl0"
for interface in $cleanupinterfaces; do
  echo "Deleting $interface"
  ip link delete $interface
done

IPTABLES="/sbin/iptables"
cat /proc/net/ip_tables_names | while read table; do
  $IPTABLES -t $table -L -n | while read c chain rest; do
      if test "X$c" = "XChain" ; then
        $IPTABLES -t $table -F $chain
      fi
  done
  $IPTABLES -t $table -X
done

echo "shutdown -r now"
shutdown -r now
