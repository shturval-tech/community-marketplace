# keycloak

Keycloak — IdP и IAM: SSO, OAuth2/OpenID Connect и SAML для приложений.

**Требует:** нет.

**Установка:**

```bash
kubectl apply -f deploy/examples/ssc/keycloak.yaml
```

**Основные параметры:** `global.imageRegistry`, `global.ingress.className`, subchart `keycloakx` в `values.yaml`.

**Upstream:** [Keycloak](https://www.keycloak.org)

Соглашения: [chart-conventions.md](../../docs/chart-conventions.md).
