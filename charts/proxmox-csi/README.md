# proxmox-csi

CSI-плагин для Proxmox VE: provisioning PersistentVolume из хранилищ гипервизора.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/proxmox-csi.yaml
```

**Основные параметры:** `global.imageRegistry`, `csiPlugin`, `storageClass` (Proxmox endpoint, credentials).

**Upstream:** [proxmox-csi-plugin](https://github.com/sergelogvinov/proxmox-csi-plugin)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
