RENDER_PNG = openscad --imgsize=1440,1920 --projection=p --colorscheme=BeforeDawn -D 'view="explode"'

.PHONY: images stl

images: images/handset-explode-back.png images/handset-explode-front.png images/speakerphone-explode.png images/speakerphone-explode-back.png

images/handset-explode-back.png: handset.scad
	mkdir -p $(@D)
	$(RENDER_PNG) --camera=0.15,69.70,31.52,180.00,305.40,179.90,553.69 -o $@ handset.scad

images/handset-explode-front.png: handset.scad
	mkdir -p $(@D)
	$(RENDER_PNG) --camera=0.15,69.70,31.52,180.00,125.40,179.90,553.69 -o $@ handset.scad

images/speakerphone-explode.png: speaker-unit.scad
	mkdir -p $(@D)
	$(RENDER_PNG) --camera=-0.23,81.43,26.45,342.20,51.80,0.50,696.89 -o $@ speaker-unit.scad

images/speakerphone-explode-back.png: speaker-unit.scad
	mkdir -p $(@D)
	$(RENDER_PNG) --camera=-0.23,81.43,26.45,342.20,232,0.50,696.89 -o $@ speaker-unit.scad

stl: handset speakerphone

handset: stl/handset-front-cover.stl stl/handset-back-cover.stl stl/handset-front-panel.stl stl/handset-stand.stl

stl/handset-front-cover.stl stl/handset-back-cover.stl stl/handset-front-panel.stl stl/handset-stand.stl: handset.scad
	mkdir -p $(@D)
	openscad -D 'render="$(basename $(@F))"' -o $@ handset.scad

speakerphone: stl/speaker-front-cover.stl stl/speaker-back-cover.stl stl/speaker-front-panel.stl stl/speaker-brim.stl

stl/speaker-front-cover.stl stl/speaker-back-cover.stl stl/speaker-front-panel.stl stl/speaker-brim.stl: speaker-unit.scad
	mkdir -p $(@D)
	openscad -D 'render="$(basename $(@F))"' -o $@ speaker-unit.scad

