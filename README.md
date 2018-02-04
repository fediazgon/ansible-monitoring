<h1 align="center">
  <div style="margin:10px;">
    <img src="https://github.com/fdiazgon/fdiazgon.github.io/blob/master/art/ansible-monitoring-logo.png?raw=true" alt="ansible-monitoring" width="200px">
  </div>
  ansible-monitoring
</h1>

<h4 align="center">Ansible role for installing <a href="https://grafana.com">Grafana</a>, <a href="https://prometheus.io">Prometheus</a> and <a href="https://github.com/prometheus/node_exporter">node_exporter</a>
</h4>

<p align="center">
  <a href="#supported-architectures">Supported architectures</a> •
  <a href="#variables">Variables</a> •
  <a href="#usage">Usage</a> •
  <a href="#improvements-needed">Improvements needed</a> •
  <a href="#credits">Credits</a>
</p>

![screenshot](https://github.com/fdiazgon/fdiazgon.github.io/blob/master/art/ansible-monitoring.gif?raw=true)

## Supported architectures

The scripts have been tested using a 2 node Raspberry Pi 3 cluster (armv7). However, it should be possible to use them with other architectures with a few changes in `defaults/main.yml`.

First, update the variable `prometheus_platform_suffix` to match yours (e.g., linux-amd64). Then, update the variables `grafana_apt_key` and `grafana_apt_repo` since I had to use an unofficial distribution to install the latest version. You can find the official repos and keys at [Installing Grafana](http://docs.grafana.org/installation/).

## Variables

| Variable    | Default  | Description  |
|-------------|----------| -------------|
| components  | []       | Services to install. Possible values: { prometheus, node_exporter, grafana }  |

## Usage

Inventory example:

```ini
[master]
halcyon1     ansible_connection=local

[workers]
halcyon2

[cluster:children]
master
workers
```

The last group is important because we need to tell Prometheus from where it should gather the metrics exported by node_exporter.

Then, you can use the provided playbooks in `tests` to install, start and stop the services.

```yml
---
#
# file: tests/monitoring_install.yml
#

- hosts: master
  become: True
  roles:
    - monitoring
  vars:
    components:
      - prometheus
      - node_exporter
      - grafana

- hosts: workers
  become: True
  roles:
    - monitoring
  vars:
    components:
      - node_exporter
```
As you can see, one node of the cluster will host Prometheus and Grafana, while the metrics will be gathered from all the nodes in the cluster.

```bash
ansible-playbook monitoring_install.yml
```

Keep in mind that the previous playbook doesn't start the services. This one does:

```bash
ansible-playbook monitoring_start.yml
```

You should be able to access Grafana and Prometheus using the browser. The installation includes two Grafana dashboards to check the status of the cluster and the individual nodes.

## Improvements needed

Fell free to create a merge request if you have a good solution for the following problems:

* Remove the need of creating the `cluster` group in the inventory. This group is accessed in `templates/prometheus.yml.j2` to add the IPs in the scrape configuration.

* Dynamically change the configuration to allow multiple architectures and distributions.

## Credits

I've been inspired by the following open source projects:

* [William-Yeh/ansible-prometheus](https://github.com/William-Yeh/ansible-prometheus)
* [ansiblebit/grafana](https://github.com/ansiblebit/grafana)
* [idealista/grafana-role](https://github.com/idealista/grafana-role)
