TARGET_CODESIGN = $(shell which ldid)

PLATFORM = iphoneos
NAME = feather
SCHEME ?= 'feather (Release)'
RELEASE = Release-iphoneos
CONFIGURATION = Release

MACOSX_SYSROOT = $(shell xcrun -sdk macosx --show-sdk-path)
TARGET_SYSROOT = $(shell xcrun -sdk $(PLATFORM) --show-sdk-path)

APP_TMP         = $(TMPDIR)/$(NAME)
STAGE_DIR   = $(APP_TMP)/stage
APP_DIR 	   = $(APP_TMP)/Build/Products/$(RELEASE)/$(NAME).app

OPTIMIZATION_LEVEL ?= -Onone

# Export PATH to ensure tools like ldid are accessible
export PATH:=$(PATH):/usr/local/bin

all: package

package:
	@rm -rf $(APP_TMP)
	# Clean Swift environment only if necessary, comment out for faster subsequent builds
	# @rm -rf ~/Library/Developer/Xcode/DerivedData
	# @xcodebuild clean
	
	@set -o pipefail; \
		xcodebuild \
		-jobs $(shell sysctl -n hw.physicalcpu) \
		-project '$(NAME).xcodeproj' \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-arch arm64 -sdk $(PLATFORM) \
		-derivedDataPath $(APP_TMP) \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		DSTROOT=$(APP_TMP)/install \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		SWIFT_PACKAGE_MANAGER_ENABLE_XCODE_PROJECT_FORMATS=NO \
		OTHER_CFLAGS="$(OPTIMIZATION_LEVEL)" \
		OTHER_SWIFT_FLAGS="$(OPTIMIZATION_LEVEL)" | xcpretty
	
	@mkdir -p $(STAGE_DIR)/Payload
	@mv $(APP_DIR) $(STAGE_DIR)/Payload/$(NAME).app
	@echo "Build artifacts: $(APP_TMP)"
	@echo "Staging directory: $(STAGE_DIR)"
	
	@rm -rf $(STAGE_DIR)/Payload/$(NAME).app/_CodeSignature
	@ln -sf $(STAGE_DIR)/Payload Payload
	@mkdir -p packages

ifeq ($(TIPA),1)
	@zip -r9 packages/$(NAME)-ts.tipa Payload
else
	@zip -r9 packages/$(NAME).ipa Payload
endif

clean:
	@rm -rf $(STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf apple-include
	@rm -rf $(APP_TMP)
	# Clean DerivedData and xcodebuild only when necessary
	# @rm -rf ~/Library/Developer/Xcode/DerivedData
	# @xcodebuild clean

.PHONY: apple-include