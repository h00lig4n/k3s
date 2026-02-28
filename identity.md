# Identity and Access Management

Ideally with all the services running, I wanted to have some form of single sign on.

## Basic requirements

- Low resource usage.
- OIDC support.
- Proxy/Ingress support with Traefik for services lacking OIDC.
- Federation with Google/Microsoft/Facebook/Github to avoid more passwords.

## Contenders

- [Authelia](https://www.authelia.com)
- [Authentik](https://goauthentik.io/)
- [Casdoor](https://casdoor.org/)
- [Dex](https://github.com/dexidp/dex)
- [Keycloak](https://www.keycloak.org/)

### Authelia

I really like Authelia because of it's low resource usage and OIDC support.
It feels very secure and the UI is enough (rather than too much).

What stopped it for me is lack of federated logins.
I'll be watching this project.

Pros:

- Low resource usage.
- OIDC support.
- Simple UI.
- Secure.

Cons:

- Helm beta support was not so intuive (I guess that's why it's still in beta).
- No federated support with Google/Microsoft/Facebook/Github.

#### Useful Links

[OpenID Connect with Authelia on Kubernetes](https://blog.stonegarden.dev/articles/2025/06/authelia-oidc/#oidc-configuration)

### Authentik

I didn't try this in my homelab. It look like the best option for me, exluding resource usage.

The ONLY reason I didn't choose it:

- It uses more resources than I'm prepared to give it.

### Casdoor

I had problems configuring Grafana with both Casdoor and Authelia.
Most likely user error :).

I find some of the UI unintuitive and see issues where you delete items in the wrong order and need to clean up manually in the database.
I am not leverage the full might of the permissions engine, it's overkill for my usecases.
I've also leveraged OAuth2-Proxy for securing non-Oidc applications and services.

#### Usefull Links

[Grafana and Casdoor](https://casdoor.org/docs/integration/go/grafana/)

Pros:

- Fairly low resource usage.
- OIDC support.
- Secure.
- Federated support.
- Powerful Casbin permission engine (might be a con in my case as it overcomplicates what I need).

Cons:

- Powerful role models were daunting until I realized I didn't need to use it all.
- Relatively unknown and therefore limited community support.
- Powerful Casbin permission engine overcomplicates my simple usecases.
- Need to use external OAuth2-Proxy for non-OIDC applications.

### Dex

I tried Dex. Awsome and lightweight. Installed LLDAP to give run as user store.

Pros:

- Low resource usage.
- Federated support.
- Looks good.
- Simple.

Cons:

- Cannot manager roles permissions need to be managed in applications.
- Cannot merge roles permissions from LDAP.

### Keycloak

I didn't try Keycloak in my homelab. I have used it previously and know it can do everything I need.
Two reasons I didn't choose it:

- It uses more resources than I'm prepared to give it.
- I have already used it so no fun there.