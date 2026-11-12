# ZHHCarouselView

纯 Swift 轮播视图，支持无限循环、自动滚动，以及普通 / 线性缩放 / 封面流布局，并附带 `ZHHPageControl` 分页指示器。

要求 iOS 15.0+，Swift 5.5+。

## 特性

- 无限循环与自动滚动（`isInfiniteLoop` / `autoScrollInterval`）
- 三种布局：`normal` / `linear` / `coverflow`
- 可配置 `itemSize`、`itemSpacing`、首尾水平居中等
- DataSource / Delegate 驱动 Cell 与页切换回调
- 页间连续滚动进度（`fromIndex` / `toIndex` / `progress`），适合颜色插值等过渡
- 配套 `ZHHPageControl`：圆点 / 胶囊指示器，可调尺寸与颜色

## 示例

```bash
cd Example
pod install
open ZHHCarouselView.xcworkspace
```

Example 为 SceneDelegate + MVVM 纯代码 Demo，可调节无限循环、自动播放、布局样式与卡片尺寸。

## 安装

### CocoaPods

```ruby
pod 'ZHHCarouselView'
```

本地开发：

```ruby
pod 'ZHHCarouselView', :path => '../'
```

也可直接依赖 git 标签：

```ruby
pod 'ZHHCarouselView', :git => 'https://github.com/yue5yueliang/ZHHCarouselView.git', :tag => '1.1.0'
```

### Swift Package Manager

仓库已提供 `Package.swift`，产品名是 `ZHHCarouselView`。打好语义化 tag 后即可被 SPM 解析，无需额外上传。

本地用 Xcode 查看包时，请打开根目录的 `Package.swift`（不要打开仓库文件夹，以免进到 CocoaPods 工程）。Demo 请始终通过 `Example/ZHHCarouselView.xcworkspace` 打开。

**Xcode**

1. File → Add Package Dependencies…
2. 填入：`https://github.com/yue5yueliang/ZHHCarouselView.git`
3. 规则选 Up to Next Major（或 Exact `1.1.0`）
4. 把产品 `ZHHCarouselView` 加到目标

**Package.swift**

```swift
dependencies: [
    .package(url: "https://github.com/yue5yueliang/ZHHCarouselView.git", from: "1.1.0")
]
```

在 target 里引用：

```swift
.product(name: "ZHHCarouselView", package: "ZHHCarouselView")
```

## 最小示例

```swift
import UIKit
import ZHHCarouselView

let pagerView = ZHHCarouselView()
pagerView.isInfiniteLoop = true
pagerView.autoScrollInterval = 3
pagerView.dataSource = self
pagerView.delegate = self
pagerView.register(MyCell.self, forCellWithReuseIdentifier: "cell")
pagerView.reloadData()
```

实现数据源与代理：

```swift
extension ViewController: ZHHCarouselViewDataSource {
    func numberOfItems(in pagerView: ZHHCarouselView) -> Int {
        items.count
    }

    func pagerView(_ pagerView: ZHHCarouselView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", for: index) as! MyCell
        cell.configure(with: items[index])
        return cell
    }

    func layout(for pagerView: ZHHCarouselView) -> ZHHCarouselPagerLayout {
        let layout = ZHHCarouselPagerLayout()
        layout.itemSize = CGSize(width: pagerView.bounds.width * 0.8, height: pagerView.bounds.height * 0.8)
        layout.itemSpacing = 15
        layout.layoutType = .linear
        layout.itemHorizontalCenter = true
        return layout
    }
}

extension ViewController: ZHHCarouselViewDelegate {
    func pagerView(_ pagerView: ZHHCarouselView, didScrollFromIndex fromIndex: Int, toIndex: Int) {
        // 离散翻页完成时再更新指示点
        pageControl.currentPage = toIndex
    }

    func pagerView(_ pagerView: ZHHCarouselView, didUpdateScrollProgress progress: CGFloat, fromIndex: Int, toIndex: Int) {
        // 拖拽 / 减速 / 自动翻页过程中持续回调；可直接做颜色插值
        // ambientColor = mix(colors[fromIndex], colors[toIndex], progress)
        _ = pagerView.scrollProgress
    }
}
```

分页指示器可叠在轮播视图上：

```swift
let pageControl = ZHHPageControl()
pageControl.numberOfPages = items.count
pageControl.pageIndicatorSize = CGSize(width: 6, height: 6)
pageControl.currentPageIndicatorSize = CGSize(width: 16, height: 6)
pageControl.currentPageIndicatorTintColor = .systemBlue
pagerView.addSubview(pageControl)
```

## Author

桃色三岁, 136769890@qq.com

## License

ZHHCarouselView is available under the MIT license. See the LICENSE file for more info.
