
### CHROME.XEP.SEARCH ###

XEP_DESCRIPTION = xep_description
APP = ext/js/app.js
OPTIONS = ext/js/options.js
SRC = src/chrome/xep/*.hx Makefile

HXJS = haxe \
	-cp src -cp ../hx.html5 -cp ../chrome.extension \
	-D chrome -D noEmbedJS \
	--no-traces
	#-D DEBUG \

all: build
	
$(XEP_DESCRIPTION):
	haxe xep_description.hxml

xep-description: $(XEP_DESCRIPTION)
	
$(APP) : $(SRC)
	$(HXJS) chrome.xep.App -js $(APP) \
		-cp ../hxmpp \
		-resource xep_description@xep
		
$(OPTIONS) : $(SRC)
	$(HXJS) chrome.xep.Options -js $(OPTIONS) \
		-cp ../uio -cp ../chrome.extension.ui
		
ext: $(XEP_DESCRIPTION) $(APP) $(OPTIONS)

build: ext

clean:
	rm -f $(APP) $(OPTIONS) 
