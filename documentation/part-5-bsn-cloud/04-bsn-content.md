# BrightSign Author Plus

[← Back to Part 5: BrightSign Control](README.md) | [↑ Main](../../README.md)

---

## Introduction

BrightSign Author Plus is the content-management side of BrightSign Control: where media and presentations live, how they are organized, and how they reach players. This chapter covers the content model and the programmatic path — the **sync spec** — that a custom deployment system uses to drive what a player downloads.

If you are building a CMS or a custom deployment pipeline, the sync spec is the part that matters. If you only need to publish content that humans authored, BrightSign Author and the BrightSign Control web interface already do this for you.

---

## The Content Model

Content lives in a virtual filesystem rooted at **`/Root`**. The documented top-level organization is:

```text
/Root
├── Images/
├── Videos/
└── Presentations/
```

This is a *virtual* path structure, not a directory layout on any particular disk. The same asset can be referenced from multiple presentations without being duplicated, and the physical storage is managed by the platform.

---

## Two Authoring Paths

There are two independent ways to get content into a BrightSign Control network:

**BrightSign Author** — BrightSign's desktop authoring application. It builds presentations locally and can publish directly to a BrightSign Control network.

**The BrightSign Control web interface** — upload, author, and publish entirely in the browser, with no desktop application involved.

> These are two separate paths to the same destination, not two halves of one workflow. It is reasonable to author in BrightSign Author and manage the result through the web interface afterward, but whether that combination is a formally supported flow is not clearly documented. Confirm with BrightSign before building a process that depends on it.

For programmatic deployment, neither path applies — use the sync spec below.

---

## Sync Specs: The Programmatic Path

A **sync spec** is a JSON document describing exactly what files a player should have. It is the mechanism behind custom and automated content deployment.

You host the sync spec yourself and write its **URL** to the player's **`nu` registry key** in the **`networking`** section. The player fetches that URL on check-in, downloads what it is missing, deletes what it should no longer have, and reports the result.

```brightscript
Sub ConfigureSyncSpec()
    reg = CreateObject("roRegistrySection", "networking")
    reg.Write("nu", "https://content.example.com/sync-spec.json")
    reg.Flush()
End Sub
```

Note that the registry holds the *pointer*, not the document. To change what a player should have, update the JSON at that URL — the player picks it up on its next check-in with no registry change needed.

### Structure

```json
{
    "meta": {
        "client": "custom-cms",
        "version": "1.0"
    },
    "files": {
        "download": [
            {
                "name": "welcome-v4.mp4",
                "link": "https://cdn.example.com/content/welcome-v4.mp4",
                "size": 52428800,
                "hash": "sha256:e3b0c44298fc1c149afbf4c8996fb924..."
            },
            {
                "name": "playlist.json",
                "link": "https://cdn.example.com/content/playlist.json",
                "size": 1024,
                "hash": "sha256:2c26b46b68ffc68ff99b453c1d304134..."
            }
        ],
        "delete": [
            "welcome-v3.mp4"
        ]
    }
}
```

### Field reference

| Field | Meaning |
|-------|---------|
| `meta.client` | Identifies the system that generated the spec |
| `meta.version` | Spec format version, as a string |
| `files.download[]` | Everything the player should have |
| `files.download[].name` | Destination filename on the player |
| `files.download[].link` | Absolute URL the player fetches from |
| `files.download[].size` | Expected byte count |
| `files.download[].hash` | **SHA-256** checksum, as a `sha256:<hex>` string |
| `files.delete[]` | Files to remove from the player |

> **Use SHA-256.** Content integrity is verified with SHA-256, matching [Integrating with BrightSign Control](01-integrating-with-bsn-cloud.md). Older examples showing a `sha1:` prefix are out of date — generate SHA-256 digests when building specs.

### Why the hash matters

The hash is not only integrity checking — it is how the player decides whether to download at all. A file already present with a matching hash is skipped. This is what makes a sync spec safe to re-apply: pushing the same spec twice costs almost no bandwidth.

It also means **you must change the hash when you change a file**. Reusing a filename with new bytes but a stale hash leaves players holding the old content and reporting success. Version your asset URLs (`welcome-v4.mp4`, not `welcome.mp4`) so this cannot happen.

### Why the hash matters

The hash is not only integrity checking — it is how the player decides whether to download at all. A file already present with a matching hash is skipped. This is what makes a sync spec safe to re-apply: pushing the same spec twice costs almost no bandwidth.

It also means **you must change the hash when you change a file**. Reusing a URL with new bytes but a stale hash in the spec leaves players holding the old content and reporting success. Version your asset URLs (`welcome-v4.mp4`, not `welcome.mp4`) so this cannot happen.

---

## Content Synchronization Cadence

Players registered with BrightSign Control check in for content changes on an interval that **defaults to 15 minutes**.

> A player-side self-updater pattern that polls for a fresh `autorun.zip` also commonly uses a ~15-minute interval. These are separate mechanisms that happen to share a default; do not assume changing one affects the other. See [Automated Provisioning](02-automated-provisioning.md).

Related delivery controls — bandwidth limiting, progressive downloads, and offline fallback — are covered in [Integrating with BrightSign Control](01-integrating-with-bsn-cloud.md).

---

## Choosing an Approach

| Situation | Use |
|-----------|-----|
| Humans author presentations | BrightSign Author or the BrightSign Control web interface |
| A CMS drives content programmatically | Sync spec URL in the `nu` registry key |
| Whole-application updates, not just media | `autorun.zip` self-update — see [Automated Provisioning](02-automated-provisioning.md) |
| One-off file push to a single player during development | Local DWS `PUT /api/v1/files/...` |

The sync spec and `autorun.zip` self-updating solve adjacent problems. The sync spec manages **content** against a cloud-hosted manifest; `autorun.zip` replaces the **application** from a server you host yourself. A self-hosted deployment is the lighter-weight option when you do not need the rest of BrightSign Control.

---

## Verifying a Deployment

Do not treat a successfully written sync spec as proof that content landed. Confirm on the device:

```bash
# List what is actually on the player
curl --digest -u admin:<dws-password> \
  http://<player-ip>/api/v1/files/sd/videos

# Take a screenshot of what is actually on screen
curl --digest -u admin:<dws-password> -X POST \
  http://<player-ip>/api/v1/snapshot
```

Remotely, the same checks run through Remote DWS — see [Per-Player Control](03-per-player-control.md).

---

## Related Resources

- [Integrating with BrightSign Control](01-integrating-with-bsn-cloud.md) — content management, distribution, bandwidth, offline fallback
- [Per-Player Control](03-per-player-control.md) — verifying and controlling individual players
- [Setting Up BrightSign Control](../../howto-articles/10-setting-up-bsn-cloud.md) — "Part 5: Content Deployment" walkthrough
- [Fetching Remote Content](../../howto-articles/08-fetching-remote-content.md) — application-level downloading and caching

---

[↑ Part 5: BrightSign Control](README.md)
