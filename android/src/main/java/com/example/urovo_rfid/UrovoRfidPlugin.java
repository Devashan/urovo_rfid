package com.example.urovo_rfid;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.ubx.usdk.USDKManager;
import com.ubx.usdk.bean.RfidParameter;
import com.ubx.usdk.rfid.RfidManager;
import com.ubx.usdk.rfid.aidl.IRfidCallback;

import org.json.JSONObject;

import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * UrovoRfidPlugin
 *
 * <p>This implementation wires the Urovo RFID SDK to a Flutter method channel and
 * event channel.  The code handles initialization, inventory start/stop, tag
 * read/write and various configuration options.  Events from the underlying
 * reader are delivered to Flutter via the EventChannel.  The method names
 * mirror those exposed through the Dart platform interface found under lib/
 * in this plugin.
 */
public class UrovoRfidPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
    // Event name used for the event channel.  This matches the stream identifier
    // used in lib/urovo_rfid_method_channel.dart.
    private static final String EVENT_NAME = "urovo_rfid/events";

    // Various event keys emitted via the event channel.
    private static final String EVENT_INIT = "event_init";
    private static final String EVENT_INVENTORY_TAG = "event_inventory_tag";
    private static final String EVENT_INVENTORY_TAG_END = "event_inventory_tag_end";

    // Unified error code used when arguments are missing or an operation fails.
    private static final int ERR_CODE = -19;

    private final String TAG = UrovoRfidPlugin.class.getSimpleName();
    private Activity activity;
    private USDKManager usdkManager;
    private RfidManager rfidManager;

    /// The MethodChannel that facilitates communication between Flutter and native Android.
    private MethodChannel channel;
    // Event sink used to dispatch asynchronous events back to Flutter.
    private EventChannel.EventSink eventSink = null;

    // Callback implementation used by the Urovo SDK to deliver inventory data.
    private final IRfidCallback rfidCallback = new IRfidCallback() {
        @Override
        public void onInventoryTag(String EPC, String TID, String strRSSI) {
            try {
                JSONObject jsonObject = new JSONObject();
                jsonObject.put("epc", EPC);
                jsonObject.put("tid", TID);
                jsonObject.put("rssi", strRSSI);
                sendEvent(getMap(EVENT_INVENTORY_TAG, jsonObject.toString()));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        @Override
        public void onInventoryTagEnd() {
            sendEvent(getMap(EVENT_INVENTORY_TAG_END, ""));
        }
    };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        // Set up the method channel.  Calls from Flutter are mapped here.
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "urovo_rfid");
        channel.setMethodCallHandler(this);
        // Create the event channel and associate a stream handler to manage the event sink.
        initEventSink(flutterPluginBinding);
        // Obtain the shared USDKManager instance using the application context.  Note that
        // the SDK will not be fully initialized until init() is invoked.
        usdkManager = USDKManager.getInstance(flutterPluginBinding.getApplicationContext());
    }

    /**
     * Set up the EventChannel and stream handler.  Flutter will subscribe to this channel
     * to receive asynchronous inventory data.  We store the received EventSink so that
     * sendEvent() can dispatch events to Flutter on the main thread.
     */
    private void initEventSink(FlutterPluginBinding flutterPluginBinding) {
        EventChannel eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), EVENT_NAME);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String method = call.method;
        if ("init".equals(method)) {
            init();
            return;
        } else if ("release".equals(method)) {
            release();
            result.success(null);
            return;
        }
        // If the reader has not been initialized, bail out.
        if (!checkInit(result)) {
            return;
        }
        switch (method) {
            case "startInventory": {
                Integer session = call.argument("session");
                startInventory(session, result);
                break;
            }
            case "stopInventory": {
                stopInventory(result);
                break;
            }
            case "readTag": {
                readTag(call, result);
                break;
            }
            case "writeTag": {
                writeTag(call, result);
                break;
            }
            case "writeTagEpc": {
                writeTagEpc(call, result);
                break;
            }
            case "getOutputPower": {
                getOutputPower(result);
                break;
            }
            case "setOutputPower": {
                setOutputPower(call, result);
                break;
            }
            case "setInventoryParameter": {
                setInventoryParameter(call);
                result.success(null);
                break;
            }
            case "enableScanHead": {
                enableScanHead(call, result);
                break;
            }
            case "getPlatformVersion": {
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    /**
     * Initialize the RFID manager.  Once complete the SDK will call back with a status
     * indicating whether initialization succeeded.  If successful, we obtain the
     * RfidManager instance and dispatch an init event to Flutter with a result of `0`
     * representing success or `-1` for failure.
     */
    private void init() {
        if (usdkManager == null) {
            return;
        }
        usdkManager.init(activity, status -> {
            if (status == USDKManager.STATUS.SUCCESS) {
                rfidManager = usdkManager.getRfidManager();
            }
            int initResult = status == USDKManager.STATUS.SUCCESS ? 0 : -1;
            sendEvent(getMap(EVENT_INIT, initResult));
        });
    }

    /**
     * Release SDK resources when the plugin is detached.  This should be called when the
     * Flutter engine shuts down or when the plugin is no longer in use.
     */
    private void release() {
        if (rfidManager != null) {
            rfidManager.release();
            rfidManager = null;
        }
        if (usdkManager != null) {
            usdkManager.release();
        }
    }

    /**
     * Verify that the rfidManager has been initialized.  If not, report an error to the
     * Flutter caller via the provided result and return false.
     */
    private boolean checkInit(Result result) {
        if (rfidManager == null) {
            Log.d(TAG, "rfidManager == null");
            result.error(String.valueOf(ERR_CODE), "RFIDManager was not inited", null);
            return false;
        }
        return true;
    }

    private void startInventory(Integer session, Result result) {
        // Register the callback before starting inventory so that tag data events are received.
        rfidManager.registerCallback(rfidCallback);
        int ret = rfidManager.startInventory((byte) (session == null ? 0 : session));
        result.success(ret);
    }

    private void stopInventory(Result result) {
        int ret = rfidManager.stopInventory();
        result.success(ret);
    }

    private void readTag(MethodCall call, Result result) {
        String epc = call.argument("epc");
        Integer memBank = call.argument("memBank");
        Integer wordAdd = call.argument("wordAdd");
        Integer wordCnt = call.argument("wordCnt");
        byte[] password = call.argument("password");
        if (memBank == null || wordAdd == null || wordCnt == null) {
            result.success(ERR_CODE);
            return;
        }
        String ret = rfidManager.readTag(epc, memBank.byteValue(),
                wordAdd.byteValue(), wordCnt.byteValue(), password);
        result.success(ret);
    }

    private void writeTag(MethodCall call, Result result) {
        String epc = call.argument("epc");
        byte[] password = call.argument("password");
        Integer memBank = call.argument("memBank");
        Integer wordAdd = call.argument("wordAdd");
        Integer wordCnt = call.argument("wordCnt");
        byte[] data = call.argument("data");
        if (memBank == null || wordAdd == null || wordCnt == null) {
            result.success(ERR_CODE);
            return;
        }
        int ret = rfidManager.writeTag(epc, password, memBank.byteValue(),
                wordAdd.byteValue(), wordCnt.byteValue(), data);
        result.success(ret);
    }

    private void writeTagEpc(MethodCall call, Result result) {
        String epc = call.argument("epc");
        String password = call.argument("password");
        String data = call.argument("data");
        int ret = rfidManager.writeTagEpc(epc, password, data);
        result.success(ret);
    }

    private void getOutputPower(Result result) {
        int ret = rfidManager.getOutputPower();
        result.success(ret);
    }

    private void setOutputPower(MethodCall call, Result result) {
        Integer power = call.argument("power");
        if (power == null) {
            result.success(ERR_CODE);
            return;
        }
        int ret = rfidManager.setOutputPower(power.byteValue());
        result.success(ret);
    }

    private void setInventoryParameter(MethodCall call) {
        // Parameters are passed as a JSON string in the call argument "params".
        String paramsJson = call.argument("params");
        if (paramsJson == null) {
            return;
        }
        RfidParameter rfidParameter = new Gson().fromJson(paramsJson, RfidParameter.class);
        if (rfidParameter != null) {
            rfidManager.setInventoryParameter(rfidParameter);
        }
    }

    private void enableScanHead(MethodCall call, Result result) {
        Boolean enable = call.argument("enable");
        if (enable != null && usdkManager != null) {
            // Enable or disable the handheld scanning head light.
            usdkManager.enableScanHead(enable);
        }
        result.success(null);
    }

    /** Helper to build a map for dispatching events to Flutter. */
    private HashMap getMap(String event, Object result) {
        HashMap map = new HashMap<>();
        map.put(event, result);
        return map;
    }

    /** Dispatch a map to Flutter on the main thread. */
    private void sendEvent(HashMap map) {
        new Handler(Looper.getMainLooper()).post(() -> {
            if (eventSink != null) {
                eventSink.success(map);
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    // ActivityAware callbacks
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // no-op
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        release();
    }
}