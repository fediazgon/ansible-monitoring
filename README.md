<h1 align="center">
  <div style="margin:10px;">
    <img src="https://github.com/fediazgon/ansible-monitoring/blob/assets/logo.png?raw=true" alt="ansible-monitoring" width="200px">
  </div>
  ansible-monitoring
</h1>

<h4 align="center">Ansible role for installing <a href="https://grafana.com">Grafana</a>, <a href="https://prometheus.io">Prometheus</a> and <a href="https://github.com/prometheus/node_exporter">node_exporter</a>
</h4>

<p align="center">
  <a href="https://travis-ci.org/fediazgon/ansible-monitoring">
    <img src="https://travis-ci.org/fediazgon/ansible-monitoring.svg?branch=master" alt="TravisCI">
  </a>

</p>

<p align="center">
  <a href="#tests">Tests</a> •
  <a href="#variables">Variables</a> •
  <a href="#usage">Usage</a> •
  <a href="#use-it-on-raspberry-pi">Use it on Raspberry Pi</a> •
  <a href="#credits">Credits</a> •
  <a href="#license">License</a>
</p>

![screenshot](https://github.com/fediazgon/ansible-monitoring/blob/assets/demo.gif?raw=true)

## Tests

The role was tested in the following distributions using [docker images](https://github.com/fdiazgon/docker-ansible).

| Distribution                | Tested             |
| --------------------------- |:------------------:|
| Debian 9 Stretch            | :white_check_mark: |
| Ubuntu 16.04 Xenial Xerus   | :white_check_mark: |
| Ubuntu 18.04 Bionic Beaver  | :white_check_mark: |

You can run the tests from the root directory using the following command.

```shell
distro=<distro> tests/runtests.sh
# <distro> is one of { debian9, ubuntu16 } (debian9 is the default one)
```

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

## Use it on Raspberry Pi

I've successfully used this role in a Raspberry Pi 3 cluster with a few changes in `defaults/main.yml`.

First, update the variable `prometheus_platform_suffix` to `armv7`. Then, update the variables `grafana_apt_key` and `grafana_apt_repo` since you need to use an unofficial repository to install the latest Grafana version. You can find the official repos and keys at [Installing Grafana](http://docs.grafana.org/installation/).

Just add the following modification to `defaults/main.yml`.

```yml
#grafana_apt_key: https://packagecloud.io/gpg.key
#grafana_apt_repo: deb https://packagecloud.io/grafana/stable/debian/ jessie main

# Use these one instead if you want to install it on Raspberry Pi 3
grafana_apt_key: https://bintray.com/user/downloadSubjectPublicKey?username=bintray
grafana_apt_repo: deb https://dl.bintray.com/fg2it/deb jessie main
```

## Credits

I've been inspired by the following open source projects:

* [William-Yeh/ansible-prometheus](https://github.com/William-Yeh/ansible-prometheus)
* [ansiblebit/grafana](https://github.com/ansiblebit/grafana)
* [idealista/grafana-role](https://github.com/idealista/grafana-role)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
