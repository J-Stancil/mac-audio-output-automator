import SwiftUI
import Cocoa

@main
struct MenuBarAudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuController: MenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuController = MenuController()
    }
}
