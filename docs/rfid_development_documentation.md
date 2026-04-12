# RFID Development Documentation (Flutter Plugin) v2.9

*This document describes the RFID SDK APIs and usage intended for a Flutter plugin integration.*

## Table of Contents
1. [Common Method Usage Process](#common-method-usage-process)
   1. [Initialization](#initialization)
   2. [Inventory](#inventory)
   3. [Read Tag](#read-tag)
   4. [Write Tag](#write-tag)
   5. [Get Output Power](#get-the-power-of-output)
   6. [Set Output Power](#set-the-power-of-output)
   7. [Parameter Setting](#parameter-setting)
   8. [Long Range Device Control](#long-range-with-handle-device-control-scanning-head-light)
2. [Interface Callback](#interface-callback)
3. [RFID API](#rfid-api)
   * (Sections 3.1-3.49 corresponding to each SDK method)
4. [Appendix 1: Return Value Error Code Table](#appendix-1-return-value-error-code-table)
5. [Appendix 2: Frequency Band Description](#appendix-2-frequency-band-description)
6. [Appendix 3: RSSI Parameter Comparison Table](#appendix-3-rssi-parameter-comparison-table)

## Common Method Usage Process

Due to the relatively high power consumption of the RFID module, it is recommended that the application powers off the RFID module when the module is not in use or the application is in the background.

* When using the RFID function or the application is in the foreground:
  ```java
  RFIDSDKManager.getInstance().init(InitListener);
  ```
* When the RFID function is not used or the application is in the background:
  ```java
  RFIDSDKManager.getInstance().disConnect();
  RFIDSDKManager.getInstance().power(false);
  ```

### Initialization
```java
RFIDManager.getInstance().init(new InitListener() {
  @Override
  public void onStatus(boolean status) {
    if (status) {
      Log.d(TAG, "initRfid() success.");
      mRfidManager = USDKManager.getInstance().getRfidManager();
    } else {
      Log.d(TAG, "initRfid fail.");
    }
  }
});
```

### Inventory
After initializing `RfidManager`'s instance, invoke `startInventory` or `startRead` to begin scanning. Results are delivered through `onInventoryTag` in `IRfidCallback`.

```java
Rfidmanager.startInventory(int session);
```

### Read Tag
Read tag data with:
```java
rfidmanager.readTag(epc, btMemBank, btWordAdd, btWordCnt, btAryPassWord);
```

### Write Tag
```java
// Write any area
int ret = rfidmanager.writeTag(epc, btAryPassWord, btMemBank, btWordAdd, btAryData);

// Write EPC area
int ret = rfidmanager.writeTagEpc(epc, strPassword, strData);
```

### Get the Power of Output
```java
rfidmanager.getOutputPower();
```

### Set the Power of Output
```java
rfidmanager.setOutputPower();
```

### Parameter Setting
```java
RfidParameter rfidParameter = mRfidManager.getInventoryParameter();
rfidParameter.Session = 0;
rfidParameter.Interval = 0;
rfidParameter.QValue = 6;
mRfidManager.setInventoryParameter(rfidParameter);
```

### Long Range (with Handle) Device Control Scanning Head Light
```java
RFIDSDKManager.getInstance().enableScanHead(boolean isOpen);
```

## Interface Callback
Register `IRfidCallback` to receive inventory events.

```java
public interface IRfidCallback {
    void onInventoryTag(String EPC, String TID, String RSSI);
    void onInventoryTagEnd();
}
```

* `onInventoryTag` – triggered for each scanned tag.
* `onInventoryTagEnd` – triggered when inventory stops.

## RFID API
Detailed descriptions of RFID SDK methods (3.1–3.49), including initialization, inventory control, tag read/write operations, power management, region configuration, mask handling, and advanced queries.

## Appendix 1: Return Value Error Code Table
A table of error codes describing success and failure states for operations.

## Appendix 2: Frequency Band Description
Descriptions of configurable frequency bands and examples of setting specific bands.

## Appendix 3: RSSI Parameter Comparison Table
Comparison chart mapping RSSI values to signal strengths in dBm.

