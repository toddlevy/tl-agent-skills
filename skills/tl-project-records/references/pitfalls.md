# Pitfalls

Lessons from running these records in production repositories, then lessons the quilt sources teach. Each names the symptom, the cause, and the rule that prevents it.

## From production use

1. **A BOM in the subject.** Symptom: a commit subject that looks right but fails every parser, or a changelog bullet with an invisible leading character. Cause: Windows PowerShell 5.1 `Set-Content -Encoding utf8` writes `EF BB BF`. Rule: write message files with `UTF8Encoding($false)`; the hook reads bytes and rejects a BOM.

2. **`git check-attr` says "unspecified" under a directory pattern.** Symptom: a release filter built on `git check-attr export-ignore` lets every file under `tools/` through even though `.gitattributes` has `tools/ export-ignore`. Cause: git applies the directory pattern to the directory for `git archive`, not to each path for `check-attr`. Rule: parse `.gitattributes` lines as the tool does, and fixture-test the filter.

3. **Enforcing subjects on history.** Symptom: CI fails on the first pull request after adoption because of subjects written years ago. Cause: a range check with no starting point. Rule: check only commits that descend from the commit that installed the hook; never rewrite or allowlist history.

4. **Shallow clones.** Symptom: the CI subject check passes vacuously or fails mysteriously. Cause: the default `fetch-depth: 1` hides the install commit and the base. Rule: `fetch-depth: 0`, and a tool that exits 1 in a shallow clone instead of guessing.

5. **A hand-curated `[Unreleased]`.** Symptom: release notes that miss changes, and a merge conflict in `CHANGELOG.md` on every concurrent branch. Cause: a second, manual copy of the commit log. Rule: `[Unreleased]` stays empty; preview renders it, cut writes the stanza.

6. **The ADR trigger rule in three places.** Symptom: agents disagree about whether a change needs an ADR, because `AGENTS.md`, a skill, and the README each say something slightly different. Cause: the rule was restated. Rule: one home (`docs/adr/README.md`); everything else links it.

7. **Editing accepted ADRs.** Symptom: an ADR whose Decision no longer matches what was decided at its acceptance date, with no record of when it changed. Cause: "small" amendments in place. Rule: accepted ADRs are immutable except the status and cross-reference lines; a revisited decision is a new ADR.

8. **Citing work by a path that moves.** Symptom: dead links in ADRs and DEVLOG entries after a plan or epic is archived. Cause: citing `plans/active/foo/` while it is active. Rule: cite work in flight by file name plus commit SHA; a path is only stable once archived.

9. **Invented rationale in backfilled records.** Symptom: an ADR whose "Alternatives considered" lists options nobody considered. Cause: an author, often an agent, filling the template from plausibility. Rule: rationale only where evidence names it; otherwise "None recorded at the time."

10. **Hooks that never fire.** Symptom: non-conforming subjects keep landing although the hook is committed. Causes: `core.hooksPath` not set in that clone, a CRLF shebang, a missing executable bit (a Windows pathspec commit silently drops a staged `+x`), or `pwsh` absent from `PATH`. Rule: set `core.hooksPath` per clone, commit hooks LF and `100755` and confirm with `git ls-tree`, and keep `check-range` in CI as the backstop for every one of these.

## From the quilt sources

11. **Logging everything.** A DEVLOG that records every session becomes a second commit log that nobody reads. Log decision points and outcomes only; in-flight work waits for its decision point.

12. **Secrets in records.** Records are committed and usually public to the whole team. Never write a credential, token, key, or personal data, and redact before drafting rather than after.

13. **Committing a record without showing it.** A standalone entry or ADR the user never saw is the agent's account, not the project's. Show the draft in full and commit after confirmation; ceremony-written entries are shown in the ceremony report.

14. **An ADR an agent cannot act on.** A Decision section that needs the reader to infer scope, or a "Compliance" section that describes a manual review, gives the next agent nothing to enforce. Run the agent-readiness review in `adr.md` before accepting.

## From adoption reviews

15. **A hook that resolves the wrong runtime.** Symptom: a chained `node`, `pnpm`, or `python` step in the same hook runner fails with a version error or "not found", while the same command works in an interactive shell. Cause: git runs hooks without loading the PowerShell profile, so a profile-based version manager (fnm, nvm-windows, pyenv-win) never activates and the system runtime wins. Rule: activate any such runtime explicitly inside the hook (see the `powershell-git` skill, section 4b, "Activate profile-based version managers explicitly"). `project-records.ps1` itself needs only `git` and PowerShell, and stays free of Node and Python.
