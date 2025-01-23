# imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder
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
- name: Playbook for building openwrt images
  hosts: tags_openwrt-imagebuilder
  vars:
    openwrt_babeld_runimagebuilder: true
    openwrt_batmanadv_runimagebuilder: true
    openwrt_bmx7_runimagebuilder: true
    openwrt_dhcp_runimagebuilder: true
    openwrt_dropbear_runimagebuilder: true
    openwrt_firewall_runimagebuilder: true
    openwrt_imagebuilder_builddir: "/home/jochen/openwrt_imagebuilder"
    openwrt_imagebuilder_outputdir: "/home/jochen/openwrt_imagebuilder_images"
    openwrt_network_runimagebuilder: true
    packages_runimagebuilder: true
    restic_runimagebuilder: true
    openwrt_services_runimagebuilder: true
    openwrt_system_runimagebuilder: true
    openwrt_uhttpd_runimagebuilder: true
    openwrt_wireguard_runimagebuilder: true
    openwrt_wireless_runimagebuilder: true
    system_users_runimagebuilder: true
  gather_facts: true
  connection: local
  serial: 1
  # become: true
  tasks:
    - name: Run imagebuilder preparations
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder
        tasks_from: prepare
    - name: Run packages
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_packages
    - name: Run acme
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtacme
    - name: Run uhttpd
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd
    - name: Run dhcp
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtdhcp
    - name: Run dropbear
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtdropbear
    - name: Run firewall
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtfirewall
    - name: Run network
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtnetwork
    - name: Run restic
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_restic
    - name: Run system
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtsystem
    - name: Run wireless
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtwireless
    - name: Run wireguard
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtwireguard
    - name: Run users
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_users
    - name: Run imagebuilder build
      ansible.builtin.import_role:
        name: imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder
        tasks_from: build
```

It's important to run the `prepare` task first. Next come your own choice of Ansible roles for OpenWrt from my collection. At the end the `build` task needs to run.
If you make use of the firewall role in which you might want to merge zones, place it in the pretask, like above.

> [!NOTE]  
> Some roles needs `ansible_packages` role to be run before, e.g. `ansible_openwrtacme` or `ansible_openwrtwireguard`.

## Variables

* `openwrt_imagebuilder_builddir` - The directory where the imagebuilder will be built. Default is `/tmp/openwrt_imagebuilder`.
* `openwrt_imagebuilder_outputdir` - The directory where the images will be put. Default is `/tmp/openwrt_imagebuilder_images`. 
  * The images will be named in format `hostname--output-of-imagebuilder.bin`
  * Additionally all output directory will be compressed in a tar.gz file and named `hostname.tar.gz`
* `openwrt_imagebuilder_downloadurl` - The URL to the imagebuilder. Default is the x86 imagebuilder. [Instruction how to find the correct URL](https://openwrt.org/docs/guide-user/additional-software/imagebuilder#obtaining_the_image_builder)
* `openwrt_imagebuilder_profile` - The profile to build. If not set, the default profile will be used.
* ``openwrt_imagebuilder_kernelvars` - Kernel variables to set. Default is empty. \
  For the build process you can specify kernel variables like in [Buildroot](https://openwrt.org/de/doc/howto/buildroot.exigence). Here you can also set the partition size, e.g:
  ```yaml
  openwrt_imagebuilder_kernelvars:
    - name: "CONFIG_TARGET_KERNEL_PARTSIZE"
      value: 32
    - name: "CONFIG_TARGET_ROOTFS_PARTSIZE"
      value: 900
  ```

> [!WARNING]  
> There are limits to partition size [see also](https://unix.stackexchange.com/questions/563203/what-is-the-maximum-value-for-the-bs-argument-of-dd). I successfully tested image sizes up to 15G.

## Special roles
There are some roles, e.g. *ansible_restic* that need to run on a deployed system so they can function. Always let Ansible run on the target device, after you deployed your firmware.

## Make own role compatible with imagebuilder
Use `openwrt_imagebuilder_deployroot` to deploy files to the image. \
This variable is a path to a files directory in imagebuilder. \
Each file in this directory will be copied to the root of the image. \
For reference see the `ansible_openwrtacme` role.