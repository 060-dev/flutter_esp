package dev.zsz.flutter_esp;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.listeners.BleScanListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import dev.zsz.flutter_esp.models.BleDevice;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * FlutterEspPlugin
 */
public class FlutterEspPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Activity activity;
    private BluetoothAdapter bleAdapter;
    private boolean isScanning = false;
    private ESPProvisionManager provisionManager;
    private final HashMap<String, BluetoothDevice> devicesMap = new HashMap<>();

    private static final String TAG = FlutterEspPlugin.class.getSimpleName();

    private static final String BT_NOT_ENABLED = "BT_NOT_ENABLED";
    private static final String ALREADY_SCANNING = "ALREADY_SCANNING";
    private static final String SCAN_FAILED = "SCAN_FAILED";
    private static final String LOCATION_PERMISSION_NOT_GRANTED = "LOCATION_PERMISSION_NOT_GRANTED";
    private static final String BT_CONNECT_PERMISSION_NOT_GRANTED = "BT_CONNECT_PERMISSION_NOT_GRANTED";
    private static final String BAD_ARGUMENTS = "BAD_ARGUMENTS";
    private static final String DEVICE_NOT_FOUND = "DEVICE_NOT_FOUND";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_esp");
        channel.setMethodCallHandler(this);

        provisionManager = ESPProvisionManager.getInstance(flutterPluginBinding.getApplicationContext());
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "searchBluetoothDevices":
                SearchArguments searchArguments;
                try {
                    searchArguments = SearchArguments.fromMap(call.arguments);
                } catch (Exception e) {
                    result.error(BAD_ARGUMENTS, e.getMessage(), null);
                    return;
                }
                btSearch(result, searchArguments.prefix);
                break;
            case "connectBluetoothDevice":
                ConnectArguments connectArguments;
                try {
                    connectArguments = ConnectArguments.fromMap(call.arguments);
                } catch (Exception e) {
                    result.error(BAD_ARGUMENTS, e.getMessage(), null);
                    return;
                }
                btConnect(result, connectArguments.deviceId);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        setActivity(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        clearActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        setActivity(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivity() {
        clearActivity();
    }

    private void setActivity(Activity activity) {
        this.activity = activity;
        final BluetoothManager bluetoothManager = (BluetoothManager) activity.getApplicationContext().getSystemService(Context.BLUETOOTH_SERVICE);
        bleAdapter = bluetoothManager.getAdapter();

    }

    private void clearActivity() {
        activity = null;
        bleAdapter = null;
    }

    private void btSearch(Result result, String prefix) {
        if (isScanning) {
            result.error(ALREADY_SCANNING, null, null);
            return;
        }
        if (bleAdapter == null || !bleAdapter.isEnabled()) {
            result.error(BT_NOT_ENABLED, null, null);
            return;
        }

        isScanning = true;

        if (activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.searchBleEspDevices(prefix, new ScanListener(result));
        } else {
            Log.e(TAG, "Not able to start scan as Location permission is not granted.");
            result.error(LOCATION_PERMISSION_NOT_GRANTED, null, null);
        }
    }

    private void btConnect(Result result, String id) {
        Log.d(TAG, "btConnect: "+id);
        final BluetoothDevice device = this.devicesMap.get(id);
        if(device != null){
            result.success(device.toString());
        }else{
            result.error(DEVICE_NOT_FOUND, null,null);
        }
    }

    private class ScanListener implements BleScanListener {
        private final Result result;
        private final ArrayList<HashMap<String,Object>> devicesList;
        private boolean submitted = false;

        ScanListener(Result result) {
            this.result = result;
            devicesList = new ArrayList<>();
        }

        @Override
        public void scanStartFailed() {
            if (!submitted) {
                result.error(BT_NOT_ENABLED, null, null);
                submitted = true;
            }
        }

        @Override
        public void onPeripheralFound(BluetoothDevice device, ScanResult scanResult) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (activity.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                    if (!submitted) {
                        result.error(BT_CONNECT_PERMISSION_NOT_GRANTED, null, null);
                        submitted = true;
                    }
                    return;
                }
            }

            Log.d(TAG, "====== onPeripheralFound ===== " + device.getName());
            boolean deviceExists = false;
            String serviceUuid = "";

            if (scanResult.getScanRecord().getServiceUuids() != null && scanResult.getScanRecord().getServiceUuids().size() > 0) {
                serviceUuid = scanResult.getScanRecord().getServiceUuids().get(0).toString();
            }
            Log.d(TAG, "Add service UUID : " + serviceUuid);

            if (devicesMap.containsKey(device.hashCode())) {
                deviceExists = true;
            }

            if (!deviceExists) {
                BleDevice bleDevice = new BleDevice();
                bleDevice.setName(scanResult.getScanRecord().getDeviceName());
                bleDevice.setId(device.toString());

                devicesMap.put(device.toString(), device);
                devicesList.add(bleDevice.toMap());
            }
        }

        @Override
        public void scanCompleted() {
            isScanning = false;
            if (!submitted) {
                result.success(devicesList);
                submitted = true;
            }
        }

        @Override
        public void onFailure(Exception e) {
            if (!submitted) {
                result.error(SCAN_FAILED, e.getMessage(), null);
                submitted = true;
            }
            Log.e(TAG, e.getMessage());
            e.printStackTrace();
            isScanning = false;
        }
    }

    static class SearchArguments {
        String prefix;
        Boolean secure;

        SearchArguments(String prefix, Boolean secure) {
            this.prefix = prefix;
            this.secure = secure;
        }

        // Parse Object to SearchArguments
        static SearchArguments fromMap(Object arguments) {
            Map<String, Object> map = (Map<String, Object>) arguments;
            String prefix = (String) map.get("prefix");
            Boolean secure = (Boolean) map.get("secure");
            return new SearchArguments(prefix, secure);
        }

    }
    static class ConnectArguments {
        String deviceId;

        ConnectArguments(String deviceId) {
            this.deviceId = deviceId;
        }

        // Parse Object to ConnectArguments
        static ConnectArguments fromMap(Object arguments) {
            Map<String, Object> map = (Map<String, Object>) arguments;
            String deviceId = (String) map.get("deviceId");
            return new ConnectArguments(deviceId);
        }
    }
}
