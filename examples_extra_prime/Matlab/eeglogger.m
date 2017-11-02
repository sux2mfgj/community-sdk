%  ** Copyright 2017 by Emotiv. All rights reserved
%  ** Example - EEG Logger
% Require Emotiv Advanced/Prime SDK or EmotivPRO license activated.
% Data is read from the headset and sent to an output file for later analysis
% Check result file: eegloger.csv
clc;
w = warning ('off','all');
bitVersion = computer('arch');
if (strcmp(bitVersion, 'win64'))
    loadlibrary('../../bin/win64/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win64/edk.dll','../../include/IEegData.h','addheader','Iedk.h','alias','libIEEGDATA');
else
    loadlibrary('../../bin/win32/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win32/edk.dll','../../include/IEegData.h','addheader','Iedk.h','alias','libIEEGDATA');
end

enuminfo.IEE_DataChannels_enum = struct('IED_COUNTER', 0, 'IED_INTERPOLATED', 1, 'IED_RAW_CQ', 2,'IED_AF3', 3, 'IED_F7',4, 'IED_F3', 5, 'IED_FC5', 6, 'IED_T7', 7,'IED_P7', 8, 'IED_Pz', 9,'IED_O2', 10, 'IED_P8', 11, 'IED_T8', 12, 'IED_FC6', 13, 'IED_F4', 14, 'IED_F8', 15, 'IED_AF4', 16, 'IED_GYROX', 17,'IED_GYROY', 18, 'IED_TIMESTAMP', 19,'IED_MARKER_HARDWARE', 20, 'IED_ES_TIMESTAMP',21, 'IED_FUNC_ID', 22, 'IED_FUNC_VALUE', 23, 'IED_MARKER', 24,'IED_SYNC_SIGNAL', 25);
enuminfo.IEE_MentalCommandTrainingControl_enum = struct('MC_NONE',0,'MC_START',1,'MC_ACCEPT',2,'MC_REJECT',3,'MC_ERASE',4,'MC_RESET',5);

DataChannels = enuminfo.IEE_DataChannels_enum;
DataChannelsNames = {'IED_COUNTER','IED_INTERPOLATED','IED_AF3','IED_T7','IED_Pz','IED_T8','IED_AF4','IED_GYROX','IED_GYROY','IED_TIMESTAMP','IED_ES_TIMESTAMP'};
DataChannelsNamesfull ={'IED_COUNTER','IED_INTERPOLATED','IED_RAW_CQ','IED_AF3','IED_F7','IED_F3','IED_FC5','IED_T7','IED_P7','IED_Pz','IED_O2','IED_P8','IED_T8','IED_FC6','IED_F4','IED_F8','IED_AF4','IED_GYROX','IED_GYROY','IED_TIMESTAMP','IED_MARKER_HARDWARE','IED_ES_TIMESTAMP','IED_FUNC_ID','IED_FUNC_VALUE','IED_MARKER','IED_SYNC_SIGNAL'};


% libfunctionsview('libIEDK');
% libfunctionsview('libIEEGDATA');

fid = fopen('eegloger.csv','wt');
header = 'IED_COUNTER,IED_INTERPOLATED,IED_RAW_CQ,IED_AF3,IED_F7,IED_F3,IED_FC5,IED_T7,IED_P7,IED_Pz,IED_O2,IED_P8,IED_T8,IED_FC6,IED_F4,IED_F8,IED_AF4,IED_GYROX,IED_GYROY,IED_TIMESTAMP,IED_MARKER_HARDWARE,IED_ES_TIMESTAMP,IED_FUNC_ID,IED_FUNC_VALUE,IED_MARKER,IED_SYNC_SIGNAL\n';

fprintf(fid,header);
EDK_OK = 0;
calllib('libIEDK','IEE_EngineConnect', 'Emotiv Systems-5');

eEvent = calllib('libIEDK','IEE_EmoEngineEventCreate');
bufferSizeInSec = 0.05;
hData = calllib('libIEEGDATA','IEE_DataCreate');
calllib('libIEEGDATA','IEE_DataSetBufferSizeInSec', bufferSizeInSec)
readytocollect = false;
acqtime = 10;
% initialize outputs:

tic;
mycolumn = numel(DataChannelsNamesfull);
fprintf('Run time: %d seconds', acqtime);
while (toc<acqtime)
    
    state = calllib('libIEDK','IEE_EngineGetNextEvent', eEvent); % state = 0 if everything's OK
    
    if(state == EDK_OK)
        eventType = calllib('libIEDK','IEE_EmoEngineEventGetType',eEvent);
        userID=libpointer('uint32Ptr',0);
        calllib('libIEDK','IEE_EmoEngineEventGetUserId',eEvent, userID);
        
        if (strcmp(eventType,'IEE_UserAdded') == true)
            userID_value = get(userID,'value');
            calllib('libIEEGDATA','IEE_DataAcquisitionEnable',userID_value,true);
            readytocollect = true;
        end
    end
    
    if(readytocollect)
        result = calllib('libIEEGDATA','IEE_DataUpdateHandle', userID_value, hData);
        
        if(result~=0)
            continue;
        end
        nSamples = libpointer('uint32Ptr',0);
        calllib('libIEEGDATA','IEE_DataGetNumberOfSample', hData, nSamples);
        nSamplesTaken = get(nSamples,'value');
        
        if (nSamplesTaken ~= 0)
            data = libpointer('doublePtr', zeros(1, nSamplesTaken));
            data2=zeros(nSamplesTaken,numel(DataChannelsNames));
            
            for i = 1:mycolumn
                calllib('libIEEGDATA', 'IEE_DataGet', hData, DataChannels.([DataChannelsNamesfull{i}]), data, uint32(nSamplesTaken));
                data_value = get(data,'value');
                for k = 1: nSamplesTaken
                    data2(k,i) = data_value(k);
                end
                disp(data_value);
            end
            
            for i = 1 : nSamplesTaken
                dlmwrite('eegloger.csv', data2(i,1:mycolumn),'-append','delimiter',',','precision','%.2f');
            end
        end
        
    end
    
end

delete data2;
fclose(fid);
clearvars userID;
clearvars nSamples;
clearvars data;

calllib('libIEEGDATA','IEE_DataFree',hData);
calllib('libIEDK','IEE_EngineDisconnect')
calllib('libIEDK','IEE_EmoEngineEventFree', eEvent);
disp('finish');

