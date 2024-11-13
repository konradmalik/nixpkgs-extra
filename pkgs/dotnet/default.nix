{
  fetchurl,
  system,
  dotnetCorePackages,
}:
let
  files = builtins.attrNames (builtins.readDir ./versions);

  makeDotnetSdk8 =
    version: url:
    dotnetCorePackages.dotnet_8.sdk.overrideAttrs (oldAttrs: {
      inherit version;
      src = fetchurl url;
    });

  makeDotnetSdk9 =
    version: url:
    dotnetCorePackages.dotnet_9.sdk.overrideAttrs (oldAttrs: {
      inherit version;
      src = fetchurl url;
    });
in
(builtins.listToAttrs (
  builtins.map (
    f:
    let
      version = builtins.replaceStrings [ ".nix" ] [ "" ] f;
      name = "dotnet-sdk_${builtins.replaceStrings [ "." ] [ "_" ] version}";
    in
    {
      inherit name;
      value =
        let
          major = builtins.substring 0 1 version;
          maker =
            {
              "8" = makeDotnetSdk8;
              "9" = makeDotnetSdk9;
            }
            ."${major}";
        in
        maker version (import ./versions/${f}).${system};
    }
  ) files
))
