BASE.DIR=$(PWD)
TEAKERNE.DIR=$(BASE.DIR)/teakerne
ORG_NAME=teakerne
APP_NAME=prototype
BASE_DIR=$(PWD)
ifneq (,$(wildcard $(TEAKERNE.DIR)))
include $(TEAKERNE.DIR)/Makefile
else
$(warning teakerne is missing)
endif

bootstrap: .FORCE
	git clone git@github.com:caseykelso/react-native-teakerne.git teakerne
	cd $(BASE.DIR)/teakerne && git checkout fix
	mkdir -p $(BASE.DIR)/$(APP_NAME)

create.project: .FORCE
	ORG_NAME=$(ORG_NAME) APP_NAME=$(APP_NAME) BASE_DIR=$(BASE_DIR)  $(MAKE) -C $(TEAKERNE.DIR) create.project

.FORCE:

