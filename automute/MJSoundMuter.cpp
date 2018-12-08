#include <cstdio>
#include <CoreAudio/CoreAudio.h>
#include <AssertMacros.h>
#import "MJSoundMuter.h"


void SoundMuter::mute()
{
    AudioObjectPropertyAddress propertyAddress = {
            kAudioHardwarePropertyDefaultOutputDevice,
            kAudioObjectPropertyScopeOutput,
            kAudioObjectPropertyElementMaster
    };
    UInt32 propSize = sizeof(AudioDeviceID);
    AudioDeviceID outputDevice;
    __Verify_noErr(AudioObjectGetPropertyData(
            kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propSize, &outputDevice));

    UInt32 mute = 1;
    propertyAddress.mSelector = kAudioDevicePropertyMute;
    AudioObjectSetPropertyData(outputDevice, &propertyAddress, 0, nullptr, sizeof(mute), &mute);
}
