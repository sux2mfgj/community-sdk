
// Emotiv Activate License Example - Android SDK 3.5
// Tested on Nexus 6 - Android 7.1.1
// Work with real phone only


package emotiv.com.emotivactivatelicenseexample;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.v4.app.ActivityCompat;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.emotiv.bluetooth.Emotiv;
import com.emotiv.sdk.IEE_LicenseInfos_t;
import com.emotiv.sdk.SWIGTYPE_p_int;
import com.emotiv.sdk.edkJava;
import com.emotiv.sdk.edkJavaJNI;

import java.text.SimpleDateFormat;
import java.util.Date;

import static com.emotiv.sdk.edkJavaConstants.EDK_OK;


public class MainActivity extends Activity {
    Button btnRefresh, btnAuthorize, btnLogin, btnSetActive;
    EditText EmotivID, Password, LicenseKey, DebitNumber;
    TextView licenseType, sessions, usedSession, seats, fromDate, toDate, softLimitDate, hardLimitDate;
    TextView status;

    private static final int MY_PERMISSIONS_REQUEST = 1;

    boolean isUserLoggedIn = false;
    boolean isLicenseAuthorized = false;
    boolean isLicenseSetActivated = false;
    boolean isRefreshed = false;

    IEE_LicenseInfos_t licenseInfos;

    int UserID;
    int err;



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btnRefresh = (Button) findViewById(R.id.btnRefresh);
        btnAuthorize = (Button) findViewById(R.id.btnAuthorize);
        btnLogin = (Button) findViewById(R.id.btnLogin);
        btnSetActive = (Button) findViewById(R.id.btnSetActive);

        btnAuthorize.setEnabled(false);

        EmotivID = (EditText) findViewById(R.id.EmotivID);
        Password = (EditText) findViewById(R.id.Password);
        LicenseKey = (EditText) findViewById(R.id.LicenseKey);
        DebitNumber = (EditText) findViewById(R.id.DebitNumber);

        licenseType = (TextView) findViewById(R.id.tvLicenseTypeVal);
        sessions = (TextView) findViewById(R.id.tvSessionsVal);
        usedSession = (TextView) findViewById(R.id.tvUsedSessionsVal);
        seats = (TextView) findViewById(R.id.tvSeatsVal);
        fromDate = (TextView) findViewById(R.id.tvFromDateVal);
        toDate = (TextView) findViewById(R.id.tvToDateVal);
        softLimitDate = (TextView) findViewById(R.id.tvSoftLimitDateVal);
        hardLimitDate = (TextView) findViewById(R.id.tvHardLimitDateVal);

        status = (TextView) findViewById(R.id.tvStatus);
        status.setText("Status");

        ActivityCompat.requestPermissions(this, new String[]{
                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
                        Manifest.permission.INTERNET,
                        Manifest.permission.ACCESS_FINE_LOCATION},
                        MY_PERMISSIONS_REQUEST);


        btnRefresh.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!isRefreshed) {
                    new Thread() {
                        @Override
                        public void run() {
                            checkLicenseInfo();
                        }
                    }.start();
                }

            }

        });

        btnSetActive.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                setLicenseActive();
            }
        });

        btnLogin.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if(!isUserLoggedIn) {
                    new Thread() {
                        @Override
                        public void run() {
                            login();
                        }
                    }.start();

                } else {
                    new Thread() {
                        @Override
                        public void run() {
                            logout();
                        }
                    }.start();
                }
            }
        });

        btnAuthorize.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                new Thread() {
                    @Override
                    public void run() {
                        authorizeLicense();
                    }
                }.start();

                runOnUiThread(new Runnable(){
                    @Override
                    public void run(){
                        // change UI elements here
                        btnAuthorize.setText("Authorizing");
                        btnAuthorize.setEnabled(false);
                    }
                });
            }
        });

        boolean deviceInit = Emotiv.IEE_EmoInitDevice(this);
        Log.e("IEE_EmoInitDevice",""+ deviceInit);
        err = edkJava.IEE_EngineConnect("Emotiv Systems-5");
        Log.e("IEE_EngineConnect","" + err);
        err = edkJava.EC_Connect();
        Log.e("EC_Connect","" + err);

        Thread processingThread = new Thread()
        {
            @Override
            public void run() {
                Log.e("processingThread", "Running");
                super.run();

                while(true) {
                    try {
                        if (isUserLoggedIn) {
                            handler.sendEmptyMessage(0);
                        }
                        if (isLicenseAuthorized) {
                            handler.sendEmptyMessage(1);
                            isLicenseAuthorized = false;
                        }
                        if (isLicenseSetActivated) {
                            handler.sendEmptyMessage(2);
                            isLicenseSetActivated = false;
                        }
                        if (isRefreshed) {
                            handler.sendEmptyMessage(3);
                            isRefreshed = false;
                        }
                        Thread.sleep(1000);
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }
                }
            }
        };
        processingThread.start();
    }

    public void login() {
        SWIGTYPE_p_int userPtr = edkJava.new_int_p();
        Log.e("EC_Login","Logging in");
        Log.e("EmotivID: " + EmotivID.getText().toString().trim(),"Password: "+ Password.getText().toString());
        try {
            int err = edkJava.EC_Login(EmotivID.getText().toString().trim(), Password.getText().toString());
            if (err == EDK_OK) {
                Log.e("EC_Login","PASSED");
                UserID =  edkJava.EC_GetUserDetail(userPtr);
                isUserLoggedIn = true;
            } else {
                isUserLoggedIn = false;
                runOnUiThread(new Runnable(){
                    @Override
                    public void run(){
                        // change UI elements here
                        status.setText("Failed to login");
                        checkLicenseInfo();
                    }
                });
            }

        } catch (Exception e) {
            Log.e("EC_Login","Failed to login, check EmotivID, Password, Internet");
            e.printStackTrace();
        }
        edkJava.delete_int_p(userPtr);

    }

    public void logout() {
        if (isUserLoggedIn) {
            if(edkJava.EC_Logout(UserID) == EDK_OK) {
                isUserLoggedIn = false;
                runOnUiThread(new Runnable(){
                    @Override
                    public void run(){
                        // change UI elements here
                        btnLogin.setText("login");
                    }
                });
            } else {
                runOnUiThread(new Runnable(){
                    @Override
                    public void run(){
                        // change UI elements here
                        status.setText("Failed to logout");
                        checkLicenseInfo();
                    }
                });
            }
        }
    }


    // Check local authorized license
    public void checkLicenseInfo() {
        licenseInfos = new IEE_LicenseInfos_t();
        err = edkJava.IEE_LicenseInformation(licenseInfos);
        if (err == EDK_OK) {
            isRefreshed = true;
        } else {
            Log.e("IEE_LicenseInformation", " " + err);
            isRefreshed = false;
        }

    }

    // If this phone has more than one authorized license, you can select which license will be used (consume local session) via IEE_SetActiveLicense function
    public void setLicenseActive () {
        String license = LicenseKey.getText().toString().trim();
        try {
            err = edkJava.IEE_SetActiveLicense(license);
            if (err == EDK_OK) {
                isLicenseSetActivated = true;
            } else {
                Log.e("IEE_SetActiveLicense " + license, " " + err);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void authorizeLicense() {
        long debitNumber = (DebitNumber.getText().toString() != "0") ? Long.parseLong(DebitNumber.getText().toString()) : 0;
        Log.e("debitNumber", " " + debitNumber);
        Log.e("LicenseKey", " " + LicenseKey.getText().toString());
        int err = edkJava.IEE_AuthorizeLicense(LicenseKey.getText().toString().trim(), debitNumber);
        if (err == EDK_OK) {
            isLicenseAuthorized = true;
        }
    }


    // Update UI
    @SuppressLint("HandlerLeak")
    Handler handler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                // Logged In
                case 0: {
                    runOnUiThread(new Runnable(){
                        @Override
                        public void run(){
                            // change UI elements here
                            if (isUserLoggedIn) {
                                btnLogin.setText("LOGOUT");
                                btnLogin.setEnabled(true);
                                btnAuthorize.setEnabled(true);
                            } else {
                                btnLogin.setText("login");
                                btnLogin.setEnabled(true);
                                btnAuthorize.setEnabled(true);
                            }

                        }
                    });
                }
                break;

                // Authorized
                case 1: {
                    runOnUiThread(new Runnable(){
                        @Override
                        public void run(){
                            // change UI elements here
                            btnAuthorize.setEnabled(true);
                            btnAuthorize.setText("Authorize");
                            status.setText("Authorized successfully");
                            DebitNumber.setText("");
                            DebitNumber.setHint("Done!");
                            checkLicenseInfo();
                        }
                    });
                }
                break;

                // Set license in-active
                case 2: {
                    runOnUiThread(new Runnable(){
                        @Override
                        public void run(){
                            // change UI elements here
                            status.setText("License Activated");
                            checkLicenseInfo();
                        }
                    });
                }
                break;

                // Refresh license info
                case 3: {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            // change UI elements here
                            btnRefresh.setClickable(true);
                            if (licenseInfos.getQuota() <= 0) {
                                licenseType.setText("Basic License");
                            } else {
                                long scope = licenseInfos.getScopes();
                                if (scope == edkJavaJNI.IEE_EEG_get()) {
                                    licenseType.setText("EEG License");
                                } else if (scope == edkJavaJNI.IEE_PM_get()) {
                                    licenseType.setText("PM License");
                                } else if (scope == edkJavaJNI.IEE_EEG_PM_get()) {
                                    licenseType.setText("EEG + PM License");
                                }
                                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
                                sessions.setText(String.valueOf(licenseInfos.getQuota()));
                                usedSession.setText(String.valueOf(licenseInfos.getUsedQuota()));
                                seats.setText(String.valueOf(licenseInfos.getSeat_count()));

                                // Got seconds since the epoch, multiply by 1000.
                                fromDate.setText(sdf.format(new Date(1000 * licenseInfos.getDate_from())));
                                toDate.setText(sdf.format(new Date(1000 * licenseInfos.getDate_to())));
                                softLimitDate.setText(sdf.format(new Date(1000 * licenseInfos.getSoft_limit_date())));
                                hardLimitDate.setText(sdf.format(new Date(1000 * licenseInfos.getHard_limit_date())));
                            }
                        }
                    });
                }
                break;
            }
        }
    };

        @Override
    protected void onResume() {
        super.onResume();
        checkLicenseInfo();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        edkJava.IEE_EngineDisconnect();
    }

}
