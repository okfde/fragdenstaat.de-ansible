# Libvirt role

Role for installation of libvirt/qemu and management of guest vms.

The role does not take care of creating the zpool. An existing zpool has to be defined via the `virt_zpool` variable.

For caching cloud images (qcow2 iso files), zfs filesystem (`pool/images`) is created and mounted to `/srv/zpool/images`. _zfs filesystems_ have no fixed size.

Volumes are stored in the zfs dataset `pool/volumes` and each created as _zvol_. In contrast to _zfs filesystems_, _zvols_ are block devices with with a fixed size and automounted to `/dev/<pool>/<volume>`, where `<volume>` can be nested.
For example, the _zvol_ `volumes/host1.okfn.de/root` in the pool `pool` is mounted to `/dev/zvol/volumes/host1.okfn.de/root`.

This roles does not make use of the libvirt wrapper for zfs, mainly because the writer of this role was frustrated with its interface.
Instead of creating pool and volumes with virsh (`virsh pool-define-as <pool> ...` or `virsh vol-create-as <pool> <volume>`) or passing a _zvol_ to libvirt as a _volume_ (`virt-install --disk vol=<pool-name>/<volume>`) _zvols_ are managed directly with `zfs` and are passed to libvirt as block devices, i.e. `virt-install --disk path=/dev/zvol/volumes/host1.okfn.de/root`

## Variables

See `defaults/main.yml` for defaults and `meta/argument_specs.yml` for valid values

## Creating new guests

1. Add guest to `virt_guests`:
  ```
  # host_vars/roy.okfn.de/main.yml

  virt_guests:
    - name: guest1.okfn.de
      cpus: 3
      memory: 4096
      disk_size: 22
      additional_disks:
        - name: data
          size: 50
          target: vdb

  ```

2. Add guest to the inventory below the group of the respective hypervisor:
  ```
  # inventory
  [roy]
  guest1.okfn.de
  ```

3. At least the internal vlan IPv4 address needs to be defined in `network_networks.pivate` in the host vars for the new guest.
  `network_networks.public` can only be defined if it contains all relevant variables to configure a public interface for the vm, otherwise it must be absent.
  ```
  # host_vars
  network_networks:
    private:
      address4: 192.168.100.103
    public:
      mac: 00:50:56:00:FD:9C
      address4: 5.9.108.212/27
      gateway4: 5.9.108.193
      address6: "2a01:4f8:162:44c7::3/64"
      gateway6: 'fe80::1'
  ```

4. Run playbook
  ```
  ansible-playbook playbooks/virtualization.yml -t virt_guests --diff
  ```

## Delete and recreate guests

If you wish to delete a guest, remove it from `virt_guests`, the inventory file and its hostvars and run the playbook with `virt_guests_delete` including the guests to remove. This will also reconcile inventory configuration, like removing its entriy in other hosts `/etc/hosts`.

```
ansible-playbook playbooks/virtualization.yml -t virt_guests --diff -e '{ "virt_guests_delete":["guest1.okfn.de"] }'
```

Running the above command _without_ removing the guest from the hostvars and inventory will purge the storage and libvirt state and create and provision the guest from scratch, without attempting to reconcile the inventory configuration.
