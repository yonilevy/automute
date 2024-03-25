#include "MJHeadphoneTracker.hpp"

#include <AssertMacros.h>
#include <IOKit/audio/IOAudioTypes.h>
#include "MJAudioUtils.hpp"
#include "MJLog.h"

HeadphonesTracker::HeadphonesTracker()
    : m_lastDefaultDesc(AudioUtils::fetchDefaultOutputDeviceDesc()),
      m_headphonesDisconnectMarker(false)
{
    MJLOG("HeadphonesTracker initiated.\n");
#ifdef DEBUG
    AudioUtils::AudioDevicesSnapshot::snap().log();
#endif
}

void HeadphonesTracker::track(OnDODChangeBlock block)
{
    AudioUtils::listenToDevicesChanges(^() {
        onDevicesChanged();
    });

    AudioUtils::listenToDefaultOutputDeviceChanges(^() {
        /// Hack: we delay handling to allow for an out-of-order devices-changed event (could only reproduce with physical aux).
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^() {
            onDefaultDeviceChanged(block);
        });
    });
}

bool HeadphonesTracker::isDefaultOutputDeviceHeadphones()
{
    return m_lastDefaultDesc.possibleHeadphones;
}

void HeadphonesTracker::onDevicesChanged()
{
    MJLOG("Devices changed\n");
#ifdef DEBUG
    AudioUtils::AudioDevicesSnapshot::snap().log();
#endif
    
    if (m_lastDefaultDesc.possibleHeadphones) {
        std::set<AudioDeviceID> deviceIds = AudioUtils::fetchAllOutputDeviceIds();
        bool didDisconnect = deviceIds.find(m_lastDefaultDesc.id) == deviceIds.end();
        MJLOG("|---- Last default was headphones, didDisconnect = %d.\n", didDisconnect);
        if (didDisconnect) {
            m_headphonesDisconnectMarker = true;
        }
    } else {
        MJLOG("|---- Last default was NOT headphones.\n");
    }
}

void HeadphonesTracker::onDefaultDeviceChanged(HeadphonesTracker::OnDODChangeBlock listenerBlock)
{
    MJLOG("Default Output Device changed.\n");
#ifdef DEBUG
    AudioUtils::AudioDevicesSnapshot::snap().log();
#endif
    
    auto defaultDesc = AudioUtils::fetchDefaultOutputDeviceDesc();
    
    listenerBlock(defaultDesc.possibleHeadphones, m_headphonesDisconnectMarker);
    
    m_lastDefaultDesc = defaultDesc;
    m_headphonesDisconnectMarker = false;
}
