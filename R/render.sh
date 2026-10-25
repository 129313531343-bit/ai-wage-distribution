#!/bin/sh
# Render the note, appendix, methods memo and summary with Quarto.
# The project folder name contains colons ("~:Projects:..."), which break Quarto's stylesheet
# compiler, so rendering happens in a temporary copy at a colon-free path and the outputs are
# copied back. Raw data and the renv library are not copied; R uses this project's renv library.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$(cd "$ROOT" && Rscript -e 'cat(.libPaths()[1])' 2>/dev/null | tail -1)"
TMP="$(mktemp -d /tmp/aiwage-render.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

rsync -a --exclude 'renv/library' --include 'data/raw/' --include 'data/raw/MANIFEST.csv' --exclude 'data/raw/**' --exclude '.git' --exclude 'private' "$ROOT/" "$TMP/"
for d in note docs; do
  printf '.libPaths(c("%s", .libPaths()))\n' "$LIB" > "$TMP/$d/.Rprofile"
done

(cd "$TMP/note" && quarto render)
# Typst will not read files outside the document's folder, so the memo gets its own copy of
# the figures in the temporary tree.
cp -R "$TMP/note/figures" "$TMP/docs/figures"
cp "$TMP/note/references.bib" "$TMP/docs/references.bib"
sed -i.bak -e 's|\.\./note/figures/|figures/|g' -e 's|\.\./note/references\.bib|references.bib|' "$TMP/docs/methods_memo.qmd"
(cd "$TMP/docs" && quarto render methods_memo.qmd)
(cd "$TMP/docs" && quarto render summary.qmd)

mkdir -p "$ROOT/note/_rendered" "$ROOT/docs/_rendered"
cp "$TMP"/note/note.html "$TMP"/note/note.pdf "$TMP"/note/appendix.html "$TMP"/note/appendix.pdf "$ROOT/note/_rendered/"
cp "$TMP"/docs/methods_memo.pdf "$TMP"/docs/summary.pdf "$TMP"/docs/summary.html "$ROOT/docs/_rendered/"
echo "Rendered to note/_rendered/ and docs/_rendered/"
