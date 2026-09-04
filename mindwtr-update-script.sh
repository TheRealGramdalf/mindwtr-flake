gitroot="$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
  echo "Git tree '${gitroot}' is dirty, unable to continue"
  exit
fi
if [ ! -e "$gitroot/pkgs/mindwtr/bun.nix" ]; then
  echo "Bun deps file not present, unable to continue"
  exit
fi


nix-update --flake mindwtr --commit

src="$(nix build "$gitroot"#mindwtr.src --no-link --print-out-paths)"

echo "$src"

cd "$src"
# Remove `copyPathToStore` entries which incorrectly attempt to provide `apps/*` directories as derivations
bun2nix | grep -Ev '^\s*?".*?" = copyPathToStore ./.*?;$' > "$gitroot/pkgs/mindwtr/bun.nix"

cd "$gitroot"
git add pkgs/mindwtr/bun.nix
git commit --amend --no-edit