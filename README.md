# NixOS system configurations for my machines

Contains system configs for my machines. At the moment contains

- My personal laptop setup, `gastropod`;
- and my server, `scallop`, running
  - [Nextcloud](https://nextcloud.com);
  - [Libreddit](https://github.com/libreddit/libreddit);
  - [Nitter](https://github.com/zedeus/nitter);
  - [Grocy](https://grocy.info/);
  - [Keycloak](https://www.keycloak.org/) for managing accounts and access;
  - [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) for locking down services without native OAuth2 support.

There is also a shell environment I use while modifying these configs, available via `nix develop` or via [`direnv`](https://direnv.net/) (with [`nix-direnv`](https://github.com/nix-community/nix-direnv)).

Secrets management is done via [agenix](https://github.com/ryantm/agenix). Minor secret-like things like URLs and emails are just kept in a separate private flake.

Applying the configurations (while in the development shell):

- Locally (laptop): ```rebuild localhost gastropod```
- Remotely (from laptop to server): ```rebuild <REMOTE_HOST> scallop```


## TODOs:
- Unify colorscheme management; `config.mollusca.colorscheme`?
