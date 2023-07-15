import SwiftUI
import WebKit
import MultiSettings

import os

@main
struct Runtime: App {
    @Environment(\.openWindow)
    var openWindow

    let once = Once()

    let config: Config = {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(Config.self, from: data),
              !config.tabs.isEmpty else {
            return Config(tabs: [Config.Tab(
                title: "",
                url: URL(string: "data:text/html;charset=utf-8,%3C%21DOCTYPE%20html%3E%0D%0ACannot%20open%20%3Ccode%3Econfig.json%3C%2Fcode%3E")!
            )])
        }
        return config
    }()

    var body: some Scene {
        WindowGroup(for: Int.self) { $index in
            TabView(config: config, index: index) { window in
                once {
                    for i in config.tabs.indices {
                        openWindow(value: i)
                    }
                    window.makeKeyAndOrderFront(nil)
                }
                if config.alwaysOnTop {
                    window.level = .floating
                }
                if !config.windowed {
                    NSApp.keyWindow?.tabGroup?.addWindow(window)
                }
                window.isExcludedFromWindowsMenu = true
            }
        } defaultValue: {
            0
        }
            .commands {
                CommandGroup(replacing: .newItem) {}
                CommandGroup(after: .singleWindowList) {
                    ForEach(0 ..< min(config.tabs.count, 9), id: \.self) { index in
                        Button(config.tabs[index].title) {
                            openWindow(value: index)
                        }
                            .keyboardShortcut(KeyEquivalent((index+1).description.first!))
                    }
                }
                CommandGroup(after: .sidebar) {
                    Button("Reload Page", #selector(WKWebView.reload(_:)))
                        .keyboardShortcut("R")
                    Button("Actual Size", #selector(WKWebView.actualSize(_:)))
                        .keyboardShortcut("0")
                    Button("Zoom In", #selector(WKWebView.zoomIn(_:)))
                        .keyboardShortcut("+")
                    Button("Zoom Out", #selector(WKWebView.zoomOut(_:)))
                        .keyboardShortcut("-")
                }
                CommandMenu("History") {
                    Button("Back", #selector(WKWebView.goBack(_:)))
                        .keyboardShortcut("[")
                    Button("Forward", #selector(WKWebView.goForward(_:)))
                        .keyboardShortcut("]")
                }
            }
        Settings {
            SettingsView(newApp: false)
        }
    }
}
