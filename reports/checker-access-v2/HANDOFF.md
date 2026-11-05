# Authorized v2 scoring and repair continuation

Status: checker access blocked. Packaging is complete. No additional simulated tests were run in this access-restoration turn. The original 88 candidates and sealed scoring bundle are preserved, as are the frozen runner sources and deployment archive.

The user has authorized the complete continuation sequence once checker access works; do not ask again for permission to score or run the counted integration subset/full repairs within these constraints.

1. Restore a working, verified route. Run real golden controls and separate setup/tool/license/timeouts from design failures.
2. Complete initial scoring on all 44 circuits in both arms, with all six token-limit candidates retained. Use the isolated validated v2 evaluation tree from commit 1720644e, not stale live paths.
3. Choose a small real subset spanning different earliest repair failures, including both arms where available. If a failure class is absent, record its absence rather than manufacturing a failure. Do not select or tune feedback based on Jasper outcomes. These are experiment repairs, not disposable smoke tests: count every generation and retain every artifact.
4. Use the same output tree and max-repairs=3 for integration and full continuation. Resume the subset in place when expanding to both arms. Never reset generation counters, regenerate initial candidates, or restart completed inference. The integration subset must not use max-repairs=1, because the chain identity fixes the budget and must remain resumable.
5. Run final Jasper grading independently and produce the initial-versus-final paired report. Distinguish the repair pipeline pass (ports/compile/functional/lint/enhanced) from the original all-five grading criterion (compile/functional/lint/enhanced/Jasper). Report ports and protocol evidence separately, with per-circuit gains/losses, repair counts and infrastructure categories. Keep all 44 circuits in each arm denominator.

Frozen identities and source checksums are in continuation.json. Prompts, evaluation assets, model settings and adapter must remain fixed. No feedback tuning from Jasper is permitted. Add simulated tests only if a specific real integration problem requires them. If an integration bug needs a code revision, preserve existing generations and identities; implement and document a compatible versioned resume migration instead of restarting chains or resetting budgets.

## Ready artifacts

- scripts/README-qwen38-repair.md: deployment, checksum-bound golden controls, endpoint protocol and future execution instructions.
- reports/runner-tests/qwen38-v2-repair-v1/repair-tools.tar.gz and adjacent SHA256: deployable runner/checker tools.
- experiments/frozen-base-lora-cdc-explicit-attempt1-v2/scoring/scoring-bundle.tar.gz and adjacent SHA256: immutable v2 candidates/evaluator bundle.
- reports/runner-tests/qwen38-v2-repair-v1/source-sha256.json: frozen feedback/runner code.

## Access findings

Direct ecs05.poly.edu resolves to 128.238.147.83, but TCP/22 times out from the login host and from compute node cs634 (Slurm diagnostic 21910270; no GPU or model job). The NYU gateway is reachable but requires keyboard-interactive authentication and rejects BatchMode. Both documented individual DTNs are reachable, but neither matches the pinned ED25519/ECDSA host keys. Host-key verification was not disabled and existing known_hosts was not changed. A new gateway first-use key was recorded only in task-local gateway-known-hosts.

A working VPN/jump route or an existing authenticated checker-side session is needed. No real controls, full initial scoring, or repairs were launched while access remained blocked. Full connection diagnostics are saved in this directory; earlier direct-access logs remain with the scoring and runner-test artifacts.

## Authenticated-route update

The DTN identity/authentication blocker has been resolved. Outside the sandbox, the host has a valid HPC.NYU.EDU Kerberos ticket. NYU's managed SSSD host directory confirms the current canonical dtn011/dtn012 host keys. Authenticated SSH to both canonical DTNs succeeded with strict host-key checking; the old dtn.torch alias pins in ~/.ssh/known_hosts remain unchanged. Managed host-key snapshots are stored separately in this directory.

The remaining blocker is reaching ecs05 itself: both authenticated DTNs time out connecting to 128.238.147.83:22, and the end-to-end ProxyJump attempt times out before the checker presents a banner. No VPN client/profile is available on the HPC host. An interactive gateway attempt was also stopped because its key differs from the task-local first-use pin; no key was replaced.

A working campus VPN/jump route or authenticated ecs05-side session is now required. No real checker controls, scoring, or repairs have run. See authenticated-route-status.json and verified-dtn011-route.stdout.log. Continue the already authorized phases above once the network route works; no generation/retraining/simulated testing is needed while blocked.

## NYU support request submitted

The connectivity request in support-request.eml was submitted to NYU Tandon IT (soehelpdesk@nyu.edu) through the host mail service. sendmail returned exit 0; this establishes local acceptance, not confirmed remote delivery. support-submission.json records the Message-ID and request hash. Replies go to ft2335@nyu.edu. Do not automatically resend the request. Frozen inputs and the recorded continuation sequence remain unchanged; wait for a working supported route or checker-side session before real evaluation.

## Support email cancellation requested

The user revoked the email and requested deletion. Local support-request.eml and support-request.txt drafts were deleted. Do not recreate or resend them. Cancellation of the submitted spool entry is not confirmed: Postfix showq is unavailable and sudo requires a password. support-cancellation.json retains the exact Message-ID/recipient for administrator removal. Do not start/flush the mail service. No further external messages are authorized.

## Git publication handoff

See GIT-DEPLOYMENT.md for the isolated-worktree fetch commands and ECS05-CODEX-MESSAGE.md for the continuation instruction. The Git handoff intentionally omits model weights, SSH/credential material, and revoked email metadata. GPU repairs use the original frozen local weights on Torch; the checker and grading run on ecs05. No merge into the dirty ecs05 checkout is authorized or needed.
