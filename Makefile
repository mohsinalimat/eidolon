WORKSPACE = Kiosk.xcworkspace
SCHEME = Kiosk
CONFIGURATION = Debug
APP_NAME = Kiosk

APP_PLIST = Kiosk/Info.plist
PLIST_BUDDY = /usr/libexec/PlistBuddy
BUNDLE_VERSION = $(shell $(PLIST_BUDDY) -c "Print CFBundleVersion" $(APP_PLIST))
GIT_COMMIT = $(shell git log -n1 --format='%h')
DATE_VERSION = $(shell date "+%Y.%m.%d")
DEVICE_HOST = platform='iOS Simulator',OS='8.1',name='iPad Air'

# Default for `make`
all: ci

oss: stub_keys
oss: 
	bundle exec pod install

bootstrap:

	@echo "\nSetting up API Keys, leave blank if you don't know."

	@printf '\nWhat is your Artsy API Client Secret? '; \
		read ARTSY_CLIENT_SECRET; \
		bundle exec pod keys set ArtsyAPIClientSecret "$$ARTSY_CLIENT_SECRET" Eidolon

	@printf '\nWhat is your Artsy API Client Key? '; \
		read ARTSY_CLIENT_KEY; \
		bundle exec pod keys set ArtsyAPIClientKey "$$ARTSY_CLIENT_KEY"

	@printf '\nWhat is your Hockey Production Secret? '; \
		read HOCKEYPRODUCTIONSECRET; \
		bundle exec pod keys set HockeyProductionSecret "$$HOCKEYPRODUCTIONSECRET"

	@printf '\nWhat is your Hockey Beta Secret? '; \
		read HOCKEYBETASECRET; \
		bundle exec pod keys set HockeyBetaSecret "$$HOCKEYBETASECRET"

	@printf '\nWhat is your production Mixpanel API Key? '; \
		read MIXPANEL_KEY; \
		bundle exec pod keys set MixpanelProductionAPIClientKey "$$MIXPANEL_KEY"

	@printf '\nWhat is your staging Mixpanel API Key? '; \
		read MIXPANEL_KEY; \
		bundle exec pod keys set MixpanelStagingAPIClientKey "$$MIXPANEL_KEY"

	@printf '\nWhat is your Cardflight API Client Key? '; \
		read CARDFLIGHT_KEY; \
		bundle exec pod keys set CardflightAPIClientKey "$$CARDFLIGHT_KEY"

	@printf '\nWhat is your Cardflight Test API Key? '; \
		read CARDFLIGHT_KEY; \
		bundle exec pod keys set CardflightAPIStagingClientKey "$$CARDFLIGHT_KEY"

	@printf '\nWhat is your Cardflight Merchant Account Production Token? '; \
		read CARDFLIGHT_TOKEN; \
		bundle exec pod keys set CardflightMerchantAccountToken "$$CARDFLIGHT_TOKEN"

	@printf '\nWhat is your Cardflight Merchant Account Test Token? '; \
		read CARDFLIGHT_TOKEN; \
		bundle exec pod keys set CardflightMerchantAccountStagingToken "$$CARDFLIGHT_TOKEN"

	@printf '\nWhat is your Balanced Marketplace Token? '; \
		read TOKEN; \
		bundle exec pod keys set BalancedMarketplaceToken "$$TOKEN"

	@printf '\nWhat is your Balanced Marketplace Staging Token? '; \
		read TOKEN; \
		bundle exec pod keys set BalancedMarketplaceStagingToken "$$TOKEN"
	bundle
	bundle exec pod install


bundle: 

	if [ ! -d ~/.cocoapods/repos/artsy ]; then \
		bundle exec pod repo add artsy https://github.com/artsy/Specs.git; \
	fi
	
	bundle exec pod install

storyboard_ids:
	bundle exec sbconstants Kiosk/Storyboards/StoryboardIdentifiers.swift --source-dir Kiosk/Storyboards --swift

build:
	set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' -sdk iphonesimulator -destination $(DEVICE_HOST) build | xcpretty -c

clean:
	xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' clean

test:
	set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration Debug test -sdk iphonesimulator -destination $(DEVICE_HOST) | xcpretty -c --test

ipa:
	$(PLIST_BUDDY) -c "Set CFBundleDisplayName $(BUNDLE_NAME)" $(APP_PLIST)
	$(PLIST_BUDDY) -c "Set CFBundleVersion $(DATE_VERSION)" $(APP_PLIST)
	ipa build --scheme $(SCHEME) --configuration $(CONFIGURATION) -t
	$(PLIST_BUDDY) -c "Set CFBundleDisplayName $(APP_NAME)" $(APP_PLIST)

distribute:
	ipa distribute:hockeyapp

prepare_ci: CONFIGURATION = Debug
prepare_ci: stub_keys

stub_keys:
	bundle exec pod keys set ArtsyAPIClientSecret "-" Eidolon
	bundle exec pod keys set ArtsyAPIClientKey "-"
	bundle exec pod keys set HockeyProductionSecret "-"
	bundle exec pod keys set HockeyBetaSecret "-"
	bundle exec pod keys set MixpanelProductionAPIClientKey "-"
	bundle exec pod keys set MixpanelStagingAPIClientKey "-"
	bundle exec pod keys set CardflightAPIClientKey "-"
	bundle exec pod keys set CardflightAPIStagingClientKey "-"
	bundle exec pod keys set CardflightMerchantAccountToken "-"
	bundle exec pod keys set CardflightMerchantAccountStagingToken "-"
	bundle exec pod keys set BalancedMarketplaceToken "-"
	bundle exec pod keys set BalancedMarketplaceStagingToken "-"
	

ci: test

beta: BUNDLE_NAME = '$(APP_NAME) β'
beta: clean build ipa distribute
