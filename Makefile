BASE.DIR=$(PWD)
TEAKERNE.DIR=$(BASE.DIR)/teakerne
ifneq (,$(wildcard $(TEAKERNE.DIR)))
include $(TEAKERNE.DIR)/Makefile
else

endif

bootstrap: .FORCE
	git clone git@github.com:caseykelso/react-native-teakerne.git teakerne
	cd $(BASE.DIR)/teakerne && git checkout integrate

.FORCE:

