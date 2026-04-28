#!/usr/bin/env python3
"""Generate DeepBreath.xcodeproj"""

import os
import uuid

def new_id():
    return uuid.uuid4().hex[:24].upper()

# Fixed IDs
PROJECT_ID = "262BF0A81C054D4BA017FAFD"
TARGET_ID = "AE9CF4E4E18240D8AB79F870"
SOURCES_PHASE_ID = "A161BCFD7F394D58A3DB1134"
RESOURCES_PHASE_ID = "D9DC744A2868485A92C8B6E4"
FRAMEWORKS_PHASE_ID = "F8D1B7A0C7EA4AAE88AC6752"
DEBUG_CONFIG_LIST_ID = "833FA65824F7435AB4D7A1C0"
RELEASE_CONFIG_LIST_ID = "B8A9338B47FE497E8CA173F1"
PROJECT_DEBUG_ID = "CF91944FDE844647BA7CDFB5"
PROJECT_RELEASE_ID = "471DC358B0EE495EADF364FD"
TARGET_DEBUG_ID = "78FE64453A6C49F392525314"
TARGET_RELEASE_ID = "63540C8C31144468A8D53BAA"
MAIN_GROUP_ID = "057498D8ADF9421698632364"
PRODUCTS_GROUP_ID = "5609534F7E294A1BB2EF60C9"
APP_PRODUCT_ID = "66016335235D46C38BD2C78A"
ASSETS_ID = "F91A3DBACAD5488CA8B2F3D5"

# Collect all Swift source files
source_dir = os.path.join(os.path.dirname(__file__), "DeepBreath")
swift_files = []
for root, dirs, files in os.walk(source_dir):
    dirs.sort()
    for f in sorted(files):
        if f.endswith(".swift"):
            rel = os.path.relpath(os.path.join(root, f), source_dir)
            swift_files.append(rel)

# Generate file ref IDs
file_ids = {f: new_id() for f in swift_files}
build_ids = {f: new_id() for f in swift_files}

def pbx_file_refs():
    lines = []
    for f in swift_files:
        name = os.path.basename(f)
        lines.append(f'\t\t{file_ids[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = {name}; path = {f}; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{ASSETS_ID} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{APP_PRODUCT_ID} /* DeepBreath.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DeepBreath.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    return "\n".join(lines)

def pbx_build_files():
    lines = []
    for f in swift_files:
        name = os.path.basename(f)
        lines.append(f'\t\t{build_ids[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ids[f]} /* {name} */; }};')
    lines.append(f'\t\t{new_id()} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ASSETS_ID} /* Assets.xcassets */; }};')
    return "\n".join(lines)

ASSETS_BUILD_ID = new_id()

def pbx_sources_phase():
    lines = []
    for f in swift_files:
        name = os.path.basename(f)
        lines.append(f'\t\t\t\t{build_ids[f]} /* {name} in Sources */,')
    return "\n".join(lines)

def pbx_main_group_children():
    # Build a tree
    seen = set()
    top_level = []
    for f in swift_files:
        parts = f.split(os.sep)
        if len(parts) == 1:
            top_level.append(('file', f))
        else:
            top_dir = parts[0]
            if top_dir not in seen:
                seen.add(top_dir)
                top_level.append(('dir', top_dir))
    lines = []
    for kind, item in top_level:
        if kind == 'file':
            lines.append(f'\t\t\t\t{file_ids[item]} /* {item} */,')
        else:
            # Create group reference
            pass
    return "\n".join(lines)

# Group IDs per subdirectory
dirs_found = set()
for f in swift_files:
    parts = f.split(os.sep)
    for i in range(1, len(parts)):
        dirs_found.add(os.sep.join(parts[:i]))

dir_group_ids = {d: new_id() for d in sorted(dirs_found)}

def pbx_groups():
    # Build a dict: dir -> [child files, child dirs]
    children_files = {d: [] for d in dirs_found}
    children_files[''] = []
    for f in swift_files:
        parent = os.path.dirname(f)
        children_files.setdefault(parent, []).append(f)

    children_dirs = {d: [] for d in dirs_found}
    children_dirs[''] = []
    for d in sorted(dirs_found):
        parent = os.path.dirname(d)
        children_dirs.setdefault(parent, []).append(d)

    lines = []

    def group_block(path, gid):
        name = os.path.basename(path) if path else "DeepBreath"
        children = []
        for sub in sorted(children_dirs.get(path, [])):
            children.append(f'\t\t\t\t{dir_group_ids[sub]} /* {os.path.basename(sub)} */,')
        for f in sorted(children_files.get(path, [])):
            children.append(f'\t\t\t\t{file_ids[f]} /* {os.path.basename(f)} */,')
        if path == '':
            children.append(f'\t\t\t\t{ASSETS_ID} /* Assets.xcassets */,')
            children.append(f'\t\t\t\t{PRODUCTS_GROUP_ID} /* Products */,')
        child_str = "\n".join(children)
        src = "\"<group>\"" if path else "\"<group>\""
        pathattr = f'path = {name};' if path else ''
        return f"""\t\t{gid} /* {name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{child_str}
\t\t\t);
\t\t\t{pathattr}
\t\t\tsourceTree = {src};
\t\t}};"""

    lines.append(group_block('', MAIN_GROUP_ID))
    for d in sorted(dirs_found):
        lines.append(group_block(d, dir_group_ids[d]))

    # Products group
    lines.append(f"""\t\t{PRODUCTS_GROUP_ID} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{APP_PRODUCT_ID} /* DeepBreath.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    return "\n\n".join(lines)

content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{pbx_build_files()}
\t\t{ASSETS_BUILD_ID} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ASSETS_ID} /* Assets.xcassets */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{pbx_file_refs()}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{pbx_groups()}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{TARGET_ID} /* DeepBreath */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {DEBUG_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget "DeepBreath" */;
\t\t\tbuildPhases = (
\t\t\t\t{SOURCES_PHASE_ID} /* Sources */,
\t\t\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */,
\t\t\t\t{RESOURCES_PHASE_ID} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = DeepBreath;
\t\t\tproductName = DeepBreath;
\t\t\tproductReference = {APP_PRODUCT_ID} /* DeepBreath.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{PROJECT_ID} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1530;
\t\t\t\tLastUpgradeCheck = 1530;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{TARGET_ID} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.3;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {RELEASE_CONFIG_LIST_ID} /* Build configuration list for PBXProject "DeepBreath" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {MAIN_GROUP_ID};
\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{TARGET_ID} /* DeepBreath */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{RESOURCES_PHASE_ID} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{ASSETS_BUILD_ID} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{SOURCES_PHASE_ID} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{pbx_sources_phase()}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{PROJECT_DEBUG_ID} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSET_CATALOG_COMPILER_OPTIMIZATION = space;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{PROJECT_RELEASE_ID} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSET_CATALOG_COMPILER_OPTIMIZATION = space;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{TARGET_DEBUG_ID} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT = YES;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_NSMicrophoneUsageDescription = "Microphone access is not used by this app.";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLE_SWIFT_VERSION = 5.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.deepbreath.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSUPPORTS_MACCATALYST = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{TARGET_RELEASE_ID} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT = YES;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_NSMicrophoneUsageDescription = "Microphone access is not used by this app.";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLE_SWIFT_VERSION = 5.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.deepbreath.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSUPPORTS_MACCATALYST = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{DEBUG_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget "DeepBreath" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{TARGET_DEBUG_ID} /* Debug */,
\t\t\t\t{TARGET_RELEASE_ID} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{RELEASE_CONFIG_LIST_ID} /* Build configuration list for PBXProject "DeepBreath" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{PROJECT_DEBUG_ID} /* Debug */,
\t\t\t\t{PROJECT_RELEASE_ID} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {PROJECT_ID} /* Project object */;
}}
"""

out_dir = os.path.join(os.path.dirname(__file__), "DeepBreath.xcodeproj")
os.makedirs(out_dir, exist_ok=True)
with open(os.path.join(out_dir, "project.pbxproj"), "w") as f:
    f.write(content)

print(f"Generated project.pbxproj with {len(swift_files)} source files:")
for f in swift_files:
    print(f"  {f}")
