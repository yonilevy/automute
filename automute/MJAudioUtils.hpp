#ifndef MJAudioUtils_hpp
#define MJAudioUtils_hpp

#include <stdio.h>
#include <MacTypes.h>
#include <set>
#include <CoreAudio/CoreAudio.h>

class AudioUtils {
public:
    struct AudioDeviceDesc {
        AudioDeviceID id;
        bool possibleHeadphones; /// Might be speakers...
    };

public:
    static std::set<AudioDeviceID> fetchAllOutputDeviceIds();
    static AudioDeviceID fetchDefaultOutputDeviceId();
    static bool isDevicePossibleHeadphones(AudioDeviceID deviceId);
    static AudioDeviceDesc fetchDefaultOutputDeviceDesc();

    /// All listener callbacks called on main queue.
    typedef void (^VoidBlock)();
    static void listenToDefaultOutputDeviceChanges(VoidBlock callback);
    static void listenToDevicesChanges(VoidBlock callback);

    static OSStatus mute(AudioDeviceID deviceId);

private:
    static void listenToSystemChange(AudioObjectPropertyAddress propertyAddress, VoidBlock block);

public:
#ifdef DEBUG
    /// Debug Helper - fetch & log a snapshot of current devices.
    struct AudioDevicesSnapshot {
        static AudioDevicesSnapshot snap();

        std::vector<AudioDeviceDesc> descs;
        AudioDeviceID defaultOutputDeviceId;

        void log();
    };
#endif
};

#endif /* MJAudioUtils_hpp */
