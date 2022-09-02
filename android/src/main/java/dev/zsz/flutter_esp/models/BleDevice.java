package dev.zsz.flutter_esp.models;

import java.util.HashMap;

public class BleDevice {
    private String name;
    private String id;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getId() {
        return id;
    }

    public void setId(String hash) {
        this.id = hash;
    }

    // Parse to HashMap
    public HashMap<String, Object> toMap() {
        HashMap<String, Object> map = new HashMap<>();
        map.put("name", name);
        map.put("id", id);
        return map;
    }
}
