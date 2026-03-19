import SwiftUI
import Cocoa
import CoreAudio

@main
struct AudioSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!

    // Match strings for your devices (as seen in macOS Sound Output list)
    private let apolloMatch = "Universal Audio Thunderbolt"
    private let samsungMatch = "SAMSUNG"

    private let apolloIcon = "🔥🔥🔥"
    private let samsungIcon = "🛜📺🛜"

    func applicationDidFinishLaunching(_ notification: Notification) {

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = apolloIcon // temporary default; we sync immediately below

        let menu = NSMenu()

        let apolloItem = NSMenuItem(title: "Apollo", action: #selector(switchToApollo), keyEquivalent: "")
        apolloItem.target = self
        menu.addItem(apolloItem)

        let samsungItem = NSMenuItem(title: "SAMSUNG", action: #selector(switchToSamsung), keyEquivalent: "")
        samsungItem.target = self
        menu.addItem(samsungItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        // Sync icon to current output at launch
        updateStatusIconForCurrentOutput()
    }

    @objc func switchToApollo() {
        guard let deviceID = findOutputDevice(containing: apolloMatch) else {
            print("Apollo not found: \(apolloMatch)")
            return
        }

        if setDefaultOutputDevice(deviceID) {
            statusItem.button?.title = apolloIcon
            print("Switched to Apollo")
        } else {
            print("Failed to switch to Apollo")
        }
    }

    @objc func switchToSamsung() {
        guard let deviceID = findOutputDevice(containing: samsungMatch) else {
            print("SAMSUNG not found: \(samsungMatch)")
            return
        }

        if setDefaultOutputDevice(deviceID) {
            statusItem.button?.title = samsungIcon
            print("Switched to SAMSUNG")
        } else {
            print("Failed to switch to SAMSUNG")
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Startup Icon Sync

    func updateStatusIconForCurrentOutput() {
        guard let currentID = getCurrentDefaultOutputDeviceID(),
              let name = getDeviceName(currentID) else {
            return
        }

        if name.contains(apolloMatch) {
            statusItem.button?.title = apolloIcon
        } else if name.contains(samsungMatch) {
            statusItem.button?.title = samsungIcon
        }
    }

    // MARK: - CoreAudio Helpers

    func getCurrentDefaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout.size(ofValue: deviceID))

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceID
        )

        return (status == noErr) ? deviceID : nil
    }

    func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceName: CFString?
        var nameSize = UInt32(MemoryLayout<CFString?>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &nameSize,
            &deviceName
        )

        if status == noErr, let deviceName {
            return deviceName as String
        }
        return nil
    }

    func findOutputDevice(containing substring: String) -> AudioDeviceID? {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let statusSize = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        )
        guard statusSize == noErr else { return nil }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(0), count: deviceCount)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        guard status == noErr else { return nil }

        for deviceID in deviceIDs {
            if !isOutputDevice(deviceID) { continue }
            if let name = getDeviceName(deviceID), name.contains(substring) {
                return deviceID
            }
        }

        return nil
    }

    func setDefaultOutputDevice(_ deviceID: AudioDeviceID) -> Bool {

        var id = deviceID

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout.size(ofValue: id)),
            &id
        )

        return status == noErr
    }

    func isOutputDevice(_ deviceID: AudioDeviceID) -> Bool {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        guard status == noErr else { return false }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }

        status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, bufferList)
        guard status == noErr else { return false }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        var totalChannels: UInt32 = 0
        for buffer in buffers { totalChannels += buffer.mNumberChannels }

        return totalChannels > 0
    }
}
