# imp1sh.ansible_managemynetwork.ansible_ohmyzsh
[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_ohmyzsh)
This is a fork of [gantsigh/oh-my-zsh](https://github.com/gantsign/ansible-role-oh-my-zsh) but it was quite heavily modified.

Supported OS:
- Debian
- Ubuntu (best effort)
- FreeBSD (best effort)
- ~~Alpine~~ (deprecated, might work though)

This role installs and manages oh-my-zsh. It depends on the *system_users* vars from the [users role](/en/junicast/docs/AnsibleManagemynetworkCollection/roleUsers).

The role will install dependencies first and then iterate over every user item in *system_users*. Only users having the object oh_my_zsh defined below the user object will get oh-my-zsh installed. Example user object:
```yaml
system_users:
  "jochen":
    state: present
    comment: "Jochen Demmer"
    uid: 2048
    shell: "zsh"
    password: "$6$0ySECRET"
    envs:
      - key: "EDITOR"
        value: "vim"
    oh_my_zsh:
      theme: bira
      plugins:
        - git
        - zsh-autosuggestions
      update_mode: auto
      update_frequency: 3
      customs:
        - "hosts_autocomplete"
        - "virtualenv"       
```

It will then install oh-my-zsh into the users home, set zsh as default shell as long as the e.g. system.users.jochen.shell equals zsh. A .zshrc will be written. You can set zsh environment variables with the *envs* attribute or enable plugins with the *plugins* attribute.
There are also some [custom extensions](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_ohmyzsh/files) available via the *customs* attribute. 
