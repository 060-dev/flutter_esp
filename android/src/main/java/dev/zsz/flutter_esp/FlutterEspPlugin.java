package dev.zsz.flutter_esp;

import static dev.zsz.flutter_esp.models.ErrorCodes.BAD_ARGUMENTS;
import static dev.zsz.flutter_esp.models.ErrorCodes.BT_CREATE_FAILED;
import static dev.zsz.flutter_esp.models.ErrorCodes.CONNECTION_FAILED;
import static dev.zsz.flutter_esp.models.ErrorCodes.MISSING_POP;
import static dev.zsz.flutter_esp.models.ErrorCodes.NO_DEVICE_SELECTED;

import android.util.Log;

import androidx.annotation.NonNull;

import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPDevice;
import com.espressif.provisioning.ESPProvisionManager;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;

import dev.zsz.flutter_esp.models.DefineDeviceArguments;
import dev.zsz.flutter_esp.models.ProvisionArguments;
import dev.zsz.flutter_esp.services.ProvisionListenerImpl;
import dev.zsz.flutter_esp.services.ResponseListenerImpl;
import dev.zsz.flutter_esp.services.SearchForDeviceHandler;
import dev.zsz.flutter_esp.services.WiFiScanListenerImpl;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * FlutterEspPlugin
 */
public class FlutterEspPlugin implements FlutterPlugin, MethodCallHandler {

    private static final String TAG = FlutterEspPlugin.class.getSimpleName();

    /**
     * The MethodChannel that will the communication between Flutter and native Android.
     * <p>
     * This local reference serves to register the plugin with the Flutter Engine and unregister it
     * when the Flutter Engine is detached from the Activity.
     */
    private MethodChannel channel;
    /**
     * The ESP Provision Manager instance.
     * <p>
     * The provision manager stores the current ESPDevice and have all the methods necessary for
     * provisioning
     */
    private ESPProvisionManager provisionManager;
    /**
     * The Flutter Plugin callback for the connection method.
     * <p>
     * When running the connection method, the Flutter Plugin callback must be stored to be called
     * when the connection is established
     */
    private Result connectionResult = null;

    // Plugin lifecycle methods ---------------------------------------------------------------
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_esp");
        channel.setMethodCallHandler(this);

        provisionManager = ESPProvisionManager.getInstance(flutterPluginBinding.getApplicationContext());

        EventBus.getDefault().register(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    // Method call handler --------------------------------------------------------------------
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "createBluetoothDevice":
                DefineDeviceArguments defineDeviceArguments;
                try {
                    defineDeviceArguments = DefineDeviceArguments.fromMap(call.arguments);
                } catch (Exception e) {
                    result.error(BAD_ARGUMENTS, e.getMessage(), null);
                    return;
                }
                btCreate(result, defineDeviceArguments.name, defineDeviceArguments.pop, defineDeviceArguments.secure);
                break;
            case "connectBluetoothDevice":
                btConnect(result);
                break;
            case "getAvailableNetworks":
                getAvailableNetworks(result);
                break;
            case "provision":
                ProvisionArguments provisionArguments;
                try {
                    provisionArguments = ProvisionArguments.fromMap(call.arguments);
                } catch (Exception e) {
                    result.error(BAD_ARGUMENTS, e.getMessage(), null);
                    return;
                }
                provision(result, provisionArguments.ssid, provisionArguments.password);
                break;
            default:
                result.notImplemented();
                break;
        }
    }


    private void btCreate(Result result, String name, String pop, Boolean secure) {
        try {
            final ESPConstants.SecurityType security = secure != Boolean.TRUE ? ESPConstants.SecurityType.SECURITY_0 : ESPConstants.SecurityType.SECURITY_1;
            final ESPDevice device = provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, security);
            device.setDeviceName(name);
            device.setProofOfPossession(pop);

            SearchForDeviceHandler searchForDeviceHandler = new SearchForDeviceHandler(provisionManager);
            searchForDeviceHandler.startSearch(result, device);

        } catch (Exception e) {
            result.error(BT_CREATE_FAILED, e.getMessage(), null);
        }
    }

    private void btConnect(Result result) {
        final ESPDevice device = provisionManager.getEspDevice();
        if (device != null) {
            connectionResult = result;

            device.connectBLEDevice(device.getBluetoothDevice(), device.getPrimaryServiceUuid());
        } else {
            result.error(NO_DEVICE_SELECTED, null, null);
        }
    }

    private void getAvailableNetworks(Result result) {
        final ESPDevice device = provisionManager.getEspDevice();
        if (device != null) {
            provisionManager.getEspDevice().scanNetworks(new WiFiScanListenerImpl(result));
        } else {
            result.error(NO_DEVICE_SELECTED, null, null);
        }
    }

    private void provision(Result result, String ssid, String password) {
        final ESPDevice device = provisionManager.getEspDevice();
        if (device != null) {
            provisionManager.getEspDevice().provision(ssid, password, new ProvisionListenerImpl(result)
            );
        } else {
            result.error(NO_DEVICE_SELECTED, null, null);
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(DeviceConnectionEvent event) {
        final Result result = connectionResult;
        connectionResult = null;

        final ESPDevice device = provisionManager.getEspDevice();

        switch (event.getEventType()) {
            case ESPConstants.EVENT_DEVICE_CONNECTED:
                Log.d(TAG, "Device Connected Event Received");
                ArrayList<String> deviceCaps = device.getDeviceCapabilities();

                if (result == null) {
                    return;
                }

                if (deviceCaps != null && !deviceCaps.contains("no_pop") && device.getSecurityType() == ESPConstants.SecurityType.SECURITY_1) {
                    if (device.getProofOfPossession() != null && !device.getProofOfPossession().isEmpty()) {
                        provisionManager.getEspDevice().initSession(new ResponseListenerImpl(result));
                    } else {
                        result.error(MISSING_POP, null, null);
                    }
                } else {
                    provisionManager.getEspDevice().initSession(new ResponseListenerImpl(result));
                }
                return;

            case ESPConstants.EVENT_DEVICE_DISCONNECTED:
                Log.d(TAG, "Device disconnected");
                break;

            case ESPConstants.EVENT_DEVICE_CONNECTION_FAILED:
                Log.e(TAG, "Failed to connect with device");

                if (result == null) {
                    return;
                }

                result.error(CONNECTION_FAILED, null, null);
                break;
        }
    }
}
