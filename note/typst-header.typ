// Typesetting adjustments shared by the PDFs of the note, appendix, methods memo and summary.
// Smaller, unjustified table text, so the wide appendix tables fit the page without stretched
// or hyphenated cells.
#show table: set text(size: 0.85em, hyphenate: false)
#show table: set par(justify: false)
// Each document supplies its own "References" heading, so the bibliography adds none.
#set bibliography(title: none)
// Titles are justified and would otherwise hyphenate "distribu-tion" across lines.
#show "distribution": it => box(it)
