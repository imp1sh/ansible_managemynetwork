# ansible_sshkeys
Ansible role in order to install ssh keys for specific users in Linux / FreeBSD.
Example variable that can be defined in group_vars so that they get rolled out.

    sshkeys:
            - description: "user Klaus ssh key Ubuntu workstation"
              user: "klaus"
              key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrBMHHozDF4Xl4lthGQab/2Fhr4kr6C5ylckNX25gFweXmFbuO/uXiw7sL4NqdROXbO7jj89pxh1qtiNF9iQu4HsuskhZcuCoPho/SCXkvdyQGcIUZIZElilyWyLOJNXK4H7YXDv7LmO5Rc9oAJp/XP7TWW6uILXYs97PdHOisUk/3QCJzkNfulodBz73z6aKjP9vSloJJQvK6YZEC2WYqv2JQKOR6Bkz1R1fvHKmOFWN2Ls3ZIYmjQ4ETZtXBAHLbPW7PHT/YLaKqOIn3zZ/1TGpJ2VP938KLMDCQG6jdnRhBiDGwbBnz67A3DrOeKKhDSDPC8gPca4aAgHhNE6WX klaus@ubuntuworkstation"

Another example of when a key should be absent:

    sshkeys:
            - description: "user Klaus ssh key Ubuntu workstation"
              state: absent
              user: "klaus"
              key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrBMHHozDF4Xl4lthGQab/2Fhr4kr6C5ylckNX25gFweXmFbuO/uXiw7sL4NqdROXbO7jj89pxh1qtiNF9iQu4HsuskhZcuCoPho/SCXkvdyQGcIUZIZElilyWyLOJNXK4H7YXDv7LmO5Rc9oAJp/XP7TWW6uILXYs97PdHOisUk/3QCJzkNfulodBz73z6aKjP9vSloJJQvK6YZEC2WYqv2JQKOR6Bkz1R1fvHKmOFWN2Ls3ZIYmjQ4ETZtXBAHLbPW7PHT/YLaKqOIn3zZ/1TGpJ2VP938KLMDCQG6jdnRhBiDGwbBnz67A3DrOeKKhDSDPC8gPca4aAgHhNE6WX klaus@ubuntuworkstation"

Regarding OpenWrt will all the given keys in `sshkeys` install on the OpenWrt devices as long as the entry is not set to absent.
