# authentik

authentik — IdP с веб-интерфейсом: SSO, OIDC, LDAP и прокси-аутентификация.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/authentik.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.ingress.className`, server/worker в `values.yaml`.

**Upstream:** [authentik](https://goauthentik.io)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
