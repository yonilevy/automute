#ifndef MJAudioUtils_hpp
#define MJAudioUtils_hpp

#include <stdio.h>
#include <MacTypes.h>
#include <vector>
#include <CoreAudio/CoreAudio.h>

class AudioUtils {
public:
    static std::vector<AudioDeviceID> fetchAllOutputDeviceIds();
    static AudioDeviceID fetchDefaultOutputDeviceId();

    static OSStatus mute(AudioDeviceID deviceId);
};

#endif /* MJAudioUtils_hpp */
