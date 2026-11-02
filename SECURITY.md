# Security policy

## Supported versions

Only the latest release in the Connect IQ Store gets security fixes. If you use an older version or a sideloaded build, update first and check that the problem is still there.

## Scope

Report a security problem if it is about:

- **API key handling**: the Liftosaur API key leaking from the app settings, watch storage, logs, the Garmin activity, or a store build. Store builds must contain no key.
- **Data sent to liftosaur.com**: the app sending data anywhere other than liftosaur.com, sending more than `store/PRIVACY.md` describes, or sending it without HTTPS.
- Anything else in this repo that exposes a user's Liftosaur account or workout data.

Out of scope, and to be reported elsewhere:

- Problems in Liftosaur's servers or apps: report them to Liftosaur (https://github.com/astashov/liftosaur).
- Problems in Garmin firmware, Connect IQ or Garmin Connect: report them to Garmin.
- A key a developer built into their own sideloaded `.prg`. That build is meant for one person; anyone with the file can use the key in it, as `README.md` says.

## How to report

Report privately through GitHub's private vulnerability reporting: open the repo's **Security** tab and choose **Report a vulnerability**. Do not open a public issue.

Include:

- what the problem is and what an attacker could do with it
- steps to reproduce, with the watch model and app version
- any fix you suggest

Do not include a real API key. If your own key may have leaked, delete it in Liftosaur (Settings → API Keys) and create a new one.

## What happens next

This is a spare-time project with one maintainer. Expect a first reply within two weeks. After a fix is in a store release, the advisory is published, with credit to you if you want it.
