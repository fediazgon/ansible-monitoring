set -e

distro=${distro:-"debian9"}

role_path="/etc/ansible/roles/monitoring"
playbooks_path=$role_path/tests

if [ "$distro" == "debian9" ]; then
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
    fdiazgon/${distro}-ansible $init

docker cp tests/inventory $container_id:/etc/ansible/hosts

# Test Ansible syntax.
echo "Checking syntax"
docker exec $container_id ansible-playbook ${playbooks_path}/monitoring_install.yml --syntax-check
docker exec $container_id ansible-playbook ${playbooks_path}/monitoring_start.yml --syntax-check
docker exec $container_id ansible-playbook ${playbooks_path}/monitoring_stop.yml --syntax-check

# Run Ansible playbook.
echo "Running install playbook"
docker exec $container_id ansible-playbook ${playbooks_path}/monitoring_install.yml --skip-tags "grafana_imports"

echo "Running start playbook"
docker exec $container_id ansible-playbook $playbooks_path/monitoring_start.yml

echo "Waiting 10 seconds for services to start"
sleep 10

echo "Checking node_exporter is running"
docker exec $container_id curl http://localhost:9100/metrics > /dev/null \
    && echo "OK" || (echo "ERROR" && exit 1)

echo "Checking Prometehus is running"
docker exec $container_id curl http://localhost:9090/metrics > /dev/null \
    && echo "OK" || (echo "ERROR" && exit 1)

echo "Checking Grafana is running"
docker exec $container_id curl http://localhost:8787 | grep "login" \
    && echo "OK" || (echo "ERROR" && exit 1)

echo "Running stop playbook"
docker exec $container_id ansible-playbook $playbooks_path/monitoring_stop.yml

echo "Checking process stopped"
docker exec $container_id curl http://localhost:9100/metrics > /dev/null

echo "Removing Docker container"
docker rm -f $container_id
