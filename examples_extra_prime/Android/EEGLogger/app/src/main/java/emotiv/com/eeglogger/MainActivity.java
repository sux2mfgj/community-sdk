// Restart headset + app if it takes more than 10 seconds to connect.
// To get raw EEG data from Android phone, you need to have at least one session available (demonstrated in Activate Liecense).
// Each time you run this example, one session will be consumed. It's highly recommended to use [PRO license](https://www.emotiv.com/developer/) while developing with Emotiv SDK.
// This project can only be built/run on real Android phone.

package emotiv.com.eeglogger;

import android.Manifest;
import android.annotation.SuppressLint;
import android.graphics.Color;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.emotiv.bluetooth.Emotiv;
import com.emotiv.sdk.*;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;

public class MainActivity extends AppCompatActivity {
    TextView HeadsetStatus, IsRecording, FileLocation;
    Button StartRecording, StopRecording;

    private static final int MY_PERMISSIONS_REQUEST = 0;

    private boolean lock = false;
    private boolean isEnablGetData = false;
    private boolean isEnableWriteFile = false;

    private SWIGTYPE_p_void EventHandlerPtr;
    private SWIGTYPE_p_void DataHandlerPtr;
    private SWIGTYPE_p_unsigned_int SamplesCountPtr;
    private SWIGTYPE_p_double data;
    private int UserID;

    private BufferedWriter dataWriter;
    private IEE_DataChannel_t[] Channel_list;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);



        HeadsetStatus = (TextView) findViewById(R.id.tvHeadsetStatus);
        IsRecording = (TextView) findViewById(R.id.tvIsRecording);
        FileLocation = (TextView) findViewById(R.id.tvFileLocation);

        StartRecording = (Button) findViewById(R.id.btnStartRecording);
        StopRecording = (Button) findViewById(R.id.btnStopRecording);

        ActivityCompat.requestPermissions(this, new String[] {
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN}, MY_PERMISSIONS_REQUEST);


        // Init -----------------------------------------
        Emotiv.IEE_EmoInitDevice(this);
        Log.e("Test","IEE_EmoInitDevice");
        edkJava.IEE_EngineConnect("Emotiv Systems-5");
        Log.e("Test","IEE_EngineConnect");

        // ----------------------------------------------

        HeadsetStatus.setText("Connecting to headset");
        StartRecording.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Log.e("Start recording", "Clicked!");
                startRecording();
                isEnableWriteFile = true;
            }
        });

        StopRecording.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                stopRecording();
                isEnableWriteFile = false;
            }
        });

        Channel_list = new IEE_DataChannel_t[] {IEE_DataChannel_t.IED_COUNTER, IEE_DataChannel_t.IED_INTERPOLATED, IEE_DataChannel_t.IED_AF3,
                IEE_DataChannel_t.IED_F7, IEE_DataChannel_t.IED_F3, IEE_DataChannel_t.IED_FC5, IEE_DataChannel_t.IED_T7,
                IEE_DataChannel_t.IED_O1, IEE_DataChannel_t.IED_O2, IEE_DataChannel_t.IED_P8, IEE_DataChannel_t.IED_T8,
                IEE_DataChannel_t.IED_FC6, IEE_DataChannel_t.IED_F4, IEE_DataChannel_t.IED_F8, IEE_DataChannel_t.IED_AF4,
                IEE_DataChannel_t.IED_RAW_CQ, IEE_DataChannel_t.IED_GYROX, IEE_DataChannel_t.IED_GYROY, IEE_DataChannel_t.IED_MARKER, IEE_DataChannel_t.IED_TIMESTAMP};

        EventHandlerPtr = edkJava.IEE_EmoEngineEventCreate();
        DataHandlerPtr = edkJava.IEE_DataCreate();

        edkJava.IEE_DataSetBufferSizeInSec(0.5f);

        SamplesCountPtr = edkJava.new_uint_p();

        Thread processingThread = new Thread()
        {
            @Override
            public void run() {
                Log.e("processingThread", "Running");
                super.run();
                while(true) {
                    try {
                        handler.sendEmptyMessage(0);
                        handler.sendEmptyMessage(1);

                        if(isEnablGetData && isEnableWriteFile) {
                            handler.sendEmptyMessage(2);
                        }
                        Thread.sleep(5);
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }
                }
            }
        };
        processingThread.start();
    }

    @SuppressLint("HandlerLeak")
    Handler handler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case 0: {
                    int state = edkJava.IEE_EngineGetNextEvent(EventHandlerPtr);
                    if (state == edkJava.EDK_OK) {
                        IEE_Event_t eventType = edkJava.IEE_EmoEngineEventGetType(EventHandlerPtr);
                        switch (eventType) {
                            case IEE_UserAdded: {
                                Log.e("SDK", "User added");
                                SWIGTYPE_p_unsigned_int pEngineId = edkJava.new_uint_p();
                                int result = edkJava.IEE_EmoEngineEventGetUserId(EventHandlerPtr, pEngineId);
                                UserID = (int) edkJava.uint_p_value(pEngineId);
                                edkJava.delete_uint_p(pEngineId);
                                edkJava.IEE_DataAcquisitionEnable(UserID, true);

                                isEnablGetData = true;
                                HeadsetStatus.setText("Connected!");
                                HeadsetStatus.setTextColor(Color.GREEN);
                            }
                            break;
                            case IEE_UserRemoved: {
                                Log.e("SDK", "User removed");
                                isEnablGetData = false;
                                HeadsetStatus.setText("Disconnected!");
                                HeadsetStatus.setTextColor(Color.BLACK);
                                IsRecording.setText("N/A");
                            }
                            break;
                        }
                    }
                    break;
                }
                case 1:
                {
                    // Try to connect to any available Insight headset first, then EPOC+
				    /*Connect device with Insight headset*/
                    int number = Emotiv.IEE_GetInsightDeviceCount();
                    if (number != 0) {
                        Log.e("Number of Insight: ", "" + number);
                        if (!lock) {
                            lock = true;
                            Emotiv.IEE_ConnectInsightDevice(0);
                        }
                    } else {
                        //--------------------------------------
				        // Connect device with EPOC Plus headset
                        number = Emotiv.IEE_GetEpocPlusDeviceCount();
                        if (number != 0) {
                            Log.e("Number of EPOC+: ", "" + number);
                            if (!lock) {
                                lock = true;
                                Emotiv.IEE_ConnectEpocPlusDevice(0, false);
                            } else lock = false;
                        }
                        //--------------------------------------
                    }
                }
                break;
                case 2: {
                    if (dataWriter == null) {
                        return;
                    }
                    edkJava.IEE_DataUpdateHandle(UserID, DataHandlerPtr);
                    edkJava.IEE_DataGetNumberOfSample(DataHandlerPtr, SamplesCountPtr);
                    int SamplesCount = (int) edkJava.uint_p_value(SamplesCountPtr);
                    Log.e("Number of sample: ", String.valueOf(SamplesCount));
                    if (SamplesCount > 0) {
                        IsRecording.setText("Getting EEG Data");
                        data = edkJava.new_double_array(SamplesCount);
                        for (int i = 0; i < SamplesCount; i++) {
                            try {
                                for (IEE_DataChannel_t channel : Channel_list) {
                                    edkJava.IEE_DataGet(DataHandlerPtr, channel, data, SamplesCount);
                                    dataWriter.write(String.valueOf(edkJava.double_array_getitem(data, i)) + ",");
                                }
                                dataWriter.newLine();
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                        data = null;
                    }
                }
                break;
            }
        }

    };

    private void startRecording() {
        try {
            Log.e("Prepare file", "");
            DateFormat df = new SimpleDateFormat("yyyy-MM-dd'-'HH:mm:ss", Locale.US);
            String date = df.format(Calendar.getInstance().getTime());

            String eeg_header = "IED_COUNTER, IED_INTERPOLATED, IED_AF3, IED_F7, IED_F3, IED_FC5, IED_T7, IED_O1, IED_O2, IED_P8, IED_T8, IED_FC6, IED_F4, IED_F8, IED_AF4, IED_RAW_CQ, IED_GYROX, IED_GYROY, IED_MARKER, IED_TIMESTAMP ";
            File root = Environment.getExternalStorageDirectory();
            String filePath = root.getAbsolutePath()+ "/EegLogger/";
            File folder = new File(filePath);

            filePath += "EegLogger" + date + ".csv";
            FileLocation.setText(filePath);

            if(!folder.exists()) {
                folder.mkdirs();
            }
            dataWriter = new BufferedWriter(new FileWriter(filePath));
            dataWriter.write(eeg_header);
            dataWriter.newLine();


        } catch (Exception e) {
            Log.e("","Exception"+ e.getMessage());
            e.printStackTrace();
        }
    }

    private void stopRecording() {
        SamplesCountPtr = null;
        try {
            dataWriter.flush();
            dataWriter.close();
            dataWriter = null;
            IsRecording.setText("N/A");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        edkJava.delete_double_p(data);
        edkJava.delete_uint_p(SamplesCountPtr);
    }
}
