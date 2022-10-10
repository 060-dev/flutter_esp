package dev.zsz.flutter_esp.models;

import java.util.Map;

public class DefineDeviceArguments {
    public final String name;
    public final String pop;
    public final Boolean secure;

    DefineDeviceArguments(String name, String pop, Boolean secure) {
        this.name = name;
        this.pop = pop;
        this.secure = secure;
    }

    // Parse Object to DefineArguments
    public static DefineDeviceArguments fromMap(Object arguments) {
        if (arguments instanceof Map) {
            Map<String, Object> args = (Map<String, Object>) arguments;
            String name = (String) args.get("name");
            String pop = (String) args.get("pop");
            Boolean secure = (Boolean) args.get("secure");

            return new DefineDeviceArguments(name, pop, secure);
        }
        return null;
    }

}
