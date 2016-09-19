# Author: Patrick Spek <p.spek@tyil.work>
#
# License: GPLv3
#
# This Makefile generates all the PDF files from the latex documents. The
# double `pdflatex` call is to make sure the page numbering and tables of
# content are correct.

DESTDIR?=$(CURDIR)/pdf_output
PDFLATEX_ARGS=-output-directory "$(DESTDIR)"

all: refresh ewrite idpri soprj5 clean

clean:
	rm -f $(DESTDIR)/*.aux
	rm -f $(DESTDIR)/*.log
	rm -f $(DESTDIR)/*.toc

prepare:
	mkdir -p "$(DESTDIR)"

refresh:
	rm -r "$(DESTDIR)"

ewrite: ewrite-email ewrite-summary ewrite-portfolio
idpri: idpri-week1 idpri-week2
soprj5: soprj5-vragen

ewrite-email: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-email.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-email.tex

ewrite-portfolio: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-portfolio.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-portfolio.tex

ewrite-summary: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-summary.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-summary.tex

idpri-week1: prepare
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week1.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week1.tex

idpri-week2: prepare
	neato -T png idpri/navigatiemodel.dot -o idpri/assets/navigatiemodel.png
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week2.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week2.tex

soprj5-vragen: prepare
	cd soprj5; pdflatex $(PDFLATEX_ARGS) soprj5-vragen.tex \
		&& pdflatex $(PDFLATEX_ARGS) soprj5-vragen.tex

