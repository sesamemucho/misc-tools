TOP	:= $(HOME)/bin

SRCS	:= \
	get_next_filename.pl \
	link-dirs.sh \
	scan_letter_1side.sh \
	scan_thin_receipt.sh \

TGTS	:= $(addprefix $(TOP)/,$(basename $(notdir $(SRCS)))) \
	$(HOME)/.config/yadm/hooks/post_alt

all: $(TGTS)

$(TOP)/%: %.sh
	install $< $@

$(TOP)/%: %.bash
	install $< $@

$(TOP)/%: %.pl
	install $< $@

$(TOP)/%: %.py
	install $< $@

$(HOME)/.config/yadm/hooks/post_alt: yadm-post-alt.sh
	mkdir -p $(@D)
	install $< $@

show:
	@echo SRCS is $(SRCS)
	@echo TGTS is $(TGTS)
	@echo TOP is $(TOP)
