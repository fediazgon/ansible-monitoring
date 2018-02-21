role_path="/etc/ansible/roles/monitoring"
playbooks_path=$role_path/tests

distro=${distro:-"debian9"}

if [ "$distro" == "debian9" ]; then
  init="/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
elif [ "$distro" == "ubuntu16" ]; then
  init="/lib/systemd/systemd"
  opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
else
  echo "Distro $distro not supported"
  exit 1
fi

container_id=$(date +%s)

echo "Starting Docker container: ${distro}-ansible"
docker pull fdiazgon/${distro}-ansible
docker run --detach --volume=${PWD}:${role_path}:ro $opts --name $container_id \
    -e ANSIBLE_FORCE_COLOR=1 \
    -e playbooks_path=$playbooks_path \
    fdiazgon/${distro}-ansible $init

echo "Copying inventory file"
docker cp tests/inventory $container_id:/etc/ansible/hosts

echo "Copying test suite"
docker cp tests/testsuite.sh $container_id:/tmp/
docker exec $container_id chmod +x /tmp/testsuite.sh

echo "Running test suite"
docker exec $container_id /bin/bash /tmp/testsuite.sh

echo "Removing Docker container"
docker rm -f $container_id
