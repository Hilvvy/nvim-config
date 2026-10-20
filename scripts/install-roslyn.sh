#!/usr/bin/env bash
# Official pinned Roslyn for Linux x86_64; no SDK/runtime installation.
set -euo pipefail
version=5.12.0-1.26426.8
sha256=50f88435f5875640fb2341878618dbfaec4354a1a134efcac0ae557247448a58
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { echo 'Roslyn installer supports Linux x86_64 only.' >&2; exit 1; }
data=${1:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim}
data=$(realpath -m -- "$data")
[[ "$data" != / && "$data" != "$HOME" && "$data" != "${XDG_DATA_HOME:-$HOME/.local/share}" ]] || { echo 'Unsafe data directory' >&2; exit 1; }
target="$data/tools/roslyn-language-server-$version"
exe="$target/tools/net10.0/linux-x64/Microsoft.CodeAnalysis.LanguageServer"
if [[ -f "$target/.hilvim-sha256" && $(cat "$target/.hilvim-sha256") == "$sha256" && -x "$exe" ]]; then
  echo "Roslyn already installed: $exe"
  exit 0
fi
[[ ! -e "$target" && ! -L "$target" ]] || { echo "Existing Roslyn directory left untouched: $target" >&2; exit 1; }
for command in curl sha256sum unzip realpath; do command -v "$command" >/dev/null || { echo "Missing $command" >&2; exit 1; }; done
stage=$(mktemp -d)
echo "Downloading verified Roslyn $version; temporary files: $stage"
url="https://api.nuget.org/v3-flatcontainer/roslyn-language-server.linux-x64/$version/roslyn-language-server.linux-x64.$version.nupkg"
curl --fail --location --retry 2 --connect-timeout 15 --max-time 180 --output "$stage/roslyn.zip" "$url"
printf '%s  %s\n' "$sha256" "$stage/roslyn.zip" | sha256sum --check --status
mkdir "$stage/package"
unzip -q "$stage/roslyn.zip" -d "$stage/package"
chmod +x "$stage/package/tools/net10.0/linux-x64/Microsoft.CodeAnalysis.LanguageServer"
printf '%s\n' "$sha256" > "$stage/package/.hilvim-sha256"
mkdir -p "$data/tools"
mv -- "$stage/package" "$target"
# Only the exact downloaded file and now-empty temporary directory are removed.
rm -- "$stage/roslyn.zip"
rmdir -- "$stage"
echo "Roslyn installed: $exe (requires host .NET 10 runtime)"
