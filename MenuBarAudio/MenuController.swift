import Cocoa

class MenuController: NSObject {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = NSMenu()
    let audioController = AudioController()

    override init() {
        super.init()
        setupMenu()
        updateStatusIcon()
    }

    func setupMenu() {
        statusItem.button?.title = AppConfig.apolloLabel

        let apolloItem = NSMenuItem(title: AppConfig.apolloLabel, action: #selector(switchToApollo), keyEquivalent: "")
        apolloItem.target = self
        menu.addItem(apolloItem)

        let samsungItem = NSMenuItem(title: AppConfig.samsungLabel, action: #selector(switchToSamsung), keyEquivalent: "")
        samsungItem.target = self
        menu.addItem(samsungItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func switchToApollo() {
        audioController.switchToApollo()
        statusItem.button?.title = AppConfig.apolloLabel
    }

    @objc func switchToSamsung() {
        audioController.switchToSamsung()
        statusItem.button?.title = AppConfig.samsungLabel
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func updateStatusIcon() {
        statusItem.button?.title = AppConfig.apolloLabel
    }
}
