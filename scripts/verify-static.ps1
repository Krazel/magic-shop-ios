[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { $failures.Add($Message) }
}

$requiredFiles = @(
    '.gitignore',
    '.gitattributes',
    '.github\workflows\ios-ci.yml',
    '.github\workflows\ios-sideloadly.yml',
    'AGENTS.md',
    'Package.swift',
    'MagicShop.xcodeproj\project.pbxproj',
    'MagicShop.xcodeproj\xcshareddata\xcschemes\MagicShop.xcscheme',
    'MagicShop\App\MagicShopApp.swift',
    'MagicShop\App\AppModel.swift',
    'MagicShop\App\ProvisionalRootView.swift',
    'MagicShop\Core\Domain\GameState.swift',
    'MagicShop\Core\Domain\FixtureModels.swift',
    'MagicShop\Core\Domain\FixtureCatalog.swift',
    'MagicShop\Core\Domain\PlacementRules.swift',
    'MagicShop\Core\Domain\GameEngine.swift',
    'MagicShop\Core\Domain\CommerceModels.swift',
    'MagicShop\Core\Domain\ShopAccess.swift',
    'MagicShop\Core\Persistence\GameSession.swift',
    'MagicShopTests\CommerceTests.swift',
    'MagicShopTests\GameSessionTests.swift',
    'MagicShopTests\AppModelTests.swift',
    'MagicShop\Core\Domain\WorldCameraState.swift',
    'MagicShop\Core\Domain\WorldMap.swift',
    'MagicShop\Core\Persistence\GameStateStore.swift',
    'MagicShop\World\ShopScene.swift',
    'MagicShop\World\ShopSceneContainer.swift',
    'MagicShopTests\WorldMapTests.swift',
    'design\APPROVALS.md',
    'design\ASSET-INVENTORY.md',
    'design\approved\starter-shop-overview.png',
    'design\approved\first-slice-onboarding-name.png',
    'design\approved\first-slice-build-catalog-v3.png',
    'design\approved\first-slice-basic-table-placement-v2.png',
    'MagicShop\Resources\Assets.xcassets\StarterShopBackground.imageset\starter-shop-background.png',
    'MagicShop\Resources\Assets.xcassets\BasicDisplayTable.imageset\basic-display-table-1x1.png',
    'MagicShop\Resources\Assets.xcassets\SimpleShelf.imageset\simple-shelf.png',
    'scripts\build-sideloadly-ipa.sh'
)

foreach ($relativePath in $requiredFiles) {
    Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot $relativePath)) "Missing required file: $relativePath"
}

Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot '.git')) 'Git repository is required for GitHub CI and Codex Cloud handoff.'
Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot 'MagicShop\Resources\Assets.xcassets\StarterShopBackground.imageset')) 'Approved clean starter background must ship in Assets.xcassets.'

$package = Get-Content -LiteralPath (Join-Path $projectRoot 'Package.swift') -Raw
Assert-True ($package.Contains('path: "MagicShop/Core"')) 'Package.swift must compile only MagicShop/Core.'
Assert-True (-not $package.Contains('MagicShop/App')) 'Package.swift must not compile SwiftUI App sources.'
Assert-True (-not $package.Contains('MagicShop/World')) 'Package.swift must not compile SpriteKit World sources.'

$project = Get-Content -LiteralPath (Join-Path $projectRoot 'MagicShop.xcodeproj\project.pbxproj') -Raw
Assert-True ($project.Contains('IPHONEOS_DEPLOYMENT_TARGET = 16.0;')) 'iOS deployment target must be 16.0.'
Assert-True ($project.Contains('MARKETING_VERSION = 0.1.1;')) 'Marketing version must be 0.1.1.'
Assert-True ($project.Contains('CURRENT_PROJECT_VERSION = 1;')) 'Build number must be 1.'
Assert-True ($project.Contains('productType = "com.apple.product-type.application";')) 'App target is missing.'
Assert-True ($project.Contains('productType = "com.apple.product-type.bundle.unit-test";')) 'Unit-test target is missing.'

$workflow = Get-Content -LiteralPath (Join-Path $projectRoot '.github\workflows\ios-ci.yml') -Raw
Assert-True ($workflow.Contains('runs-on: macos-15')) 'iOS CI must use a macOS runner.'
Assert-True ($workflow.Contains('xcodebuild build')) 'iOS CI build step is missing.'
Assert-True ($workflow.Contains('xcodebuild test')) 'iOS CI XCTest step is missing.'
Assert-True ($workflow.Contains('CODE_SIGNING_ALLOWED=NO')) 'Simulator CI must remain unsigned.'
Assert-True ($workflow.Contains('actions/upload-artifact@v4')) 'CI build/test artifacts are not retained.'

$sideloadWorkflow = Get-Content -LiteralPath (Join-Path $projectRoot '.github\workflows\ios-sideloadly.yml') -Raw
Assert-True ($sideloadWorkflow.Contains('workflow_dispatch:')) 'Sideloadly IPA workflow must be manually dispatched.'
Assert-True (-not $sideloadWorkflow.Contains('pull_request:')) 'Sideloadly IPA workflow must not run on pull requests.'
Assert-True (-not $sideloadWorkflow.Contains('push:')) 'Sideloadly IPA workflow must not run on push.'
Assert-True ($sideloadWorkflow.Contains('runs-on: macos-15')) 'Sideloadly IPA workflow must use a macOS runner.'
Assert-True ($sideloadWorkflow.Contains('build-sideloadly-ipa.sh')) 'Sideloadly IPA workflow must use the reviewed build script.'
Assert-True ($sideloadWorkflow.Contains('MagicShop-0.1.1-build-1-unsigned.ipa')) 'Sideloadly IPA artifact name is missing.'
Assert-True ($sideloadWorkflow.Contains('actions/upload-artifact@v4')) 'Sideloadly IPA artifact is not retained.'

$sideloadScript = Get-Content -LiteralPath (Join-Path $projectRoot 'scripts\build-sideloadly-ipa.sh') -Raw
Assert-True ($sideloadScript.Contains('-sdk iphoneos')) 'Sideloadly build must target the physical iPhone SDK.'
Assert-True ($sideloadScript.Contains('-destination "generic/platform=iOS"')) 'Sideloadly build must target a generic iOS device.'
Assert-True ($sideloadScript.Contains('CODE_SIGNING_ALLOWED=NO')) 'Sideloadly build must remain unsigned in GitHub Actions.'
Assert-True ($sideloadScript.Contains('Payload/MagicShop.app')) 'Sideloadly IPA must contain Payload/MagicShop.app.'

$identifierMatches = [regex]::Matches($project, '\b[A-Za-z0-9]{24}\b(?=\s*(?:/\*|[,;]))')
foreach ($identifier in $identifierMatches.Value) {
    Assert-True ($identifier -match '^[A-F0-9]{24}$') "Invalid PBX object identifier: $identifier"
}
$definedIdentifiers = [regex]::Matches($project, '(?m)^\s*([A-F0-9]{24}) /\*.*?\*/ = \{') |
    ForEach-Object { $_.Groups[1].Value }
$duplicateIdentifiers = $definedIdentifiers | Group-Object | Where-Object Count -gt 1
Assert-True ($duplicateIdentifiers.Count -eq 0) 'Duplicate PBX object identifiers found.'

$allProjectSwift = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'MagicShop') -Filter '*.swift' -Recurse
$allTestSwift = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'MagicShopTests') -Filter '*.swift'
foreach ($file in @($allProjectSwift) + @($allTestSwift)) {
    Assert-True ($project.Contains("/* $($file.Name) */")) "Xcode project does not reference: $($file.Name)"
}

try {
    [xml](Get-Content -LiteralPath (Join-Path $projectRoot 'MagicShop.xcodeproj\xcshareddata\xcschemes\MagicShop.xcscheme') -Raw) | Out-Null
} catch {
    $failures.Add('MagicShop.xcscheme is not valid XML.')
}

foreach ($jsonFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'MagicShop\Resources\Assets.xcassets') -Filter 'Contents.json' -Recurse) {
    try {
        Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
    } catch {
        $failures.Add("Invalid asset catalog JSON: $($jsonFile.FullName)")
    }
}

$coreSwift = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'MagicShop\Core') -Filter '*.swift' -Recurse
foreach ($file in $coreSwift) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    Assert-True (-not ($content -match '(?m)^import (SwiftUI|SpriteKit|UIKit)$')) "Core imports an iOS UI framework: $($file.Name)"
}

$testCount = 0
foreach ($file in $allTestSwift) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $testCount += ([regex]::Matches($content, '(?m)^\s*func test[A-Za-z0-9_]+\s*\(')).Count
}
Assert-True ($testCount -ge 37) "Expected at least 37 unit tests, found $testCount."

$firstSliceUI = Get-Content -LiteralPath (Join-Path $projectRoot 'MagicShop\App\ProvisionalRootView.swift') -Raw
Assert-True ($firstSliceUI.Contains('TextField("My Shop"')) 'Approved onboarding name field is missing.'
Assert-True ($firstSliceUI.Contains('A Shop of Your Own')) 'Approved onboarding title is missing.'
Assert-True ($firstSliceUI.Contains('Open the Door')) 'Approved onboarding action is missing.'
Assert-True ($firstSliceUI.Contains('accessibilityIdentifier("shop-name-field")')) 'Shop name accessibility identifier is missing.'
Assert-True ($firstSliceUI.Contains('accessibilityIdentifier("confirm-placement")')) 'Placement accessibility identifier is missing.'
Assert-True ($firstSliceUI.Contains('isEnabled: false')) 'Stock/Open disabled state is missing.'

$catalog = Get-Content -LiteralPath (Join-Path $projectRoot 'MagicShop\Core\Domain\FixtureCatalog.swift') -Raw
Assert-True ($catalog -match 'basicDisplayTable[\s\S]*?price:\s*50,') 'Basic Display Table must cost $50.'
Assert-True ($catalog -match 'basicDisplayTable[\s\S]*?footprint:\s*GridFootprint\(width:\s*1,\s*depth:\s*1\)') 'Basic Display Table must use a 1x1 footprint.'

$worldMap = Get-Content -LiteralPath (Join-Path $projectRoot 'MagicShop\Core\Domain\WorldMap.swift') -Raw
Assert-True ($worldMap.Contains('struct FloorStyleID')) 'FloorStyleID is missing.'
Assert-True ($worldMap.Contains('struct FloorStyle')) 'FloorStyle is missing.'
Assert-True ($worldMap.Contains('struct ShopFloorState')) 'Persistent floor state is missing.'
Assert-True ($worldMap.Contains('struct WorldHitMap')) 'WorldHitMap is missing.'
Assert-True ($worldMap.Contains('dynamicOccupancy')) 'Dynamic fixture occupancy is missing.'
Assert-True ($worldMap.Contains('commonWallAdjacency')) 'Wall adjacency metadata is missing.'
Assert-True ($worldMap.Contains('CameraViewportTransform')) 'Testable screen/world transform is missing.'

$gameState = Get-Content -LiteralPath (Join-Path $projectRoot 'MagicShop\Core\Domain\GameState.swift') -Raw
Assert-True ($gameState.Contains('currentSchemaVersion = 3')) 'GameState schema must include commerce and world persistence.'
Assert-True ($gameState.Contains('public var world: ShopWorldState')) 'GameState must persist ShopWorldState.'

$shopScene = Get-Content -LiteralPath (Join-Path $projectRoot 'MagicShop\World\ShopScene.swift') -Raw
Assert-True ($shopScene.Contains('StarterShopBackground')) 'ShopScene must render the approved clean background directly.'
Assert-True (-not $shopScene.Contains('addPlacementGrid')) 'ShopScene must not draw a visible placement grid.'
Assert-True (-not ($shopScene -match 'RearPlasterPanel|WornTerracottaTile|FacadeEntranceBay|HangingLamp')) 'ShopScene must not assemble the modular environment.'

$implementationText = ($allProjectSwift | ForEach-Object {
    Get-Content -LiteralPath $_.FullName -Raw
}) -join [Environment]::NewLine
Assert-True (-not ($implementationText -match 'Basic Display Table[^\r\n]*\$100')) 'Legacy $100 Basic Display Table copy remains in implementation.'

$approvalHashes = @{
    'design\approved\starter-shop-overview.png' = 'F109DED9C96B1DDFD5B64039A86526AD7593ABC8F874C7385FD211FCE09F3006'
    'design\approved\first-slice-onboarding-name.png' = '3337E2D279E5D5CE74CB35F15A169E2EAF82D582AE2C079C201A2D334E9D857A'
    'design\approved\first-slice-build-catalog-v3.png' = '49E25DEA9F007151C559C450BDD0994ECBCE61D7683C658DF753433F1F42964E'
    'design\approved\first-slice-basic-table-placement-v2.png' = '032CC2C513E60643FFCC53903C2AE7F283FC858D43D118F88D646CC03BD991DB'
}
foreach ($entry in $approvalHashes.GetEnumerator()) {
    $path = Join-Path $projectRoot $entry.Key
    if (Test-Path -LiteralPath $path) {
        Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -eq $entry.Value) "Approved image hash changed: $($entry.Key)"
    }
}

$assetPairs = @(
    @('design\assets\first-slice\starter-shop-background.png', 'MagicShop\Resources\Assets.xcassets\StarterShopBackground.imageset\starter-shop-background.png'),
    @('design\assets\first-slice\basic-display-table-1x1.png', 'MagicShop\Resources\Assets.xcassets\BasicDisplayTable.imageset\basic-display-table-1x1.png'),
    @('design\assets\first-slice\simple-shelf.png', 'MagicShop\Resources\Assets.xcassets\SimpleShelf.imageset\simple-shelf.png'),
    @('design\assets\first-slice\modular\floor\terracotta-tile-base.png', 'MagicShop\Resources\Assets.xcassets\WornTerracottaTile.imageset\terracotta-tile-base.png'),
    @('design\assets\first-slice\modular\floor\terracotta-tile-variant-a.png', 'MagicShop\Resources\Assets.xcassets\WornTerracottaVariantA.imageset\terracotta-tile-variant-a.png'),
    @('design\assets\first-slice\modular\floor\terracotta-tile-variant-b.png', 'MagicShop\Resources\Assets.xcassets\WornTerracottaVariantB.imageset\terracotta-tile-variant-b.png'),
    @('design\assets\first-slice\modular\floor\terracotta-crack-decal.png', 'MagicShop\Resources\Assets.xcassets\TerracottaCrackDecal.imageset\terracotta-crack-decal.png'),
    @('design\assets\first-slice\modular\floor\terracotta-stain-decal.png', 'MagicShop\Resources\Assets.xcassets\TerracottaStainDecal.imageset\terracotta-stain-decal.png'),
    @('design\assets\first-slice\modular\walls\rear-plaster-panel.png', 'MagicShop\Resources\Assets.xcassets\RearPlasterPanel.imageset\rear-plaster-panel.png'),
    @('design\assets\first-slice\modular\walls\side-wall-left.png', 'MagicShop\Resources\Assets.xcassets\SideWallLeft.imageset\side-wall-left.png'),
    @('design\assets\first-slice\modular\walls\side-wall-right.png', 'MagicShop\Resources\Assets.xcassets\SideWallRight.imageset\side-wall-right.png'),
    @('design\assets\first-slice\modular\walls\teal-baseboard-rear.png', 'MagicShop\Resources\Assets.xcassets\TealBaseboardRear.imageset\teal-baseboard-rear.png'),
    @('design\assets\first-slice\modular\walls\cutaway-cap-left.png', 'MagicShop\Resources\Assets.xcassets\CutawayCapLeft.imageset\cutaway-cap-left.png'),
    @('design\assets\first-slice\modular\walls\cutaway-cap-rear.png', 'MagicShop\Resources\Assets.xcassets\CutawayCapRear.imageset\cutaway-cap-rear.png'),
    @('design\assets\first-slice\modular\walls\cutaway-cap-right.png', 'MagicShop\Resources\Assets.xcassets\CutawayCapRight.imageset\cutaway-cap-right.png'),
    @('design\assets\first-slice\modular\facade\window-bay.png', 'MagicShop\Resources\Assets.xcassets\FacadeWindowBay.imageset\window-bay.png'),
    @('design\assets\first-slice\modular\facade\entrance-bay.png', 'MagicShop\Resources\Assets.xcassets\FacadeEntranceBay.imageset\entrance-bay.png'),
    @('design\assets\first-slice\modular\facade\corner-post.png', 'MagicShop\Resources\Assets.xcassets\FacadeCornerPost.imageset\corner-post.png'),
    @('design\assets\first-slice\modular\props\debris-papers.png', 'MagicShop\Resources\Assets.xcassets\DebrisPapers.imageset\debris-papers.png'),
    @('design\assets\first-slice\modular\props\debris-plaster.png', 'MagicShop\Resources\Assets.xcassets\DebrisPlaster.imageset\debris-plaster.png'),
    @('design\assets\first-slice\modular\props\debris-wood-slats.png', 'MagicShop\Resources\Assets.xcassets\DebrisWoodSlats.imageset\debris-wood-slats.png'),
    @('design\assets\first-slice\modular\props\hanging-lamp.png', 'MagicShop\Resources\Assets.xcassets\HangingLamp.imageset\hanging-lamp.png')
)
foreach ($pair in $assetPairs) {
    $source = Join-Path $projectRoot $pair[0]
    $runtime = Join-Path $projectRoot $pair[1]
    Assert-True (Test-Path -LiteralPath $source) "Missing source asset: $($pair[0])"
    Assert-True (Test-Path -LiteralPath $runtime) "Missing runtime asset: $($pair[1])"
    if ((Test-Path -LiteralPath $source) -and (Test-Path -LiteralPath $runtime)) {
        Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $runtime).Hash) "Runtime asset differs from inventory source: $($pair[1])"
    }
}

function Get-PngHeaderInfo {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 26 -or
        $bytes[0] -ne 137 -or $bytes[1] -ne 80 -or $bytes[2] -ne 78 -or $bytes[3] -ne 71) {
        return $null
    }
    [pscustomobject]@{
        Width = ([int]$bytes[16] -shl 24) -bor ([int]$bytes[17] -shl 16) -bor ([int]$bytes[18] -shl 8) -bor [int]$bytes[19]
        Height = ([int]$bytes[20] -shl 24) -bor ([int]$bytes[21] -shl 16) -bor ([int]$bytes[22] -shl 8) -bor [int]$bytes[23]
        ColorType = [int]$bytes[25]
    }
}

function Test-PngHasTransparentPixels {
    param([string]$Path)
    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::new($Path)
    try {
        $rectangle = [System.Drawing.Rectangle]::new(0, 0, $bitmap.Width, $bitmap.Height)
        $format = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        $data = $bitmap.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, $format)
        try {
            $length = [Math]::Abs($data.Stride) * $bitmap.Height
            $pixels = [byte[]]::new($length)
            [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $pixels, 0, $length)
            for ($index = 3; $index -lt $pixels.Length; $index += 4) {
                if ($pixels[$index] -lt 255) { return $true }
            }
            return $false
        } finally {
            $bitmap.UnlockBits($data)
        }
    } finally {
        $bitmap.Dispose()
    }
}

$pinnedAssetSpecifications = @(
    @{ Path = 'design\assets\first-slice\starter-shop-background.png'; Hash = 'CBB8A68B876CF8B1EBF9D0FD64A3672195594B6271BD9DA342FC29A7DDF073B3'; Width = 853; Height = 1844; ColorType = 2 },
    @{ Path = 'design\assets\first-slice\basic-display-table-1x1.png'; Hash = 'E840C4B750D915F6F197F7759DFDE579AA20B7978D7E75CF247BF618FF796B0A'; Width = 802; Height = 849; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\simple-shelf.png'; Hash = 'B232233FA16FF816B9C0C1AB3C9F0CAC91B65A4F61D6BDF9659E108516384D0E'; Width = 762; Height = 1036; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\floor\terracotta-tile-base.png'; Hash = 'CF0B041D3620395A8CAD82B87D85D5FAC84E3777C9484B543217795615158FF7'; Width = 256; Height = 256; ColorType = 2 },
    @{ Path = 'design\assets\first-slice\modular\floor\terracotta-tile-variant-a.png'; Hash = '21406E40C72BADD65B51D18EA027AF1B09AAE56730EBCABCC0148EBC7A40B6B7'; Width = 256; Height = 256; ColorType = 2 },
    @{ Path = 'design\assets\first-slice\modular\floor\terracotta-tile-variant-b.png'; Hash = 'B5C61FA14D053C3D0470D1B03F0E9B804251FCACC7034AD3281FDEA91818D45A'; Width = 256; Height = 256; ColorType = 2 },
    @{ Path = 'design\assets\first-slice\modular\floor\terracotta-crack-decal.png'; Hash = 'F724B579EFD6B0AABFC659333747111FA1FDADA09841FABA37480B069088CB2C'; Width = 193; Height = 256; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\floor\terracotta-stain-decal.png'; Hash = '91D1205C5F5037EEC04EBDDDB74C0806455625C475DDBAF984BDF2F57516B329'; Width = 256; Height = 229; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\walls\rear-plaster-panel.png'; Hash = 'DB178BD2ADD004862E70AA281D5D97A05F229B4613D55950B275601BB8500E0F'; Width = 256; Height = 512; ColorType = 2 },
    @{ Path = 'design\assets\first-slice\modular\walls\side-wall-left.png'; Hash = '21E4B2FF5D8ECF1FE44363585564A9AF68A9BEFD253175C31F7AACEF04BE8379'; Width = 231; Height = 1024; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\walls\side-wall-right.png'; Hash = '703995B557088E1F32B0A92030844704830080772E34A754BBA7958720E9685F'; Width = 249; Height = 1024; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\walls\teal-baseboard-rear.png'; Hash = '89388815F4B5862F99B6AA1B0272B097A5473251BCC8B650A2FEC3E8F7736B4E'; Width = 1024; Height = 277; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\walls\cutaway-cap-left.png'; Hash = '5F1111656CC765B7132AFADCC40A480FE7155D70FBCD6B3456CB6CF6B5634DB0'; Width = 716; Height = 939; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\walls\cutaway-cap-rear.png'; Hash = 'EE154E9AF2BEEA40990072F7280E8178B721BFCB413CC3D2E675256CE675AD66'; Width = 1024; Height = 137; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\walls\cutaway-cap-right.png'; Hash = 'A855F29C40C3C20773B12407D840EB71AA8E76EA18CAB8D983510FBAF2E7BF5E'; Width = 580; Height = 1024; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\facade\window-bay.png'; Hash = '64F05114D6F5EDA0EE747278B02A9F6496C52E6354589DD499DDE54C74886DF5'; Width = 1024; Height = 843; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\facade\entrance-bay.png'; Hash = '61F856112B75205699F14F5481480BCBCEE0D79E631E2664C09F8E507FF78F0B'; Width = 705; Height = 959; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\facade\corner-post.png'; Hash = '6809ED14BFAD17A8DC609B4C945D236F0CC332DC857168D184AEE4F6583CF3B3'; Width = 207; Height = 1024; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\props\debris-papers.png'; Hash = 'D3FB0C60F804B6A4298C19AEBD53F4D3C4A78DC4FE602BD2C7697E6177EF5BC3'; Width = 466; Height = 512; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\props\debris-plaster.png'; Hash = 'B7E6A143D3B32D264565813E28235922A2FB7540846C94B585EDE5F02DD878C1'; Width = 512; Height = 412; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\props\debris-wood-slats.png'; Hash = '2AA7EC29501AAC715C7B61C2545F4E52681F81AB0909B21A4D464FC040FAE934'; Width = 512; Height = 310; ColorType = 6 },
    @{ Path = 'design\assets\first-slice\modular\props\hanging-lamp.png'; Hash = 'A054019A9534A12111A4CEE97D76A42E77E3C96FB1F1AF42864040894E11E48E'; Width = 374; Height = 768; ColorType = 6 }
)

foreach ($specification in $pinnedAssetSpecifications) {
    $path = Join-Path $projectRoot $specification.Path
    if (-not (Test-Path -LiteralPath $path)) { continue }
    Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -eq $specification.Hash) "Pinned asset hash changed: $($specification.Path)"
    $png = Get-PngHeaderInfo -Path $path
    Assert-True ($null -ne $png) "Invalid PNG header: $($specification.Path)"
    if ($null -ne $png) {
        Assert-True ($png.Width -eq $specification.Width -and $png.Height -eq $specification.Height) "Pinned asset dimensions changed: $($specification.Path)"
        Assert-True ($png.ColorType -eq $specification.ColorType) "Pinned asset color type changed: $($specification.Path)"
        if ($specification.ColorType -eq 6) {
            Assert-True (Test-PngHasTransparentPixels -Path $path) "RGBA asset has no transparent pixels: $($specification.Path)"
        }
    }
}

$modularSourceCount = (Get-ChildItem -LiteralPath (Join-Path $projectRoot 'design\assets\first-slice\modular') -Filter '*.png' -File -Recurse).Count
Assert-True ($modularSourceCount -eq 19) "Expected 19 modular source PNGs, found $modularSourceCount."

if ($failures.Count -gt 0) {
    Write-Output 'STATIC VERIFICATION: FAIL'
    foreach ($failure in $failures) { Write-Output "- $failure" }
    exit 1
}

Write-Output 'STATIC VERIFICATION: PASS'
Write-Output "- Required files: $($requiredFiles.Count)"
Write-Output "- Core Swift files: $($coreSwift.Count)"
Write-Output "- XCTest methods declared: $testCount"
Write-Output '- Package.swift excludes SwiftUI/SpriteKit sources'
Write-Output '- iOS 16.0, version 0.1.1, build 1'
Write-Output '- Git repository and unsigned macOS iOS CI workflow verified'
Write-Output '- Manual unsigned iphoneos IPA workflow for Sideloadly verified'
Write-Output '- Four current approval hashes verified'
Write-Output '- Approved clean background, 19 preserved modular assets and two furniture assets match pinned hashes and runtime copies'
Write-Output '- Runtime scene uses the clean background directly without a visible grid or modular assembly'
Write-Output '- Persistent floor/hitmap structures and declared test coverage verified statically; XCTest execution still requires macOS/Xcode'
Write-Output '- Basic Display Table is $50 with a 1x1 footprint'
