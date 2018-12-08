#ifndef MJHeadphoneDetector_hpp
#define MJHeadphoneDetector_hpp

#include <stdio.h>
#include <MacTypes.h>
#include <vector>
#include <CoreAudio/CoreAudio.h>

class HeadPhoneDetector {
public:
    typedef void (^OnHeadphoneChangeBlock)(bool headphonesConnected);

    HeadPhoneDetector();
    void listen(OnHeadphoneChangeBlock block);
    bool areHeadphonesConnected();

private:
    std::vector<AudioDeviceID> fetchAllDevices();
    bool isDeviceHeadphones(UInt32 deviceId);
    void onChangeDetected(HeadPhoneDetector::OnHeadphoneChangeBlock listenerBlock);
    void deviceListen(AudioDeviceID deviceId, AudioObjectPropertyListenerBlock block);

    bool m_headphonesConnected;
};

#endif /* MJHeadphoneDetector_hpp */
