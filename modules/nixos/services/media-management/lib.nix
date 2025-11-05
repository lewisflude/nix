_:
let
  inherit (builtins) toString;
in
{
  mkDirRule =
    {
      path,
      mode ? "0755",
      user,
      group,
    }:
    "d ${path} ${mode} ${toString user} ${toString group} -";
}
