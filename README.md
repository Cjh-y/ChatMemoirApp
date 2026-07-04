# ChatMemoir

**把值得珍藏的聊天，做成一本真正属于你的书。**

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)](https://github.com/Cjh-y/ChatMemoirApp)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

---

## 这是什么

ChatMemoir 是一个 iOS App，它将聊天记录变成一本可以翻页阅读的数字回忆录。

不是数据分析工具。不是 AI 聊天总结。**是一本书。**

## 当前版本 v0.1

| 特性 | 状态 |
|------|------|
| Apple Books 风格欢迎页 | ✅ |
| 3 组示例故事（Alice / Bob / 家） | ✅ |
| 生成动画（动态文案） | ✅ |
| 页面卷曲翻页（`.pageCurl` + `.mid` spine） | ✅ |
| 深色模式 | ✅ |
| 封面 / 正文页 / 结尾页 | ✅ |

## 架构

```
ChatMemoirApp          ← 这个仓库（iOS App）
    ↓ 依赖
ChatMemoir             ← 核心管线（TimelineEngine → StoryEngine → PresentationEngine）
    ↓ 依赖
ChatImportKit          ← 聊天导入框架（平台无关数据模型）
```

## 依赖

- [ChatMemoir](https://github.com/Cjh-y/ChatMemoir) — 核心管线
- [ChatImportKit](https://github.com/Cjh-y/ChatImportKit) — 数据模型

## 快速开始

```bash
# 克隆所有仓库
git clone https://github.com/Cjh-y/ChatImportKit.git
git clone https://github.com/Cjh-y/ChatMemoir.git
git clone https://github.com/Cjh-y/ChatMemoirApp.git

# 打开 Xcode
open ChatMemoirApp/Package.swift
```

## License

MIT
