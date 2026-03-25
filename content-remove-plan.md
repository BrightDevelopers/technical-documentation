# Plan: Remove BSN.content Docs (Content, Presentations, Schedules)

All BSN.content cloud API documentation covering content management, presentations,
and schedules is being relocated to `/external/purplecontent/docs`. This plan
describes every file to delete and every file to edit.

---

## Files to Delete

| File | Reason |
|------|--------|
| `documentation/part-5-bsn-cloud/04-bsn-content.md` | Dedicated BSN.content stub chapter |

No other files are wholesale deletions — the rest have mixed content that requires
surgical edits.

---

## Files to Edit

### 1. `documentation/part-5-bsn-cloud/01-integrating-with-bsn-cloud.md`

Remove the following sections entirely (they cover BSN.content APIs exclusively):

- **"Content Management"** section (starts ~line 210) — includes:
  - Content Library Organization
  - Content Library API examples (`listContent`, `uploadContent`)
  - Content Versioning (`getContentInfo`)
  - Content Tagging (`addContentTags`)
  - Content Distribution / CDN description

- **"Presentation Creation"** section (starts ~line 336) — includes:
  - BrightAuthor:connected workflow
  - Web-based presentation editing
  - Interactive Presentations example (`createPresentation`)

- **"Scheduling and Playlists"** section (starts ~line 426) — includes:
  - Time-based scheduling
  - Day-part scheduling
  - Date ranges / dynamic playlists

Also update the **intro paragraph** (line 9): remove "content management" from the
list of topics covered, keeping provisioning, remote control, and API-based automation.

Also update the **"bsn.Content" service tier block** (lines 36–43): either remove the
entire tier description or replace it with a one-line pointer to `/external/purplecontent/docs`.

Keep everything else: architecture overview, account setup, organization structure,
user management, device provisioning, authentication, and device control.

---

### 2. `documentation/part-5-bsn-cloud/README.md`

- **Chapters table**: remove the BSN.content row:
  ```
  | 4 | [BSN.content](04-bsn-content.md) | Content management and scheduling |
  ```

- **Code Examples table**: remove the Content Management row:
  ```
  | [Content Management](examples/content-management/) | Upload, scheduling, synchronization |
  ```

- **"What You'll Learn" table**: remove the "REST API Integration" row if it refers
  specifically to content/presentation APIs (review in context). If the row is generic,
  keep it.

- Update the section intro text: remove "content management" from the platform
  description.

---

### 3. `documentation/README.md` (Technical Documentation index)

- **Part 5 chapter table**: remove the BSN.content row:
  ```
  | [BSN.content](part-5-bsn-cloud/04-bsn-content.md) | Content management and distribution |
  ```

---

### 4. `howto-articles/10-setting-up-bsn-cloud.md`

- **"What You'll Learn" list** (line 17): remove the bullet:
  ```
  - Deploying content through BSN.cloud
  ```

- **"BSN.cloud Benefits" table** (lines 22–30): remove the rows:
  ```
  | **Content Deployment** | Push content updates without physical access |
  | **Scheduling** | Time-based content scheduling |
  ```

- **"Part 5: Content Deployment"** section (~line 384): remove the entire section,
  including the manual UI steps and the sync spec / programmatic deployment examples.

- Review the **Troubleshooting** table (~line 624): remove any rows that reference
  content not updating or sync spec issues.

- Review **"Next Steps"** section (~line 646): remove the Content Deployment step and
  any link that points to content-specific workflows.

- The article is otherwise about account setup, player registration, and provisioning
  (mDNS, DHCP Option 43, Remote DWS) — keep all of that.

---

### 5. `documentation/part-5-bsn-cloud/examples/README.md`

- Remove the **Content Management** category entry and its link to
  `examples/content-management/`.

---

### 6. `documentation/part-6-appendices/README.md`

- **"Additional Resources" table**: evaluate the BSN.cloud API Reference link
  (`https://docs.bsn.cloud/`). If that URL documents BSN.content APIs (content,
  presentations, schedules) alongside other APIs, replace it with a note pointing to
  `/external/purplecontent/docs` for content APIs. If the URL covers non-content
  APIs (device management, provisioning), keep it.

---

## Files to Leave Unchanged

The following files contain incidental mentions of "content" in the generic sense
(media playback, file downloads) — not BSN.content cloud API references. No changes
needed:

- `documentation/part-2-brightscript-development/01-brightscript-language-reference.md`
- `documentation/part-2-brightscript-development/02-practical-development.md`
- `documentation/part-3-javascript-development/01-javascript-playback.md`
- `howto-articles/04-playing-video-content.md`
- `howto-articles/05-creating-image-slideshow.md`
- `howto-articles/08-fetching-remote-content.md`
- `README.md` (root) — line 57 mentions "managing players, content, and schedules"
  in a generic cloud context; the surrounding text already points to gopurple and
  does not document BSN.content APIs directly. Low-priority edit if desired.

---

## Execution Order

1. Delete `documentation/part-5-bsn-cloud/04-bsn-content.md`
2. Edit `documentation/part-5-bsn-cloud/01-integrating-with-bsn-cloud.md` — remove
   Content Management, Presentation Creation, and Scheduling sections
3. Edit `documentation/part-5-bsn-cloud/README.md` — remove BSN.content chapter row
   and Content Management examples row
4. Edit `documentation/README.md` — remove BSN.content chapter row from Part 5 table
5. Edit `howto-articles/10-setting-up-bsn-cloud.md` — remove Part 5: Content Deployment
   section and associated references
6. Edit `documentation/part-5-bsn-cloud/examples/README.md` — remove Content Management
   category
7. Evaluate and edit `documentation/part-6-appendices/README.md` — update BSN.cloud
   API Reference link as appropriate
8. Verify no dangling internal links remain (`grep -r "04-bsn-content\|content-management"`)
