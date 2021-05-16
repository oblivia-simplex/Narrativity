TITLE="Narrativity"
BASE?="narrativity"
OUT="./out"
BUILD="./build"
ASTERISM_SVG="pandanus.svg"
export ASTERISM_PNG="pandanus.png"
FONT="Tex Gyre Pagella"
#FONT="BemboStd"
LATEX="lualatex"
#FONT="Minion Pro"

all: epub mobi pdf html

outdir:
	mkdir -p $(OUT) $(BUILD)
	cp images/* $(BUILD)

zip: all
	cd $(OUT) && zip -r ../MortalLeap.zip .

cover:
	convert images/cover.jpg \
	    -resize 1480x2100 \
	    $(BUILD)/_cover.pdf
	pdfjam --paper a5paper --outfile $(BUILD)/cover.pdf $(BUILD)/_cover.pdf
	rm $(BUILD)/_cover.pdf

clean:
	rm -rf $(BUILD) $(OUT)

cleanbuild:
	rm -rf $(BUILD)

collate: outdir 
	cat frontmatter.md [1-2]_*.md backmatter.md > $(BUILD)/$(BASE).md

mobi: epub
	ebook-convert $(BUILD)/$(BASE).epub $(BUILD)/$(BASE).mobi
	cp $(BUILD)/$(BASE).mobi $(OUT)

pdf2: tex cover
	$(LATEX) --output-dir=$(BUILD) $(BUILD)/$(BASE).tex 
	mv $(BUILD)/$(BASE).pdf $(BUILD)/$(BASE)_no_cover.pdf
	convert xc:none -page A5 $(BUILD)/blank.pdf
	pdfunite $(BUILD)/cover.pdf \
	    $(BUILD)/blank.pdf \
	    $(BUILD)/$(BASE)_no_cover.pdf $(BUILD)/$(BASE).pdf
	cp $(BUILD)/$(BASE).pdf $(OUT)

epub: collate metadata
# set the asterism image
	sed "s/ASTERISM/$(ASTERISM_SVG)/" epub.css > $(BUILD)/epub.css
# generate the epub
	pandoc --standalone -o $(BUILD)/$(BASE).epub \
			--lua-filter=filters/smallcaps.lua \
			--lua-filter=filters/no_chapter_numbering.lua \
	    --css=$(BUILD)/epub.css \
	    --epub-cover-image=$(BUILD)/cover.png \
	    title.txt $(BUILD)/$(BASE).md
# insert the asterism image into the epub
	./add_media.sh $(BUILD)/$(BASE).epub images/$(ASTERISM_SVG)
	cp $(BUILD)/$(BASE).epub $(OUT)

html: collate metadata
	pandoc --standalone -o $(BUILD)/$(BASE).html \
			--lua-filter=filters/smallcaps.lua \
			--lua-filter=filters/no_chapter_numbering.lua \
	    title.txt $(BUILD)/$(BASE).md
	cp $(BUILD)/$(BASE).html $(OUT)



pdf: collate metadata
	cat $(BUILD)/$(BASE).md \
	|	pandoc --standalone \
			--lua-filter=filters/asterism.lua \
			--lua-filter=filters/smallcaps.lua \
			--lua-filter=filters/no_chapter_numbering.lua \
			--lua-filter=filters/lettrine.lua \
			--lua-filter=filters/verse.lua \
	    --template template.tex \
			-V lettrinefont=Zallman \
	    -V documentclass=memoir \
	    -V numbersections=false \
	    -V geometry:a5paper \
			-V asterism=$(ASTERISM_PNG) \
	    -V mainfont=$(FONT) \
	    -o $(BUILD)/$(BASE).pdf title.txt -
# sed -i 's|\(\\hfill\\break\)|\\hfill\\break\\noindent%|' $(BUILD)/$(BASE).tex


metadata: 
	sed -i "s/^identifier:.*/identifier: `git log -n1 | grep ^Date | cut -d: -f2-`/"  title.txt

ast: collate
	pandoc $(BUILD)/$(BASE).md \
			--lua-filter=filters/smallcaps.lua \
			--lua-filter=filters/no_chapter_numbering.lua \
			--lua-filter=filters/lettrine.lua \
			--lua-filter=filters/asterism.lua \
		  -t json | jq . > $(BUILD)/$(BASE).json
