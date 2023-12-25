# # imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder
In certain scenarios it might be interesting to automate the [OpenWrt Imagebuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) process. With this role you can do this. It will not only build the designated Image for your specific devices, but it will also:

- integrate your configurations
- adjust the partition sizes
- integrate your packages

The ansible host you plan to build your images on you need to prepare to [this documentation](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) accordingly.

It is an ideal method to automate your build process and to automate upgrading your OpenWrt devices with a new firmware release. This makes the whole process hassle free, since you don't need to install packages afterwards or resize your partition manually.

> For larger partitions you will need plenty of space on your build machine. For an image root partition size of 11 GiB it took over 70 GiB of space on the building machine. On a 100G machine I was not able to build a 15G image.
This space is largely freed, after build is finished.
{.is-warning}

> For larger partitions you will also need plenty of RAM, otherwise you might get the below error.
{.is-warning}

```
dd: memory exhausted by input buffer of size
```

This is an example playbook for the ansible_openwrtimagebuilder role.

```yaml
---
- hosts: tags_openwrt-imagebuilder
  pre_tasks:
    - name: combine default zones with manual settings
      set_fact:
        openwrt_firewall_zonesdefault: "{{ openwrt_firewall_zonesdefault | combine(openwrt_firewall_zones_mysite, recursive=true) }}"
      when: openwrt_firewall_zones_mysite is defined
  vars:
    openwrt_imagebuilder_builddir: "/home/jochen/openwrt_imagebuilder"
    openwrt_imagebuilder_outputdir: "/home/jochen/openwrt_imagebuilder_images"
    openwrt_acme_runimagebuilder: true
    openwrt_babeld_runimagebuilder: true
    openwrt_batmanadv_runimagebuilder: true
    openwrt_bmx7_runimagebuilder: true
    openwrt_dhcp_runimagebuilder: true
    openwrt_dropbear_runimagebuilder: true
    openwrt_firewall_runimagebuilder: true
    openwrt_network_runimagebuilder: true
    openwrt_packages_runimagebuilder: true
    openwrt_restic_runimagebuilder: true
    openwrt_services_runimagebuilder: true
  gather_facts: no
  connection: local
  serial: 1
  #become: true
  tasks:
    - name: run imagebuilder preparations
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder
        tasks_from: prepare
    - name: run acme
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtacme
    - name: run dhcp
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtdhcp
    - name: run dropbear
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtdropbear
    - name: run firewall
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtfirewall
    - name: run network
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtnetwork
    - name: run restic
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtrestic
    - name: run system
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtsystem
    - name: run imagebuilder build
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder
        tasks_from: build

```

It's important to run the `prepare` task first. Next come your own choice of Ansible roles for OpenWrt from my collection. At the end the `build` task needs to run.
If you make use of the firewall role in which you might want to merge zones, place it in the pretask, like above.

## Variables

If you don't adjust the `openwrt_imagebuilder_builddir` variable, the path `/tmp/openwrt_imagebuilder` will be used for building. The variable `openwrt_imagebuilder_outputdir` defines where the final images will be put. If you don't adjust, it will be in `/tmp/openwrt_imagebuilder_images`. The images will be named after the hostname in Ansible and will be compressed (tar.gz.)
You can specify the image for your system by setting this variable `openwrt_imagebuilder_downloadurl`. If you don't specify, the default x86 imagebuilder URL will be used. Here is an example url link for the [Ubiquiti Edgerouter X](https://downloads.openwrt.org/releases/22.03.1/targets/ramips/mt7621/).

For the build process you can specify kernel variables like in [Buildroot](https://openwrt.org/de/doc/howto/buildroot.exigence). Here you can also set the partition size, e.g:
```yaml
openwrt_imagebuilder_kernelvars:
  - name: "CONFIG_TARGET_KERNEL_PARTSIZE"
    value: 32
  - name: "CONFIG_TARGET_ROOTFS_PARTSIZE"
    value: 900
```

> There are limits to partition size [see also](https://unix.stackexchange.com/questions/563203/what-is-the-maximum-value-for-the-bs-argument-of-dd). I successfully tested image sizes up to 15G.
{.is-warning}

## Special roles
There are some roles, e.g. *openwrt_restic* that need to run on a deployed system so they can function. Always let Ansible run on the target device, after you deployed your firmware.
