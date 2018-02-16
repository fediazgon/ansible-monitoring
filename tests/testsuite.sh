# This script contains a collection of test cases. It will be copied inside
# the Docker container where Ansible is installed and executed from there

# Terminate as soon as any command fails
set -e

# Test Ansible syntax.
echo "Checking syntax"
ansible-playbook ${playbooks_path}/monitoring_install.yml --syntax-check
ansible-playbook ${playbooks_path}/monitoring_start.yml --syntax-check
ansible-playbook ${playbooks_path}/monitoring_stop.yml --syntax-check

# Run Ansible playbook.
echo "Running install playbook"
ansible-playbook ${playbooks_path}/monitoring_install.yml --skip-tags "grafana_imports"

echo "Running start playbook"
ansible-playbook $playbooks_path/monitoring_start.yml

echo "Waiting 10 seconds for services to start"
sleep 10

echo "Checking node_exporter is running"
curl http://localhost:9100/metrics > /dev/null \
    && echo "OK" || (echo "ERROR" && exit 1)

echo "Checking Prometehus is running"
curl http://localhost:9090/metrics > /dev/null \
    && echo "OK" || (echo "ERROR" && exit 1)

echo "Checking Grafana is running"
curl http://localhost:8787 | grep "login" \
    && echo "OK" || (echo "ERROR" && exit 1)

echo "Running stop playbook"
ansible-playbook $playbooks_path/monitoring_stop.yml
