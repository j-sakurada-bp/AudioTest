import Foundation
import AVFoundation

protocol AudioControllerDelegate {
    func processSampleData(_ data:Data) -> Void
}

class AudioController {
    var remoteIOUnit: AudioComponentInstance? // optional to allow it to be an inout argument
    var delegate : AudioControllerDelegate!
    
    static var sharedInstance = AudioController()
    
    deinit {
        AudioComponentInstanceDispose(remoteIOUnit!);
    }
    
    func prepare(specifiedSampleRate: Int) -> OSStatus {
        var status = noErr
        
        let session = AVAudioSession.sharedInstance()
        
        var sampleRate = session.sampleRate
        sampleRate = Double(specifiedSampleRate)
        
        // Describe the RemoteIO unit
        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output;
        audioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        audioComponentDescription.componentFlags = 0;
        audioComponentDescription.componentFlagsMask = 0;
        
        // Get the RemoteIO unit
        let remoteIOComponent = AudioComponentFindNext(nil, &audioComponentDescription)
        status = AudioComponentInstanceNew(remoteIOComponent!, &remoteIOUnit)
        if (status != noErr) {
            return status
        }
        
        let bus1 : AudioUnitElement = 1
        var oneFlag : UInt32 = 1
        
        // Configure the RemoteIO unit for input
        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input,
                                      bus1,
                                      &oneFlag,
                                      UInt32(MemoryLayout<UInt32>.size));
        if (status != noErr) {
            return status
        }
        
        // Set format for mic input (bus 1) on RemoteIO's output scope
        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = sampleRate
        asbd.mFormatID = kAudioFormatLinearPCM
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        asbd.mBytesPerPacket = 2
        asbd.mFramesPerPacket = 1
        asbd.mBytesPerFrame = 2
        asbd.mChannelsPerFrame = 1
        asbd.mBitsPerChannel = 16
        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output,
                                      bus1,
                                      &asbd,
                                      UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        if (status != noErr) {
            return status
        }
        
        // Set the recording callback
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = recordingCallback
        callbackStruct.inputProcRefCon = nil
        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Global,
                                      bus1,
                                      &callbackStruct,
                                      UInt32(MemoryLayout<AURenderCallbackStruct>.size));
        if (status != noErr) {
            return status
        }
        
        // Initialize the RemoteIO unit
        if let remoteIOUnit = remoteIOUnit {
            return AudioUnitInitialize(remoteIOUnit)
        }
        return 0
    }
    
    func start() -> OSStatus {
        if let remoteIOUnit = remoteIOUnit {
            return AudioOutputUnitStart(remoteIOUnit)
        }
        return 0
    }
    
    func stop() -> OSStatus {
        if let remoteIOUnit = remoteIOUnit {
            return AudioOutputUnitStop(remoteIOUnit)
        }
        return 0
    }
}

func recordingCallback(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBusNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    var status = noErr
    
    let channelCount : UInt32 = 1
    
    var bufferList = AudioBufferList()
    bufferList.mNumberBuffers = channelCount
    let buffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &bufferList.mBuffers,
                                                          count: Int(bufferList.mNumberBuffers))
    buffers[0].mNumberChannels = 1
    buffers[0].mDataByteSize = inNumberFrames * 2
    buffers[0].mData = nil
    
    // エラー対応
    if AudioController.sharedInstance.remoteIOUnit == nil {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "returnPerformNotification"), object: nil)
        
        return noErr
    }
    
    // get the recorded samples
    status = AudioUnitRender(AudioController.sharedInstance.remoteIOUnit!,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             UnsafeMutablePointer<AudioBufferList>(&bufferList))
    if (status != noErr) {
        return status;
    }
    
    let data = Data(bytes:  buffers[0].mData!, count: Int(buffers[0].mDataByteSize))
    DispatchQueue.main.async {
        AudioController.sharedInstance.delegate.processSampleData(data)
    }
    
    return noErr
}

