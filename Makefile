# all of the below variables need to be changed
GIT_ORG=yourgitorg
GIT_REPO=yourgitrepo/react-native-helloworld
APPLE_ACCOUNT=lorem
APPLE_ID=appleid
APP_ID_ROOT=appidroot
APPLE_DEVELOPMENT_TEAM=appledevteam
S3_BUCKET=s3bucket
BASE.DIR=$(PWD)
TEAKERNE.DIR=$(BASE.DIR)/teakerne
ORG_NAME=yourorg
APP_NAME=prototype
# all of the above variables need to be changed
BASE_DIR=$(PWD)
export GIT_ORG GIT_REPO APPLE_ACCOUNT APPLE_ID APP_ID_ROOT APPLE_DEVELOPMENT_TEAM S3_BUCKET ORG_NAME APP_NAME BASE_DIR
ifneq (,$(wildcard $(TEAKERNE.DIR)))
include $(TEAKERNE.DIR)/Makefile
else
$(warning teakerne is missing)
endif

bootstrap: .FORCE
	git clone git@github.com:caseykelso/react-native-teakerne.git teakerne
	cd $(BASE.DIR)/teakerne && git checkout fix-android-sdk
	mkdir -p $(BASE.DIR)/$(APP_NAME)

create.project: .FORCE
	ORG_NAME=$(ORG_NAME) APP_NAME=$(APP_NAME) BASE_DIR=$(BASE_DIR)  $(MAKE) -C $(TEAKERNE.DIR) create.project

.FORCE:

