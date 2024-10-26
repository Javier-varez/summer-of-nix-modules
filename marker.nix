{ lib, config, ... }:
let
  firstUpperAlnum =
    str: lib.mapNullable lib.head (builtins.match "[^A-Z0-9]*([A-Z0-9]).*" (lib.toUpper str));

  colorType = lib.types.either (lib.types.strMatching "0x[0-9A-F]{6}") (
    lib.types.enum [
      "black"
      "brown"
      "green"
      "purple"
      "yellow"
      "blue"
      "gray"
      "orange"
      "red"
      "white"
    ]
  );

  markerType = lib.types.submodule {
    options = {
      location = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };

      style.label = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "[A-Z0-9]");
        default = null;
      };

      style.size = lib.mkOption {
        type = lib.types.enum [
          "tiny"
          "small"
          "medium"
          "large"
        ];
        default = "medium";
      };

      style.color = lib.mkOption {
        type = colorType;
        default = "red";
      };
    };
  };

  userType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        departure = lib.mkOption {
          type = markerType;
          default = { };
        };

        arrival = lib.mkOption {
          type = markerType;
          default = { };
        };
      };

      config = {
        departure.style.label = lib.mkDefault (firstUpperAlnum name);
        arrival.style.label = lib.mkDefault (firstUpperAlnum name);
      };
    }
  );

in
{
  imports = [
    ./path.nix
  ];

  options = {
    users = lib.mkOption { type = lib.types.attrsOf userType; };
    map.markers = lib.mkOption { type = lib.types.listOf markerType; };
  };

  config = {
    map.center = lib.mkIf (lib.length config.map.markers >= 1) null;
    map.zoom = lib.mkIf (lib.length config.map.markers >= 2) null;


    map.markers = lib.filter (marker: marker.location != null) (
      lib.concatMap (user: [ user.departure user.arrival ]) (lib.attrValues config.users)
    );

    requestParams =
      let
        paramPerMarker =
          marker:
          let
            size =
              {
                tiny = "tiny";
                small = "small";
                medium = "mid";
                large = null;
              }
              .${marker.style.size};
            attr =
              (lib.optional (marker.style.label != null) "label:${marker.style.label}")
              ++ (lib.optional (size != null) "size:${size}")
              ++ [ "color:${marker.style.color}" ]
              ++ [ "$(${config.scripts.geocode}/bin/geocode ${lib.escapeShellArg marker.location})" ];
          in
          "markers=\"${lib.concatStringsSep "|" attr}\"";
      in
      builtins.map paramPerMarker config.map.markers;
  };
}
