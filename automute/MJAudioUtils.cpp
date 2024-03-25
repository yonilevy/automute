#include "MJAudioUtils.hpp"

#include <AssertMacros.h>
#include <IOKit/audio/IOAudioTypes.h>
#include "MJLog.h"

std::set<AudioDeviceID> AudioUtils::fetchAllOutputDeviceIds()
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
    
    std::set<AudioDeviceID> res(deviceIds, deviceIds + numDevices);
    delete[] deviceIds;
    return res;
}

AudioDeviceID AudioUtils::fetchDefaultOutputDeviceId()
{
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

bool AudioUtils::isDevicePossibleHeadphones(AudioDeviceID deviceId)
{
    AudioObjectPropertyAddress propertyAddress = {
            kAudioDevicePropertyStreams,
            kAudioDevicePropertyScopeOutput,
            kAudioObjectPropertyElementMaster
    };

    UInt32 propSize;
    __Verify_noErr(AudioObjectGetPropertyDataSize(deviceId, &propertyAddress, 0, NULL, &propSize));

    int numStreams = propSize / sizeof(AudioStreamID);
    AudioStreamID *streamIds = new AudioStreamID[numStreams];
    __Verify_noErr(AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &propSize, streamIds));

    bool foundHeadphones = false;
    for (int i = 0 ; i < numStreams ; ++i) {
        AudioObjectPropertyAddress sourceAddr2 = {
                kAudioStreamPropertyTerminalType,
                kAudioObjectPropertyScopeGlobal,
                kAudioObjectPropertyElementMaster
        };

        UInt32 terminalType = 0;
        UInt32 terminalTypeSize = sizeof(UInt32);
        __Verify_noErr(AudioObjectGetPropertyData(streamIds[i], &sourceAddr2, 0, NULL, &terminalTypeSize, &terminalType));

        if (terminalType == OUTPUT_HEADPHONES || terminalType == kAudioStreamTerminalTypeHeadphones) {
            foundHeadphones = true;
            break;
        }
    }

    delete[] streamIds;
    return foundHeadphones;
}

AudioUtils::AudioDeviceDesc AudioUtils::fetchDefaultOutputDeviceDesc()
{
    AudioDeviceID deviceId = AudioUtils::fetchDefaultOutputDeviceId();
    bool possibleHeadphones = AudioUtils::isDevicePossibleHeadphones(deviceId);
    return AudioDeviceDesc{deviceId, possibleHeadphones};
}

void AudioUtils::listenToDefaultOutputDeviceChanges(VoidBlock callback)
{
    listenToSystemChange(
            AudioObjectPropertyAddress{
                    kAudioHardwarePropertyDefaultOutputDevice,
                    kAudioObjectPropertyScopeGlobal,
                    kAudioObjectPropertyElementMaster
            },
            callback);
}

void AudioUtils::listenToDevicesChanges(VoidBlock callback)
{
    listenToSystemChange(
            AudioObjectPropertyAddress{
                kAudioHardwarePropertyDevices,
                kAudioObjectPropertyScopeGlobal,
                kAudioObjectPropertyElementMaster
            },
            callback);
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

void AudioUtils::listenToSystemChange(AudioObjectPropertyAddress propertyAddress, VoidBlock block)
{
    auto onChangeBlock = ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            block();
        });
    };

    AudioObjectAddPropertyListenerBlock(kAudioObjectSystemObject, &propertyAddress, nullptr, onChangeBlock);
}

////////////////////////////////////////////////////////////////////////////////
///////////////////////////   AudioDevicesSnapshot   ///////////////////////////
////////////////////////////////////////////////////////////////////////////////


#ifdef DEBUG

AudioUtils::AudioDevicesSnapshot AudioUtils::AudioDevicesSnapshot::snap() {
    AudioDevicesSnapshot res;
    for (const auto& deviceId : AudioUtils::fetchAllOutputDeviceIds()) {
        bool possibleHeadphones = AudioUtils::isDevicePossibleHeadphones(deviceId);
        res.descs.push_back(AudioDeviceDesc{deviceId, possibleHeadphones});
    }
    res.defaultOutputDeviceId = AudioUtils::fetchDefaultOutputDeviceId();
    return res;
}

void AudioUtils::AudioDevicesSnapshot::log() {
    MJLOG("=======================================\n");
    for (auto const& desc : descs) {
        bool isDefault = desc.id == defaultOutputDeviceId;
        MJLOG("|   Device %5u [hp=%d] [default=%d]   |\n", desc.id, desc.possibleHeadphones, isDefault);
    }
    MJLOG("=======================================\n");
}

#endif
