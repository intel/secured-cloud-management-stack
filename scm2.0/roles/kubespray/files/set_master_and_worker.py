#!/usr/bin/env python3

import os
import sys
import yaml
from collections import OrderedDict

CONFIG_FILE = os.environ.get("CONFIG_FILE", "./inventory/mycluster/hosts.yaml")

# to remove 'null' when dumping file
def represent_none(self, _):
    return self.represent_scalar('tag:yaml.org,2002:null', '')

yaml.add_representer(type(None), represent_none)

class KubesprayInventory(object):
    def __init__(self, changed_hosts=None, config_file=None):
        self.config_file = config_file
        self.yaml_config = {}
        if self.config_file:
            try:
                with open(config_file, 'r') as f:
                    self.yaml_config = yaml.safe_load(f)
            except OSError:
                pass
        print (self.yaml_config)
        raw_master_ips = changed_hosts[0]
        raw_worker_ips = changed_hosts[1]
        master_ips = self.split_ips(raw_master_ips, ',')
        worker_ips = self.split_ips(raw_worker_ips, ',')

        master_hostnames = self.get_hostnames(master_ips)
        worker_hostnames = self.get_hostnames(worker_ips)
        self.set_kube_master(master_hostnames)
        self.set_kube_node(worker_hostnames)
        print (self.yaml_config)

        self.write_config()

    def split_ips(self, ips, partition):
        return ips.split(partition) 

    def get_hostnames(self, changed_hosts):
        all_hosts = self.yaml_config['all']['hosts'] 
        hostnames = {}
        for host_ip in changed_hosts:
            for host, host_opt in all_hosts.items():
                if host_opt['ip'] == host_ip:
                    hostnames[host] = None
        return hostnames

    def set_kube_master(self, hosts):
        self.clean_group('kube_control_plane')
        for host in hosts:
            self.add_host_to_group('kube_control_plane', host)

    def set_kube_node(self, hosts):
        self.clean_group('kube_node')
        for host in hosts:
            self.add_host_to_group('kube_node', host)

    def clean_group(self, group):
        self.yaml_config['all']['children'][group]['hosts'] = {}

    def add_host_to_group(self, group, host, opts=""):
        if self.yaml_config['all']['children'][group]['hosts'] is None:
            self.yaml_config['all']['children'][group]['hosts'] = {
                host: None}
        else:
            self.yaml_config['all']['children'][group]['hosts'][host] = None

    def write_config(self):
        with open(self.config_file, 'w') as f:
            yaml.dump(self.yaml_config, f, sort_keys=False)

def main(argv=None):
    if not argv:
        argv = sys.argv[1:]
    print (argv)
    KubesprayInventory(argv, CONFIG_FILE)

if __name__ == "__main__":
    sys.exit(main())
