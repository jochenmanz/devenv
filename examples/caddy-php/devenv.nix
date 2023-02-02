{ pkgs, config, inputs, lib, ... }:

let
  phpPackage = pkgs.php.buildEnv {
    extraConfig = ''
      memory_limit = 256M
    '';
  };
in
{
  languages.php.enable = true;
  languages.php.package = phpPackage;
  languages.php.fpm.pools.web = {
    settings = {
      "pm" = "dynamic";
      "pm.max_children" = 5;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 5;
    };
  };

  services.mysql.enable = true;
  services.mysql.initialDatabases = lib.mkDefault [{ name = "shopware"; }];
  services.mysql.ensureUsers = lib.mkDefault [
    {
      name = "shopware";
      password = "shopware";
      ensurePermissions = { "*.*" = "ALL PRIVILEGES"; };
    }
  ];
  services.mysql.settings = {
    mysql = {
      user = "shopware";
      password = "shopware";
    };
    mysqldump = {
      user = "shopware";
      password = "shopware";
    };
    mysqladmin = {
      user = "shopware";
      password = "shopware";
    };
  };


  env.DATABASE_URL = lib.mkDefault "mysql://shopware:shopware@127.0.0.1:3306/shopware";

  services.caddy.enable = true;
  services.caddy.virtualHosts."http://localhost:8000" = {
    extraConfig = ''
      root * public
      php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}
      file_server
    '';
  };
}
