-- Presentation-only adjustments shared by the note, appendix, methods memo and summary.

-- Backticks mark literal numbers and codes in the prose (years, versions, scheme numbers) so
-- that R/check.R does not read them as unsourced results. Print those as ordinary text; keep
-- code formatting for file names and paths.
function Code(c)
  if c.text:find("[/_]") or c.text:find("%.%a+$") then
    return nil
  end
  return pandoc.Str(c.text)
end

-- In the PDF, keep a paragraph that is only a bold label (such as "Crosswalk.") on the same
-- page as the list that follows it.
function Para(p)
  if not quarto.doc.is_format("typst") then
    return nil
  end
  if #p.content == 1 and p.content[1].t == "Strong" then
    local body = pandoc.write(pandoc.Pandoc({p}), "typst")
    return pandoc.RawBlock("typst", "#block(sticky: true)[" .. body .. "]")
  end
end
