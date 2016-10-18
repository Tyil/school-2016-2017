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
	rm -f ewrite/ewrite-tutorial.tex

prepare:
	mkdir -p "$(DESTDIR)"

refresh:
	rm -fr "$(DESTDIR)"

ewrite: ewrite-email ewrite-email-new ewrite-summary ewrite-summary-new ewrite-tutorial ewrite-tutorial-new ewrite-portfolio
idpri: idpri-week1 idpri-week2 idpri-week3 idpri-week4
soprj5: soprj5-vragen

ewrite-email: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-email.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-email.tex

ewrite-email-new: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-email-new.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-email-new.tex

ewrite-portfolio: prepare
	#cd ewrite; pandoc -s ewrite-tutorial.md -o ewrite-tutorial.tex
	#cd ewrite; pandoc -s ewrite-tutorial-new.md -o ewrite-tutorial-new.tex
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-portfolio.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-portfolio.tex

ewrite-summary: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-summary.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-summary.tex

ewrite-summary-new: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-summary-new.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-summary-new.tex

ewrite-tutorial: prepare
	cd ewrite; pandoc --template=ewrite-tutorial.textpl -s ewrite-tutorial.md \
		-o ewrite-tutorial.pdf
	mv ewrite/ewrite-tutorial.pdf pdf_output

ewrite-tutorial-new: prepare
	cd ewrite; pandoc --template=ewrite-tutorial.textpl -s ewrite-tutorial-new.md \
		-o ewrite-tutorial-new.pdf
	mv ewrite/ewrite-tutorial-new.pdf pdf_output

idpri-week1: prepare
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week1.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week1.tex

idpri-week2: prepare
	neato -T png idpri/navigatiemodel.dot -o idpri/assets/navigatiemodel.png
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week2.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week2.tex

idpri-week3: prepare
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week3.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week3.tex

idpri-week4: prepare
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week4.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week4.tex

soprj5-vragen: prepare
	cd soprj5; pdflatex $(PDFLATEX_ARGS) soprj5-vragen.tex \
		&& pdflatex $(PDFLATEX_ARGS) soprj5-vragen.tex

