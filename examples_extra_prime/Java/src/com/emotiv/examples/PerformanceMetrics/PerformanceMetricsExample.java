/***************************
 Performance Metrics Example
 Emotiv SDK 3.5
 ***************************/

package com.emotiv.examples.PerformanceMetrics;

import com.emotiv.Iedk.Edk;
import com.emotiv.Iedk.EdkErrorCode;
import com.emotiv.Iedk.EmoState;
import com.emotiv.Iedk.PerformanceMetrics;
import com.sun.jna.Pointer;
import com.sun.jna.ptr.*;
import java.util.HashMap;
import java.util.Iterator;


public class PerformanceMetricsExample {

    // Get calculated PM score from scaled PM scores
    private static float getCalculatedScore(DoubleByReference raw, DoubleByReference min, DoubleByReference max) {
        float score = 0;
        System.out.printf("Performance Metrics: raw %5.2f, max %5.2f, min %5.2f \n", raw.getValue(), max.getValue(), min.getValue());
        if (raw.getValue() < min.getValue()) {
            score = 0;
        } else if (raw.getValue() > max.getValue()) {
            score = 1;
        } else if (max.getValue() == min.getValue()){
            score = (float) ((raw.getValue() - min.getValue()) / (max.getValue() - min.getValue()));
        }
        else
        {
        	score = 0;
        }
        return score;
    }

    // Get calculated PM score
    private static HashMap getScaledPerformanceMetricsScore(Pointer eState) {
        HashMap<String, Float> finalScores = new HashMap<String,Float>();
        DoubleByReference ptrRawScore = new DoubleByReference(0);
        DoubleByReference ptrMinScale = new DoubleByReference(0);
        DoubleByReference ptrMaxScale = new DoubleByReference(0);
         

        PerformanceMetrics.INSTANCE.IS_PerformanceMetricGetStressModelParams(eState, ptrRawScore, ptrMinScale, ptrMaxScale);
        finalScores.put("Stress", (getCalculatedScore(ptrRawScore, ptrMinScale, ptrMaxScale)));

        PerformanceMetrics.INSTANCE.IS_PerformanceMetricGetEngagementBoredomModelParams(eState, ptrRawScore, ptrMinScale, ptrMaxScale);
        finalScores.put("EngagementBoredom", getCalculatedScore(ptrRawScore, ptrMinScale, ptrMaxScale));

        PerformanceMetrics.INSTANCE.IS_PerformanceMetricGetRelaxationModelParams(eState, ptrRawScore, ptrMinScale, ptrMaxScale);
        finalScores.put("Relaxation", getCalculatedScore(ptrRawScore, ptrMinScale, ptrMaxScale));

        PerformanceMetrics.INSTANCE.IS_PerformanceMetricGetInstantaneousExcitementModelParams(eState, ptrRawScore, ptrMinScale, ptrMaxScale);
        finalScores.put("InstantaneousExcitement", getCalculatedScore(ptrRawScore, ptrMinScale, ptrMaxScale));

        PerformanceMetrics.INSTANCE.IS_PerformanceMetricGetInterestModelParams(eState, ptrRawScore, ptrMinScale, ptrMaxScale);
        finalScores.put("Interest", getCalculatedScore(ptrRawScore, ptrMinScale, ptrMaxScale));

        return finalScores;
    }

    public static void main(String[] args) {
        final long NANOSEC_PER_SEC = 1000L * 1000 * 1000;
        // 60 seconds run time
        final long RUN_TIME = 60 * NANOSEC_PER_SEC;

        float timeStamp = 0;
        int errorCode = 0;
        int state;
        int eventType;
        HashMap<String, Float> scores;
        boolean isUserAdded = false;
        Pointer ptrEnginEvent = Edk.INSTANCE.IEE_EmoEngineEventCreate();
        Pointer ptrEngineState = Edk.INSTANCE.IEE_EmoStateCreate();
        IntByReference ptrUserID = new IntByReference();

        System.out.println("Performance Metrics Example");

        errorCode = Edk.INSTANCE.IEE_EngineConnect("Emotiv Systems-5");

        long startTime = System.nanoTime();
        //(System.nanoTime() - startTime) <  RUN_TIME

        while (true){
            state = Edk.INSTANCE.IEE_EngineGetNextEvent(ptrEnginEvent);
            if (state == EdkErrorCode.EDK_OK.ToInt()) {
                eventType = Edk.INSTANCE.IEE_EmoEngineEventGetType(ptrEnginEvent);
                errorCode = Edk.INSTANCE.IEE_EmoEngineEventGetUserId(ptrEnginEvent, ptrUserID);

                if (!isUserAdded) {
                    if (eventType == Edk.IEE_Event_t.IEE_UserAdded.ToInt()) {
                        if (ptrUserID != null) {
                            // Note:
                            // If headset is connected via Emotiv Universal Dongle, ptrUserID.getValue() will be
                            // DONGLE_STREAM_MASK   = 0x1000;
                            // If headset is connected via Bluetooth, ptrUserID.getValue() will be
                            // BTLE_STREAM_MASK     = 0x2000;
                            System.out.format("User Added: %d \n", ptrUserID.getValue());
                            if (ptrUserID.getValue() != 0) {
                                isUserAdded = true;
                            }
                        }
                    }
                    
                } else {
                    if (eventType == Edk.IEE_Event_t.IEE_EmoStateUpdated.ToInt()) {
                        timeStamp = EmoState.INSTANCE.IS_GetTimeFromStart(ptrEngineState);
                        System.out.format("Time stamp (s): %7.3f --- ", timeStamp);
                        errorCode = Edk.INSTANCE.IEE_EmoEngineEventGetEmoState(ptrEnginEvent, ptrEngineState);
                        scores = getScaledPerformanceMetricsScore(ptrEngineState);
                        Iterator it = scores.entrySet().iterator();
                        while (it.hasNext()) {
                            HashMap.Entry pair = (HashMap.Entry) it.next();
                            // Note: un-licensed PC will get 0 scores in first 10 seconds run time
                            System.out.format("%s: %3.3f,\t", pair.getKey(), pair.getValue());
                            it.remove();
                        }
                        System.out.println();
                    }
                    else if(eventType == Edk.IEE_Event_t.IEE_UserRemoved.ToInt())
                    {
                    	System.out.format("User Removed: %d \n", ptrUserID.getValue());
                    	break;
                    }
                }
            }
        }
        System.out.println("Disconnected!");

        Edk.INSTANCE.IEE_EngineDisconnect();
        Edk.INSTANCE.IEE_EmoStateFree(ptrEngineState);
        Edk.INSTANCE.IEE_EmoEngineEventFree(ptrEnginEvent);
        
    }
}
