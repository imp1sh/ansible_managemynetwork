ansible_talos
=========
- Only static IP configuration is supported

at the end run
```bash
talosctl kubeconfig --nodes <masternode> --endpoints <masternode> --talosconfig ./talosconfig
```
in order to get your kubeconfig
