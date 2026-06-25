# NFCReader SDK for iOS

The **NFCReader** SDK reads and verifies electronic identity documents (passports, national ID cards) over NFC on iOS. It performs the full chip read — secure-messaging setup (BAC / PACE), data-group extraction, and authentication (active authentication, chip authentication, passive verification) — and returns a structured result.

The SDK can operate in two modes:

- **Local** — reading *and* validation happen on the device, using a master list of certificates you provide.
- **Remote** — reading happens on the device, but validation is delegated to a backend service.

---

## Requirements

| | |
|---|---|
| Platform | iOS 14.0+ |
| Language | Swift 5.9+ |
| Device | A physical iPhone with NFC (iPhone 7 and later). The NFC chip is **not** available in the iOS Simulator. |
| Distribution | Swift Package Manager (binary XCFramework) |

---

## Installation

The SDK is distributed as a binary XCFramework via Swift Package Manager. It depends on OpenSSL, which SPM resolves automatically.

### Xcode

1. **File ▸ Add Package Dependencies…**
2. Enter the package repository URL.
3. Add the **`NFCReaderLibrary`** product to your app target.

---

## Project configuration

Reading an NFC document requires the following capabilities and `Info.plist` entries in your **app** target.

### 1. Near Field Communication entitlement

Enable **Near Field Communication Tag Reading** in *Signing & Capabilities*, and declare the supported reader-session formats in your `.entitlements` file:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
    <string>PACE</string>
</array>
```

### 2. NFC usage description

```xml
<key>NFCReaderUsageDescription</key>
<string>This app uses NFC to scan id documents</string>
```

### 3. Application IDs (ISO 7816 select identifiers)

The document applications the reader is allowed to select:

```xml
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
    <string>A0000002472001</string>
    <string>A000000077030C60000000FE00000500</string>
    <string>00000000000000</string>
</array>
```

### 4. (Remote mode only) App Transport Security

If your backend service is served over HTTP or a non-standard domain, add the appropriate `NSAppTransportSecurity` exceptions for that domain.

---

## Quick start

### 1. Activate the SDK

Call `activate()` once, typically at app launch (e.g. in your `AppDelegate`). This wires up the SDK's internal dependencies.

```swift
import NFCReader

try NfcReader.sharedInstance.activate()
```

### 2. Set up a session

Configure the mode, the authentication protocol, the polling option, and (optionally) a listener and custom on-screen messages.

```swift
try NfcReader.sharedInstance.setupSession(
    mode: .local(masterListURL: Bundle.main.url(forResource: "ml", withExtension: "pem")),
    nfcReaderEventListener: self,        // optional
    nfcPollingOption: .iso14443,
    nfcProtocol: .mrz(
        documentNumber: "123456789",
        dateOfBirth: birthDate,
        dateOfExpiry: expiryDate
    ),
    nfcDisplayMessages: nil              // optional, uses defaults if nil
)
```

### 3. Start reading

`startReading()` is an `async` call that presents the system NFC sheet, drives the full read, and returns an `NfcReaderResult` on success.

```swift
do {
    let result = try await NfcReader.sharedInstance.startReading()

    let mrz = result.dG1Result?.mrz
    let faceImage = result.dG2Result?.faceImage
    let authentic = result.isContentAuthentic
    // …
} catch let error as NfcReaderError {
    // Handle the error (see "Error handling" below)
}
```

### 4. Stop or abort (optional)

```swift
// Cancel an in-progress read
try NfcReader.sharedInstance.stopReading()

// Remote mode only: tell the server to terminate the session after an unrecoverable error
try await NfcReader.sharedInstance.abortSession(cause: "PIN_WRONG", detail: "User entered wrong PIN")
```

---

## API reference

The public surface of the SDK is the `NfcReader` singleton plus the public types described below.

### `NfcReader`

Accessed via `NfcReader.sharedInstance`.

| Method | Description |
|---|---|
| `activate() throws` | Initializes the SDK. Must be called before any other method. |
| `setupSession(mode:nfcReaderEventListener:nfcPollingOption:nfcProtocol:nfcDisplayMessages:) throws` | Configures a reading session. |
| `startReading() async throws -> NfcReaderResult` | Presents the NFC sheet and performs the read. |
| `stopReading() throws` | Stops an in-progress read. |
| `abortSession(cause:detail:) async throws` | **Remote mode only.** Notifies the server to terminate the session. |

All methods throw `NfcReaderError`.

### `NfcReaderMode`

```swift
enum NfcReaderMode {
    case local(masterListURL: URL?)              // read + validate on device
    case remote(serviceURL: String, sessionId: String)   // validate on backend
}
```

In `remote` mode, the `sessionId` is generated by your backend before launching the reader. `abortSession` is only available in this mode.

### `NfcProtocol`

The access-control protocol used to establish secure messaging with the chip.

```swift
enum NfcProtocol {
    case mrz(documentNumber: String, dateOfBirth: Date, dateOfExpiry: Date)
    case can(can: String)
    case romanian(can: String, pin: String?)
}
```

### `NfcPollingOption`

```swift
enum NfcPollingOption {
    case iso14443   // standard ISO 14443 cards
    case pace       // PACE-based electronic ID cards
}
```

### `NfcDisplayMessages`

Optional, fully customizable strings shown on the system NFC sheet during each phase of the read (`requestPresentId`, `authenticating`, `readingDataGroup`, `performingActiveAuthentication`, `performingChipAuthentication`, `success`, `error`). Defaults are provided if omitted.

### `NfcReaderResult`

Returned by `startReading()` on success.

| Property | Type | Description |
|---|---|---|
| `dataGroups` | `[NfcDataGroup]` | The data groups that were read. |
| `dG1Result` | `DG1Result?` | MRZ-derived fields: document number, names, nationality, dates, gender, etc. |
| `dG2Result` | `DG2Result?` | `faceImage` bytes of the holder. |
| `dG11Result` | `DG11Result?` | Additional personal details (address, place of birth, profession, …). |
| `dG12Result` | `DG12Result?` | Additional document details (issuing authority, dates, …). |
| `isContentAuthentic` | `Bool` | Result of passive (content) verification. |
| `activeAuthenticationResult` | `NfcActiveAuthenticationResult` | `.success` / `.failure` / `.unavailable`. |
| `chipAuthenticationResult` | `NfcChipAuthenticationResult` | `.success` / `.failure` / `.unavailable`. |
| `romanianAddress` | `String?` | Address read from the Romanian-address branch, if applicable. |

### `NfcReaderEventListener`

Implement this protocol and pass it to `setupSession` to observe the read in real time — useful for progress UI, logging, and analytics.

```swift
protocol NfcReaderEventListener {
    func onNfcReaderEvent(state: NfcState, transition: NfcStateTransition)
    func onNfcReaderError(error: NfcReaderError)
}
```

`NfcState` reports the current phase of the read (`waitingForTag`, `readDG1`, `performChipAuthentication`, …) and `NfcStateTransition` reports the event that caused it (`onTagFound`, `onDataGroupRead`, …). Both expose a stable string identifier (`rawValue`) suitable for logging.

---

## Error handling

Every error crossing the SDK boundary is a typed `NfcReaderError`:

```swift
enum NfcReaderError: Error {
    case internalError(internalError: InternalErrorDetails)
    case tagNotFound
    case tagLost
    case pinWrong
    case connectionError(details: String)
    case authenticationError(details: String)
    case readingError(details: String)
    case serverError(details: ServerErrorDetails)
    case stoppedByUser
    case abortedSessionDetail(cause: String, detail: String)
    case abortedSession(error: NfcReaderError)
}
```

| Case | Meaning |
|---|---|
| `tagNotFound` / `tagLost` | No chip detected, or the connection dropped mid-read (move closer / hold still). |
| `pinWrong` | Incorrect PIN (Romanian ID flow). |
| `authenticationError` | BAC / PACE / chip authentication failed — usually wrong credentials (MRZ / CAN). |
| `connectionError` | Communication error with the chip. |
| `readingError` | A data group could not be read. |
| `serverError` | Remote-mode backend error (`unknownSession`, `alreadyFinished`, `other`). |
| `stoppedByUser` | The read was cancelled via `stopReading()` or the system sheet. |
| `internalError` | SDK misuse (e.g. not activated, already reading) or an unexpected internal failure. |

---

## Typical flow

1. `activate()` — once per app lifetime.
2. `setupSession(...)` — once per document read, with the credentials the user supplied (MRZ/CAN/PIN).
3. `startReading()` — `await` the result.
4. On success, read the `NfcReaderResult`. On `NfcReaderError`, surface the appropriate message and (in remote mode) optionally `abortSession(...)`.

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for the full release history.

---

© IDnow. All rights reserved.
