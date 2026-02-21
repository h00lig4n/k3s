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

Pros:

- Low resource usage.
- OIDC support.
- Simple UI.
- Secure.

Cons:

- Helm beta support was not so intuive (I guess that's why it's still in beta).
- No federated support with Google/Microsoft/Facebook/Github.

#### Usefull Links

[OpenID Connect with Authelia on Kubernetes](https://blog.stonegarden.dev/articles/2025/06/authelia-oidc/#oidc-configuration)

### Authentik

I didn't try this in my homelab. It look like the best option for me, exluding resource usage.

The ONLY reason I didn't choose it:

- It uses more resources than I'm prepared to give it.

### Casdoor

https://casdoor.org/docs/integration/go/grafana/

Pros:

- Fairly low resource usage.
- OIDC support.
- Secure.
- Federated support.
- Powerful Casbin permission engine.

Cons:

- Setting up simple role mappings was not trivial.
- Relatively unknown and therefore limited community support.

### Dex

Not done yet.

### Keycloak

I didn't try Keycloak in my homelab. I have used it previously and know it can do everything I need.
Two reasons I didn't choose it:

- It uses more resources than I'm prepared to give it.
- I have already used it so no fun there.
