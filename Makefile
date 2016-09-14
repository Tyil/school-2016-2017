DESTDIR?=$(CURDIR)/pdf_output
PDFLATEX_ARGS=-output-directory "$(DESTDIR)"

all: refresh ewrite idpri clean

clean:
	rm -f $(DESTDIR)/*.aux
	rm -f $(DESTDIR)/*.log
	rm -f $(DESTDIR)/*.toc

prepare:
	mkdir -p "$(DESTDIR)"

refresh:
	rm -r "$(DESTDIR)"

ewrite: ewrite-email ewrite-portfolio
idpri: idpri-week1 idpri-week2

ewrite-email: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-email.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-email.tex

ewrite-portfolio: prepare
	cd ewrite; pdflatex $(PDFLATEX_ARGS) ewrite-portfolio.tex \
		&& pdflatex $(PDFLATEX_ARGS) ewrite-portfolio.tex

idpri-week1: prepare
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week1.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week1.tex

idpri-week2: prepare
	neato -T png idpri/navigatiemodel.dot -o idpri/assets/navigatiemodel.png
	cd idpri; pdflatex $(PDFLATEX_ARGS) idpri-week2.tex \
		&& pdflatex $(PDFLATEX_ARGS) idpri-week2.tex

