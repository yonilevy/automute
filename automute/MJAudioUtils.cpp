#include "MJAudioUtils.hpp"

#include <AssertMacros.h>
#include <IOKit/audio/IOAudioTypes.h>

std::vector<AudioDeviceID> AudioUtils::fetchAllOutputDeviceIds()
{
    UInt32 propSize;
    
    AudioObjectPropertyAddress propertyAddress = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    __Verify_noErr(AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propSize));
    int numDevices = propSize / sizeof(AudioDeviceID);
    
    AudioDeviceID *deviceIds = new AudioDeviceID[numDevices];
    __Verify_noErr(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propSize, deviceIds));
    
    std::vector<AudioDeviceID> res(deviceIds, deviceIds + numDevices);
    delete[] deviceIds;
    return res;
}

AudioDeviceID AudioUtils::fetchDefaultOutputDeviceId() {
    AudioObjectPropertyAddress propertyAddress = {
            kAudioHardwarePropertyDefaultOutputDevice,
            kAudioObjectPropertyScopeOutput,
            kAudioObjectPropertyElementMaster
    };
    UInt32 propSize = sizeof(AudioDeviceID);
    AudioDeviceID outputDeviceId;
    __Verify_noErr(AudioObjectGetPropertyData(
            kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propSize, &outputDeviceId));
    return outputDeviceId;
}

OSStatus AudioUtils::mute(AudioDeviceID deviceId)
{
    AudioObjectPropertyAddress propertyAddress = {
        kAudioDevicePropertyMute,
        kAudioObjectPropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    UInt32 mute = 1;
    return AudioObjectSetPropertyData(deviceId, &propertyAddress, 0, nullptr, sizeof(mute), &mute);
}
