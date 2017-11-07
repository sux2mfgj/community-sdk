%  ** Copyright 2017 by Emotiv. All rights reserved
%  ** Example - Average Band Powers
% This example work with Insight headset by default.
% Edit dataChannel struct to EPOC+ sensor to make it work with EPOC+
clc;
w = warning ('off','all');
bitVersion = computer('arch');
if (strcmp(bitVersion, 'win64'))
    loadlibrary('../../bin/win64/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win64/edk.dll','../../include/IEmoStateDLL.h', 'alias', 'libIEmoStateDLL');
else
    loadlibrary('../../bin/win32/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win32/edk.dll','../../include/IEmoStateDLL.h', 'alias','libIEmoStateDLL');
end

% libfunctionsview('edk');
EDK_OK = 0;

% Full enum channels: 
% IEE_DataChannels_enum = struct('IED_COUNTER', 0, 'IED_INTERPOLATED', 1, 'IED_RAW_CQ', 2,'IED_AF3', 3, 'IED_F7',4, 'IED_F3', 5, 'IED_FC5', 6, 'IED_T7', 7,'IED_P7', 8, 'IED_Pz', 9,'IED_O2', 10, 'IED_P8', 11, 'IED_T8', 12, 'IED_FC6', 13, 'IED_F4', 14, 'IED_F8', 15, 'IED_AF4', 16, 'IED_GYROX', 17,'IED_GYROY', 18, 'IED_TIMESTAMP', 19,'IED_MARKER_HARDWARE', 20, 'IED_ES_TIMESTAMP',21, 'IED_FUNC_ID', 22, 'IED_FUNC_VALUE', 23, 'IED_MARKER', 24,'IED_SYNC_SIGNAL', 25);
% Hard-coded enum value based on IEE_DataChannels_enum (Iedk.h) for Insight headset sensor:
dataChannel = struct('IED_F3', 3, 'IED_AF4', 16, 'IED_T7', 7,'IED_T8', 12, 'IED_Pz', 9);
channelName = {'IED_F3', 'IED_AF4', 'IED_T7', 'IED_T8', 'IED_Pz'};

res = calllib('libIEDK','IEE_EngineConnect', 'Emotiv Systems-5');
eEvent = calllib('libIEDK','IEE_EmoEngineEventCreate');
eState = calllib('libIEDK','IEE_EmoStateCreate');

% run 20 seconds
runtime = 20;
fprintf('Run time: %d \n', runtime);
userAdded = false;

numberSamplePtr = libpointer('uint32Ptr', 0);
thetaPtr = libpointer('doublePtr', 0);
alphaPtr = libpointer('doublePtr', 0);
lowBetaPtr = libpointer('doublePtr', 0);
highBetaPtr = libpointer('doublePtr', 0);
gammaPtr = libpointer('doublePtr', 0);
userIdPtr = libpointer('uint32Ptr', 0);
tic;

while (toc < runtime)
    state = calllib('libIEDK','IEE_EngineGetNextEvent',eEvent);
    
    if(state == EDK_OK)
        eventType = calllib('libIEDK','IEE_EmoEngineEventGetType',eEvent);
        calllib('libIEDK','IEE_EmoEngineEventGetUserId',eEvent, userIdPtr);
        if (strcmp(eventType,'IEE_UserAdded') == true)
            fprintf('User added: %d', userIdPtr.Value)
            userAdded = true;
        end
    end

    if (userAdded)
        if strcmp(eventType,'IEE_EmoStateUpdated') == true
            thetaPtr.Value = 0;
            alphaPtr.Value = 0;
            lowBetaPtr.Value = 0;
            highBetaPtr.Value = 0;
            gammaPtr.Value = 0;
            for index = 1 : numel(channelName)
                res = calllib('libIEDK','IEE_GetAverageBandPowers', userIdPtr.Value, dataChannel.([channelName{index}]), thetaPtr, alphaPtr, lowBetaPtr, highBetaPtr, gammaPtr);
                if (res == EDK_OK)
                    fprintf('theta: %f , alpha: %f , low beta: %f , high beta: %f , gamma: %f , channel: %s \n', thetaPtr.Value, alphaPtr.Value, lowBetaPtr.Value, highBetaPtr.Value, gammaPtr.Value, channelName{index});
                end
            end    	
        end
    end
end

calllib('libIEDK','IEE_EngineDisconnect')
calllib('libIEDK','IEE_EmoStateFree',eState);
calllib('libIEDK','IEE_EmoEngineEventFree',eEvent);

disp('finish');

