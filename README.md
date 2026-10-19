# opencode-key-safety

**Video:** VIDEO_URL_TBD (ProAI Clips, "OpenCode Hack Explained: What Was Stolen and What to Do Now")

A calm, ten-minute checklist for the OpenCode Console breach of 16–17 October 2026, plus a small script that tells you whether an old AI key is really dead. It never prints your key.

> **What happened, in one line.** OpenCode says a breach linked to a "large scale distillation attack" exposed outside provider keys (OpenAI, Anthropic, Google) that 1.4% of OpenCode Console users had saved in the hosted Console. The open-source OpenCode app on your machine was not the problem. If you didn't get OpenCode's email, OpenCode says you weren't affected. Sources are at the bottom.
>
> Status as of 19 Oct 2026: OpenCode hasn't published a full write-up or root cause, and OpenAI hasn't made a public statement. Check the sources for updates.

## Were you affected? (video 4:44)

1. Did you ever use **OpenCode Console**, the website (not just the app)?
2. Did you, or anyone on your team, connect an outside provider key in Console's **Providers** tab?
3. Did you get an email titled **"Action Required: Potential provider key breach"**? Check spam too.

## Quick start

Each step has the command, what you should see, and where it is in the video. Run them in any folder. Nothing here needs a real key except step 2, which reads the key from a hidden prompt or `OLD_KEY` and prints only the HTTP status.

### 1. Replace every key you saved in Console (video 6:14)

No command: open the provider's dashboard yourself (don't click links in an email). Create the new key, update your apps, then delete the old one.

Expected: your apps keep working on the new key; the old key is gone from the provider's list.

### 2. Check the old key is really dead (video 6:45)

```bash
git clone https://github.com/schoolofai/opencode-key-safety && cd opencode-key-safety
./scripts/check-key.sh openai      # or: anthropic, gemini
```

Expected output (filmed with a dummy key that was never valid):

```text
Paste the OLD key (input hidden):
401
refused: the key is dead.
```

`200` with `STILL LIVE: revoke this key now.` means the key still works. Revoke it in the provider's dashboard and run the check again. The same check by hand:

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://api.openai.com/v1/models -H "Authorization: Bearer $OLD_KEY"
curl -s -o /dev/null -w '%{http_code}\n' https://api.anthropic.com/v1/models -H "x-api-key: $OLD_KEY" -H 'anthropic-version: 2023-06-01'
```

### 3. Check your usage from 16 October onwards (video 6:56)

No command: open each provider's usage page. Charges you didn't make go to the provider's billing support (Google says exactly that). OpenCode Console account problems: help@anoma.ly.

### 4. Put a ceiling on the damage (video 7:20)

No command: set a monthly spend limit at every provider (Anthropic calls these spend limits). In OpenCode Console: **Budget limits → Monthly workspace budget**. At the cap, requests get HTTP 429 until it resets on the 1st (00:00 UTC).

### 5. One key per tool (video 7:35)

Give every app or agent its own key, with its own limit. Anthropic's advice: separate keys for different purposes, rotated about every 90 days.

### 6. If OpenCode says your Console key expired (video 7:56)

```bash
opencode auth logout
opencode auth login
opencode auth list
env | grep -c '^OPENCODE_API_KEY=' # 1 = an old key in your environment may still be overriding it
```

Expected (`opencode auth list` on a clean machine, filmed in a throwaway folder):

```text
No authenticated integrations
```

After `opencode auth login`, the list shows the integration you just connected. Make a new key in Console first.

### 7. Keep the app updated, official installs only (video 8:22)

```bash
opencode --version
npm view @opencode/cli version
```

Expected (19 Oct 2026):

```text
opencode v2.0.32
2.0.32
```

Install only from https://opencode.ai or the official README. OpenCode is never installed with `iex(irm ...)`.

### 8. Tighten what the agent can touch (video 8:29)

Copy [`examples/opencode.jsonc`](examples/opencode.jsonc) into your project (rules from the OpenCode permissions docs; the last matching rule wins):

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "permissions": [
    { "action": "shell", "resource": "*", "effect": "ask" },
    { "action": "shell", "resource": "git status *", "effect": "allow" },
    { "action": "read", "resource": "*.env", "effect": "deny" },
    { "action": "shell", "resource": "git push *", "effect": "deny" },
  ],
}
```

Then check OpenCode loaded it:

```bash
opencode debug config | grep '"resource"\|"effect"' | paste -d' ' - - | tr -s ' '
```

Expected:

```text
 "resource": "*", "effect": "ask"
 "resource": "git status *", "effect": "allow"
 "resource": "*.env", "effect": "deny"
 "resource": "git push *", "effect": "deny"
```

For code you don't trust, run the agent in a container or a throwaway VM (general good practice, not an OpenCode rule).

## Not this hack (video 9:01)

- **GHSA-632h-h47v-g4x4** (24 Sep 2026): a cross-site request to `opencode serve` could install a package (RCE) for npm/pnpm/Bun installs. Fixed in **1.18.22**. Check `opencode --version` is newer.
- **Fake "easy install" commands** in OpenCode's GitHub issues: one was data-stealing malware.

## Sources

- OpenCode's post: https://x.com/opencode/status/2111519637049319818
- Dax Raad (OpenCode): https://x.com/thdxr/status/2111572618340188393 , https://x.com/thdxr/status/2111608620441817449
- Anthropic (Lydia Hallie): https://x.com/lydiahallie/status/2111563956666110287
- Google AI Studio (Evan Otero): https://x.com/EvanOtero/status/2111591525876474100
- Console providers docs: https://opencode.ai/v2/docs/console/providers/
- Console budgets docs: https://opencode.ai/v2/docs/console/budgets/
- CLI auth docs: https://opencode.ai/v2/docs/cli/providers
- Permissions docs: https://opencode.ai/v2/docs/permissions/
- Advisory: https://github.com/anomalyco/opencode/security/advisories/GHSA-632h-h47v-g4x4
- Datadog Security Labs: https://securitylabs.datadoghq.com/articles/opencode-upgrade-remote-code-execution/
- Fake installer issue: https://github.com/anomalyco/opencode/issues/56424
- Anthropic on distillation: https://www.anthropic.com/research/distillation-defenses
- Anthropic API key best practices: https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure
- Gemini API keys: https://ai.google.dev/gemini-api/docs/api-key

MIT licensed. Not affiliated with OpenCode, Anomaly, Anthropic, OpenAI or Google.
