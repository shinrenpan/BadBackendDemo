# BadBackendDemo

**Swift 網路層生存指南** 系列文章的完整可執行 Demo。

展示如何用 `SafeBox`、`SafeArray`、`ShieldedResponse`、`BaseResponse` 打造一套對抗糟糕後端的防禦性網路層架構。

## 系列文章

| 篇 | 主題 | 連結 |
|---|---|---|
| (1) | SafeBox / SafeArray：欄位層防禦 | [Swift 網路層生存指南 (1)](http://shinrenpan.github.io/posts/2026-01-01/) |
| (2) | BaseResponseProtocol + ShieldedResponse：外殼層防禦 | [Swift 網路層生存指南 (2)](http://shinrenpan.github.io/posts/2026-01-10/) |
| (3) | BaseResponse + decodePath：完整串接 | [Swift 網路層生存指南 (3)](http://shinrenpan.github.io/posts/2026-02-06/) |

## 執行方式

需要 macOS 13+ 與 Swift 5.9+（隨 Xcode 15 附帶）。

```bash
git clone https://github.com/shinrenpan/BadBackendDemo.git
cd BadBackendDemo
swift run
```

## Demo 內容

| Scene | 展示內容 |
|---|---|
| Scene 1 | `SafeBox`：null、型別錯置、欄位缺失、Bool 創意解析 |
| Scene 2 | `SafeArray`：陣列損毀元素修復、欄位缺失補空陣列 |
| Scene 3 | `ShieldedResponse` + `decodePath`：直球對決 / 單層 / 多層路徑導航 |
| Scene 4 | `BaseResponse`：HTTP 200 成功、401/500 快速熔斷 |

## 專案結構

```
Sources/BadBackendDemo/
├── Core/
│   ├── DemoLog.swift          # print 取代 OSLog（讓輸出顯示在終端機）
│   ├── SafeDecoding.swift     # SafeBox / SafeArray / DomainConvertible
│   ├── ShieldedResponse.swift # BaseResponseProtocol / ShieldedResponse
│   └── BaseResponse.swift     # APIError / BaseResponse
└── Scenes/
    ├── Scene1_SafeBox.swift
    ├── Scene2_SafeArray.swift
    ├── Scene3_Navigation.swift
    ├── Scene4_Fuse.swift
    └── main.swift
```
