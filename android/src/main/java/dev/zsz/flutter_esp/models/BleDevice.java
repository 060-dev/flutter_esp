package dev.zsz.flutter_esp.models;

import android.bluetooth.BluetoothDevice;

import java.util.HashMap;

public class BleDevice {
    private final String name;
    private final BluetoothDevice device;
    private final String uuid;

    public BleDevice(String name, BluetoothDevice device, String uuid) {
        this.name = name;
        this.device = device;
        this.uuid = uuid;
    }

    // Getters
    public BluetoothDevice getDevice() {
        return device;
    }

    public String getUuid() {
        return uuid;
    }

    // Parse to HashMap
    public HashMap<String, Object> toMap() {
        HashMap<String, Object> map = new HashMap<>();
        map.put("name", name);
        map.put("id", device.getAddress());
        return map;
    }
}
