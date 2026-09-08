# Moodle Permissions Manager

Sets ownership and file modes on a Moodle installation according to Moodle's
own security guidance, in two selectable models.

- **Release:** 26.09
- **Author:** Daniele Lolli (UncleDan)
- **Licence:** GPL-3.0
- **Applies to:** Moodle 4.x and 5.x (the permission model is branch independent)

---

## What it does

Moodle's security documentation is explicit that the web service account needs
no write permission on the code tree. A default installation rarely follows
that: the web user often owns everything, which turns any file-write bug or
compromised plugin into persistent code execution.

This script applies one of two models:

| | `--semi-harden` (default choice) | `--harden` |
|---|---|---|
| Code tree owner | `root:<webgroup>` | `root:root` |
| Code dirs / files | 0755 / 0644 | 0755 / 0644 |
| `config.php` | `root:<webgroup>` 0640 | `root:<webgroup>` 0640 |
| Plugin type dirs | 2775 / 0664 (group-writable, setgid) | 0755 / 0644 |
| moodledata owner | `<webuser>:<webgroup>` | `<webuser>:<webgroup>` |
| moodledata dirs / files | 0750 / 0640 | 0750 / 0640 |
| `.htaccess` in moodledata | created, `root:<webgroup>` 0640 | not created |
| Plugin install/update/uninstall from the web UI | works | blocked |

`--harden` reproduces the TurnKey Linux Moodle appliance layout. `--semi-harden`
keeps the same protection for core code but grants group write on the plugin
type directories only, so the web UI remains fully interactive.

Neither mode pre-creates anything under moodledata. Moodle creates its own
subdirectories on demand via `make_*_directory()`, using the mode in
`$CFG->directorypermissions`; pre-creating them would impose a mode Moodle did
not choose.

### What `--harden` actually blocks

Exactly three web UI actions: install, update and uninstall a plugin. Everything
else writes to moodledata and keeps working — language packs (they install into
`dataroot/lang`, not `dirroot/lang`), theme changes and SCSS, backups and
restores, H5P content and libraries, file uploads, cache purges, analytics
models, antivirus quarantine, and every database-backed setting.

### What `--semi-harden` protects

After a run, the web service can no longer write to `lib/`, `install/`,
`admin/` outside `tool` and `report`, `vendor/`, `.git/`, `index.php`,
`version.php` or `config.php`. It retains write access to the 43 plugin type
directories and to moodledata.

The trade-off: the plugin type directories are made writable **recursively**,
because updating or uninstalling a plugin means deleting its existing directory
tree, not just writing into the parent. Core plugins that live inside those
roots (`mod/assign`, `theme/boost`, …) are therefore writable too.

---

## Requirements

- Bash
- root privileges for `--semi-harden` and `--harden`
- `php` on `PATH` is optional — used to read `config.php` accurately; without it
  a literal text parse is used instead

The web user is detected automatically, trying `www-data`, then `apache`, then
`nginx`, falling back to `www-data`.

---

## Usage

```
moodle_permissions_manager.sh [OPTIONS]
```

| Option | Description |
|---|---|
| `-h`, `--help` | Show the built-in help |
| `-d`, `--dry-run` | Print every operation without executing it |
| `-sh`, `--semi-harden` | Apply the semi-hardened model (requires root) |
| `-f`, `--fix` | Alias of `--semi-harden`, kept for compatibility |
| `-hd`, `--harden` | Apply the fully hardened model (requires root) |
| `-c`, `--clear-cache` | Purge the Moodle cache afterwards |
| `-mp`, `--moodlepath PATH` | Moodle path (default `/var/www/moodle`) |
| `-md`, `--moodledata PATH` | moodledata path; read from `config.php` if omitted |

`--semi-harden` and `--harden` are mutually exclusive, as are `--dry-run` and
`--semi-harden`. Use `--dry-run --harden` to simulate the hardened model.

### Examples

```bash
# see what would happen, changing nothing
./moodle_permissions_manager.sh --dry-run

# usual case: paths read from config.php
sudo ./moodle_permissions_manager.sh --semi-harden

# full TurnKey-style lockdown, then purge caches
sudo ./moodle_permissions_manager.sh --harden --clear-cache

# explicit paths, nothing read from config.php
sudo ./moodle_permissions_manager.sh -mp /srv/moodle -md /srv/moodledata -sh
```

---

## Path resolution

Any path not supplied on the command line is read from `config.php`:

- `-mp` always wins over `$CFG->dirroot`
- `-md` always wins over `$CFG->dataroot`
- if both are supplied, `config.php` is never opened

`config.php` is read with PHP when available, defining `ABORT_AFTER_CONFIG` so
`lib/setup.php` returns before bootstrapping Moodle. This handles configs where
`dataroot` is built from a variable or concatenation. Without PHP, a literal
`sed` parse of the assignment is used — that fallback expects the assignment at
the start of a line, which is how real Moodle configs are written.

The header reports where each path came from: `(argument)`, `(config.php)` or
`(default)`.

---

## Plugin type directories

`--semi-harden` grants group write on 43 plugin type roots, defined in the
`PLUGIN_TYPE_DIRS` array near the top of the script:

```
mod  blocks  theme  local  filter  enrol  auth  report
admin/tool  admin/report
question/type  question/behaviour  question/format  question/bank
course/format  availability/condition  calendar/type  message/output
repository  portfolio  plagiarism  webservice
cache/stores  cache/locks  contenttype  customfield/field  dataformat
files/converter  gradingform  grade/export  grade/import  grade/report
h5p/h5plib  lib/antivirus  lib/editor  media/player  payment/gateway
search/engine  user/profile/field  communication/provider
ai/provider  ai/placement  mnet/service
```

Entries that do not exist are skipped and counted, so the same list works
across branches — on a 4.05 install the newer types are simply reported as not
present. Moodle validates plugin installation per plugin type directory, so
this is the exact granularity the installer checks.

Add new entries here if a future Moodle release introduces a plugin type.

---

## SELinux

The script changes owner and mode only. It does **not** relabel SELinux
contexts. On RHEL, Alma, Rocky or Fedora with SELinux enforcing, a recursive
`chown`/`chmod` can leave the tree with wrong labels, and the web service will
be denied access even when owner and mode look correct.

```bash
restorecon -R -v /var/www/moodle /var/moodledata
```

If the labels were never defined:

```bash
semanage fcontext -a -t httpd_sys_content_t    '/var/www/moodle(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/moodledata(/.*)?'
```

Check with `getenforce` and `ls -Z`. Both modes print this reminder on
completion.

---

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Invalid arguments |
| 2 | Root required for `--semi-harden` / `--harden` |
| 3 | Directory not found |
| 5 | `chmod` error |
| 6 | `chown` error |
| 8 | Cache purge error |
| 9 | `config.php` not found or not readable |
| 10 | `$CFG->dataroot` not found in `config.php` |

Codes 4 and 7 are reserved and no longer returned.

---

## Notes and caveats

- **Plugin updates and root-deployed plugins.** Under `--semi-harden`, plugins
  installed through the UI are group-writable and update normally. Under
  `--harden`, all plugin management moves to the CLI as root.
- **PHP-FPM pool users.** Detection assumes the web service runs as the
  detected user. If PHP-FPM runs under a different user than the web server,
  adjust `WWW_USER` / `WWW_GROUP` accordingly.
- **`.htaccess` protects nothing on Nginx**, and nothing at all when moodledata
  sits outside the served tree — which is where it belongs. `--semi-harden`
  still writes one as a defence in depth; `--harden` does not.
- **Piping the output through `head`** kills the run mid-way via SIGPIPE and
  leaves the tree half-processed. Redirect to a file instead.
- **`$CFG->preventexecpath = true`** is worth setting in `config.php`
  independently; this script does not manage it.

---

## History

The version scheme is `YY.MM`.

### 26.09

A rewrite of what the script does, not just how it does it. Prompted by
comparing the original permission model against the TurnKey Linux Moodle
appliance and Moodle's own security guidance, which showed the script was
loosening security rather than tightening it.

- **Translated to English.** All comments and output strings; logic, variable
  names, flags and exit codes unchanged.
- **New `--harden` mode.** Reproduces the TurnKey layout: code tree
  `root:root`, `config.php` not writable by the web service, moodledata
  0750/0640.
- **`--fix` replaced by `--semi-harden`.** The old model gave the web user
  ownership of the entire code tree with `u=rwX`, and left `config.php`
  web-writable. The new model keeps the code read-only for the web service
  while granting group write on plugin type directories only, so the web UI
  stays fully interactive. `-f` / `--fix` remains as an alias.
- **Directory pre-creation removed** from both modes. Moodle creates its own
  moodledata subdirectories with the configured mode. The old 4.x/5.x split was
  also inaccurate — `localcache` and `muc` are long-standing, not 5.x-only —
  and the list was missing `muc`, `models` and `antivirus_quarantine`.
- **`chmod +x` on `admin/cli/*.php` dropped.** Those scripts are invoked as
  `php script.php`; the executable bit was never needed.
- **Paths read from `config.php`.** `$CFG->dataroot` and, when explicitly set,
  `$CFG->dirroot`, with new exit codes 9 and 10 when resolution fails. The
  header now shows the provenance of each path.
- **`-mv` / `--moodleversion` removed.** Once pre-creation was gone, the branch
  selector affected nothing but printed output. Exit code 4 is now reserved.
- **SELinux documented** in the help and in the completion message of both
  modes. Deliberately not executed by the script.
- **`.htaccess` hardened** in `--semi-harden` (`root:<webgroup>` 0640 instead of
  web-writable 0660) and removed from `--harden`.
- **Default branch bumped to 5.2** before the branch selector was removed
  entirely.

### 26.06

Initial unified script. Supported `MOODLE_405_STABLE` through
`MOODLE_502_STABLE` with `-mv`, applied `www-data` ownership across both trees,
`u=rwX,g=rX,o=rX` on the code and `u=rwX,g=rwX,o=` on moodledata, hardened
`config.php` to 640, wrote a `deny from all` `.htaccess` into moodledata,
made `admin/cli/*.php` executable, and pre-created version-specific moodledata
directories. Italian interface, `--dry-run` and `--clear-cache` already
present.

---

## Licence

GPL-3.0
