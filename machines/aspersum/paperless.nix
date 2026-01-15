{
  config,
  pkgs,
  lib,
  self,
  inputs,
  ...
}:
{
  services.paperless = {
    enable = true;
    consumptionDirIsPublic = true;
    settings = {
      PAPERLESS_OCR_LANGUAGE = "deu+eng+rus";
      PAPERLESS_AUTO_LOGIN_USERNAME = "admin";
      PAPERLESS_DATE_PARSER_LANGUAGES = "de";
      PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = true;
    };
  };
}
