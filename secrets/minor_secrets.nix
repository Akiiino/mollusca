{
  inputs,
  self,
}:
(inputs.nixpkgs.lib.importJSON "${self}/secrets/minor_secrets.json")
// {
  personal_subdomain = subdomain: subdomain + "." + self.secrets.personal_domain;
  public_subdomain = subdomain: subdomain + "." + self.secrets.public_domain;
}
