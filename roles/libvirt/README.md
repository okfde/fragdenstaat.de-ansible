# Libvirt role

Sets up libvirt and a zpool (`pool`, mounted to `/srv/zpool`)

For caching cloud images (qcow2 iso files), zfs filesystem (`pool/images`) is created and mounted to `/srv/zpool/images`. _zfs filesystems_ have no fixed size.

Volumes are stored in the `pool/volumes` and created as _zvol_. In contrast to _zfs filesystems_, _zvols_ are block devices with with a fixed size and automounted to `/dev/<pool>/<volume>`, where `<volume>` can be nested.
For example, the _zvol_ `volumes/host1.okfn.de/root` in the pool `pool` is mounted to `/dev/zvol/volumes/host1.okfn.de/root`.

This roles does not make use of the libvirt wrapper for zfs, mainly because the writer of this role was frustrated with its interface.
Instead of creating pool and volumes with virsh (`virsh pool-define-as <pool> ...` or `virsh vol-create-as <pool> <volume>`) or passing a _zvol_ to libvirt as a _volume_ (`virt-install --disk vol=<pool-name>/<volume>`) _zvols_ are managed directly with `zfs` and are passed to libvirt as block devices, i.e. `virt-install --disk path=/dev/zvol/volumes/host1.okfn.de/root`

## Variables

See `defaults/main.yml`

A list of guests can be defined in `libvirt_guests`. See `meta/argument_specs.yml` for valid values.
```
libvirt_guests:
  - name: testvm4.okfn.de
    cpus: 3
    memory: 4096
    disks:
      - name: root
        size: 20
      - name: data
        size: 200
```
