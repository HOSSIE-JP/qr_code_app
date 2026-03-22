import Flutter
import UIKit
import CloudKit
import MSAL

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "jp.co.geroneko.priqr/cloud_backup"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return MSALPublicClientApplication.handleMSALResponse(
      url,
      sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CloudBackupChannel") else {
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleCloudBackupMethod(call: call, result: result)
    }
  }

  private func handleCloudBackupMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isICloudAvailable":
      CKContainer.default().accountStatus { status, error in
        if let error {
          result(FlutterError(code: "icloud_account_error", message: error.localizedDescription, details: nil))
          return
        }
        result(status == .available)
      }
    case "uploadBackup":
      guard let args = call.arguments as? [String: Any],
            let fileName = args["fileName"] as? String,
            let bytes = args["bytes"] as? FlutterStandardTypedData,
            let mimeType = args["mimeType"] as? String else {
        result(FlutterError(code: "invalid_args", message: "uploadBackup の引数が不正です", details: nil))
        return
      }
      uploadBackup(fileName: fileName, data: bytes.data, mimeType: mimeType, result: result)
    case "listBackups":
      listBackups(result: result)
    case "downloadBackup":
      guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? String else {
        result(FlutterError(code: "invalid_args", message: "downloadBackup の引数が不正です", details: nil))
        return
      }
      downloadBackup(recordName: id, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func uploadBackup(fileName: String, data: Data, mimeType: String, result: @escaping FlutterResult) {
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let assetUrl = temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + fileName)
    do {
      try data.write(to: assetUrl)
    } catch {
      result(FlutterError(code: "write_temp_failed", message: error.localizedDescription, details: nil))
      return
    }

    let record = CKRecord(recordType: "BackupFile")
    record["fileName"] = fileName as CKRecordValue
    record["mimeType"] = mimeType as CKRecordValue
    record["updatedAt"] = Date() as CKRecordValue
    record["fileSize"] = data.count as CKRecordValue
    record["fileAsset"] = CKAsset(fileURL: assetUrl)

    CKContainer.default().privateCloudDatabase.save(record) { _, error in
      try? FileManager.default.removeItem(at: assetUrl)
      if let error {
        result(FlutterError(code: "icloud_upload_failed", message: error.localizedDescription, details: nil))
        return
      }
      result(nil)
    }
  }

  private func listBackups(result: @escaping FlutterResult) {
    let query = CKQuery(recordType: "BackupFile", predicate: NSPredicate(value: true))
    query.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
    CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
      if let error {
        result(FlutterError(code: "icloud_list_failed", message: error.localizedDescription, details: nil))
        return
      }
      let mapped = (records ?? []).map { record in
        [
          "id": record.recordID.recordName,
          "name": (record["fileName"] as? String) ?? "unknown",
          "mimeType": (record["mimeType"] as? String) ?? "application/octet-stream",
          "size": (record["fileSize"] as? Int) ?? 0,
          "modifiedAt": ((record["updatedAt"] as? Date) ?? Date.distantPast).ISO8601Format(),
        ]
      }
      result(mapped)
    }
  }

  private func downloadBackup(recordName: String, result: @escaping FlutterResult) {
    let recordId = CKRecord.ID(recordName: recordName)
    CKContainer.default().privateCloudDatabase.fetch(withRecordID: recordId) { record, error in
      if let error {
        result(FlutterError(code: "icloud_download_failed", message: error.localizedDescription, details: nil))
        return
      }
      guard let record,
            let asset = record["fileAsset"] as? CKAsset,
            let fileURL = asset.fileURL else {
        result(FlutterError(code: "icloud_asset_missing", message: "CloudKit Asset が見つかりません", details: nil))
        return
      }
      do {
        let data = try Data(contentsOf: fileURL)
        result(FlutterStandardTypedData(bytes: data))
      } catch {
        result(FlutterError(code: "icloud_read_failed", message: error.localizedDescription, details: nil))
      }
    }
  }
}
