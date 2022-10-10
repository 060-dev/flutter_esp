package dev.zsz.flutter_esp.models;

import java.util.Map;

public class ProvisionArguments {
    public final String ssid;
    public final String password;

    ProvisionArguments( String ssid, String password){
        this.ssid = ssid;
        this.password = password;
    }

    // Parse Object to ProvisionArguments
    public static ProvisionArguments fromMap(Object arguments) {
        Map<String, Object> map = (Map<String, Object>) arguments;
        String ssid = (String) map.get("ssid");
        String password = (String) map.get("password");
        return new ProvisionArguments(ssid, password);
    }
}
