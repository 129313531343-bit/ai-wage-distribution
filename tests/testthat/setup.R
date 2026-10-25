root <- normalizePath(file.path(getwd(), "..", ".."))
for (f in list.files(file.path(root, "R"), pattern = "^(utils|fn_).*\\.R$", full.names = TRUE)) source(f)
