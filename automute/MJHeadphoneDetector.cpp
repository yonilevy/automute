#include "MJHeadphoneDetector.hpp"

#include <AssertMacros.h>
#include <IOKit/audio/IOAudioTypes.h>

#define MJLOG(fmt, ...) \
            do { if (DEBUG) printf(fmt, ##__VA_ARGS__); } while (0)


HeadPhoneDetector::HeadPhoneDetector() :
        m_headphonesConnected(areHeadphonesConnected())
{
}

void HeadPhoneDetector::listen(HeadPhoneDetector::OnHeadphoneChangeBlock listenerBlock)
{
    AudioObjectPropertyAddress propAddress = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster };
    auto onChangeDetectedBlock = ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses) {
        onChangeDetected(listenerBlock);
    };

    AudioObjectAddPropertyListenerBlock(kAudioObjectSystemObject, &propAddress, nullptr, onChangeDetectedBlock);

    propAddress.mSelector = kAudioDevicePropertyDataSource;
    propAddress.mScope = kAudioObjectPropertyScopeOutput;
    std::vector<AudioDeviceID> devices(fetchAllDevices());
    for (auto it = devices.begin() ; it != devices.end() ; ++it) {
        AudioDeviceID deviceId = *it;
        AudioObjectAddPropertyListenerBlock(deviceId, &propAddress, nullptr, onChangeDetectedBlock);
        deviceListen(deviceId, onChangeDetectedBlock);
    }
}

void HeadPhoneDetector::deviceListen(AudioDeviceID deviceId, AudioObjectPropertyListenerBlock block)
{
    AudioObjectPropertyAddress sourceAddr = {
        kAudioDevicePropertyStreams,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };

    UInt32 propSize;
    __Verify_noErr(AudioObjectGetPropertyDataSize(deviceId, &sourceAddr, 0, NULL, &propSize));
    int numStreams = propSize / sizeof(AudioStreamID);

    AudioStreamID *streamIds = new AudioStreamID[numStreams];
    __Verify_noErr(AudioObjectGetPropertyData(deviceId, &sourceAddr, 0, NULL, &propSize, streamIds));

    for (int i = 0 ; i < numStreams ; ++i) {
        AudioObjectPropertyAddress sourceAddr2 = {
            kAudioStreamPropertyTerminalType,
            kAudioObjectPropertyScopeGlobal,
            kAudioObjectPropertyElementMaster
        };
        __Verify_noErr(AudioObjectAddPropertyListenerBlock(
                streamIds[i], &sourceAddr2, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block));
    }
    
    delete[] streamIds;
}

std::vector<AudioDeviceID> HeadPhoneDetector::fetchAllDevices()
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

bool HeadPhoneDetector::areHeadphonesConnected()
{
    std::vector<AudioDeviceID> devices(fetchAllDevices());
    bool foundHeadphones = false;
    for (auto deviceIdPtr = devices.begin() ; deviceIdPtr != devices.end() ; ++deviceIdPtr) {
        MJLOG("================\n");
        MJLOG("Device ID: %d\n", *deviceIdPtr);
        if (isDeviceHeadphones(*deviceIdPtr)) {
            foundHeadphones = true;
        }
        MJLOG("================\n");
        MJLOG("\n");
    }
    return foundHeadphones;
}

bool HeadPhoneDetector::isDeviceHeadphones(UInt32 deviceId)
{
    AudioObjectPropertyAddress sourceAddr = {
        kAudioDevicePropertyStreams,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    UInt32 propSize;
    __Verify_noErr(AudioObjectGetPropertyDataSize(deviceId, &sourceAddr, 0, NULL, &propSize));

    int numStreams = propSize / sizeof(AudioStreamID);
    AudioStreamID *streamIds = new AudioStreamID[numStreams];
    __Verify_noErr(AudioObjectGetPropertyData(deviceId, &sourceAddr, 0, NULL, &propSize, streamIds));

    MJLOG("Number of streams: %d\n", numStreams);
    bool foundHeadphones = false;
    for (int i = 0 ; i < numStreams ; ++i) {
        MJLOG("\tStream ID: %lu\n", (unsigned long)streamIds[i]);
        
        AudioObjectPropertyAddress sourceAddr2 = {
            kAudioStreamPropertyTerminalType,
            kAudioObjectPropertyScopeGlobal,
            kAudioObjectPropertyElementMaster
        };
        
        UInt32 terminalType = 0;
        UInt32 terminalTypeSize = sizeof(UInt32);
        __Verify_noErr(AudioObjectGetPropertyData(streamIds[i], &sourceAddr2, 0, NULL, &terminalTypeSize, &terminalType));

        MJLOG("\tStream Terminal Type: %lu\n", (unsigned long)terminalType);
        if (terminalType == OUTPUT_HEADPHONES || terminalType == kAudioStreamTerminalTypeHeadphones) {
            MJLOG("\tHeadphones\n");
            foundHeadphones = true;
        } else {
            MJLOG("\tNot Headphones\n");
        }
        
    }
    
    delete[] streamIds;
    return foundHeadphones;
}

void HeadPhoneDetector::onChangeDetected(HeadPhoneDetector::OnHeadphoneChangeBlock listenerBlock)
{
    MJLOG("Device change Detected!\n");
    MJLOG("Previous connected: %d\n", m_headphonesConnected);
    bool connected = areHeadphonesConnected();
    MJLOG("Current connected: %d\n", connected);
    if (m_headphonesConnected != connected) {
        m_headphonesConnected = connected;
        dispatch_async(dispatch_get_main_queue(), ^() {
            listenerBlock(m_headphonesConnected);
        });
    }
}
