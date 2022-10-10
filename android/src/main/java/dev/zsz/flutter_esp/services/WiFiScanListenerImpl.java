package dev.zsz.flutter_esp.services;

import static dev.zsz.flutter_esp.models.ErrorCodes.WIFI_SCAN_FAILED;

import android.util.Log;

import com.espressif.provisioning.WiFiAccessPoint;
import com.espressif.provisioning.listeners.WiFiScanListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class WiFiScanListenerImpl implements WiFiScanListener {
    private static final String TAG = WiFiScanListenerImpl.class.getSimpleName();
    private Boolean isSubmitted = false;
    private final  MethodChannel.Result result;

    public WiFiScanListenerImpl(MethodChannel.Result result) {
        this.result = result;
    }

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
