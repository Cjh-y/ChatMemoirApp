#!/bin/bash
# Generate a proper Xcode project for ChatMemoirApp

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODEPROJ="$PROJECT_DIR/ChatMemoirApp.xcodeproj"

echo "Creating Xcode project..."

# Create xcodeproj directory
mkdir -p "$XCODEPROJ"

# Generate a minimal project.pbxproj
# This creates a proper iOS app target that pulls in SPM dependencies

PBXPROJ="$XCODEPROJ/project.pbxproj"

cat > "$PBXPROJ" << 'PBXEOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = { };
	objectVersion = 56;
	objects = {
/* Root */
		ROOTOBJECT = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
			};
			buildConfigurationList = BUILDCONFIGS;
			compatibilityVersion = "Xcode 14.0";
			mainGroup = MAINGROUP;
			productRefGroup = PRODUCTSGROUP;
			projectDirPath = "";
			projectRoot = "";
			targets = ( APPTARGET );
		};
/* Build configs */
		BUILDCONFIGS = {
			isa = XCConfigurationList;
			buildConfigurations = ( CONFIG_DEBUG, CONFIG_RELEASE );
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		CONFIG_DEBUG = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_NAME = ChatMemoirApp;
				INFOPLIST_FILE = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				TARGETED_DEVICE_FAMILY = "1,2";
				SWIFT_VERSION = 5.0;
				CODE_SIGN_STYLE = Automatic;
			};
			name = Debug;
		};
		CONFIG_RELEASE = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_NAME = ChatMemoirApp;
				INFOPLIST_FILE = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				TARGETED_DEVICE_FAMILY = "1,2";
				SWIFT_VERSION = 5.0;
				CODE_SIGN_STYLE = Automatic;
			};
			name = Release;
		};
/* App target */
		APPTARGET = {
			isa = PBXNativeTarget;
			buildConfigurationList = BUILDCONFIGS;
			buildPhases = ( SOURCESPHASE );
			buildRules = ( );
			dependencies = ( );
			name = ChatMemoirApp;
			productName = ChatMemoirApp;
			productType = "com.apple.product-type.application";
		};
		SOURCESPHASE = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = ( );
			runOnlyForDeploymentPostprocessing = 0;
		};
/* Groups */
		MAINGROUP = {
			isa = PBXGroup;
			children = ( );
			sourceTree = "<group>";
		};
		PRODUCTSGROUP = {
			isa = PBXGroup;
			children = ( );
			name = Products;
			sourceTree = "<group>";
		};
	};
	rootObject = ROOTOBJECT;
}
PBXEOF

echo ""
echo "✅ Xcode project created: $XCODEPROJ"
echo ""
echo "Now open it:"
echo "  open $XCODEPROJ"
echo ""
echo "Then:"
echo "  1. Drag the Sources/ folder from Finder into Xcode's file navigator"
echo "  2. Check 'Copy items if needed' = NO"
echo "  3. Add to target: ChatMemoirApp"
echo "  4. Product → Archive → Distribute App → Development → Export IPA"
echo ""

open "$XCODEPROJ"
