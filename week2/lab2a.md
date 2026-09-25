# Lab 2.A — A service and a timer

## 1. Unit Files

### `/etc/systemd/system/disk-report.service`
```ini
[Unit]
Description=Append disk usage to log
Documentation=man:df(1)
After=local-fs.target

[Service]
Type=oneshot
User=reports
ExecStart=/usr/local/bin/disk-report.sh
StandardOutput=append:/var/log/disk-report.log
StandardError=append:/var/log/disk-report.log




### /etc/systemd/system/disk-report.timer
[Unit]
Description=Run disk-report every five minutes
Documentation=systemd.time(7)

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target



## 2. Initial journal Error

Sep 24 06:20:01 normaalne disk-report.sh[15040]: /usr/local/bin/disk-report.sh: line 2: /var/log/disk-report.log: Permission denied
Sep 24 06:20:01 normaalne systemd[1]: disk-report.service: Main process exited, code=exited, status=1/FAILURE

Analysis:

    What it said: The execution of /usr/local/bin/disk-report.sh failed at line 2 due to a Permission denied error when trying to write to /var/log/disk-report.log.
    What it told us: The service was executed under the non-root dedicated user User=reports. Because /var/log is owned by root:root with default restricted permissions, an unprivileged user cannot write to files in that directory.
    Confirmation: The explicit error line /var/log/disk-report.log: Permission denied confirmed that missing filesystem write permissions caused the exit code failure.

## 3. Why option B is better than A
Option B (StandardOutput=append:) is superior to Option A (chown) because it adheres strictly to the principle of least privilege.
In Option A, file ownership is manually altered, which is fragile: if the log file is removed, rotated, or recreated, permissions break immediately, and the reports user still retains write permissions within the log file itself.
Option B allows systemd (running as root) to open the file handle on behalf of the service prior to dropping privileges to reports.
The script remains completely agnostic of the log destination, requiring no directory-level write permissions for the service account.

## 4. Verification outputs

systemctl list-timers disk-report.timer

NEXT                        LEFT LAST                         PASSED    UNIT              ACTIVATES
Sat 2026-09-26 00:00:00 UTC  18h Fri 2026-09-25 05:30:34 UTC  6min ago disk-report.timer disk-report.service


Sucessful log entries from: /var/log/disk-report.log

=== 2026-09-24T06:52:37+00:00 ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        25G  3.0G   21G  13% /
=== 2026-09-25T05:30:34+00:00 ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        25G  3.0G   21G  13% /

## 5. Two lines from journalctl

Sep 25 05:30:34 normaalne systemd[1]: disk-report.service: Deactivated successfully.
Sep 25 05:50:33 normaalne systemd[1]: disk-report.service: Deactivated successfully.

## 6. Security flag analysis

The reports user was created with --no-create-home and --shell /usr/sbin/nologin because it gives 
least privelege for background daemon and no storage or interactive login permissions.
If these flags were omitted, an attacker would get access to home directory and login shell, making
it much easier for the attacker to show their preserence.
