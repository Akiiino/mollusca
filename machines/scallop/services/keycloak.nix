{
  config,
  self,
  pkgs,
  ...
}: {
  config = {
    age.secrets.keycloakDBPass = {
      file = "${self}/secrets/keycloak_db_pass.age";
    };

    services.keycloak = {
      enable = true;
      database.passwordFile = config.age.secrets.keycloakDBPass.path;
      initialAdminPassword = "keycloak_change_me";
      settings = {
        hostname = self.secrets.personal_subdomain "keycloak";
        hostname-strict-backchannel = true;
      };
    };

    services.nginx.virtualHosts = {};
  };
}
