# Security Findings - Vault Search

**Review Date**: 2026-03-01
**Reviewer**: Alice (automated security review)
**Status**: Initial review

**Severity Summary**: 0 Critical, 1 High, 3 Medium, 2 Low

---

## Findings Table

| ID | Severity | Finding | File:Line | Status |
|----|----------|---------|-----------|--------|
| AVS-01 | HIGH | All API communication uses plaintext HTTP | SearchService.swift:4, StatusService.swift:122-123, NotificationService.swift:8-9 | Open |
| AVS-02 | MEDIUM | No authentication on API requests | SearchService.swift, StatusService.swift, NotificationService.swift | Open |
| AVS-03 | MEDIUM | Raw server response data included in error messages | SearchService.swift:31-41,122-123 | Open |
| AVS-04 | MEDIUM | Hardcoded internal IP address | SearchService.swift:4, StatusService.swift:122 | Open |
| AVS-05 | LOW | Face recognition API has no access control | SearchService.swift:57-100 | Open |
| AVS-06 | LOW | NotificationService uses URLSession.shared (no timeout) | NotificationService.swift:30 | Open |

---

## Detailed Findings

### AVS-01: All API communication uses plaintext HTTP (HIGH)

**File**: `SearchService.swift:4`, `StatusService.swift:122-123`, `NotificationService.swift:8-9`

All three services communicate with the media indexer API over plaintext HTTP:

```swift
// SearchService.swift
private let baseURL = "http://10.10.11.157:8081"

// StatusService.swift
private let host = "10.10.11.157"
private let indexerPort = 8081

// NotificationService.swift
private let host = "10.10.11.157"
private let port = 8081
```

Search queries, face recognition data, media metadata, and notification content are all transmitted in cleartext on the network.

**Impact**: Network eavesdropping of search queries, media metadata, and face recognition data on the LAN.
**Remediation**: Enable HTTPS on the media indexer API. If the internal server does not support TLS, document this as an accepted risk for the internal network. At minimum, the API should be restricted to the local network segment.

---

### AVS-02: No authentication on API requests (MEDIUM)

**File**: `SearchService.swift`, `StatusService.swift`, `NotificationService.swift`

None of the API requests include any authentication token or credential. Any device on the network that can reach `10.10.11.157:8081` can search the media vault, trigger face detection, merge face clusters, and read notifications.

**Impact**: Unauthorized access to the media search and face recognition APIs from any device on the network.
**Remediation**: Add API key or token authentication to the media indexer API. The token should be stored in Keychain on the client side.

---

### AVS-03: Raw server response data in error messages (MEDIUM)

**File**: `SearchService.swift:31-41,122-123`

Error handling includes up to 500 bytes of raw server response in error messages:

```swift
let raw = String(data: data.prefix(500), encoding: .utf8) ?? "non-utf8"
throw SearchError.decodeError("Missing key '\(key.stringValue)' ... Raw: \(raw)")
```

This could expose internal server details, error messages, or partial data in user-facing error dialogs or logs.

**Impact**: Information disclosure of server internals through error messages.
**Remediation**: Only include raw response data in debug builds. In release builds, show a generic error message without the raw server response.

---

### AVS-04: Hardcoded internal IP address (MEDIUM)

**File**: `SearchService.swift:4`, `StatusService.swift:122`

The server IP `10.10.11.157` is hardcoded in the source code. If the server's IP changes, the app must be rebuilt and redistributed.

**Impact**: App becomes non-functional if server IP changes. Also reveals internal network addressing.
**Remediation**: Make the server address configurable via settings, with the current IP as the default. This also supports testing and development environments.

---

### AVS-05: Face recognition API has no access control (LOW)

**File**: `SearchService.swift:57-100`

The face recognition endpoints allow any caller to:
- Detect faces in all media
- Cluster faces
- Name and rename people
- Merge and ignore clusters

These are destructive operations (renaming, merging) that could corrupt the face recognition database.

**Impact**: Unauthorized modification of face recognition data.
**Remediation**: This is primarily a server-side concern. The client should send auth tokens; the server should enforce access control. Document as accepted risk if the API is internal-only.

---

### AVS-06: NotificationService uses shared URLSession without timeout (LOW)

**File**: `NotificationService.swift:30`

The `NotificationService` uses `URLSession.shared` for requests, while `StatusService` correctly creates a custom session with short timeouts:

```swift
// NotificationService (no timeout)
let (data, resp) = try await URLSession.shared.data(from: url)

// StatusService (good - custom timeout)
config.timeoutIntervalForRequest = 5
config.timeoutIntervalForResource = 8
```

If the server is unresponsive, notification requests could hang for the default 60-second timeout.

**Impact**: UI thread blocking if notification requests hang (mitigated by async usage, but resource waste).
**Remediation**: Use a custom URLSession with short timeouts, matching the pattern in StatusService.

---

## Security Posture Assessment

Vault Search is an internal tool that connects to a local media indexer API on the church network. Its security profile is primarily defined by the server-side API it connects to. The app itself does not store credentials, does not run network servers, and does not execute shell commands. The main concerns are the use of plaintext HTTP and lack of authentication, which are partially mitigated by the internal network context.

The app properly uses URLComponents for URL encoding (preventing query injection), uses appropriate JSON decoding patterns, and has a clean separation of concerns.

**Overall Risk**: MEDIUM - The plaintext HTTP and lack of authentication are the primary concerns, but the internal network context reduces exploitability significantly. The risk is appropriate for an internal-only tool.

---

## Remediation Priority

1. **AVS-01** (HIGH) - Enable HTTPS on media indexer API or document as accepted risk
2. **AVS-02** (MEDIUM) - Add API authentication
3. **AVS-03** (MEDIUM) - Remove raw response data from release error messages
4. **AVS-04** (MEDIUM) - Make server address configurable
5. **AVS-05** (LOW) - Document server-side access control requirements
6. **AVS-06** (LOW) - Add request timeout to NotificationService
