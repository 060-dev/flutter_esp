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
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.WiFiAccessPoint;
import com.espressif.provisioning.listeners.BleScanListener;
import com.espressif.provisioning.listeners.ProvisionListener;
import com.espressif.provisioning.listeners.ResponseListener;
import com.espressif.provisioning.listeners.WiFiScanListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

import dev.zsz.flutter_esp.models.BleDevice;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

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

    // TODO: improve hadling of variables that are relevant for a single invocation
    private Result connectionResult = null;
    private ESPConstants.SecurityType securityType = ESPConstants.SecurityType.SECURITY_1;
    private String proofOfPossession = null;

    private ESPProvisionManager provisionManager;
    private final Handler handler = new Handler();
    private final HashMap<String, BleDevice> devicesMap = new HashMap<>();

    private static final String TAG = FlutterEspPlugin.class.getSimpleName();

    private static final String BT_NOT_ENABLED = "BT_NOT_ENABLED";
    private static final String ALREADY_SCANNING = "ALREADY_SCANNING";
    private static final String BT_SCAN_FAILED = "SCAN_FAILED";
    private static final String LOCATION_PERMISSION_NOT_GRANTED = "LOCATION_PERMISSION_NOT_GRANTED";
    private static final String BT_CONNECT_PERMISSION_NOT_GRANTED = "BT_CONNECT_PERMISSION_NOT_GRANTED";
    private static final String BAD_ARGUMENTS = "BAD_ARGUMENTS";
    private static final String DEVICE_NOT_FOUND = "DEVICE_NOT_FOUND";
    private static final String MISSING_POP = "MISSING_POP";
    private static final String WIFI_SCAN_FAILED = "WIFI_SCAN_FAILED";
    private static final String CONNECTION_FAILED = "CONNECTION_FAILED";
    // Provision failure codes
    private static final String WIFI_CONFIG_FAILED = "WIFI_CONFIG_FAILED";
    private static final String WIFI_CONFIG_APPLY_FAILED = "WIFI_CONFIG_APPLY_FAILED";
    private static final String PROVISION_FAILED = "PROVISION_FAILED";
    private static final String PROVISION_FAILED_FROM_DEVICE = "PROVISION_FAILED_FROM_DEVICE";
    private static final String CREATE_SESSION_FAILED = "CREATE_SESSION_FAILED";


    private static final long DEVICE_CONNECT_TIMEOUT = 20000;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_esp");
        channel.setMethodCallHandler(this);

        provisionManager = ESPProvisionManager.getInstance(flutterPluginBinding.getApplicationContext());

        EventBus.getDefault().register(this);
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
                btConnect(result, connectArguments.deviceId, connectArguments.secure, connectArguments.proofOfPossession);
                break;
            case "getAvailableNetworks":
                GetNetworksArguments getNetworksArguments;
                try {
                    getNetworksArguments = GetNetworksArguments.fromMap(call.arguments);
                } catch (Exception e) {
                    result.error(BAD_ARGUMENTS, e.getMessage(), null);
                    return;
                }
                getAvailableNetworks(result, getNetworksArguments.deviceId);
                break;
                case "provision":
                ProvisionArguments provisionArguments;
                try {
                    provisionArguments = ProvisionArguments.fromMap(call.arguments);
                } catch (Exception e) {
                    result.error(BAD_ARGUMENTS, e.getMessage(), null);
                    return;
                }
                provision(result, provisionArguments.deviceId, provisionArguments.ssid, provisionArguments.password);
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
        provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, securityType);

        if (activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.searchBleEspDevices(prefix, new ScanListener(result));
        } else {
            Log.e(TAG, "Not able to start scan as Location permission is not granted.");
            result.error(LOCATION_PERMISSION_NOT_GRANTED, null, null);
        }
    }

    private void btConnect(Result result, String id, Boolean secure, String pop) {
        Log.d(TAG, "btConnect: " + id);
        final BleDevice device = this.devicesMap.get(id);
        if (device != null) {
            securityType = secure != Boolean.TRUE ? ESPConstants.SecurityType.SECURITY_0 : ESPConstants.SecurityType.SECURITY_1;
            connectionResult = result;
            proofOfPossession = pop;

            provisionManager.getEspDevice().connectBLEDevice(device.getDevice(), device.getUuid());
            handler.postDelayed(disconnectDeviceTask, DEVICE_CONNECT_TIMEOUT);
        } else {
            result.error(DEVICE_NOT_FOUND, null, null);
        }
    }

    private void getAvailableNetworks(Result result, String id) {
        final BleDevice device = this.devicesMap.get(id);
        Log.d(TAG, "getAvailableNetworks: " + id);
        if (device != null) {
            provisionManager.getEspDevice().scanNetworks(
                    new WiFiScanListener() {
                        private Boolean isSubmitted = false;

                        @Override
                        public void onWifiListReceived(ArrayList<WiFiAccessPoint> wifiList) {
                            Log.d(TAG, "onWifiListReceived: " + wifiList.size());
                            ArrayList<Map<String, Object>> networks = new ArrayList<>();
                            for (WiFiAccessPoint accessPoint : wifiList) {
                                Map<String, Object> network = new HashMap<>();
                                network.put("ssid", accessPoint.getWifiName());
                                network.put("rssi", accessPoint.getRssi());
                                network.put("auth", accessPoint.getSecurity());
                                networks.add(network);
                            }
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.success(networks);
                            }
                        }

                        @Override
                        public void onWiFiScanFailed(Exception e) {
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.error(WIFI_SCAN_FAILED, e.getMessage(), null);
                            }
                        }
                    }
            );
        } else {
            result.error(DEVICE_NOT_FOUND, null, null);
        }
    }

    private void provision(Result result, String id, String ssid, String password) {
        final BleDevice device = this.devicesMap.get(id);
        Log.d(TAG, "provision: " + id);
        if (device != null) {
            provisionManager.getEspDevice().provision(
                    ssid,
                    password,
                    new ProvisionListener() {
                        private Boolean isSubmitted = false;

                        @Override
                        public void wifiConfigSent() {
                            // Do nothing
                        }


                        @Override
                        public void wifiConfigApplied() {
                            // Do nothing
                        }



                        @Override
                        public void deviceProvisioningSuccess() {
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.success(null);
                            }
                        }

                        @Override
                        public void createSessionFailed(Exception e) {
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.error(CREATE_SESSION_FAILED, e.getMessage(), null);
                            }
                        }

                        @Override
                        public void wifiConfigFailed(Exception e) {
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.error(WIFI_CONFIG_FAILED, e.getMessage(), null);
                            }
                        }
                        @Override
                        public void wifiConfigApplyFailed(Exception e) {
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.error(WIFI_CONFIG_APPLY_FAILED, e.getMessage(), null);
                            }
                        }
                        @Override
                        public void onProvisioningFailed(Exception e) {
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.error(PROVISION_FAILED, e.getMessage(), null);
                            }
                        }

                        @Override
                        public void provisioningFailedFromDevice(ESPConstants.ProvisionFailureReason failureReason) {
                            if (!isSubmitted) {
                                isSubmitted = true;
                                result.error(PROVISION_FAILED_FROM_DEVICE, failureReason.toString(), null);
                            }
                        }
                    }
            );
        } else {
            result.error(DEVICE_NOT_FOUND, null, null);
        }
    }

    private final Runnable disconnectDeviceTask = () -> {

        Log.e(TAG, "Disconnect device");
        // TODO Disconnect device
        Result result = connectionResult;
        connectionResult = null;

        if (result != null) {
            result.error(CONNECTION_FAILED, null, null);
        }
    };


    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(DeviceConnectionEvent event) {
        handler.removeCallbacks(disconnectDeviceTask);

        final Result result = connectionResult;
        connectionResult = null;

        switch (event.getEventType()) {
            case ESPConstants.EVENT_DEVICE_CONNECTED:
                Log.d(TAG, "Device Connected Event Received");
                ArrayList<String> deviceCaps = provisionManager.getEspDevice().getDeviceCapabilities();

                if (result == null) {
                    return;
                }

                if (deviceCaps != null && !deviceCaps.contains("no_pop") && securityType == ESPConstants.SecurityType.SECURITY_1) {
                    if (proofOfPossession != null && !proofOfPossession.isEmpty()) {
                        provisionManager.getEspDevice().setProofOfPossession(proofOfPossession);
                        provisionManager.getEspDevice().initSession(new SessionListener(result));
                    } else {
                        result.error(MISSING_POP, null, null);
                    }
                } else {
                    provisionManager.getEspDevice().initSession(new SessionListener(result));
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

    private static class SessionListener implements ResponseListener {
        private final Result result;

        SessionListener(Result result) {
            this.result = result;
        }

            @Override
            public void onSuccess(byte[] returnData) {
                result.success(null);
            }

            @Override
            public void onFailure(Exception e) {
                result.error(CONNECTION_FAILED, e.getMessage(), null);
            }
    }

    private class ScanListener implements BleScanListener {
        private final Result result;
        private final ArrayList<HashMap<String, Object>> devicesList;
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

            boolean deviceExists = false;
            String serviceUuid = "";


            if (scanResult.getScanRecord().getServiceUuids() != null && scanResult.getScanRecord().getServiceUuids().size() > 0) {
                serviceUuid = scanResult.getScanRecord().getServiceUuids().get(0).toString();
            }

            if (devicesMap.containsKey(device.getAddress())) {
                deviceExists = true;
            }

            if (!deviceExists) {
                BleDevice bleDevice = new BleDevice(
                        scanResult.getScanRecord().getDeviceName(),
                        device,
                        serviceUuid
                );

                devicesMap.put(device.getAddress(), bleDevice);
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
                result.error(BT_SCAN_FAILED, e.getMessage(), null);
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
        Boolean secure;
        String proofOfPossession;

        ConnectArguments(String deviceId, Boolean secure, String proofOfPossession) {
            this.deviceId = deviceId;
            this.secure = secure;
            this.proofOfPossession = proofOfPossession;
        }

        // Parse Object to ConnectArguments
        static ConnectArguments fromMap(Object arguments) {
            Map<String, Object> map = (Map<String, Object>) arguments;
            String deviceId = (String) map.get("deviceId");
            Boolean secure = (Boolean) map.get("secure");
            String proofOfPossession = (String) map.get("proofOfPossession");
            return new ConnectArguments(deviceId, secure, proofOfPossession);
        }
    }

    static class GetNetworksArguments {
        String deviceId;

        GetNetworksArguments(String deviceId) {
            this.deviceId = deviceId;
        }

        // Parse Object to GetNetworksArguments
        static GetNetworksArguments fromMap(Object arguments) {
            Map<String, Object> map = (Map<String, Object>) arguments;
            String deviceId = (String) map.get("deviceId");
            return new GetNetworksArguments(deviceId);
        }
    }

    static class ProvisionArguments{
        String deviceId;
        String ssid;
        String password;

        ProvisionArguments(String deviceId, String ssid, String password){
            this.deviceId = deviceId;
            this.ssid = ssid;
            this.password = password;
        }

        // Parse Object to ProvisionArguments
        static ProvisionArguments fromMap(Object arguments) {
            Map<String, Object> map = (Map<String, Object>) arguments;
            String deviceId = (String) map.get("deviceId");
            String ssid = (String) map.get("ssid");
            String password = (String) map.get("password");
            return new ProvisionArguments(deviceId, ssid, password);
        }
    }
}
