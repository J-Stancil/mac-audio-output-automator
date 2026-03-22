import Foundation
import CoreAudio

class AudioController {

    func switchToApollo() {
        switchDevice(containing: AppConfig.apolloMatch)
    }

    func switchToSamsung() {
        switchDevice(containing: AppConfig.samsungMatch)
    }

    private func switchDevice(containing nameFragment: String) {

        guard let deviceID = findOutputDevice(containing: nameFragment) else {
            print("Device not found: \(nameFragment)")
            return
        }

        _ = setDefaultOutputDevice(deviceID)
    }

    private func findOutputDevice(containing substring: String) -> AudioDeviceID? {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(0), count: deviceCount)

        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs)

        for deviceID in deviceIDs {

            if let name = getDeviceName(deviceID),
               name.contains(substring),
               isOutputDevice(deviceID) {
                return deviceID
            }
        }

        return nil
    }

    private func getDeviceName(_ deviceID: AudioDeviceID) -> String? {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceName: CFString?
        var nameSize = UInt32(MemoryLayout<CFString?>.size)

        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &nameSize, &deviceName)

        if status == noErr, let deviceName {
            return deviceName as String
        }

        return nil
    }

    private func setDefaultOutputDevice(_ deviceID: AudioDeviceID) -> Bool {

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

    private func isOutputDevice(_ deviceID: AudioDeviceID) -> Bool {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }

        AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, bufferList)

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        var totalChannels: UInt32 = 0

        for buffer in buffers {
            totalChannels += buffer.mNumberChannels
        }

        return totalChannels > 0
    }
}
