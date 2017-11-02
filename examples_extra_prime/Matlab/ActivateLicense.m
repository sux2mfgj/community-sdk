%  ** Copyright 2017 by Emotiv. All rights reserved
%  ** Example - Activate License
%  ** This example demonstrates how to work with Emotiv SDK license
clc;
w = warning ('off','all');
bitVersion = computer('arch');
if (strcmp(bitVersion, 'win64'))
    loadlibrary('../../bin/win64/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win64/edk.dll','../../include/EmotivCloudClient.h','addheader','Iedk.h','alias','libCloud');
    loadlibrary('../../bin/win64/edk.dll','../../include/EmotivLicense.h','addheader','Iedk.h','alias','libLicense');
    fprintf('Load 64bit');
else
    loadlibrary('../../bin/win32/edk.dll','../../include/Iedk.h','addheader','IedkErrorCode.h','addheader','IEmoStateDLL.h','addheader','FacialExpressionDetection.h','addheader','MentalCommandDetection.h','addheader','IEmotivProfile.h','addheader','EmotivLicense.h','alias','libIEDK');
    loadlibrary('../../bin/win32/edk.dll','../../include/EmotivCloudClient.h','addheader','Iedk.h','alias','libCloud');
    loadlibrary('../../bin/win32/edk.dll','../../include/EmotivLicense.h','addheader','Iedk.h','alias','libLicense');
end
EDK_OK = 0;
err = calllib('libIEDK','IEE_EngineConnect', 'Emotiv Systems-5');
err = calllib('libCloud','EC_Connect');
if (err == EDK_OK)
    emotivid = input('EmotivID: ', 's');
    password = input('Password: ', 's');
    err      = calllib('libCloud','EC_Login', emotivid, password);
    if (err ~= EDK_OK)
        disp('Incorrect EmotivID or Password');
        return;
    end
else
    disp('Connect to Emotiv Cloud failed.');
    return;
end


% SDK License
LICENSE = input('License Key: ', 's');
%define license type according to IEE_LicenseType (EmotivLicense.h)
IEE_EEG    = 1;
IEE_PM     = 2;
IEE_EEG_PM = 3;
%Enter value of debit you want to get
%get Debit info
disp('***************************************************************************');
disp('License Information: ');
IEE_DebitInfos = struct('remainingSessions',0,'total_session_inMonth',0,'total_session_inYear',0);
sp = libpointer('IEE_DebitInfos_struct',IEE_DebitInfos);
result = calllib('libLicense','IEE_GetDebitInformation',LICENSE,sp);
%print result
if (result == EDK_OK)
    if (sp.Value.total_session_inYear > 0)
        X=['Remaining Sessions       ',num2str(sp.Value.remainingSessions)];
        disp(X);
        X=['Total debitable sessions in Year        ' ,num2str(sp.Value.total_session_inYear)];
        disp(X);
    elseif (sp.Value.total_session_inMonth > 0)
        X=['Remaining Sessions       ',num2str(sp.Value.remainingSessions)];
        disp(X);
        X=['Total debitable sessions in Month        ' ,num2str(sp.Value.total_session_inMonth)];
        disp(X);
    else
        X=['Remaining Sessions       : unlimitted'];
        disp(X);
        X=['Total debitable sessions in Month        : unlimitted'];
        disp(X);
    end
    disp(' ');
else
    X=['GET DEBIT INFORMATION UNSUCCESSFULLY! errorcode: ', result];
    disp(X);
end

prompt = 'Please enter number of debit you want to get: ';
debit_num =input(prompt);
    

%% The license error. 
EDK_LICENSE_ERROR = hex2dec('2010');

%The license expried
EDK_LICENSE_EXPIRED = hex2dec('2011');

% The license was not found
EDK_LICENSE_NOT_FOUND = hex2dec('2012');

%% The license is over quota
EDK_OVER_QUOTA = hex2dec('2013');

%% Debit number is invalid
EDK_INVALID_DEBIT_ERROR = hex2dec('2014');

%% Device list of the license is over
EDK_OVER_DEVICE_LIST = hex2dec('2015');

EDK_APP_QUOTA_EXCEEDED = hex2dec('2016');

EDK_APP_INVALID_DATE = hex2dec('2017');

%% Application register device number is exceeded. 
EDK_LICENSE_DEVICE_LIMITED = hex2dec('2019');

%% The license registered with the device. 
EDK_LICENSE_REGISTERED = hex2dec('2020');

%% No license is activated
EDK_NO_ACTIVE_LICENSE = hex2dec('2021');

% The license is updated
EDK_UPDATE_LICENSE = hex2dec('2023');

% Session debit number is more then max of remaining session number
EDK_INVALID_DEBIT_NUMBER = hex2dec('2024');

% Session debit is limited today
EDK_DAILY_DEBIT_LIMITED = hex2dec('2025');
%! One of the parameters supplied to the function is invalid
EDK_INVALID_PARAMETER = hex2dec('0302');

EDK_NO_INTERNET_CONNECTION = hex2dec('2100');

EDK_ACCESS_DENIED = hex2dec('2031');

EDK_UNKNOWN_ERROR = hex2dec('0001');
    
result = calllib('libLicense','IEE_AuthorizeLicense', LICENSE, debit_num) ;

switch (result)

case EDK_INVALID_DEBIT_NUMBER
    disp('Invalid Debit number');
case EDK_INVALID_DEBIT_ERROR
    disp('Invalid number of Debit');
    
case EDK_INVALID_PARAMETER
    disp('Invalid user info') ;
    
case EDK_NO_INTERNET_CONNECTION
    disp('Internet Connection');
    
case EDK_LICENSE_EXPIRED
    disp('License expired') ;
    
case EDK_OVER_DEVICE_LIST
    disp('Over device list') ;
    
case EDK_DAILY_DEBIT_LIMITED
    disp('Over daily debit number') ;
    
case EDK_ACCESS_DENIED
    disp('Access denied') ;
    
case EDK_LICENSE_REGISTERED
    disp('The License has registered') ;
    
case EDK_LICENSE_ERROR
    disp('Error License') ;
    
case EDK_LICENSE_NOT_FOUND
    disp('License not found') ;
    
case EDK_UNKNOWN_ERROR
    disp('unknown error') ;
    
otherwise
    
end
disp('***************************************************************************');
if ((result == EDK_OK) || (result == EDK_LICENSE_REGISTERED))
    IEE_LicenseInfos = struct('scopes',0,'date_from',0,'date_to',0,'soft_limit_date',0,'hard_limit_date',0,'seat_count',0,'usedQuota',0,'quota',0);
    sp               = libpointer('IEE_LicenseInfos_struct', IEE_LicenseInfos);
    [xobj,xval]      = calllib('libLicense','IEE_LicenseInformation', sp);
    
    if (sp.Value.scopes == IEE_EEG)
        licensetype = 'EEG';
    elseif (sp.Value.scopes == IEE_PM)
        licensetype = 'PM';
    elseif (sp.Value.scopes == IEE_EEG_PM)
        licensetype = 'EEG+PM';
    end
    X   = ['License type      : ',licensetype];
    disp(X);
    %convert time
    utc = sp.Value.date_from;
    
    X   = ['From date         : ',datestr(datenum([1970, 1, 1, 0, 0, utc])),' GMT'];
    disp(X);
    utc = sp.Value.date_to;
    X   = ['To date           : ',datestr(datenum([1970, 1, 1, 0, 0, utc])),' GMT'];
    disp(X);
    
    utc = sp.Value.soft_limit_date;
    X   = ['Soft Limit Date   : ', datestr(datenum([1970, 1, 1, 0, 0, utc])),' GMT'];
    disp(X);
    
    utc = sp.Value.hard_limit_date;
    X   = ['Hard Limit Date   : ', datestr(datenum([1970, 1, 1, 0, 0, utc])),' GMT'];
    disp(X);
    
    X = ['Number of seat    : ',num2str(sp.Value.seat_count)];
    disp(X);
    
    X = ['Used Quotas       : ' ,num2str(sp.Value.usedQuota)];
    disp(X);
    X = ['Total Quotas      : ' ,num2str(sp.Value.quota)];
    disp(X);
end

disp('******************************* END ***************************************');