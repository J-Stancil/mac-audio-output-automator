import Cocoa
import CoreAudio

class MenuController: NSObject {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = NSMenu()
    let audioController = AudioController()
    private var listenerBlock: AudioObjectPropertyListenerBlock?

    private var outputDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    override init() {
        super.init()
        setupMenu()
        setupOutputDeviceListener()
        updateStatusIcon()
    }

    deinit {
        if let block = listenerBlock {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &outputDeviceAddress,
                DispatchQueue.main,
                block
            )
        }
    }

    func setupMenu() {
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

    func setupOutputDeviceListener() {
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.updateStatusIcon()
        }
        listenerBlock = block
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &outputDeviceAddress,
            DispatchQueue.main,
            block
        )
    }

    @objc func switchToApollo() {
        audioController.switchToApollo()
        updateStatusIcon()
    }

    @objc func switchToSamsung() {
        audioController.switchToSamsung()
        updateStatusIcon()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func updateStatusIcon() {
        guard let currentName = audioController.currentOutputDeviceName() else {
            statusItem.button?.title = "?"
            return
        }

        if currentName.contains(AppConfig.apolloMatch) {
            statusItem.button?.title = AppConfig.apolloLabel
        } else if currentName.contains(AppConfig.samsungMatch) {
            statusItem.button?.title = AppConfig.samsungLabel
        } else {
            statusItem.button?.title = currentName
        }
    }
}
