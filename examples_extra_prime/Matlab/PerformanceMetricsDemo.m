%  ** Copyright 2017 by Emotiv. All rights reserved
%  ** Example - EEG Logger
% Require Emotiv Prime SDK license activated.
% Data is read from the headset and sent to an output file for later analysis
% Check result file: PerformanceMetrics.csv
clc;
warning ('off','all');
bitVersion = computer('arch');
if (strcmp(bitVersion, 'win64'))
    loadlibrary('../../bin/win64/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win64/edk.dll','../../include/IEegData.h','addheader','Iedk.h','alias','libIEEGDATA');
    loadlibrary('../../bin/win64/edk.dll','../../include/IEmoStatePerformanceMetric.h','addheader','Iedk.h','alias','libPM');
else
    loadlibrary('../../bin/win32/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win32/edk.dll','../../include/IEegData.h','addheader','Iedk.h','alias','libIEEGDATA');
    loadlibrary('../../bin/win32/edk.dll','../../include/IEmoStatePerformanceMetric.h','addheader','Iedk.h','alias','libPM');
end

% libfunctionsview('libIEDK');
% libfunctionsview('libIEEGDATA');
% libfunctionsview('libPM');

fid = fopen('PerformanceMetrics.csv','wt');
strfull = ['Time,UserID,Stress raw score,Stress min score,Stress max score,'...
    'Stress scaled score,Engagement boredom raw score,Engagement boredom min score,Engagement boredom max score,'...
    'Engagement boredom scaled score,'...
    'Relaxation raw score,'...
    'Relaxation min score,'...
    'Relaxation max score,'...
    'Relaxation scaled score,'...
    'Excitement raw score,'...
    'Excitement min score,'...
    'Excitement max score,'...
    'Excitement scaled score,'...
    'Interest raw score,'...
    'Interest min score,'...
    'Interest max score,'...
    'Interest scaled score,\n'];
fprintf(fid,strfull);
eEvent = calllib('libIEDK','IEE_EmoEngineEventCreate');
eState = calllib('libIEDK','IEE_EmoStateCreate');
calllib('libIEDK','IEE_EngineConnect', 'Emotiv Systems-5'); % success means this value is 0;2

EDK_OK=0;
rectime = 1;

calllib('libIEEGDATA','IEE_DataSetBufferSizeInSec',rectime)

acqtime = 20; % time (second) for getting performance metrics data
tic
fprintf('Getting Performance Metrics Data for %d seconds', acqtime);
while (toc<acqtime)
    
    state = calllib('libIEDK','IEE_EngineGetNextEvent',eEvent); % state = 0 if everything's OK
    
    if(state==EDK_OK)
        
        eventType = calllib('libIEDK','IEE_EmoEngineEventGetType',eEvent);
        
        userID=libpointer('uint32Ptr',0);
        calllib('libIEDK','IEE_EmoEngineEventGetUserId',eEvent, userID);
        
        if (strcmp(eventType,'IEE_UserAdded') == true)
            userID_value = get(userID,'value');
            calllib('libIEEGDATA','IEE_DataAcquisitionEnable',userID_value,true);   
        end
        if (strcmp(eventType,'IEE_EmoStateUpdated') == true)
            calllib('libIEDK','IEE_EmoEngineEventGetEmoState',eEvent,eState);
            time=calllib('libIEDK','IS_GetTimeFromStart',eState);
            fprintf(fid,'%6.3f,%d,',time,get(userID,'Value'));
            %IS_GetTimeFromStart(EmoStateHandle state);
            rawScore = libpointer('doublePtr',0);
            minScale = libpointer('doublePtr',0);
            maxScale = libpointer('doublePtr',0);
            %scaledScore = libPMointer('doublePtr',0);
            calllib('libPM','IS_PerformanceMetricGetStressModelParams',eState,rawScore,minScale,maxScale);
            raw=get(rawScore,'Value');
            min=get(minScale,'Value');
            max=get(maxScale,'Value');
            fprintf(fid,'%6.2f,%6.2f,%6.2f,',raw,min,max);
            if (min == max)
                
                fprintf(fid,'undefined,');
                %os << "undefined" << ",";
                
            else
                scaledScore = CaculateScale(raw, max, min);
                fprintf(fid,'%6.6f,',scaledScore);
                %os << scaledScore << ",";
            end
            
            
            calllib('libPM','IS_PerformanceMetricGetEngagementBoredomModelParams',eState,rawScore,minScale,maxScale);
            r=get(rawScore,'Value');
            min=get(minScale,'Value');
            max=get(maxScale,'Value');
            fprintf(fid,'%6.6f,%6.6f,%6.6f,',r,min,max);
            if (min == max)
                
                fprintf(fid,'undefined,');
                %os << "undefined" << ",";
                
            else
                scaledScore = CaculateScale(raw, max, min);
                fprintf(fid,'%6.6f,',scaledScore);
                %os << scaledScore << ",";
            end
            
            calllib('libPM','IS_PerformanceMetricGetRelaxationModelParams',eState,rawScore,minScale,maxScale);
            raw=get(rawScore,'Value');
            min=get(minScale,'Value');
            max=get(maxScale,'Value');
            fprintf(fid,'%6.6f,%6.6f,%6.6f,',raw,min,max);
            if (min == max)
                
                fprintf(fid,'undefined,');
                %os << "undefined" << ",";
                
            else
                scaledScore = CaculateScale(raw, max, min);
                fprintf(fid,'%6.6f,',scaledScore);
                %os << scaledScore << ",";
            end
            
            calllib('libPM','IS_PerformanceMetricGetInstantaneousExcitementModelParams',eState,rawScore,minScale,maxScale);
            raw=get(rawScore,'Value');
            min=get(minScale,'Value');
            max=get(maxScale,'Value');
            fprintf(fid,'%6.6f,%6.6f,%6.6f,',raw,min,max);
            if (min == max)
                fprintf(fid,'undefined,');
            else
                scaledScore = CaculateScale(raw, max, min);
                fprintf(fid,'%6.6f,',scaledScore);
            end
            
            calllib('libPM','IS_PerformanceMetricGetInterestModelParams',eState,rawScore,minScale,maxScale);
            raw=get(rawScore,'Value');
            min=get(minScale,'Value');
            max=get(maxScale,'Value');
            fprintf(fid,'%6.6f,%6.6f,%6.6f,',raw,min,max);
            if (min == max)
                fprintf(fid,'undefined,');
            else
                scaledScore = CaculateScale(raw, max, min);
                fprintf(fid,'%6.6f,',scaledScore);
            end
            fprintf(fid,'\n');
        end
    end
end
fclose(fid);
calllib('libIEDK','IEE_EmoEngineEventFree', eEvent);
calllib('libIEDK','IEE_EngineDisconnect')
disp('finish');

function y = CaculateScale(raw, max, min)
    if(raw<min)
        y = 0;
    elseif (raw>max)
        y = 1;
    else
        y = (raw-min)/(max-min);
    end
end

