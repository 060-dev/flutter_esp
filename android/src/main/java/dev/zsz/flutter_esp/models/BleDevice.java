package dev.zsz.flutter_esp.models;

import android.bluetooth.BluetoothDevice;

public class BleDevice {
    private String name;
    private BluetoothDevice bluetoothDevice;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public BluetoothDevice getBluetoothDevice() {
        return bluetoothDevice;
    }

    public void setBluetoothDevice(BluetoothDevice bluetoothDevice) {
        this.bluetoothDevice = bluetoothDevice;
    }
}
