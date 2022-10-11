package dev.zsz.flutter_esp.services;

import static dev.zsz.flutter_esp.models.ErrorCodes.BT_SEARCH_FAILED;
import static dev.zsz.flutter_esp.models.ErrorCodes.CONNECTION_FAILED;

import android.Manifest;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;
import android.os.Handler;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.RequiresPermission;

import com.espressif.provisioning.ESPDevice;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.listeners.BleScanListener;

import io.flutter.plugin.common.MethodChannel;

public class SearchForDeviceHandler {
    public Boolean isDeviceFound = false;
    public int searchCnt = 0;
    public final ESPProvisionManager provisionManager;
    public final Handler searchHandler = new Handler();

    public SearchForDeviceHandler(ESPProvisionManager provisionManager) {
        this.provisionManager = provisionManager;
    }

    public void startSearch(MethodChannel.Result result, ESPDevice device) {
        SearchDeviceTask searchDeviceTask = new SearchDeviceTask(device, result);
        searchHandler.post(searchDeviceTask);
    }

    private class SearchDeviceTask implements Runnable {
        private final ESPDevice device;
        private final MethodChannel.Result result;

        public SearchDeviceTask(ESPDevice device, MethodChannel.Result result) {
            searchCnt++;
            isDeviceFound = false;
            this.device = device;
            this.result = result;
        }

        @Override
        @RequiresPermission(allOf = {Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.BLUETOOTH,
                Manifest.permission.ACCESS_FINE_LOCATION,
        })
        public void run() {
            provisionManager.searchBleEspDevices(new BleSearchForDeviceListener(result, device));
        }
    }

    private class BleSearchForDeviceListener implements BleScanListener {
        private final String TAG = BleSearchForDeviceListener.class.getSimpleName();
        private final MethodChannel.Result result;
        private final ESPDevice device;

        public BleSearchForDeviceListener(MethodChannel.Result result, ESPDevice device) {
            this.result = result;
            this.device = device;
        }

        @Override
        public void scanStartFailed() {
            result.error(CONNECTION_FAILED, "Please turn on bluetooth and try again.", null);
        }

        @Override
        @RequiresPermission(allOf = {Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.BLUETOOTH,
                Manifest.permission.ACCESS_FINE_LOCATION,
        })
        public void onPeripheralFound(BluetoothDevice btDevice, ScanResult scanResult) {
            if (!isDeviceFound && btDevice != null && !TextUtils.isEmpty(scanResult.getScanRecord().getDeviceName())) {
                if (scanResult.getScanRecord().getDeviceName().equals(device.getDeviceName())) {
                    // Device found
                    isDeviceFound = true;
                    String serviceUuid = "";

                    if (scanResult.getScanRecord().getServiceUuids() != null && scanResult.getScanRecord().getServiceUuids().size() > 0) {
                        serviceUuid = scanResult.getScanRecord().getServiceUuids().get(0).toString();
                    }

                    device.setBluetoothDevice(btDevice);
                    device.setPrimaryServiceUuid(serviceUuid);
                }
            }
        }

        private void handleResult() {
            if (!isDeviceFound) {
                if (searchCnt < 3) {
                    SearchDeviceTask searchDeviceTask = new SearchDeviceTask(device, result);
                    searchHandler.postDelayed(searchDeviceTask, 500);
                } else {
                    String errMsg = "" + device.getDeviceName() + " device not found";
                    result.error(BT_SEARCH_FAILED, errMsg, null);
                }
            } else {
                result.success(true);
            }
        }

        @Override
        public void scanCompleted() {
            Log.d(TAG, "scanCompleted");
            Log.d(TAG, "isDeviceFound : " + isDeviceFound);
            Log.d(TAG, "searchCnt : " + searchCnt);

            handleResult();
        }

        @Override
        public void onFailure(Exception e) {
            e.printStackTrace();
            Log.d(TAG, "onFailure");
            Log.d(TAG, "isDeviceFound : " + isDeviceFound);
            Log.d(TAG, "searchCnt : " + searchCnt);

            handleResult();
        }
    }
}
