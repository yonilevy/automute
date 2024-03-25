#ifndef MJHeadphonesTracker_hpp
#define MJHeadphonesTracker_hpp

#include <stdio.h>
#include <MacTypes.h>
#include <vector>
#include <CoreAudio/CoreAudio.h>
#include <optional>
#include "MJAudioUtils.hpp"

/**
 * This class notifies its listener when the default audio output device changes,
 * letting it know whether that change came as a result of a possibly-headphones
 * device disconnecting.
 *
 * To achieve that, we listen to both (1) devices-changed and (2) default-output-device-changed events.
 * Note: In the majority of cases, when a default-output-device gets disconnected, we'd get (1) immediately
 * followed by (2). That's the order which we assume when handling the events. To support the the rare cases
 * where (2) precedes (1) [only rarely reproduces with an aux cable], we delay the handling of (2) by a tiny bit.
 *
 * Note: We can't really differentiate headphones from speakers, so all headphones mentions
 *  are referring to a device that *might be* headphones (we get false positives).
 */
class HeadphonesTracker {
private:
    /// Keeping track of the current default-output-device.
    AudioUtils::AudioDeviceDesc m_lastDefaultDesc;

    /// Used to mark a default-headphones-disconnect event, to be consumed by the following dod-change event.
    bool m_headphonesDisconnectMarker;

public:
    HeadphonesTracker();
    typedef void (^OnDODChangeBlock)(bool isHeadphones, bool isFollowingHeadphonesDisconnect);
    void track(OnDODChangeBlock block);
    bool isDefaultOutputDeviceHeadphones();

private:
    void onDevicesChanged();
    void onDefaultDeviceChanged(HeadphonesTracker::OnDODChangeBlock listenerBlock);
};

#endif /* MJHeadphonesTracker_hpp */
