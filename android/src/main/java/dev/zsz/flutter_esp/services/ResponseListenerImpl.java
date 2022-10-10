package dev.zsz.flutter_esp.services;

import static dev.zsz.flutter_esp.models.ErrorCodes.CONNECTION_FAILED;

import com.espressif.provisioning.listeners.ResponseListener;

import io.flutter.plugin.common.MethodChannel;

public class ResponseListenerImpl implements ResponseListener {
    private final MethodChannel.Result result;

    public ResponseListenerImpl(MethodChannel.Result result) {
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
