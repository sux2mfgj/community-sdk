%  ** Copyright 2017 by Emotiv. All rights reserved
%  ** Example - Motion Data Logger
%  ** This example demonstrates how to extract live Motion data using the EmoEngineTM
%  ** Data is read from the headset and sent to an output file for later analysis
%  ** Check result file: MotionDatalogger.csv
clc;
w = warning ('off','all');
MotionDataChannelsNamesfull ={'IMD_COUNTER','IMD_GYROX','IMD_GYROY','IMD_GYROZ','IMD_ACCX','IMD_ACCY','IMD_ACCZ','IMD_MAGX','IMD_MAGY','IMD_MAGZ','IMD_TIMESTAMP'};
IEE_MotionDataChannels_enum = struct('IMD_COUNTER',0,'IMD_GYROX',1,'IMD_GYROY',2,'IMD_GYROZ',3,'IMD_ACCX',4,'IMD_ACCY',5,'IMD_ACCZ',6,'IMD_MAGX',7,'IMD_MAGY',8,'IMD_MAGZ',9,'IMD_TIMESTAMP',10);
MotionDataChannels = IEE_MotionDataChannels_enum;

bitVersion = computer('arch');

if (strcmp(bitVersion, 'win64'))
    loadlibrary('../../bin/win64/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libEDK');
    loadlibrary('../../bin/win64/edk.dll','../../include/IEegData.h','addheader','Iedk.h','alias','libEEGData');
else
    loadlibrary('../../bin/win32/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libEDK');
    loadlibrary('../../bin/win32/edk.dll','../../include/IEegData.h','addheader','Iedk.h','alias','libEEGData');
end

AllOK = calllib('libEDK','IEE_EngineConnect', 'Emotiv Systems-5');

filename='MotionDatalogger.csv';
fid = fopen(filename,'wt');

headers = 'IMD_COUNTER,IMD_GYROX,IMD_GYROY,IMD_GYROZ,IMD_ACCX,IMD_ACCY,IMD_ACCZ,IMD_MAGX,IMD_MAGY,IMD_MAGZ,IMD_TIMESTAMP\n';
fprintf(fid,headers);

eEvent = calllib('libEDK','IEE_EmoEngineEventCreate');
eState = calllib('libEDK','IEE_EmoStateCreate');
userIdPointer = libpointer('uint32Ptr',0);
EDK_OK = 0;
rectime = 1;
hMotionData = calllib('libEDK','IEE_MotionDataCreate');
calllib('libEEGData','IEE_DataSetBufferSizeInSec',rectime);
userAdded = false;

mycolumn = numel(MotionDataChannelsNamesfull);
acqtime = 20;% run in 20 second
Message = ['Run time:',num2str(acqtime),' second...'];
disp(Message);

tic;
while (toc<acqtime)
    
    state = calllib('libEDK','IEE_EngineGetNextEvent',eEvent);
    
    if(state == EDK_OK)
        eventType = calllib('libEDK','IEE_EmoEngineEventGetType',eEvent);
        calllib('libEDK','IEE_EmoEngineEventGetUserId',eEvent, userIdPointer);
        if (strcmp(eventType,'IEE_UserAdded') == true)
            userIdValue = get(userIdPointer,'value');
            disp(userIdValue);
            userAdded = true;
        end
    end
    
    if(userAdded)
        
        result = calllib('libEDK','IEE_MotionDataUpdateHandle', userIdValue, hMotionData);
        
        if(result~=0)
            continue;
        end
        nSamples = libpointer('uint32Ptr',0);
        calllib('libEDK','IEE_MotionDataGetNumberOfSample',hMotionData, nSamples);
        nSamplesTaken = get(nSamples,'value');
        if (nSamplesTaken ~= 0)
            data = libpointer('doublePtr', zeros(1, nSamplesTaken));
            data2=zeros(nSamplesTaken,mycolumn);
            
            for i = 1:mycolumn
                calllib('libEEGData', 'IEE_DataGet', hMotionData, MotionDataChannels.([MotionDataChannelsNamesfull{i}]), data, uint32(nSamplesTaken));
                data_value = get(data,'value');
                for k = 1 : nSamplesTaken
                    data2(k,i) = data_value(k);
                end
            end
            for i=1:nSamplesTaken
                % disp(data2(i,1:mycolumn));
                dlmwrite(filename,data2(i,1:mycolumn),'-append','delimiter',',','precision','%.3f');
            end
        end
        
    end
    
end

fclose(fid);

disp('finish');




