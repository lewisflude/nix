{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

# To update this package to a new version:
# 1. Run: nurl https://github.com/eat-pray-ai/yutu v<NEW_VERSION>
# 2. Copy the output and replace the src block below
# 3. Update the version field
# 4. Update vendorHash if needed (set to null first, then build to get correct hash)

buildGoModule rec {
  pname = "yutu";
  version = "0.10.4";

  src = fetchFromGitHub {
    owner = "eat-pray-ai";
    repo = "yutu";
    rev = "v${version}";
    hash = "sha256-353SQGH+5FiVTsLwYU3lMjl0CXzEP6hGVYKRghUwSvg=";
  };

  vendorHash = "sha256-z6qRI/v6JwVWcHBgV9gC2yBU6hLSoBz8lOqG8WSOfPk=";

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/eat-pray-ai/yutu/cmd.Version=${version}"
  ];

  meta = {
    description = "Fully functional MCP server and CLI for YouTube";
    homepage = "https://github.com/eat-pray-ai/yutu";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "yutu";
  };
}
