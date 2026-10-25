"""Generate the dependency-free Xcode project; stable IDs make changes reviewable."""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
def uid(name):return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def q(text):return '"'+str(text).replace('\\','\\\\').replace('"','\\"')+'"'
objects=[]
def obj(name,body):
 i=uid(name);objects.append(f'{i} = {{ {body} }};');return i
sources=[];refs=[]
for source in sorted((root/'Sources/SkinsApp').glob('*.swift')):
 path=source.relative_to(root)
 ref=obj(str(path),'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = '+q(path)+'; sourceTree = SOURCE_ROOT;')
 refs.append(ref);sources.append(obj('build:'+str(path),f'isa = PBXBuildFile; fileRef = {ref};'))
resource=obj('resources','isa = PBXFileReference; lastKnownFileType = folder; path = Sources/SkinsApp/Content; sourceTree = SOURCE_ROOT;')
assets=obj('assets','isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = SOURCE_ROOT;')
app=obj('app','isa = PBXFileReference; explicitFileType = wrapper.application; path = Skins.app; sourceTree = BUILT_PRODUCTS_DIR;')
products=obj('products',f'isa = PBXGroup; children = ({app},); name = Products; sourceTree = "<group>";')
group=obj('main',f'isa = PBXGroup; children = ({", ".join(refs+[resource,assets,products])},); sourceTree = "<group>";')
resources=obj('resourcesPhase',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({obj("copyResources",f"isa = PBXBuildFile; fileRef = {resource};")},{obj("buildAssets",f"isa = PBXBuildFile; fileRef = {assets};")},); runOnlyForDeploymentPostprocessing = 0;')
sourcephase=obj('sourcesPhase',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(sources)},); runOnlyForDeploymentPostprocessing = 0;')
package=obj('package','isa = XCLocalSwiftPackageReference; relativePath = .;')
core=obj('coreProduct','isa = XCSwiftPackageProductDependency; productName = SkinsCore;')
framework=obj('framework',f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({obj("linkCore",f"isa = PBXBuildFile; productRef = {core};")},); runOnlyForDeploymentPostprocessing = 0;')
common={'IPHONEOS_DEPLOYMENT_TARGET':'17.0','SDKROOT':'iphoneos','SWIFT_VERSION':'6.0','CLANG_ENABLE_MODULES':'YES'}
appsettings={'PRODUCT_BUNDLE_IDENTIFIER':'app.kaitofl.skins','PRODUCT_NAME':'Skins','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'Skins','INFOPLIST_KEY_LSApplicationCategoryType':'public.app-category.healthcare-fitness','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations':'UIInterfaceOrientationPortrait','INFOPLIST_KEY_UIUserInterfaceStyle':'Light','INFOPLIST_KEY_CFBundleDevelopmentRegion':'ja','CODE_SIGN_STYLE':'Automatic','TARGETED_DEVICE_FAMILY':'1','MARKETING_VERSION':'0.1.0','CURRENT_PROJECT_VERSION':'1','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','SWIFT_EMIT_LOC_STRINGS':'YES'}
def configlist(label,settings):
 configs=[]
 for name in ['Debug','Release']:
  s={**settings,'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if name=='Debug' else '-O'}
  if name=='Debug':
   s['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG'
   s['ONLY_ACTIVE_ARCH']='YES'
  configs.append(obj(label+name,'isa = XCBuildConfiguration; buildSettings = {'+' '.join(k+' = '+q(v)+';' for k,v in s.items())+'}; name = '+name+';'))
 return obj(label+'configs',f'isa = XCConfigurationList; buildConfigurations = ({", ".join(configs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
targetconfig=configlist('target',appsettings)
projectconfig=configlist('project',common)
target=obj('target',f'isa = PBXNativeTarget; buildConfigurationList = {targetconfig}; buildPhases = ({sourcephase},{framework},{resources},); buildRules = (); dependencies = (); name = Skins; packageProductDependencies = ({core},); productName = Skins; productReference = {app}; productType = "com.apple.product-type.application";')
project=obj('project',f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; BuildIndependentTargetsInParallel = YES; }}; buildConfigurationList = {projectconfig}; compatibilityVersion = "Xcode 14.0"; developmentRegion = ja; hasScannedForEncodings = 0; knownRegions = (ja,en,Base,); mainGroup = {group}; packageReferences = ({package},); productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target},);')
(root/'Skins.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {project}; }}\n')
(root/'Skins.xcodeproj/xcshareddata/xcschemes/Skins.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="Skins.app" BlueprintName="Skins" ReferencedContainer="container:Skins.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"/>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="Skins.app" BlueprintName="Skins" ReferencedContainer="container:Skins.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="Skins.app" BlueprintName="Skins" ReferencedContainer="container:Skins.xcodeproj"/></BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated',root/'Skins.xcodeproj')
