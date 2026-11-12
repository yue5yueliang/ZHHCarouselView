# Changelog

## 1.1.0

- 新增页间连续滚动进度：`ZHHCarouselScrollProgress` 与 `scrollProgress` 只读属性
- 新增代理 `pagerView(_:didUpdateScrollProgress:fromIndex:toIndex:)`（默认空实现，旧业务零改动升级）
- 进度在 `scrollViewDidScroll` 中更新，覆盖拖拽、减速、自动翻页与 `scrollToItem` 动画
- 语义：`fromIndex` 为当前锚定页，`toIndex` 为滑动方向相邻页，`progress` 为 0...1；静止时 from == to、progress == 0

## 1.0.1

- 公开 `ZHHPageControl.setCurrentPage(_:animated:)`，修复跨模块不可访问
- PageControl / Layout 源码按 extension 分组并补齐中文注释

## 1.0.0

- 首次发布：无限循环、自动滚动、普通 / 线性 / 封面流布局与 PageControl
- 提供 CocoaPods 与 Swift Package Manager 安装方式
