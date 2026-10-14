# cnpg-operator

Оператор CloudNativePG для развёртывания и сопровождения PostgreSQL в Kubernetes (репликация, failover, резервные копии).

**Требует:** нет (ставится первым перед `cnpg-cluster`).

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/cnpg-operator.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.storageClass`, настройки subchart `cloudnative-pg` в `values.yaml`.

**Upstream:** [CloudNativePG](https://cloudnative-pg.io)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
