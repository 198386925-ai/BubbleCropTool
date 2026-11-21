# 折角-You — 微信聊天气泡裁剪工具

iOS App（SwiftUI），照截图里的「折角-You」工具做的：上传气泡图，三左三右实时预览，裁剪四边（九宫格），一键自动算裁剪值，改完自动保存。

## 功能

- **实时预览**：聊天底上的三左三右气泡排版（左三个、右三个，错开，间距已缩到最紧）。左边用左尾巴图（左上宽、左单、左下短），右边用右尾巴图（右单短、右上中、右下宽）。日间 / 夜间切换（浅色泡 / 深色泡 + 聊天底跟着变）。
- **上传气泡**：从相册导入自己的气泡图，替换到指定位置，预览立刻跟着变。导入的图存到 Documents，下次打开还在。
- **气泡裁剪**：四个数——上、左（尾巴那侧）、下、右，九宫格拉伸，角和尾巴不变形，只拉中间。0 = 这一边自动识别。改数字预览实时跟着变。
- **一键自动**：用「左单」日间图算一遍，填进四个数。左单（171×120）算出来是上 9、左 17、下 11、右 12。
- **四边全部改回自动**：四个数全改回 0。
- **顶栏**：返回「商品」、标题「折角-You」、已自动保存、撤销 / 重做。

## 工程结构

```
BubbleCropTool.xcodeproj/        Xcode 工程
BubbleCropTool/
  BubbleCropToolApp.swift        App 入口
  Info.plist                     Bundle id / 相册权限说明
  LaunchScreen.storyboard        启动屏
  Assets.xcassets/               AppIcon
  Bubbles/                       内置 12 张气泡图（6 浅 + 6 深，171×120）
    浅 左上.PNG / 浅 左中:单.PNG / 浅 左下.PNG
    浅 右上.PNG / 浅 右中:单.PNG / 浅 右下.PNG
    深 左上.PNG / 深 左中:单.PNG / 深 左下.PNG
    深 右上.PNG / 深 右中:单.PNG / 深 右下.PNG
  Models/
    Bubble.swift                 气泡位置（6 个槽位 + 排版坐标 + 示例文字）
    CropInsets.swift             裁剪值模型（上/左/下/右，0 = 自动）
    BubbleStore.swift            状态管理（气泡、裁剪值、日夜、撤销重做、自动保存、导入）
  Logic/
    AutoCrop.swift               一键自动：读 alpha 通道算四个边的裁剪值
  Views/
    ContentView.swift            主界面（顶栏 + 预览卡片 + 裁剪入口）
    ChatPreviewView.swift        三左三右实时预览 + 日间夜间切换
    NinePatchImage.swift         九宫格渲染（UIImage.resizableImage + capInsets）
    CropPanelView.swift          裁剪底部弹窗（四个数 + 一键自动 + 导入）
```

## 关键实现

- **九宫格渲染**：`NinePatchImage` 用 `UIViewRepresentable` 包 `UIImageView`，图走 `image.resizableImage(withCapInsets:resizingMode: .stretch)`，这是 iOS 标准的九宫格等价物。capInsets 按裁剪值来，0 的边先按自动值补齐。
- **一键自动**（`AutoCrop.analyze`）：读图的 alpha 通道找内容框（alpha > 10），再按标定公式算四个数：上 = 内容顶 + 6，下 = 底部留白 + 1，左 = 内容左 + 1，右 = 右边留白 - 1。左单实测内容框 x 16–158、y 3–110，算出来正好是上 9、左 17、下 11、右 12。
- **预览排版**：6 个气泡的位置是 1080×1080 画布上的归一化坐标（用户定的三左三右排版，间距缩过两次，列内约 13–15px），按预览区大小等比缩放。
- **自动保存**：裁剪值改完 0.3 秒后写 UserDefaults，顶栏显示「已自动保存」。

## 构建

- Bundle id：`com.youyou.zhejiao`
- 部署目标：iOS 16.0，Swift 5，无第三方依赖。

本机（macOS + Xcode）构建：

```bash
xcodebuild -project BubbleCropTool.xcodeproj \
  -scheme BubbleCropTool \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  build
```

打 IPA（GitHub Actions macOS runner 上跑，参考 LUIYo 的 workflow）：

```bash
xcodebuild -project BubbleCropTool.xcodeproj \
  -scheme BubbleCropTool \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  archive -archivePath build/BubbleCropTool.xcarchive
xcodebuild -exportArchive \
  -archivePath build/BubbleCropTool.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa
```

> 注意：本机是 Linux，没有 Xcode，IPA 得在 macOS runner 上打。工程本身是标准 Xcode 工程，直接 `xcodebuild` 就能编。

## 版本

- 1.0.0（Build 1）：首版，实时预览 + 裁剪四边 + 一键自动 + 导入 + 日夜切换。
