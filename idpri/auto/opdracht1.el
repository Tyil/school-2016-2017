(TeX-add-style-hook
 "opdracht1"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "11pt" "english")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("babel" "english")))
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art11"
    "babel"
    "enumitem"
    "fancyhdr"
    "graphicx"
    "lastpage")
   (TeX-add-symbols
    "Frontpage"))
 :latex)

