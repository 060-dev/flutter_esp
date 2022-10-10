package dev.zsz.flutter_esp.services;

import static dev.zsz.flutter_esp.models.ErrorCodes.CREATE_SESSION_FAILED;
import static dev.zsz.flutter_esp.models.ErrorCodes.PROVISION_FAILED;
import static dev.zsz.flutter_esp.models.ErrorCodes.PROVISION_FAILED_FROM_DEVICE;
import static dev.zsz.flutter_esp.models.ErrorCodes.WIFI_CONFIG_APPLY_FAILED;
import static dev.zsz.flutter_esp.models.ErrorCodes.WIFI_CONFIG_FAILED;

import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.listeners.ProvisionListener;

import io.flutter.plugin.common.MethodChannel;

public class ProvisionListenerImpl implements ProvisionListener {
    private final MethodChannel.Result result;
    private Boolean isSubmitted = false;

    public ProvisionListenerImpl(MethodChannel.Result result) {
        this.result = result;
    }

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
