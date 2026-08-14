# Programming Against the Cloud with gopurple

[← Back to Part 5: BrightSign Control](README.md) | [↑ Main](../../README.md)

---

## Introduction

**[gopurple](https://github.com/BrightDevelopers/gopurple)** is BrightSign's Go SDK for BrightSign Control. It is the fastest path from "I need to manage players programmatically" to working code, and it is what the rest of Part 5 assumes you will use rather than hand-rolling HTTP calls.

This chapter covers constructing a client, the shape of the API, and the conventions the SDK expects you to follow. For the underlying REST surface see [Integrating with BrightSign Control](01-integrating-with-bsn-cloud.md) and [Per-Player Control](03-per-player-control.md).

**Status: external beta.** Pin a tagged version, and expect the surface to grow.

---

## Why Go

The SDK is Go rather than Python for reasons that matter to how you deploy it:

- **Single binary.** `go build` produces one self-contained file. No interpreter, no virtualenv, no dependency resolution on the target host — copy it to a server, a container, or a CI runner and run it.
- **Compile-time type safety.** Every nested wire type is exported, so a wrong field name is a build error rather than a runtime `KeyError`.
- **Concurrency.** Goroutines make fleet-wide operations across hundreds of players straightforward.
- **AI assistants write good Go.** Strong typing and a small, consistent syntax mean generated code tends to compile and work on the first try — which is a stated goal of this documentation set.

The patterns also translate: if you need Python or TypeScript, gopurple is a reliable reference for what the correct call sequence looks like.

---

## Installation

```bash
go get github.com/brightdevelopers/gopurple
```

Pin to a tagged release in production rather than tracking the default branch — check the repository's releases for the current tag:

```go
// go.mod
require github.com/brightdevelopers/gopurple v0.2.3
```

Follow semver expectations when upgrading: new exported types and fields are minor bumps; a removed or renamed export is a major bump.

---

## Authentication

Credentials come from environment variables when `New()` is called with no options. This is the recommended configuration path for CLIs and services:

| Variable | Purpose |
|----------|---------|
| `BS_CLIENT_ID` | OAuth2 client ID |
| `BS_SECRET` | OAuth2 client secret |
| `BS_NETWORK` | Default network name |

```go
package main

import (
    "context"
    "log"

    "github.com/brightdevelopers/gopurple"
)

func main() {
    client, err := gopurple.New()
    if err != nil {
        log.Fatal(err)
    }

    ctx := context.Background()
    if err := client.Authenticate(ctx); err != nil {
        log.Fatal(err)
    }

    devices, err := client.Devices.List(ctx)
    if err != nil {
        log.Fatal(err)
    }

    for _, d := range devices.Items {
        log.Printf("%s (%s)", d.Serial, d.Model)
    }
}
```

Two rules the SDK enforces:

1. **`Authenticate(ctx)` must run before any other call.** Token refresh is handled for you afterward.
2. **Every network call takes `ctx context.Context` first.** Use it for timeouts and cancellation.

### Functional options

When environment variables are not appropriate — multiple clients with different credentials in one process, for example — pass functional options instead of poking struct fields:

```go
client, err := gopurple.New(
    gopurple.WithCredentials(clientID, clientSecret),
    gopurple.WithNetwork("production-fleet"),
    gopurple.WithTimeout(30*time.Second),
    gopurple.WithRetryCount(3),
)
```

Available options include `WithCredentials`, `WithNetwork`, `WithTimeout`, `WithRetryCount`, `WithDebug`, `WithEndpoints`, `WithTokenEndpoint`, `WithOIDCURL`, `WithProvisioningEndpoint`, `WithDeviceSerial`, and `WithAccessToken`.

---

## The Client Is Split Into Sub-Services

There is no flat top-level API. A single `Client` struct exposes named sub-services, each scoped to one area:

| Sub-service | Covers |
|-------------|--------|
| `client.Devices` | Device and group management on the main REST API |
| `client.RDWS` | Remote Diagnostic Web Server — per-player operations |
| `client.BDeploy` | B-Deploy provisioning setups and device records |
| `client.Provisioning` | Provisioning operations |
| `client.Subscriptions` | Device subscriptions |
| `client.DeviceWebPages` | Device web pages |

> **There is no `client.Content` sub-service.** BrightSign does not expose the Content cloud APIs through this SDK. Content deployment from your own code goes through the sync spec mechanism described in [BrightSign Author Plus](04-bsn-content.md), not through gopurple.

---

## Device Management

`client.Devices` addresses players by **either** numeric ID or serial number — most operations have both forms, with the serial variant suffixed `BySerial`:

```go
// By serial - usually what you have on hand
device, err := client.Devices.Get(ctx, "D4A3B2C1")
status, err := client.Devices.GetStatusBySerial(ctx, "D4A3B2C1")

// By numeric ID
device, err := client.Devices.GetByID(ctx, 4127)
status, err := client.Devices.GetStatus(ctx, 4127)
```

Representative operations:

```go
// Reboot
resp, err := client.Devices.RebootBySerial(ctx, serial, types.RebootTypeNormal)

// Screenshot
snap, err := client.Devices.TakeSnapshotBySerial(ctx, serial, &types.SnapshotRequest{})

// Recent errors
errs, err := client.Devices.GetErrorsBySerial(ctx, serial)

// Groups
groups, err := client.Devices.ListGroups(ctx)
group, err := client.Devices.CreateGroup(ctx, "lobby-displays")
```

> `Reprovision` / `ReprovisionBySerial` exist on this service and are **close to a factory reset** — see the warning in [Per-Player Control](03-per-player-control.md) before calling either.

### Pagination

List calls accept list options rather than manual query-string building:

```go
devices, err := client.Devices.List(ctx,
    gopurple.WithPageSize(100),
    gopurple.WithFilter("[Model] IS 'XT1145'"),
    gopurple.WithSort("[Serial] ASC"),
)
```

`WithMarker` continues from a previous page. Page size maxes out at 100.

---

## Remote Player Operations

`client.RDWS` wraps the Remote Diagnostic Web Server surface described in [Per-Player Control](03-per-player-control.md), so you never assemble the `destinationType`/`destinationName` query parameters or the `data` envelope yourself. Every method takes the player's serial:

```go
info, err := client.RDWS.GetInfo(ctx, serial)
health, err := client.RDWS.GetHealth(ctx, serial)

// Files
files, err := client.RDWS.ListFiles(ctx, serial, "sd/content")
ok, err := client.RDWS.UploadFile(ctx, serial, "sd/content", "playlist.json", contents, "application/json")

// Network diagnostics
ping, err := client.RDWS.Ping(ctx, serial, "8.8.8.8")
dns, err := client.RDWS.DNSLookup(ctx, serial, "api.bsn.cloud")
route, err := client.RDWS.TraceRoute(ctx, serial, "8.8.8.8")
neighbors, err := client.RDWS.GetNetworkNeighborhood(ctx, serial)

// Remote access control - development players only
ok, err := client.RDWS.SetSSHStatus(ctx, serial, true, 22, tempPassword)
ok, err := client.RDWS.SetLocalDWS(ctx, serial, true)

// Packet capture
id, err := client.RDWS.StartPacketCapture(ctx, serial, req)
path, err := client.RDWS.StopPacketCapture(ctx, serial)
```

`ReformatStorage` is also on this interface. It erases the named storage device — disable the autorun first, or the running presentation holds the device.

---

## Use the Exported Types

Every nested wire type is exported specifically so you get compile-time checking and IDE autocomplete. Reach into fields directly:

```go
// Good - the compiler checks every step of this path
version := device.Status.Firmware.Version

// Wrong - defeats the entire point of the SDK
version := device.(map[string]interface{})["status"].(map[string]interface{})["firmware"]
```

**Optional nested structs are pointers,** so guard the path before dereferencing. `Device.Status` is a `*DeviceStatusEmbed` and `DeviceStatusEmbed.Firmware` is a `*FirmwareInfo`; both are omitted when the platform has nothing to report:

```go
func firmwareVersion(d types.Device) string {
    if d.Status == nil || d.Status.Firmware == nil {
        return ""
    }
    return d.Status.Firmware.Version
}
```

This also gives you tests without HTTP mocking. Construct the typed struct directly in a table-driven test rather than standing up a fake server:

```go
func TestFirmwareVersion(t *testing.T) {
    tests := []struct {
        name   string
        device types.Device
        want   string
    }{
        {"current", types.Device{Status: &types.DeviceStatusEmbed{
            Firmware: &types.FirmwareInfo{Version: "9.1.85"}}}, "9.1.85"},
        {"no status reported", types.Device{}, ""},
    }
    // ...
}
```

Prefer small extractor, validator, and builder functions — typed struct in, derived or validated value out — over field-poking scattered through business logic.

---

## Error Handling

Branch on **typed predicates**, never on error strings or HTTP status codes:

```go
if err := client.Authenticate(ctx); err != nil {
    switch {
    case gopurple.IsAuthenticationError(err):
        log.Fatal("check BS_CLIENT_ID and BS_SECRET")
    case gopurple.IsConfigurationError(err):
        log.Fatal("client is misconfigured")
    case gopurple.IsRetryableError(err):
        // Transient - back off and retry. Rate-limit (429) responses
        // are folded into this predicate.
        return backoffAndRetry(ctx)
    case gopurple.IsNetworkError(err):
        log.Fatal("cannot reach the platform")
    default:
        log.Fatal(err)
    }
}
```

The predicates re-exported at the package root are `IsAuthenticationError`, `IsNetworkError`, `IsConfigurationError`, and `IsRetryableError`. Put retry and backoff decisions behind `IsRetryableError` in one place rather than duplicating them per call site.

---

## Check Endpoint Coverage Before You Write

**The SDK deliberately implements a subset of the platform.** Roughly **72 of the 395 inventoried endpoints (about 18%)** are implemented; the rest are marked `[NOT-DONE]`.

Before writing code against a method that "should" exist, check `docs/all-apis.md` in the SDK for the endpoint's `[DONE]` / `[NOT-DONE]` status. If it is `[NOT-DONE]`, that is not a typo on your side — it means new SDK surface has to be added, which is worth knowing before you plan the work.

Content, presentation, and upload endpoints are absent from the inventory entirely, by design.

---

## Start From the Example Programs

The SDK ships **65 runnable example CLI tools** under `examples/` — complete programs, not snippets. They are the fastest way to see a correct call sequence, and several are useful as-is for operations work.

| Prefix | Area |
|--------|------|
| `main-device-*` | Device info, status, errors, downloads, operations |
| `main-group-*` | Group management |
| `main-subscription-*` | Subscriptions |
| `rdws-*` | Per-player remote operations |
| `bdeploy-*` | B-Deploy setups and device records |

If you are writing your own CLI, match the conventions already established in these examples rather than inventing new flag names: `--network` / `-n` (falling back to `BS_NETWORK`), `--json`, `--verbose`, `--timeout`, and `--force` / `-y`.

---

## Service Layout Worth Copying

If you are building a service that embeds this client, gopurple's own package split is the house pattern:

```text
internal/
├── auth/       OAuth2 token lifecycle
├── config/     Configuration loading and validation
├── errors/     Typed errors and predicates
├── http/       HTTP client wrapper with retry/backoff
├── services/   One file per API area, exposed as named sub-services
└── types/      All exported wire types
```

Keep the public surface a single `Client` struct with named sub-services, construct it with functional options, and take `context.Context` first on every network-calling method.

---

## Related Resources

- [Integrating with BrightSign Control](01-integrating-with-bsn-cloud.md) — the REST surface underneath the SDK
- [Automated Provisioning](02-automated-provisioning.md) — B-Deploy provisioning flows
- [Per-Player Control](03-per-player-control.md) — the Remote DWS surface `client.RDWS` wraps
- [BrightSign Author Plus](04-bsn-content.md) — content deployment, which does not go through this SDK
- [gopurple on GitHub](https://github.com/BrightDevelopers/gopurple) — source, examples, and API inventory

---

[↑ Part 5: BrightSign Control](README.md)
