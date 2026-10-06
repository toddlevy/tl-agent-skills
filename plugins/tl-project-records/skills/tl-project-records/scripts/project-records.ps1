<#
.SYNOPSIS
  Project records tool: the commit-subject rule, the archive rule, whole-tree record checks, and the
  changelog renderer for an ADR directory, DEVLOG.md, and CHANGELOG.md.

.DESCRIPTION
  One script owns every records check and the changelog renderer. The commit-msg and pre-commit hook
  shims call it, the CI records job calls it, and operators run it from Windows PowerShell 5.1 or
  PowerShell 7 on any platform.

  Configuration: every repository-specific value (paths, the commit-type vocabulary, the changelog
  section order, the release tag pattern, the optional archive rule and removal ledger) lives in one
  JSON file, records.config.json at the repository root unless -Config names another file. The script
  carries no defaults for those values, so the config file is the single home for the vocabulary.
  self-test needs no config.

  Output contract: every diagnostic line is prefixed with the configured logPrefix. Success lines go
  to stdout and failure lines to stderr. The one exception is changelog-preview without -OutFile,
  whose stdout is the raw markdown with no prefix. Its warnings (skipped unparseable subjects) are
  WARN-prefixed lines on stderr, followed by a closing "Preview rendered N commits, skipped M" line,
  so a capture of either stream sees them.

  Subcommands and exit codes:

    check-msg <path>
      Subject rule for a commit message file. The file is read as raw bytes so a UTF-8 byte order
      mark is seen. Exit 0 when the subject is accepted, 1 otherwise.

    check-commit
      Archive rule for the staged commit: every added file under the configured archive root that
      ends with the configured suffix needs its key (the first path segment below the root) named as
      a whole token in the staged DEVLOG. Exit 0 when the rule passes or is not configured, 1 otherwise.

    check-range -Base <rev> -Head <rev>
      Applies the subject rule to every non-merge commit in Base..Head that descends from the commit
      that first added the configured commit-msg hook, or from subject.enforceFrom when the config
      sets it. Exit 1 in a shallow clone, when a subject fails, when subject.enforceFrom does not
      resolve, or when Head has lost the hook file. Exit 0 with "0 checked" when no enforceFrom is
      set and Head has no install commit.

    check
      Whole-tree record checks: ADR names, numbering, headers, and index; DEVLOG structure, date
      order, categories, ADR references, and coverage of every archived key; CHANGELOG headings,
      tags, and sections. Exit 0 or 1.

    changelog-preview [-From <rev>] [-To <rev>] [-OutFile <path>]
      Renders the [Unreleased] section for the range (defaults from the config) to stdout, or to
      -OutFile as UTF-8 without a BOM. Never touches CHANGELOG.md.

    changelog-cut -Tag <tag> [-From <rev>]
      Writes the release stanza for an existing tag that matches the configured tag pattern directly
      below [Unreleased] in CHANGELOG.md and updates the compare links. Exit 1 on any refusal.

    self-test
      Fixtures built in temp directories and temp git repositories only. Exit 0 when every fixture
      passes, 1 otherwise.

  Any unknown subcommand, unknown flag for the subcommand, missing required value, or invalid config
  exits 1.

.EXAMPLE
  ./scripts/project-records.ps1 check
  ./scripts/project-records.ps1 check-msg .git/COMMIT_EDITMSG
  ./scripts/project-records.ps1 check-range -Base origin/main -Head HEAD
  ./scripts/project-records.ps1 changelog-preview -OutFile ./pr-body.md
  ./scripts/project-records.ps1 changelog-cut -Tag v1.4.0
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command,
    [Parameter(Position = 1)][string]$Path,
    [string]$Base,
    [string]$Head,
    [string]$From,
    [string]$To,
    [string]$OutFile,
    [string]$Tag,
    [string]$Config
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RecordsDefaultLogPrefix = '[REC][Records]'
$script:RecordsConfigFileName = 'records.config.json'
$script:RecordsScriptPath = $PSCommandPath
$script:RecordsCommands = @('check-msg', 'check-commit', 'check-range', 'check', 'changelog-preview', 'changelog-cut', 'self-test')
$script:RecordsUtf8 = New-Object System.Text.UTF8Encoding $false
$script:RecordsUtf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$script:RecordsAdrStatusRegex = [regex]::new('\A(Proposed|Accepted \(\d{4}-\d{2}-\d{2}\)|Superseded by \d{4}|Deprecated)\z')
$script:RecordsScopePattern = '[a-z0-9][a-z0-9-]*'
$script:RecordsLatestTagToken = '@latest-tag'
$script:RecordsFixtureRoot = $null

# ---------------------------------------------------------------------------------------------
# Outcomes: lines are stored unprefixed; the CLI applies the configured prefix when it writes them.
# ---------------------------------------------------------------------------------------------

function New-RecordsOutcome {
    param([int]$ExitCode, [string[]]$Lines, [string[]]$Warnings = @(), [string]$Summary = '')
    $stdoutLines = if ($ExitCode -eq 0) { @($Lines) } else { @() }
    $stderrLines = if ($ExitCode -eq 0) { @() } else { @($Lines) }
    return [pscustomobject]@{
        ExitCode    = $ExitCode
        Lines       = @($Lines)
        StdoutLines = @($stdoutLines)
        StderrLines = @($stderrLines)
        Warnings    = @($Warnings)
        Summary     = $Summary
        Raw         = $false
    }
}

function New-RecordsSplitOutcome {
    param([int]$ExitCode, [string[]]$StdoutLines, [string[]]$StderrLines)
    return [pscustomobject]@{
        ExitCode    = $ExitCode
        Lines       = @(@($StdoutLines) + @($StderrLines))
        StdoutLines = @($StdoutLines)
        StderrLines = @($StderrLines)
        Warnings    = @()
        Summary     = ''
        Raw         = $false
    }
}

function New-RecordsRawOutcome {
    param([string[]]$Lines, [string[]]$Warnings = @(), [string]$Summary = '')
    return [pscustomobject]@{
        ExitCode    = 0
        Lines       = @($Lines)
        StdoutLines = @($Lines)
        StderrLines = @()
        Warnings    = @($Warnings)
        Summary     = $Summary
        Raw         = $true
    }
}

# ---------------------------------------------------------------------------------------------
# Text and process helpers
# ---------------------------------------------------------------------------------------------

function Test-RecordsBom {
    param([AllowNull()][AllowEmptyCollection()][byte[]]$Bytes)
    if ($null -eq $Bytes) { return $false }
    return ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF)
}

# Lenient by default so reading records and git output never fails; -Strict throws on an invalid
# UTF-8 sequence, which the commit-message rule turns into the `encoding` verdict.
function ConvertFrom-RecordsBytes {
    param([AllowNull()][AllowEmptyCollection()][byte[]]$Bytes, [switch]$Strict)
    if ($null -eq $Bytes -or $Bytes.Length -eq 0) { return '' }
    $offset = 0
    if (Test-RecordsBom $Bytes) { $offset = 3 }
    $decoder = if ($Strict) { $script:RecordsUtf8Strict } else { $script:RecordsUtf8 }
    return $decoder.GetString($Bytes, $offset, $Bytes.Length - $offset)
}

function Get-RecordsNewline {
    param([string]$Text)
    if ($Text.Contains("`r`n")) { return "`r`n" }
    return "`n"
}

function Split-RecordsLines {
    param([string]$Text)
    return @([regex]::Split($Text, '\r?\n'))
}

function Split-RecordsNul {
    param([string]$Text)
    return @($Text.Split([char]0) | Where-Object { $_ -ne '' })
}

function Write-RecordsTextFile {
    param([string]$FilePath, [string]$Text)
    $directory = Split-Path -Parent $FilePath
    if ($directory -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }
    [System.IO.File]::WriteAllText($FilePath, $Text, $script:RecordsUtf8)
}

function Read-RecordsTextFile {
    param([string]$FilePath)
    return ConvertFrom-RecordsBytes ([System.IO.File]::ReadAllBytes($FilePath))
}

function Resolve-RecordsPath {
    param([string]$InputPath)
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InputPath)
}

function Join-RecordsRepoPath {
    param([string]$RepoRoot, [string]$RelativePath)
    return Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function ConvertTo-RecordsArgument {
    param([AllowEmptyString()][string]$Value)
    if ($Value.Length -gt 0 -and $Value -cnotmatch '[\s"]') { return $Value }
    $doubled = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $doubled = [regex]::Replace($doubled, '(\\+)\z', '$1$1')
    return '"' + $doubled + '"'
}

function Invoke-RecordsProcess {
    param(
        [string]$FileName,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory,
        [hashtable]$Environment = @{},
        [string[]]$RemoveEnvironment = @(),
        [AllowNull()][byte[]]$InputBytes = $null
    )
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FileName
    $startInfo.Arguments = (@($Arguments | ForEach-Object { ConvertTo-RecordsArgument $_ }) -join ' ')
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardErrorEncoding = $script:RecordsUtf8
    foreach ($name in $RemoveEnvironment) {
        if ($startInfo.EnvironmentVariables.ContainsKey($name)) { $startInfo.EnvironmentVariables.Remove($name) }
    }
    foreach ($name in $Environment.Keys) {
        $startInfo.EnvironmentVariables[[string]$name] = [string]$Environment[$name]
    }

    $process = [System.Diagnostics.Process]::Start($startInfo)
    try {
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if ($null -ne $InputBytes -and $InputBytes.Length -gt 0) {
            $process.StandardInput.BaseStream.Write($InputBytes, 0, $InputBytes.Length)
            $process.StandardInput.BaseStream.Flush()
        }
        $process.StandardInput.Close()
        $stdoutBuffer = New-Object System.IO.MemoryStream
        $process.StandardOutput.BaseStream.CopyTo($stdoutBuffer)
        $process.WaitForExit()
        return [pscustomobject]@{
            ExitCode    = $process.ExitCode
            StdoutBytes = $stdoutBuffer.ToArray()
            Stderr      = $stderrTask.Result
        }
    } finally {
        $process.Dispose()
    }
}

function Invoke-RecordsGit {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments,
        [AllowNull()][byte[]]$InputBytes = $null,
        [hashtable]$Environment = @{},
        [switch]$IsolateEnvironment
    )
    $removeNames = if ($IsolateEnvironment) { @('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_PREFIX', 'GIT_COMMON_DIR') } else { @() }
    $raw = Invoke-RecordsProcess -FileName 'git' -Arguments $Arguments -WorkingDirectory $RepoRoot `
        -Environment $Environment -RemoveEnvironment $removeNames -InputBytes $InputBytes
    $stdoutText = ConvertFrom-RecordsBytes $raw.StdoutBytes
    $trimmedText = $stdoutText.TrimEnd([char]13, [char]10)
    $lines = @(if ($trimmedText.Length -eq 0) { @() } else { Split-RecordsLines $trimmedText })
    return [pscustomobject]@{
        ExitCode    = $raw.ExitCode
        StdoutBytes = $raw.StdoutBytes
        Stdout      = $stdoutText
        Lines       = $lines
        Stderr      = $raw.Stderr
    }
}

function Invoke-RecordsGitChecked {
    param([string]$RepoRoot, [string[]]$Arguments)
    $result = Invoke-RecordsGit -RepoRoot $RepoRoot -Arguments $Arguments
    if ($result.ExitCode -ne 0) {
        throw "git $($Arguments -join ' ') exited $($result.ExitCode): $($result.Stderr.Trim())"
    }
    return $result
}

function Resolve-RecordsRevision {
    param([string]$RepoRoot, [string]$Revision)
    $result = Invoke-RecordsGit -RepoRoot $RepoRoot -Arguments @('rev-parse', '--verify', '--quiet', "$Revision^{commit}")
    if ($result.ExitCode -ne 0 -or $result.Lines.Count -eq 0) { return $null }
    return $result.Lines[0].Trim()
}

function Test-RecordsTagExists {
    param([string]$RepoRoot, [string]$TagName)
    $result = Invoke-RecordsGit -RepoRoot $RepoRoot -Arguments @('rev-parse', '--verify', '--quiet', "refs/tags/$TagName")
    return ($result.ExitCode -eq 0)
}

function Get-RecordsShortSha {
    param([string]$Sha)
    if ($Sha.Length -le 8) { return $Sha }
    return $Sha.Substring(0, 8)
}

function Get-RecordsRepoRoot {
    param([string]$WorkingDirectory)
    $result = Invoke-RecordsGit -RepoRoot $WorkingDirectory -Arguments @('rev-parse', '--show-toplevel')
    if ($result.ExitCode -ne 0 -or $result.Lines.Count -eq 0) { return $null }
    return [System.IO.Path]::GetFullPath($result.Lines[0].Trim())
}

# ---------------------------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------------------------

function Test-RecordsHasProperty {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    return ($null -ne $Object.PSObject.Properties[$Name])
}

function Get-RecordsRequiredValue {
    param($Object, [string]$Name, [string]$Where)
    if (-not (Test-RecordsHasProperty $Object $Name)) { throw "config: $Where.$Name is required" }
    return $Object.$Name
}

function Get-RecordsRequiredString {
    param($Object, [string]$Name, [string]$Where)
    $value = Get-RecordsRequiredValue $Object $Name $Where
    if ($value -isnot [string] -or $value.Length -eq 0) { throw "config: $Where.$Name must be a non-empty string" }
    return $value
}

function Get-RecordsRequiredStringArray {
    param($Object, [string]$Name, [string]$Where)
    $value = Get-RecordsRequiredValue $Object $Name $Where
    $items = @($value)
    if ($items.Count -eq 0) { throw "config: $Where.$Name must be a non-empty array of strings" }
    foreach ($item in $items) {
        if ($item -isnot [string] -or $item.Length -eq 0) { throw "config: $Where.$Name must contain only non-empty strings" }
    }
    return [string[]]$items
}

function Get-RecordsRequiredStringArrayAllowEmpty {
    param($Object, [string]$Name, [string]$Where)
    $null = Get-RecordsRequiredValue $Object $Name $Where
    $value = $Object.PSObject.Properties[$Name].Value
    if ($value -is [array] -and $value.Count -eq 0) { return , [string[]]@() }
    return Get-RecordsRequiredStringArray $Object $Name $Where
}

function ConvertTo-RecordsRelativePath {
    param([string]$Value, [string]$Where)
    $normalized = $Value -replace '\\', '/'
    if ($normalized.StartsWith('/', [System.StringComparison]::Ordinal) -or $normalized -match '\A[A-Za-z]:') {
        throw "config: $Where must be relative to the repository root"
    }
    return $normalized
}

function ConvertTo-RecordsConfig {
    param($Document)
    if ($null -eq $Document) { throw 'config: the file is empty' }

    $logPrefix = Get-RecordsRequiredString $Document 'logPrefix' 'root'

    $paths = Get-RecordsRequiredValue $Document 'paths' 'root'
    $devlogPath = ConvertTo-RecordsRelativePath (Get-RecordsRequiredString $paths 'devlog' 'paths') 'paths.devlog'
    $changelogPath = ConvertTo-RecordsRelativePath (Get-RecordsRequiredString $paths 'changelog' 'paths') 'paths.changelog'
    $adrDirectory = (ConvertTo-RecordsRelativePath (Get-RecordsRequiredString $paths 'adrDirectory' 'paths') 'paths.adrDirectory').TrimEnd('/')
    $commitMsgHook = ConvertTo-RecordsRelativePath (Get-RecordsRequiredString $paths 'commitMsgHook' 'paths') 'paths.commitMsgHook'

    $subject = Get-RecordsRequiredValue $Document 'subject' 'root'
    $maxLength = Get-RecordsRequiredValue $subject 'maxLength' 'subject'
    if (-not ($maxLength -is [int] -or $maxLength -is [long]) -or $maxLength -lt 20) { throw 'config: subject.maxLength must be an integer of at least 20' }
    $passthroughPrefixes = Get-RecordsRequiredStringArrayAllowEmpty $subject 'passthroughPrefixes' 'subject'
    $enforceFrom = $null
    if (Test-RecordsHasProperty $subject 'enforceFrom') {
        $enforceFromText = $subject.enforceFrom
        if ($enforceFromText -isnot [string] -or $enforceFromText -cnotmatch '\A[0-9a-f]{7,40}\z') {
            throw 'config: subject.enforceFrom must be a lowercase hexadecimal commit SHA of 7 to 40 characters'
        }
        $enforceFrom = $enforceFromText
    }

    $changelog = Get-RecordsRequiredValue $Document 'changelog' 'root'
    $sectionOrder = Get-RecordsRequiredStringArray $changelog 'sectionOrder' 'changelog'

    $commitTypes = [System.Collections.Generic.List[object]]::new()
    $typeNames = [System.Collections.Generic.List[string]]::new()
    foreach ($typeEntry in @(Get-RecordsRequiredValue $Document 'commitTypes' 'root')) {
        $typeName = Get-RecordsRequiredString $typeEntry 'type' 'commitTypes[]'
        if ($typeName -cnotmatch '\A[a-z][a-z0-9-]*\z') { throw "config: commit type `"$typeName`" must be lowercase letters, digits, and hyphens" }
        if ($typeNames -ccontains $typeName) { throw "config: commit type `"$typeName`" is listed twice" }
        $section = Get-RecordsRequiredValue $typeEntry 'section' "commitTypes[$typeName]"
        if ($null -ne $section -and ($sectionOrder -cnotcontains [string]$section)) {
            throw "config: commit type `"$typeName`" maps to section `"$section`", which is not in changelog.sectionOrder"
        }
        $typeNames.Add($typeName)
        $commitTypes.Add([pscustomobject]@{ Type = $typeName; Included = ($null -ne $section); Section = $section })
    }
    if ($commitTypes.Count -eq 0) { throw 'config: commitTypes must list at least one type' }

    $scopeSections = @{}
    if (Test-RecordsHasProperty $Document 'scopeSections') {
        foreach ($property in $Document.scopeSections.PSObject.Properties) {
            if ($property.Name -cnotmatch ('\A' + $script:RecordsScopePattern + '\z')) { throw "config: scopeSections key `"$($property.Name)`" is not a valid scope" }
            if ($sectionOrder -cnotcontains [string]$property.Value) { throw "config: scopeSections.$($property.Name) maps to `"$($property.Value)`", which is not in changelog.sectionOrder" }
            $scopeSections[$property.Name] = [string]$property.Value
        }
    }

    $devlog = Get-RecordsRequiredValue $Document 'devlog' 'root'
    $categories = Get-RecordsRequiredStringArray $devlog 'categories' 'devlog'
    $adr = Get-RecordsRequiredValue $Document 'adr' 'root'
    $headerLabels = Get-RecordsRequiredStringArray $adr 'headerLabels' 'adr'
    if ($headerLabels -cnotcontains 'Status') { throw 'config: adr.headerLabels must include Status' }

    $releaseFilter = Get-RecordsRequiredString $changelog 'releaseFilter' 'changelog'
    if (@('export-ignore', 'none') -cnotcontains $releaseFilter) { throw 'config: changelog.releaseFilter must be export-ignore or none' }
    $tagPatternText = Get-RecordsRequiredString $changelog 'tagPattern' 'changelog'
    try { $tagPattern = [regex]::new($tagPatternText) } catch { throw "config: changelog.tagPattern is not a valid regular expression: $($_.Exception.Message)" }
    $tagGlob = Get-RecordsRequiredString $changelog 'tagGlob' 'changelog'
    $compareTarget = Get-RecordsRequiredString $changelog 'compareTarget' 'changelog'
    $previewFrom = Get-RecordsRequiredString $changelog 'previewFrom' 'changelog'
    $previewTo = Get-RecordsRequiredString $changelog 'previewTo' 'changelog'

    $ledger = $null
    $ledgerDocument = Get-RecordsRequiredValue $changelog 'removalLedger' 'changelog'
    if ($null -ne $ledgerDocument) {
        $ledgerHeader = Get-RecordsRequiredStringArray $ledgerDocument 'header' 'changelog.removalLedger'
        $columnIndex = {
            param([string]$PropertyName)
            $columnName = Get-RecordsRequiredString $ledgerDocument $PropertyName 'changelog.removalLedger'
            $index = [array]::IndexOf($ledgerHeader, $columnName)
            if ($index -lt 0) { throw "config: changelog.removalLedger.$PropertyName `"$columnName`" is not a header column" }
            return $index
        }
        $lineTemplate = Get-RecordsRequiredString $ledgerDocument 'lineTemplate' 'changelog.removalLedger'
        if (-not $lineTemplate.Contains('{item}')) { throw 'config: changelog.removalLedger.lineTemplate must contain {item}' }
        $ledger = [pscustomobject]@{
            Path             = ConvertTo-RecordsRelativePath (Get-RecordsRequiredString $ledgerDocument 'path' 'changelog.removalLedger') 'changelog.removalLedger.path'
            Header           = $ledgerHeader
            ItemIndex        = & $columnIndex 'itemColumn'
            EnvironmentIndex = & $columnIndex 'environmentColumn'
            StatusIndex      = & $columnIndex 'statusColumn'
            EnvironmentMatch = Get-RecordsRequiredString $ledgerDocument 'environmentMatch' 'changelog.removalLedger'
            StatusPrefix     = Get-RecordsRequiredString $ledgerDocument 'statusPrefix' 'changelog.removalLedger'
            LineTemplate     = $lineTemplate
            Section          = Get-RecordsRequiredString $ledgerDocument 'section' 'changelog.removalLedger'
        }
        if ($sectionOrder -cnotcontains $ledger.Section) { throw "config: changelog.removalLedger.section `"$($ledger.Section)`" is not in changelog.sectionOrder" }
    }

    $archive = $null
    $archiveDocument = Get-RecordsRequiredValue $Document 'archive' 'root'
    if ($null -ne $archiveDocument) {
        $archiveRoot = ConvertTo-RecordsRelativePath (Get-RecordsRequiredString $archiveDocument 'root' 'archive') 'archive.root'
        if (-not $archiveRoot.EndsWith('/', [System.StringComparison]::Ordinal)) { $archiveRoot += '/' }
        $archive = [pscustomobject]@{
            Root   = $archiveRoot
            Suffix = Get-RecordsRequiredString $archiveDocument 'fileSuffix' 'archive'
        }
    }

    $subjectRegex = [regex]::new(
        '\A(?<type>' + (@($typeNames | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')(?:\((?<scope>' + $script:RecordsScopePattern + ')\))?(?<breaking>!)?: (?<subject>\S.*)\z')

    return [pscustomobject]@{
        LogPrefix           = $logPrefix
        DevlogPath          = $devlogPath
        ChangelogPath       = $changelogPath
        AdrDirectory        = $adrDirectory
        CommitMsgHookPath   = $commitMsgHook
        SubjectMaxLength    = [int]$maxLength
        PassthroughPrefixes = $passthroughPrefixes
        EnforceFrom         = $enforceFrom
        CommitTypes         = $commitTypes.ToArray()
        TypeNames           = $typeNames.ToArray()
        SubjectRegex        = $subjectRegex
        ScopeSections       = $scopeSections
        SectionOrder        = $sectionOrder
        DevlogCategories    = $categories
        AdrHeaderLabels     = $headerLabels
        ReleaseFilter       = $releaseFilter
        TagPattern          = $tagPattern
        TagGlob             = $tagGlob
        CompareTarget       = $compareTarget
        PreviewFrom         = $previewFrom
        PreviewTo           = $previewTo
        Ledger              = $ledger
        Archive             = $archive
    }
}

function Read-RecordsConfig {
    param([string]$ConfigPath)
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        throw "config file not found: $ConfigPath (copy assets/templates/$($script:RecordsConfigFileName) from the tl-project-records skill)"
    }
    $text = Read-RecordsTextFile $ConfigPath
    try { $document = $text | ConvertFrom-Json } catch { throw "config: $ConfigPath is not valid JSON: $($_.Exception.Message)" }
    return ConvertTo-RecordsConfig $document
}

function New-RecordsContext {
    param([string]$RepoRoot, [pscustomobject]$Config)
    return [pscustomobject]@{ RepoRoot = $RepoRoot; Config = $Config }
}

# ---------------------------------------------------------------------------------------------
# Subject rule (check-msg, check-range)
# ---------------------------------------------------------------------------------------------

function New-RecordsMessageVerdict {
    param([bool]$Passed, [string]$Subject, [string]$Rule, [string]$Reason)
    return [pscustomobject]@{ Passed = $Passed; Subject = $Subject; Rule = $Rule; Reason = $Reason }
}

function Get-RecordsSubjectLine {
    param([string]$MessageText)
    foreach ($line in (Split-RecordsLines $MessageText)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.StartsWith('#', [System.StringComparison]::Ordinal)) { continue }
        return $line
    }
    return $null
}

function Test-RecordsMessageBytes {
    param([pscustomobject]$Config, [AllowNull()][AllowEmptyCollection()][byte[]]$MessageBytes)
    if (Test-RecordsBom $MessageBytes) {
        return New-RecordsMessageVerdict $false '' 'bom' 'the message starts with a UTF-8 byte order mark (U+FEFF); write the message file without a BOM'
    }
    $messageText = $null
    try {
        $messageText = ConvertFrom-RecordsBytes $MessageBytes -Strict
    } catch {
        return New-RecordsMessageVerdict $false '' 'encoding' 'the message is not valid UTF-8; save the message file as UTF-8 without a BOM'
    }
    $subject = Get-RecordsSubjectLine $messageText
    if ($null -eq $subject) {
        return New-RecordsMessageVerdict $false '' 'no-subject' 'the message has no subject line'
    }
    foreach ($prefix in $Config.PassthroughPrefixes) {
        if ($subject.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
            return New-RecordsMessageVerdict $true $subject 'passthrough' ''
        }
    }
    if (-not $Config.SubjectRegex.IsMatch($subject)) {
        return New-RecordsMessageVerdict $false $subject 'shape' 'the subject does not match type(scope): subject'
    }
    if ($subject.Length -gt $Config.SubjectMaxLength) {
        return New-RecordsMessageVerdict $false $subject 'length' "the subject is $($subject.Length) characters; the limit is $($Config.SubjectMaxLength)"
    }
    return New-RecordsMessageVerdict $true $subject 'ok' ''
}

function Get-RecordsSubjectRuleLines {
    param([pscustomobject]$Config)
    return @(
        '      shape: type(scope): subject  (scope: lowercase letters, digits, hyphens; optional ! before the colon)',
        "      allowed types: $($Config.TypeNames -join ', ')"
    )
}

function Invoke-RecordsCheckMsg {
    param([pscustomobject]$Context, [string]$MessagePath)
    if ([string]::IsNullOrWhiteSpace($MessagePath)) {
        return New-RecordsOutcome 1 @('FAIL check-msg requires a message file path')
    }
    $resolvedPath = Resolve-RecordsPath $MessagePath
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        return New-RecordsOutcome 1 @("FAIL message file not found: $MessagePath")
    }
    $verdict = Test-RecordsMessageBytes $Context.Config ([System.IO.File]::ReadAllBytes($resolvedPath))
    if ($verdict.Passed) {
        return New-RecordsOutcome 0 @("OK commit subject accepted: `"$($verdict.Subject)`"")
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    if ($verdict.Subject) { $lines.Add("FAIL commit subject rejected: `"$($verdict.Subject)`"") } else { $lines.Add('FAIL commit message rejected') }
    $lines.Add("      rule: $($verdict.Reason)")
    foreach ($ruleLine in (Get-RecordsSubjectRuleLines $Context.Config)) { $lines.Add($ruleLine) }
    return New-RecordsOutcome 1 $lines.ToArray()
}

# ---------------------------------------------------------------------------------------------
# Archive rule (check-commit)
# ---------------------------------------------------------------------------------------------

function Get-RecordsArchivedKey {
    param([pscustomobject]$Archive, [string]$RepoPath)
    if (-not $RepoPath.EndsWith($Archive.Suffix, [System.StringComparison]::Ordinal)) { return $null }
    if (-not $RepoPath.StartsWith($Archive.Root, [System.StringComparison]::Ordinal)) { return $null }
    $remainder = $RepoPath.Substring($Archive.Root.Length)
    if ($remainder.Length -eq 0) { return $null }
    $separatorIndex = $remainder.IndexOf('/')
    if ($separatorIndex -lt 0) { return $remainder }
    if ($separatorIndex -eq 0) { return $null }
    return $remainder.Substring(0, $separatorIndex)
}

function Test-RecordsKeyNamed {
    param([string]$Text, [string]$Key)
    $pattern = '(?<![A-Za-z0-9_.-])' + [regex]::Escape($Key) + '(?![A-Za-z0-9_-])'
    return [regex]::IsMatch($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
}

function Invoke-RecordsCheckCommit {
    param([pscustomobject]$Context)
    $config = $Context.Config
    if ($null -eq $config.Archive) {
        return New-RecordsOutcome 0 @('OK the archive rule is not configured')
    }
    $added = Invoke-RecordsGit -RepoRoot $Context.RepoRoot -Arguments @('diff', '--cached', '--name-only', '--diff-filter=A', '--no-renames', '-z')
    if ($added.ExitCode -ne 0) {
        return New-RecordsOutcome 1 @("FAIL git diff --cached exited $($added.ExitCode): $($added.Stderr.Trim())")
    }
    $keys = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($addedPath in (Split-RecordsNul $added.Stdout)) {
        $key = Get-RecordsArchivedKey $config.Archive $addedPath
        if ($null -ne $key) { [void]$keys.Add($key) }
    }
    if ($keys.Count -eq 0) {
        return New-RecordsOutcome 0 @('OK nothing is archived in this commit')
    }

    $devlog = Invoke-RecordsGit -RepoRoot $Context.RepoRoot -Arguments @('show', ":$($config.DevlogPath)")
    $devlogText = if ($devlog.ExitCode -eq 0) { $devlog.Stdout } else { $null }
    $unrecorded = @($keys | Where-Object { $null -eq $devlogText -or -not (Test-RecordsKeyNamed $devlogText $_) })
    if ($unrecorded.Count -eq 0) {
        return New-RecordsOutcome 0 @("OK archived key(s) named in the staged $($config.DevlogPath): $(@($keys) -join ', ')")
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $unrecorded) {
        $reason = if ($null -eq $devlogText) { "$($config.DevlogPath) is not in the index" } else { "the staged $($config.DevlogPath) does not name it" }
        $lines.Add("FAIL `"$key`" is archived under $($config.Archive.Root) but $reason")
    }
    $lines.Add("      write the DEVLOG close-out entry naming the archived folder or file name and stage $($config.DevlogPath), then commit again")
    return New-RecordsOutcome 1 $lines.ToArray()
}

# ---------------------------------------------------------------------------------------------
# Subject range (check-range)
# ---------------------------------------------------------------------------------------------

function Get-RecordsCommitMessageBytes {
    param([string]$RepoRoot, [string]$Sha)
    $commit = Invoke-RecordsGit -RepoRoot $RepoRoot -Arguments @('cat-file', 'commit', $Sha)
    if ($commit.ExitCode -ne 0) { throw "git cat-file commit $Sha exited $($commit.ExitCode): $($commit.Stderr.Trim())" }
    $bytes = $commit.StdoutBytes
    for ($index = 0; $index -lt ($bytes.Length - 1); $index++) {
        if ($bytes[$index] -eq 10 -and $bytes[$index + 1] -eq 10) {
            $messageLength = $bytes.Length - ($index + 2)
            $messageBytes = New-Object byte[] $messageLength
            [System.Array]::Copy($bytes, $index + 2, $messageBytes, 0, $messageLength)
            return , $messageBytes
        }
    }
    return , (New-Object byte[] 0)
}

function Invoke-RecordsCheckRange {
    param([pscustomobject]$Context, [string]$BaseRevision, [string]$HeadRevision)
    $repoRoot = $Context.RepoRoot
    $hookPath = $Context.Config.CommitMsgHookPath
    if ([string]::IsNullOrWhiteSpace($BaseRevision) -or [string]::IsNullOrWhiteSpace($HeadRevision)) {
        return New-RecordsOutcome 1 @('FAIL check-range requires -Base and -Head')
    }
    $shallow = Invoke-RecordsGit -RepoRoot $repoRoot -Arguments @('rev-parse', '--is-shallow-repository')
    if ($shallow.ExitCode -eq 0 -and $shallow.Stdout.Trim() -ceq 'true') {
        return New-RecordsOutcome 1 @('FAIL this is a shallow clone, so the range cannot be walked; fetch full history (fetch-depth: 0)')
    }
    if ($null -eq (Resolve-RecordsRevision $repoRoot $BaseRevision)) {
        return New-RecordsOutcome 1 @("FAIL base revision `"$BaseRevision`" does not resolve to a commit")
    }
    if ($null -eq (Resolve-RecordsRevision $repoRoot $HeadRevision)) {
        return New-RecordsOutcome 1 @("FAIL head revision `"$HeadRevision`" does not resolve to a commit")
    }

    $enforceFrom = $Context.Config.EnforceFrom
    if ($null -ne $enforceFrom) {
        $anchorSha = Resolve-RecordsRevision $repoRoot $enforceFrom
        if ($null -eq $anchorSha) {
            return New-RecordsOutcome 1 @("FAIL subject.enforceFrom `"$enforceFrom`" does not resolve to a commit; fetch full history or correct the config")
        }
        $anchorLabel = "enforced from $(Get-RecordsShortSha $anchorSha)"
        $hookRemovedReason = "$hookPath is absent at $HeadRevision"
    } else {
        $installLog = Invoke-RecordsGit -RepoRoot $repoRoot -Arguments @('log', '--diff-filter=A', '--no-renames', '--format=%H', '--reverse', $HeadRevision, '--', $hookPath)
        if ($installLog.ExitCode -ne 0) {
            return New-RecordsOutcome 1 @("FAIL git log for the install commit exited $($installLog.ExitCode): $($installLog.Stderr.Trim())")
        }
        if ($installLog.Lines.Count -eq 0) {
            return New-RecordsOutcome 0 @("OK 0 checked: $HeadRevision has no install commit for $hookPath")
        }
        $anchorSha = $installLog.Lines[0].Trim()
        $installShort = Get-RecordsShortSha $anchorSha
        $anchorLabel = "install commit $installShort"
        $hookRemovedReason = "$hookPath was installed in $installShort but is absent at $HeadRevision"
    }

    $hookAtHead = Invoke-RecordsGit -RepoRoot $repoRoot -Arguments @('cat-file', '-e', "${HeadRevision}:$hookPath")
    if ($hookAtHead.ExitCode -ne 0) {
        return New-RecordsOutcome 1 @("FAIL $hookRemovedReason; the subject rail was removed")
    }

    $candidates = Invoke-RecordsGit -RepoRoot $repoRoot -Arguments @('rev-list', '--no-merges', $HeadRevision, "^$BaseRevision")
    if ($candidates.ExitCode -ne 0) {
        return New-RecordsOutcome 1 @("FAIL git rev-list exited $($candidates.ExitCode): $($candidates.Stderr.Trim())")
    }
    $checkedCount = 0
    $failedCount = 0
    $failureLines = [System.Collections.Generic.List[string]]::new()
    foreach ($candidateLine in $candidates.Lines) {
        $candidateSha = $candidateLine.Trim()
        if ($candidateSha.Length -eq 0) { continue }
        $ancestry = Invoke-RecordsGit -RepoRoot $repoRoot -Arguments @('merge-base', '--is-ancestor', $anchorSha, $candidateSha)
        if ($ancestry.ExitCode -ne 0) { continue }
        $checkedCount++
        $verdict = Test-RecordsMessageBytes $Context.Config (Get-RecordsCommitMessageBytes $repoRoot $candidateSha)
        if ($verdict.Passed) { continue }
        $failedCount++
        $subjectText = if ($verdict.Subject) { " `"$($verdict.Subject)`"" } else { '' }
        $failureLines.Add("FAIL $(Get-RecordsShortSha $candidateSha)${subjectText}: $($verdict.Reason)")
    }
    if ($failedCount -eq 0) {
        return New-RecordsOutcome 0 @("OK $checkedCount checked ($anchorLabel)")
    }
    $failureLines.Add("FAIL $failedCount of $checkedCount checked subjects break the rule ($anchorLabel)")
    foreach ($ruleLine in (Get-RecordsSubjectRuleLines $Context.Config)) { $failureLines.Add($ruleLine) }
    return New-RecordsOutcome 1 $failureLines.ToArray()
}

# ---------------------------------------------------------------------------------------------
# Whole-tree checks (check)
# ---------------------------------------------------------------------------------------------

function Get-RecordsArchivedKeys {
    param([pscustomobject]$Context)
    $archive = $Context.Config.Archive
    $keys = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
    if ($null -eq $archive) { return @($keys) }
    $listing = Invoke-RecordsGitChecked -RepoRoot $Context.RepoRoot -Arguments @('ls-files', '-z', '--', $archive.Root.TrimEnd('/'))
    foreach ($listedPath in (Split-RecordsNul $listing.Stdout)) {
        $key = Get-RecordsArchivedKey $archive $listedPath
        if ($null -ne $key) { [void]$keys.Add($key) }
    }
    return @($keys)
}

function Split-RecordsTableRow {
    param([string]$Line)
    $trimmed = $Line.Trim()
    if (-not $trimmed.StartsWith('|', [System.StringComparison]::Ordinal)) { return $null }
    $inner = $trimmed.Substring(1)
    if ($inner.EndsWith('|', [System.StringComparison]::Ordinal) -and -not $inner.EndsWith('\|', [System.StringComparison]::Ordinal)) {
        $inner = $inner.Substring(0, $inner.Length - 1)
    }
    return @([regex]::Split($inner, '(?<!\\)\|') | ForEach-Object { $_.Trim() })
}

function Remove-RecordsStatusDate {
    param([string]$Status)
    return ([regex]::Replace($Status, ' \(\d{4}-\d{2}-\d{2}\)\z', ''))
}

function Test-RecordsAdrs {
    param([pscustomobject]$Context, [System.Collections.Generic.List[string]]$Problems)
    $adrRelative = $Context.Config.AdrDirectory
    $adrDirectory = Join-RecordsRepoPath $Context.RepoRoot $adrRelative
    if (-not (Test-Path -LiteralPath $adrDirectory -PathType Container)) {
        $Problems.Add("ADR: $adrRelative is missing")
        return 0
    }
    $nameRegex = [regex]::new('\A(\d{4})-[a-z0-9]+(-[a-z0-9]+)*\.md\z')
    $fileStatus = @{}
    $fileNumbers = [System.Collections.Generic.List[int]]::new()
    $seenNumbers = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $adrDirectory -File -Filter '*.md')) {
        if ($file.Name -ceq 'README.md' -or $file.Name -ceq 'template.md') { continue }
        $nameMatch = $nameRegex.Match($file.Name)
        if (-not $nameMatch.Success) {
            $Problems.Add("ADR: file name `"$($file.Name)`" does not match NNNN-kebab-title.md")
            continue
        }
        $numberText = $nameMatch.Groups[1].Value
        if ($seenNumbers.ContainsKey($numberText)) {
            $Problems.Add("ADR: number $numberText is used by more than one file ($($seenNumbers[$numberText]) and $($file.Name))")
            continue
        }
        $seenNumbers[$numberText] = $file.Name
        $fileNumbers.Add([int]$numberText)

        $headerLines = [System.Collections.Generic.List[string]]::new()
        foreach ($fileLine in (Split-RecordsLines (Read-RecordsTextFile $file.FullName))) {
            if ($fileLine.StartsWith('## ', [System.StringComparison]::Ordinal)) { break }
            $headerLines.Add($fileLine)
        }
        foreach ($label in $Context.Config.AdrHeaderLabels) {
            $prefix = "- **${label}:**"
            $present = $false
            foreach ($headerLine in $headerLines) {
                if ($headerLine.StartsWith($prefix, [System.StringComparison]::Ordinal)) { $present = $true; break }
            }
            if (-not $present) { $Problems.Add("ADR ${numberText}: header bullet `"$label`" is missing") }
        }
        foreach ($headerLine in $headerLines) {
            if (-not $headerLine.StartsWith('- **Status:**', [System.StringComparison]::Ordinal)) { continue }
            $statusValue = $headerLine.Substring('- **Status:**'.Length).Trim()
            if (-not $script:RecordsAdrStatusRegex.IsMatch($statusValue)) {
                $Problems.Add("ADR ${numberText}: status `"$statusValue`" is not Proposed, Accepted (YYYY-MM-DD), Superseded by NNNN, or Deprecated")
            } else {
                $fileStatus[$numberText] = $statusValue
            }
            break
        }
    }

    $sortedNumbers = @($fileNumbers | Sort-Object)
    if ($sortedNumbers.Count -gt 0) {
        if ($sortedNumbers[0] -ne 1) { $Problems.Add('ADR: numbering must start at 0001') }
        $highest = $sortedNumbers[$sortedNumbers.Count - 1]
        for ($expected = 1; $expected -le $highest; $expected++) {
            if ($sortedNumbers -notcontains $expected) { $Problems.Add("ADR: numbering gap, $($expected.ToString('0000')) is missing") }
        }
    }

    $readmeRelative = "$adrRelative/README.md"
    $readmePath = Join-RecordsRepoPath $Context.RepoRoot $readmeRelative
    if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
        $Problems.Add("ADR: $readmeRelative is missing")
        return $fileNumbers.Count
    }
    $indexRows = @{}
    $inIndex = $false
    foreach ($readmeLine in (Split-RecordsLines (Read-RecordsTextFile $readmePath))) {
        if ($readmeLine -ceq '## Index') { $inIndex = $true; continue }
        if ($inIndex -and $readmeLine.StartsWith('## ', [System.StringComparison]::Ordinal)) { break }
        if (-not $inIndex) { continue }
        $cells = Split-RecordsTableRow $readmeLine
        if ($null -eq $cells -or $cells.Count -lt 3) { continue }
        if ($cells[0] -cnotmatch '\A\d{4}\z') { continue }
        $rowNumber = $cells[0]
        if ($indexRows.ContainsKey($rowNumber)) {
            $Problems.Add("ADR index: more than one row for $rowNumber")
            continue
        }
        $indexRows[$rowNumber] = $cells
    }
    foreach ($numberText in @($seenNumbers.Keys | Sort-Object)) {
        if (-not $indexRows.ContainsKey($numberText)) {
            $Problems.Add("ADR ${numberText}: no index row in $readmeRelative")
            continue
        }
        $cells = $indexRows[$numberText]
        $linkMatch = [regex]::Match($cells[1], '\]\((?:\./)?([^)]+)\)')
        if (-not $linkMatch.Success -or $linkMatch.Groups[1].Value -cne $seenNumbers[$numberText]) {
            $Problems.Add("ADR ${numberText}: index row does not link $($seenNumbers[$numberText])")
        }
        if ($fileStatus.ContainsKey($numberText)) {
            $statusOfFile = $fileStatus[$numberText]
            $statusOfRow = $cells[2]
            if ($statusOfRow -cne $statusOfFile -and $statusOfRow -cne (Remove-RecordsStatusDate $statusOfFile)) {
                $Problems.Add("ADR ${numberText}: index status `"$statusOfRow`" does not match the file status `"$statusOfFile`"")
            }
        }
    }
    foreach ($rowNumber in @($indexRows.Keys | Sort-Object)) {
        if (-not $seenNumbers.ContainsKey($rowNumber)) { $Problems.Add("ADR index: row $rowNumber has no file") }
    }
    return $fileNumbers.Count
}

function Test-RecordsDevlog {
    param([pscustomobject]$Context, [System.Collections.Generic.List[string]]$Problems)
    $config = $Context.Config
    $devlogPath = Join-RecordsRepoPath $Context.RepoRoot $config.DevlogPath
    if (-not (Test-Path -LiteralPath $devlogPath -PathType Leaf)) {
        $Problems.Add("DEVLOG: $($config.DevlogPath) is missing")
        return 0
    }
    $devlogText = Read-RecordsTextFile $devlogPath
    $devlogLines = Split-RecordsLines $devlogText
    $headingRegex = [regex]::new('\A## \[(\d{4}-\d{2}-\d{2})\] (\S.*)\z')

    $entries = [System.Collections.Generic.List[object]]::new()
    $currentBody = $null
    for ($lineIndex = 0; $lineIndex -lt $devlogLines.Count; $lineIndex++) {
        $line = $devlogLines[$lineIndex]
        if ($line.StartsWith('## ', [System.StringComparison]::Ordinal)) {
            $headingMatch = $headingRegex.Match($line)
            if ($headingMatch.Success) {
                $parsedDate = [datetime]::MinValue
                $dateText = $headingMatch.Groups[1].Value
                if (-not [datetime]::TryParseExact($dateText, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsedDate)) {
                    $Problems.Add("DEVLOG line $($lineIndex + 1): `"$dateText`" is not a calendar date")
                }
                $currentBody = [System.Collections.Generic.List[string]]::new()
                $entries.Add([pscustomobject]@{ Date = $dateText; Line = $lineIndex + 1; Body = $currentBody })
            } elseif ($entries.Count -gt 0) {
                $Problems.Add("DEVLOG line $($lineIndex + 1): entry heading must read ## [YYYY-MM-DD] Title")
                $currentBody = $null
            }
            continue
        }
        if ($null -ne $currentBody) { $currentBody.Add($line) }
    }

    $previousDate = $null
    foreach ($entry in $entries) {
        if ($null -ne $previousDate -and [string]::CompareOrdinal($entry.Date, $previousDate) -gt 0) {
            $Problems.Add("DEVLOG line $($entry.Line): date $($entry.Date) is newer than the entry above it ($previousDate); entries run newest first")
        }
        $previousDate = $entry.Date

        $bodyLines = @($entry.Body)
        $cursor = 0
        $sequence = @(
            @{ Label = '**Category:**'; Pattern = '\A\*\*Category:\*\*' },
            @{ Label = '**Tags:**'; Pattern = '\A\*\*Tags:\*\*' },
            @{ Label = '### Summary'; Pattern = '\A### Summary\s*\z' },
            @{ Label = '### Detail'; Pattern = '\A### Detail\s*\z' },
            @{ Label = '### Related'; Pattern = '\A### Related\s*\z' }
        )
        foreach ($step in $sequence) {
            $foundAt = -1
            for ($bodyIndex = $cursor; $bodyIndex -lt $bodyLines.Count; $bodyIndex++) {
                if ([regex]::IsMatch($bodyLines[$bodyIndex], $step.Pattern)) { $foundAt = $bodyIndex; break }
            }
            if ($foundAt -lt 0) {
                $Problems.Add("DEVLOG line $($entry.Line): $($step.Label) is missing or out of order")
                continue
            }
            if ($step.Label -ceq '**Category:**') {
                $categoryText = ($bodyLines[$foundAt].Substring('**Category:**'.Length)).Trim().Trim('`').Trim()
                if ($config.DevlogCategories -cnotcontains $categoryText) {
                    $Problems.Add("DEVLOG line $($entry.Line): category `"$categoryText`" is not one of $($config.DevlogCategories -join ', ')")
                }
            }
            if ($step.Label -ceq '**Tags:**' -and $bodyLines[$foundAt].Substring('**Tags:**'.Length).Trim().Length -eq 0) {
                $Problems.Add("DEVLOG line $($entry.Line): **Tags:** is empty")
            }
            $cursor = $foundAt + 1
        }
    }

    foreach ($key in (Get-RecordsArchivedKeys $Context)) {
        if (-not (Test-RecordsKeyNamed $devlogText $key)) {
            $Problems.Add("DEVLOG: archived key `"$key`" is not named in any entry")
        }
    }

    $referenced = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($referenceMatch in [regex]::Matches($devlogText, '(?<![A-Za-z0-9])ADR-(\d{4})(?!\d)')) {
        [void]$referenced.Add($referenceMatch.Groups[1].Value)
    }
    $adrDirectory = Join-RecordsRepoPath $Context.RepoRoot $config.AdrDirectory
    foreach ($adrNumber in $referenced) {
        $matchingFiles = @()
        if (Test-Path -LiteralPath $adrDirectory -PathType Container) {
            $matchingFiles = @(Get-ChildItem -LiteralPath $adrDirectory -File -Filter "$adrNumber-*.md")
        }
        if ($matchingFiles.Count -eq 0) {
            $Problems.Add("DEVLOG: ADR-$adrNumber is referenced but $($config.AdrDirectory) has no $adrNumber-*.md file")
        }
    }
    return $entries.Count
}

function Get-RecordsTagCreatorDate {
    param([string]$RepoRoot, [string]$TagName)
    $result = Invoke-RecordsGit -RepoRoot $RepoRoot -Arguments @('for-each-ref', '--format=%(creatordate:short)', "refs/tags/$TagName")
    if ($result.ExitCode -ne 0 -or $result.Lines.Count -eq 0) { return $null }
    return $result.Lines[0].Trim()
}

function Test-RecordsChangelog {
    param([pscustomobject]$Context, [System.Collections.Generic.List[string]]$Problems)
    $config = $Context.Config
    $changelogPath = Join-RecordsRepoPath $Context.RepoRoot $config.ChangelogPath
    if (-not (Test-Path -LiteralPath $changelogPath -PathType Leaf)) {
        $Problems.Add("CHANGELOG: $($config.ChangelogPath) is missing")
        return 0
    }
    $changelogLines = Split-RecordsLines (Read-RecordsTextFile $changelogPath)
    $stanzaRegex = [regex]::new('\A## \[(?<tag>[^\]]+)\] - (?<date>\d{4}-\d{2}-\d{2})\z')
    $unreleasedCount = 0
    $stanzaCount = 0
    $headingCount = 0
    $previousRank = $null
    $sectionPosition = -1
    $currentHeading = $null
    for ($lineIndex = 0; $lineIndex -lt $changelogLines.Count; $lineIndex++) {
        $line = $changelogLines[$lineIndex]
        $lineNumber = $lineIndex + 1
        if ($line.StartsWith('### ', [System.StringComparison]::Ordinal)) {
            $sectionName = $line.Substring(4).Trim()
            $position = [array]::IndexOf($config.SectionOrder, $sectionName)
            if ($position -lt 0) {
                $Problems.Add("CHANGELOG line ${lineNumber}: section `"$sectionName`" is not one of $($config.SectionOrder -join ', ')")
            } elseif ($position -le $sectionPosition) {
                $Problems.Add("CHANGELOG line ${lineNumber}: section `"$sectionName`" is repeated or out of order under $currentHeading")
            } else {
                $sectionPosition = $position
            }
            continue
        }
        if (-not $line.StartsWith('## ', [System.StringComparison]::Ordinal)) { continue }
        $headingCount++
        $sectionPosition = -1
        $currentHeading = $line
        if ($line -ceq '## [Unreleased]') {
            $unreleasedCount++
            if ($headingCount -ne 1) { $Problems.Add("CHANGELOG line ${lineNumber}: [Unreleased] must be the first second-level heading") }
            continue
        }
        $headingProblem = "CHANGELOG line ${lineNumber}: heading must read ## [<tag>] - YYYY-MM-DD with a tag matching $($config.TagPattern) (got `"$line`")"
        $stanzaMatch = $stanzaRegex.Match($line)
        if (-not $stanzaMatch.Success) {
            $Problems.Add($headingProblem)
            continue
        }
        $tagMatch = $config.TagPattern.Match($stanzaMatch.Groups['tag'].Value)
        if (-not $tagMatch.Success) {
            $Problems.Add($headingProblem)
            continue
        }
        $stanzaCount++
        $tagName = $stanzaMatch.Groups['tag'].Value
        $headingDate = $stanzaMatch.Groups['date'].Value
        $tagExists = Test-RecordsTagExists $Context.RepoRoot $tagName
        if (-not $tagExists) {
            $Problems.Add("CHANGELOG line ${lineNumber}: tag $tagName does not exist locally")
        }
        $tagDate = $null
        if ($tagMatch.Groups['date'].Success) { $tagDate = $tagMatch.Groups['date'].Value }
        elseif ($tagExists) { $tagDate = Get-RecordsTagCreatorDate $Context.RepoRoot $tagName }
        if ($null -ne $tagDate -and $headingDate -cne $tagDate) {
            $Problems.Add("CHANGELOG line ${lineNumber}: heading date $headingDate differs from the date of $tagName ($tagDate)")
        }
        $dailyNumber = if ($tagMatch.Groups['number'].Success) { [int]$tagMatch.Groups['number'].Value } else { 1 }
        $rank = [pscustomobject]@{ Date = $headingDate; Number = $dailyNumber }
        if ($null -ne $previousRank) {
            $dateOrder = [string]::CompareOrdinal($rank.Date, $previousRank.Date)
            if ($dateOrder -gt 0 -or ($dateOrder -eq 0 -and $rank.Number -gt $previousRank.Number)) {
                $Problems.Add("CHANGELOG line ${lineNumber}: $tagName is newer than the stanza above it; stanzas run newest first")
            }
        }
        $previousRank = $rank
    }
    if ($unreleasedCount -ne 1) {
        $Problems.Add("CHANGELOG: expected exactly one ## [Unreleased] heading, found $unreleasedCount")
    }
    return $stanzaCount
}

function Invoke-RecordsCheck {
    param([pscustomobject]$Context)
    $problems = [System.Collections.Generic.List[string]]::new()
    $adrCount = Test-RecordsAdrs $Context $problems
    $entryCount = Test-RecordsDevlog $Context $problems
    $stanzaCount = Test-RecordsChangelog $Context $problems
    if ($problems.Count -eq 0) {
        return New-RecordsOutcome 0 @("OK check: $adrCount ADR file(s), $entryCount DEVLOG entr(ies), $stanzaCount CHANGELOG stanza(s)")
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("FAIL check: $($problems.Count) problem(s)")
    foreach ($problem in $problems) { $lines.Add("      - $problem") }
    return New-RecordsOutcome 1 $lines.ToArray()
}

# ---------------------------------------------------------------------------------------------
# Changelog renderer (changelog-preview, changelog-cut)
# ---------------------------------------------------------------------------------------------

function ConvertTo-RecordsGlobRegexText {
    param([string]$Glob)
    $builder = New-Object System.Text.StringBuilder
    foreach ($character in $Glob.ToCharArray()) {
        if ($character -eq '*') { [void]$builder.Append('[^/]*') }
        elseif ($character -eq '?') { [void]$builder.Append('[^/]') }
        else { [void]$builder.Append([regex]::Escape([string]$character)) }
    }
    return $builder.ToString()
}

# git check-attr reports "unspecified" for files under a directory pattern, so the export-ignore set
# is parsed from .gitattributes lines: a trailing-slash pattern matches a directory of that name at any
# depth, a pattern with no other slash matches a file name at any depth, and an inner slash anchors the
# pattern to the repository root.
function Get-RecordsExportIgnoreMatchers {
    param([AllowEmptyString()][string]$AttributesText)
    $matchers = [System.Collections.Generic.List[regex]]::new()
    foreach ($attributeLine in (Split-RecordsLines $AttributesText)) {
        $trimmed = $attributeLine.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#', [System.StringComparison]::Ordinal)) { continue }
        $fields = @($trimmed -split '\s+')
        if ($fields.Count -lt 2) { continue }
        $hasExportIgnore = $false
        for ($fieldIndex = 1; $fieldIndex -lt $fields.Count; $fieldIndex++) {
            if ($fields[$fieldIndex] -ceq 'export-ignore') { $hasExportIgnore = $true; break }
        }
        if (-not $hasExportIgnore) { continue }

        $pattern = $fields[0]
        $isDirectory = $pattern.EndsWith('/', [System.StringComparison]::Ordinal)
        $bare = $pattern.TrimEnd('/')
        $isAnchored = $false
        if ($bare.StartsWith('/', [System.StringComparison]::Ordinal)) {
            $bare = $bare.TrimStart('/')
            $isAnchored = $true
        } elseif ($bare.Contains('/')) {
            $isAnchored = $true
        }
        $globText = ConvertTo-RecordsGlobRegexText $bare
        if ($isDirectory -and $isAnchored) { $expression = '\A' + $globText + '/' }
        elseif ($isDirectory) { $expression = '(?:\A|/)' + $globText + '/' }
        elseif ($isAnchored) { $expression = '\A' + $globText + '\z' }
        else { $expression = '(?:\A|/)' + $globText + '\z' }
        $matchers.Add([regex]::new($expression, [System.Text.RegularExpressions.RegexOptions]::CultureInvariant))
    }
    return , $matchers.ToArray()
}

function Test-RecordsReleaseBound {
    param([string[]]$ChangedPaths, [regex[]]$Matchers)
    foreach ($changedPath in $ChangedPaths) {
        $ignored = $false
        foreach ($matcher in $Matchers) {
            if ($matcher.IsMatch($changedPath)) { $ignored = $true; break }
        }
        if (-not $ignored) { return $true }
    }
    return $false
}

function Get-RecordsCommitPaths {
    param([string]$RepoRoot, [string]$Sha)
    $listing = Invoke-RecordsGitChecked -RepoRoot $RepoRoot -Arguments @('diff-tree', '--no-commit-id', '--name-only', '-r', '--no-renames', '--root', '-z', $Sha)
    return @(Split-RecordsNul $listing.Stdout)
}

function Get-RecordsLedgerRemovedRows {
    param([pscustomobject]$Context, [string]$Revision)
    $ledgerConfig = $Context.Config.Ledger
    $rows = [System.Collections.Generic.List[object]]::new()
    $ledger = Invoke-RecordsGit -RepoRoot $Context.RepoRoot -Arguments @('show', "${Revision}:$($ledgerConfig.Path)")
    if ($ledger.ExitCode -ne 0) { return , $rows.ToArray() }
    $ledgerLines = Split-RecordsLines $ledger.Stdout
    $seenKeys = @{}
    $columnCount = $ledgerConfig.Header.Count
    for ($lineIndex = 0; $lineIndex -lt $ledgerLines.Count; $lineIndex++) {
        $headerCells = Split-RecordsTableRow $ledgerLines[$lineIndex]
        if ($null -eq $headerCells) { continue }
        if ($lineIndex + 1 -ge $ledgerLines.Count) { continue }
        if ($ledgerLines[$lineIndex + 1] -cnotmatch '\A\s*\|\s*:?-{3,}') { continue }
        if (($headerCells -join '|') -cne ($ledgerConfig.Header -join '|')) {
            throw "removal ledger table header at $Revision line $($lineIndex + 1) is not the configured $columnCount-column shape ($($ledgerConfig.Header -join ' | '))"
        }
        for ($rowIndex = $lineIndex + 2; $rowIndex -lt $ledgerLines.Count; $rowIndex++) {
            $cells = Split-RecordsTableRow $ledgerLines[$rowIndex]
            if ($null -eq $cells) { break }
            if ($cells.Count -ne $columnCount) {
                throw "removal ledger row at $Revision line $($rowIndex + 1) has $($cells.Count) cells; expected $columnCount"
            }
            $environment = $cells[$ledgerConfig.EnvironmentIndex]
            $isMatchingEnvironment = $environment.IndexOf($ledgerConfig.EnvironmentMatch, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
            $isRemoved = $cells[$ledgerConfig.StatusIndex].StartsWith($ledgerConfig.StatusPrefix, [System.StringComparison]::Ordinal)
            if (-not ($isMatchingEnvironment -and $isRemoved)) { continue }
            $item = $cells[$ledgerConfig.ItemIndex]
            $rowKey = $item + [char]0x1F + $environment
            if ($seenKeys.ContainsKey($rowKey)) { continue }
            $seenKeys[$rowKey] = $true
            $rows.Add([pscustomobject]@{ Key = $rowKey; Item = $item })
        }
        $lineIndex = $rowIndex - 1
    }
    return , $rows.ToArray()
}

function Get-RecordsRenderModel {
    param([pscustomobject]$Context, [string]$FromRevision, [string]$ToRevision)
    $config = $Context.Config
    $repoRoot = $Context.RepoRoot
    $matchers = @()
    if ($config.ReleaseFilter -ceq 'export-ignore') {
        $attributes = Invoke-RecordsGit -RepoRoot $repoRoot -Arguments @('show', "${ToRevision}:.gitattributes")
        $attributesText = if ($attributes.ExitCode -eq 0) { $attributes.Stdout } else { '' }
        $matchers = Get-RecordsExportIgnoreMatchers $attributesText
    }

    $sections = @{}
    foreach ($sectionName in $config.SectionOrder) { $sections[$sectionName] = [System.Collections.Generic.List[string]]::new() }
    $warnings = [System.Collections.Generic.List[string]]::new()
    $renderedCount = 0

    $commitLog = Invoke-RecordsGitChecked -RepoRoot $repoRoot -Arguments @('log', '--no-merges', '--format=%H%x1f%s', "${FromRevision}..${ToRevision}")
    foreach ($commitLine in $commitLog.Lines) {
        $fields = $commitLine.Split([char]0x1F)
        if ($fields.Count -lt 2) { continue }
        $sha = $fields[0]
        $subject = $fields[1]
        $subjectMatch = $config.SubjectRegex.Match($subject)
        $typeEntry = $null
        if ($subjectMatch.Success) {
            $typeEntry = $config.CommitTypes | Where-Object { $_.Type -ceq $subjectMatch.Groups['type'].Value } | Select-Object -First 1
            if (-not $typeEntry.Included) { continue }
        }
        if ($config.ReleaseFilter -ceq 'export-ignore') {
            $changedPaths = Get-RecordsCommitPaths $repoRoot $sha
            if (-not (Test-RecordsReleaseBound $changedPaths $matchers)) { continue }
        }
        if (-not $subjectMatch.Success) {
            $warnings.Add("skipped commit $(Get-RecordsShortSha $sha) with an unparseable subject: $subject")
            continue
        }
        $scope = if ($subjectMatch.Groups['scope'].Success) { $subjectMatch.Groups['scope'].Value } else { $null }
        $sectionName = $typeEntry.Section
        if ($null -ne $scope -and $config.ScopeSections.ContainsKey($scope)) { $sectionName = $config.ScopeSections[$scope] }
        $text = $subjectMatch.Groups['subject'].Value
        $shortSha = Get-RecordsShortSha $sha
        $bullet = if ($null -ne $scope) { "- **$scope** $text ($shortSha)" } else { "- $text ($shortSha)" }
        $sections[$sectionName].Add($bullet)
        $renderedCount++
    }

    if ($null -ne $config.Ledger) {
        $fromKeys = @{}
        foreach ($row in (Get-RecordsLedgerRemovedRows $Context $FromRevision)) { $fromKeys[$row.Key] = $true }
        foreach ($row in (Get-RecordsLedgerRemovedRows $Context $ToRevision)) {
            if ($fromKeys.ContainsKey($row.Key)) { continue }
            $sections[$config.Ledger.Section].Add($config.Ledger.LineTemplate.Replace('{item}', $row.Item).Replace('{path}', $config.Ledger.Path))
        }
    }

    $hasChanges = $false
    foreach ($sectionName in $config.SectionOrder) {
        if ($sections[$sectionName].Count -gt 0) { $hasChanges = $true }
    }
    return [pscustomobject]@{ Sections = $sections; Warnings = $warnings.ToArray(); RenderedCount = $renderedCount; HasChanges = $hasChanges }
}

function Format-RecordsStanza {
    param([pscustomobject]$Config, [string]$Heading, [pscustomobject]$Model)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($Heading)
    $lines.Add('')
    if (-not $Model.HasChanges) {
        $lines.Add('No release-bound changes.')
        $lines.Add('')
        return $lines.ToArray()
    }
    foreach ($sectionName in $Config.SectionOrder) {
        $bullets = $Model.Sections[$sectionName]
        if ($bullets.Count -eq 0) { continue }
        $lines.Add("### $sectionName")
        $lines.Add('')
        foreach ($bullet in $bullets) { $lines.Add($bullet) }
        $lines.Add('')
    }
    return $lines.ToArray()
}

function Resolve-RecordsPreviewRevision {
    param([pscustomobject]$Context, [string]$Revision)
    if ($Revision -cne $script:RecordsLatestTagToken) { return $Revision }
    $nearest = Invoke-RecordsGit -RepoRoot $Context.RepoRoot -Arguments @('describe', '--tags', '--abbrev=0', '--match', $Context.Config.TagGlob, 'HEAD')
    if ($nearest.ExitCode -ne 0 -or $nearest.Lines.Count -eq 0) { return $null }
    return $nearest.Lines[0].Trim()
}

function Invoke-RecordsChangelogPreview {
    param([pscustomobject]$Context, [string]$FromRevision, [string]$ToRevision, [string]$OutputPath)
    $config = $Context.Config
    $requestedFrom = if ([string]::IsNullOrWhiteSpace($FromRevision)) { $config.PreviewFrom } else { $FromRevision }
    $requestedTo = if ([string]::IsNullOrWhiteSpace($ToRevision)) { $config.PreviewTo } else { $ToRevision }
    $resolvedFrom = Resolve-RecordsPreviewRevision $Context $requestedFrom
    if ($null -eq $resolvedFrom) {
        return New-RecordsOutcome 1 @("FAIL no tag matching $($config.TagGlob) is an ancestor of HEAD, so $($script:RecordsLatestTagToken) has no value; pass -From")
    }
    foreach ($revision in @($resolvedFrom, $requestedTo)) {
        if ($null -eq (Resolve-RecordsRevision $Context.RepoRoot $revision)) {
            return New-RecordsOutcome 1 @("FAIL revision `"$revision`" does not resolve to a commit; push and fetch first, or pass -From and -To")
        }
    }
    $model = Get-RecordsRenderModel $Context $resolvedFrom $requestedTo
    $stanzaLines = Format-RecordsStanza $config '## [Unreleased]' $model
    $summary = "Preview rendered $($model.RenderedCount) commits, skipped $($model.Warnings.Count)"
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        return New-RecordsRawOutcome $stanzaLines $model.Warnings $summary
    }
    $resolvedOutput = Resolve-RecordsPath $OutputPath
    Write-RecordsTextFile $resolvedOutput (($stanzaLines -join "`n") + "`n")
    return New-RecordsOutcome 0 @("OK wrote the [Unreleased] preview for $resolvedFrom..$requestedTo to $resolvedOutput") $model.Warnings $summary
}

function Get-RecordsRepositoryUrl {
    param([string]$RepoRoot)
    $remote = Invoke-RecordsGit -RepoRoot $RepoRoot -Arguments @('remote', 'get-url', 'origin')
    if ($remote.ExitCode -ne 0 -or $remote.Lines.Count -eq 0) { return $null }
    $url = $remote.Lines[0].Trim()
    $scpMatch = [regex]::Match($url, '\A[^@/\s]+@(?<host>[^:/\s]+):(?<path>.+)\z')
    if ($scpMatch.Success) { $url = "https://$($scpMatch.Groups['host'].Value)/$($scpMatch.Groups['path'].Value)" }
    if ($url.EndsWith('.git', [System.StringComparison]::Ordinal)) { $url = $url.Substring(0, $url.Length - 4) }
    return $url
}

function Invoke-RecordsChangelogCut {
    param([pscustomobject]$Context, [string]$TagName, [string]$FromRevision)
    $config = $Context.Config
    $repoRoot = $Context.RepoRoot
    $tagMatch = $config.TagPattern.Match([string]$TagName)
    if (-not $tagMatch.Success) {
        return New-RecordsOutcome 1 @("FAIL -Tag must match the configured tag pattern $($config.TagPattern) (got `"$TagName`")")
    }
    if (-not (Test-RecordsTagExists $repoRoot $TagName)) {
        return New-RecordsOutcome 1 @("FAIL tag $TagName does not exist locally; create and push the release tag first, then cut")
    }
    $tagDate = if ($tagMatch.Groups['date'].Success) { $tagMatch.Groups['date'].Value } else { Get-RecordsTagCreatorDate $repoRoot $TagName }
    if ([string]::IsNullOrEmpty($tagDate)) {
        return New-RecordsOutcome 1 @("FAIL could not read the date of tag $TagName")
    }

    if ([string]::IsNullOrWhiteSpace($FromRevision)) {
        # describe walks the ancestry graph, so the nearest earlier release tag wins even when commit dates tie.
        $nearest = Invoke-RecordsGit -RepoRoot $repoRoot -Arguments @('describe', '--tags', '--abbrev=0', '--match', $config.TagGlob, '--exclude', $TagName, "$TagName^{commit}")
        $previousTag = if ($nearest.ExitCode -eq 0 -and $nearest.Lines.Count -gt 0) { $nearest.Lines[0].Trim() } else { $null }
        if ($null -eq $previousTag) {
            return New-RecordsOutcome 1 @(
                "FAIL no earlier tag matching $($config.TagGlob) is an ancestor of $TagName, so there is no range start",
                '      first release rule: pass -From explicitly, naming the last commit the first release does not include'
            )
        }
        $FromRevision = $previousTag
    }
    $fromSha = Resolve-RecordsRevision $repoRoot $FromRevision
    if ($null -eq $fromSha) {
        return New-RecordsOutcome 1 @("FAIL -From revision `"$FromRevision`" does not resolve to a commit")
    }
    # The compare link is permanent, so a relative or branch revision is pinned to its commit.
    $fromLinkTarget = if (Test-RecordsTagExists $repoRoot $FromRevision) { $FromRevision } else { Get-RecordsShortSha $fromSha }

    $changelogPath = Join-RecordsRepoPath $repoRoot $config.ChangelogPath
    if (-not (Test-Path -LiteralPath $changelogPath -PathType Leaf)) {
        return New-RecordsOutcome 1 @("FAIL $($config.ChangelogPath) is missing")
    }
    $changelogText = Read-RecordsTextFile $changelogPath
    $newline = Get-RecordsNewline $changelogText
    $changelogLines = [System.Collections.Generic.List[string]]::new()
    $changelogLines.AddRange([string[]](Split-RecordsLines $changelogText))

    foreach ($existingLine in $changelogLines) {
        if ($existingLine.StartsWith("## [$TagName]", [System.StringComparison]::Ordinal)) {
            return New-RecordsOutcome 1 @("FAIL $($config.ChangelogPath) already has a stanza for $TagName")
        }
    }

    $model = Get-RecordsRenderModel $Context $FromRevision $TagName
    if (-not $model.HasChanges) {
        return New-RecordsOutcome 1 @("FAIL $FromRevision..$TagName has no release-bound commit and no removal row; there is nothing to cut")
    }

    $unreleasedIndex = -1
    $footIndex = -1
    for ($lineIndex = 0; $lineIndex -lt $changelogLines.Count; $lineIndex++) {
        if ($unreleasedIndex -lt 0 -and $changelogLines[$lineIndex] -ceq '## [Unreleased]') { $unreleasedIndex = $lineIndex }
        if ($footIndex -lt 0 -and $changelogLines[$lineIndex].StartsWith('[Unreleased]: ', [System.StringComparison]::Ordinal)) { $footIndex = $lineIndex }
    }
    if ($unreleasedIndex -lt 0) { return New-RecordsOutcome 1 @("FAIL $($config.ChangelogPath) has no ## [Unreleased] heading") }
    if ($footIndex -lt 0) { return New-RecordsOutcome 1 @("FAIL $($config.ChangelogPath) has no [Unreleased]: foot link to rewrite") }
    $repositoryUrl = Get-RecordsRepositoryUrl $repoRoot
    if ($null -eq $repositoryUrl) { return New-RecordsOutcome 1 @('FAIL git remote get-url origin failed; the compare links need the repository URL') }

    $changelogLines[$footIndex] = "[Unreleased]: $repositoryUrl/compare/$TagName...$($config.CompareTarget)"
    $changelogLines.Insert($footIndex + 1, "[$TagName]: $repositoryUrl/compare/$fromLinkTarget...$TagName")

    $stanzaLines = Format-RecordsStanza $config "## [$TagName] - $tagDate" $model
    $insertAt = $unreleasedIndex + 1
    if ($insertAt -lt $changelogLines.Count -and $changelogLines[$insertAt].Length -ne 0) {
        $changelogLines.Insert($insertAt, '')
    }
    $changelogLines.InsertRange($insertAt + 1, [string[]]$stanzaLines)

    Write-RecordsTextFile $changelogPath ($changelogLines -join $newline)
    return New-RecordsOutcome 0 @("OK cut $TagName into $($config.ChangelogPath) from $FromRevision (range $FromRevision..$TagName)") $model.Warnings
}

# ---------------------------------------------------------------------------------------------
# Self-test fixtures
# ---------------------------------------------------------------------------------------------

$script:RecordsFixtureCommitMsgHook = @'
#!/bin/sh
# Conventional subject rule; see scripts/project-records.ps1 check-msg.
exec pwsh -NoProfile -File scripts/project-records.ps1 check-msg "$1"
'@

$script:RecordsFixturePreCommitHook = @'
#!/bin/sh
# Archived work units need a DEVLOG entry; see scripts/project-records.ps1 check-commit.
# Chain other pre-commit checks above this line with `|| exit 1`, and keep this exec last.
exec pwsh -NoProfile -File scripts/project-records.ps1 check-commit
'@

function Get-RecordsFixtureConfigDocument {
    param([switch]$Semver)
    $document = [ordered]@{
        logPrefix     = '[REC][Fixture]'
        paths         = [ordered]@{ devlog = 'DEVLOG.md'; changelog = 'CHANGELOG.md'; adrDirectory = 'docs/adr'; commitMsgHook = '.githooks/commit-msg' }
        subject       = [ordered]@{ maxLength = 120; passthroughPrefixes = @('Merge ', 'Revert "', 'fixup! ', 'squash! ', 'amend! ') }
        commitTypes   = @(
            [ordered]@{ type = 'feat'; section = 'Added' }, [ordered]@{ type = 'fix'; section = 'Fixed' },
            [ordered]@{ type = 'perf'; section = 'Changed' }, [ordered]@{ type = 'refactor'; section = 'Changed' },
            [ordered]@{ type = 'revert'; section = 'Changed' }, [ordered]@{ type = 'docs'; section = $null },
            [ordered]@{ type = 'plan'; section = $null }, [ordered]@{ type = 'chore'; section = $null },
            [ordered]@{ type = 'ci'; section = $null }, [ordered]@{ type = 'test'; section = $null },
            [ordered]@{ type = 'style'; section = $null }
        )
        scopeSections = [ordered]@{ legal = 'Legal'; security = 'Security' }
        devlog        = [ordered]@{ categories = @('architecture', 'milestone', 'incident', 'bug', 'ops', 'design', 'strategy', 'takeaway') }
        adr           = [ordered]@{ headerLabels = @('Status', 'Component', 'Originating signal', 'Owner', 'Supersedes', 'Recorded') }
        changelog     = [ordered]@{
            sectionOrder   = @('Legal', 'Security', 'Added', 'Changed', 'Fixed', 'Removed')
            releaseFilter  = 'export-ignore'
            tagPattern     = '\Adeploy/(?<date>\d{4}-\d{2}-\d{2})(?:-(?<number>\d+))?\z'
            tagGlob        = 'deploy/*'
            compareTarget  = 'staging'
            previewFrom    = 'origin/main'
            previewTo      = 'origin/staging'
            removalLedger  = [ordered]@{
                path = 'docs/removal-ledger.md'; header = @('Item', 'Environment', 'Status', 'Notes')
                itemColumn = 'Item'; environmentColumn = 'Environment'; statusColumn = 'Status'
                environmentMatch = 'production'; statusPrefix = 'Removed'; section = 'Removed'
                lineTemplate = '- {item} from production (see [removal ledger]({path}))'
            }
        }
        archive       = [ordered]@{ root = 'plans/complete/'; fileSuffix = '.plan.md' }
    }
    if ($Semver) {
        $document.changelog.tagPattern = '\Av\d+\.\d+\.\d+\z'
        $document.changelog.tagGlob = 'v*'
        $document.changelog.compareTarget = 'main'
        $document.changelog.previewFrom = '@latest-tag'
        $document.changelog.previewTo = 'HEAD'
        $document.changelog.releaseFilter = 'none'
        $document.changelog.removalLedger = $null
        $document.archive = $null
    }
    return $document
}

function New-RecordsFixtureConfig {
    param([switch]$Semver, [scriptblock]$Edit)
    $document = Get-RecordsFixtureConfigDocument -Semver:$Semver
    if ($null -ne $Edit) { & $Edit $document }
    return ConvertTo-RecordsConfig (($document | ConvertTo-Json -Depth 8) | ConvertFrom-Json)
}

function Get-RecordsTextBytes {
    param([string]$Text)
    return , $script:RecordsUtf8.GetBytes($Text)
}

function Get-RecordsHostExecutable {
    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($null -ne $pwshCommand) { return $pwshCommand.Source }
    return 'powershell'
}

function Assert-RecordsFixturePath {
    param([string]$FixturePath)
    $root = $script:RecordsFixtureRoot
    if ($null -eq $root) { throw 'fixture root is not set' }
    $fullPath = [System.IO.Path]::GetFullPath($FixturePath)
    if (-not $fullPath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "refusing to run a fixture command outside the temp fixture root: $fullPath"
    }
}

function Invoke-RecordsFixtureGit {
    param([string]$Repo, [string[]]$Arguments, [hashtable]$Environment = @{}, [switch]$AllowFailure)
    Assert-RecordsFixturePath $Repo
    $fullArguments = @('-c', 'user.name=records-selftest', '-c', 'user.email=selftest@localhost', '-c', 'commit.gpgsign=false', '-c', 'tag.gpgsign=false') + $Arguments
    $result = Invoke-RecordsGit -RepoRoot $Repo -Arguments $fullArguments -Environment $Environment -IsolateEnvironment
    if ($result.ExitCode -ne 0 -and -not $AllowFailure) {
        throw "fixture git $($Arguments -join ' ') exited $($result.ExitCode): $($result.Stderr.Trim())"
    }
    return $result
}

function New-RecordsFixtureRepo {
    param([string]$Name)
    $repo = Join-Path $script:RecordsFixtureRoot $Name
    $null = New-Item -ItemType Directory -Path $repo -Force
    $null = Invoke-RecordsFixtureGit $repo @('init', '-q')
    $null = Invoke-RecordsFixtureGit $repo @('symbolic-ref', 'HEAD', 'refs/heads/main')
    $null = Invoke-RecordsFixtureGit $repo @('config', 'core.autocrlf', 'false')
    $null = Invoke-RecordsFixtureGit $repo @('config', 'core.safecrlf', 'false')
    $null = Invoke-RecordsFixtureGit $repo @('config', 'core.hooksPath', (Join-Path $script:RecordsFixtureRoot 'no-hooks'))
    return $repo
}

function Write-RecordsFixtureFile {
    param([string]$Repo, [string]$RelativePath, [string]$Text)
    Assert-RecordsFixturePath $Repo
    Write-RecordsTextFile (Join-RecordsRepoPath $Repo $RelativePath) $Text
}

function Add-RecordsFixtureCommit {
    param([string]$Repo, [string]$Message, [hashtable]$Files = @{}, [string[]]$Remove = @(), [switch]$AllowEmpty)
    foreach ($relativePath in $Files.Keys) {
        Write-RecordsFixtureFile $Repo $relativePath ([string]$Files[$relativePath])
        $null = Invoke-RecordsFixtureGit $Repo @('add', '--', $relativePath)
    }
    foreach ($relativePath in $Remove) {
        $null = Invoke-RecordsFixtureGit $Repo @('rm', '-q', '--', $relativePath)
    }
    $commitArguments = @('commit', '-q', '-m', $Message)
    if ($AllowEmpty) { $commitArguments += '--allow-empty' }
    $null = Invoke-RecordsFixtureGit $Repo $commitArguments
    return (Invoke-RecordsFixtureGit $Repo @('rev-parse', 'HEAD')).Lines[0].Trim()
}

function New-RecordsLedgerText {
    param([string[]]$Rows)
    $lines = @('# Removal ledger', '', '| Item | Environment | Status | Notes |', '|---|---|---|---|') + $Rows + @('')
    return ($lines -join "`n")
}

function New-RecordsLedgerRow {
    param([string]$Item, [string]$Environment, [string]$Status, [string]$Notes)
    return "| ``$Item`` | $Environment | $Status | $Notes |"
}

function Get-RecordsFixtureAttributes {
    return "AGENTS.md export-ignore`nbin/ export-ignore`ndocs/ export-ignore`n*.code-workspace export-ignore`n"
}

function Invoke-RecordsSelfTestConfig {
    param([scriptblock]$Assert)
    $valid = $null
    try { $valid = New-RecordsFixtureConfig } catch { }
    & $Assert 'config: accepts the fixture config' ($null -ne $valid) ''

    $cases = @(
        @{ Name = 'a commit type mapped to a section not in sectionOrder'; Edit = { param($d) $d.commitTypes[0].section = 'Novelties' }; Pattern = 'not in changelog.sectionOrder' },
        @{ Name = 'a missing logPrefix'; Edit = { param($d) $d.Remove('logPrefix') }; Pattern = 'logPrefix is required' },
        @{ Name = 'an invalid releaseFilter'; Edit = { param($d) $d.changelog.releaseFilter = 'everything' }; Pattern = 'releaseFilter must be' },
        @{ Name = 'an absolute devlog path'; Edit = { param($d) $d.paths.devlog = '/DEVLOG.md' }; Pattern = 'relative to the repository root' },
        @{ Name = 'a duplicate commit type'; Edit = { param($d) $d.commitTypes += [ordered]@{ type = 'feat'; section = 'Added' } }; Pattern = 'listed twice' },
        @{ Name = 'a missing passthroughPrefixes'; Edit = { param($d) $d.subject.Remove('passthroughPrefixes') }; Pattern = 'passthroughPrefixes is required' },
        @{ Name = 'an empty-string passthrough prefix'; Edit = { param($d) $d.subject.passthroughPrefixes = @('') }; Pattern = 'passthroughPrefixes must contain only non-empty strings' },
        @{ Name = 'an empty changelog.sectionOrder, so the shared array rule is unchanged'; Edit = { param($d) $d.changelog.sectionOrder = @() }; Pattern = 'sectionOrder must be a non-empty array' },
        @{ Name = 'an enforceFrom that is not a SHA'; Edit = { param($d) $d.subject['enforceFrom'] = 'main' }; Pattern = 'enforceFrom must be a lowercase hexadecimal' },
        @{ Name = 'an enforceFrom that is too short'; Edit = { param($d) $d.subject['enforceFrom'] = 'abc12' }; Pattern = 'enforceFrom must be a lowercase hexadecimal' },
        @{ Name = 'a null enforceFrom'; Edit = { param($d) $d.subject['enforceFrom'] = $null }; Pattern = 'enforceFrom must be a lowercase hexadecimal' }
    )
    foreach ($case in $cases) {
        $document = Get-RecordsFixtureConfigDocument
        & $case.Edit $document
        $message = ''
        try { $null = ConvertTo-RecordsConfig (($document | ConvertTo-Json -Depth 8) | ConvertFrom-Json) } catch { $message = $_.Exception.Message }
        & $Assert "config: rejects $($case.Name)" ($message -match $case.Pattern) $message
    }

    $enforced = $null
    try { $enforced = New-RecordsFixtureConfig -Edit { param($d) $d.subject['enforceFrom'] = '0123abc' } } catch { }
    & $Assert 'config: accepts a lowercase hexadecimal enforceFrom' ($null -ne $enforced -and $enforced.EnforceFrom -ceq '0123abc') ''
    & $Assert 'config: leaves EnforceFrom unset when the key is absent' ($null -eq $valid.EnforceFrom) ''

    $noPassthrough = $null
    try { $noPassthrough = New-RecordsFixtureConfig -Edit { param($d) $d.subject.passthroughPrefixes = @() } } catch { }
    & $Assert 'config: accepts an empty passthroughPrefixes array' ($null -ne $noPassthrough -and @($noPassthrough.PassthroughPrefixes).Count -eq 0) ''

    $missingPath = Join-Path $script:RecordsFixtureRoot 'absent/records.config.json'
    $message = ''
    try { $null = Read-RecordsConfig $missingPath } catch { $message = $_.Exception.Message }
    & $Assert 'config: reports a missing config file' ($message -match 'config file not found') $message
}

function Invoke-RecordsSelfTestSubject {
    param([scriptblock]$Assert)
    $config = New-RecordsFixtureConfig
    $accepted = @(
        @('scoped feat', 'feat(forms): add field'),
        @('unscoped workspace type', 'plan: add spoke'),
        @('breaking marker', 'feat(api)!: drop endpoint'),
        @('Merge subject', "Merge branch 'staging' into main"),
        @('Revert subject', 'Revert "feat: add field"'),
        @('fixup subject', 'fixup! feat: add field'),
        @('subject at the length limit', ('feat(x): ' + ('a' * 111))),
        @('subject after # comment lines', "# first comment`n# second comment`nfeat: real subject`n")
    )
    foreach ($case in $accepted) {
        $verdict = Test-RecordsMessageBytes $config (Get-RecordsTextBytes $case[1])
        & $Assert "subject: accepts a $($case[0])" $verdict.Passed "rule=$($verdict.Rule) reason=$($verdict.Reason)"
    }
    $bomBytes = [byte[]](@(0xEF, 0xBB, 0xBF) + @($script:RecordsUtf8.GetBytes('feat: ok')))
    $rejected = @(
        @('free-form text', (Get-RecordsTextBytes 'Update stuff'), 'shape'),
        @('unknown type wip', (Get-RecordsTextBytes 'wip: stuff'), 'shape'),
        @('capitalized type', (Get-RecordsTextBytes 'Feat: stuff'), 'shape'),
        @('uppercase scope', (Get-RecordsTextBytes 'feat(Api): stuff'), 'shape'),
        @('multi-name scope', (Get-RecordsTextBytes 'plan(a, b): stuff'), 'shape'),
        @('missing space after the colon', (Get-RecordsTextBytes 'feat:stuff'), 'shape'),
        @('empty message', (Get-RecordsTextBytes ''), 'no-subject'),
        @('U+FEFF-prefixed message', $bomBytes, 'bom'),
        @('subject one past the length limit', (Get-RecordsTextBytes ('feat(x): ' + ('a' * 112))), 'length')
    )
    foreach ($case in $rejected) {
        $verdict = Test-RecordsMessageBytes $config $case[1]
        & $Assert "subject: rejects $($case[0])" (-not $verdict.Passed -and $verdict.Rule -ceq $case[2]) "rule=$($verdict.Rule) passed=$($verdict.Passed)"
    }

    $invalidSequence = [byte[]](0xC3, 0x28)
    $invalidInSubject = [byte[]](@($script:RecordsUtf8.GetBytes('chore: bad ')) + $invalidSequence)
    $invalidInBody = [byte[]](@($script:RecordsUtf8.GetBytes("chore: ok`n`nbody ")) + $invalidSequence + @($script:RecordsUtf8.GetBytes("`n")))
    $encodingCases = @(
        @('invalid UTF-8 in the subject', $invalidInSubject),
        @('invalid UTF-8 in the body', $invalidInBody)
    )
    foreach ($case in $encodingCases) {
        $verdict = Test-RecordsMessageBytes $config $case[1]
        & $Assert "subject: rejects $($case[0]) with rule encoding" (-not $verdict.Passed -and $verdict.Rule -ceq 'encoding') "rule=$($verdict.Rule) passed=$($verdict.Passed)"
    }
    $validMultibyte = Test-RecordsMessageBytes $config (Get-RecordsTextBytes "chore: caf$([char]0xE9) and $([char]0x2014) dash`n`nbody $([char]0xE9)`n")
    & $Assert 'subject: accepts valid multibyte UTF-8 in the subject and body' $validMultibyte.Passed "rule=$($validMultibyte.Rule)"

    $strictConfig = New-RecordsFixtureConfig -Edit { param($d) $d.subject.passthroughPrefixes = @() }
    foreach ($text in @('fixup! feat: add field', "Merge branch 'staging' into main")) {
        $verdict = Test-RecordsMessageBytes $strictConfig (Get-RecordsTextBytes $text)
        & $Assert "subject: an empty passthroughPrefixes rejects `"$text`"" (-not $verdict.Passed -and $verdict.Rule -ceq 'shape') "rule=$($verdict.Rule) passed=$($verdict.Passed)"
    }
    $verdict = Test-RecordsMessageBytes $strictConfig (Get-RecordsTextBytes 'feat: add field')
    & $Assert 'subject: an empty passthroughPrefixes still accepts a conventional subject' $verdict.Passed "rule=$($verdict.Rule)"
}

function Invoke-RecordsSelfTestArchive {
    param([scriptblock]$Assert)
    $repo = New-RecordsFixtureRepo 'archive'
    $context = New-RecordsContext $repo (New-RecordsFixtureConfig)
    $null = Add-RecordsFixtureCommit $repo 'chore: base' @{ 'README.md' = "base`n" }
    $stageScenario = {
        param([hashtable]$StagedFiles)
        $null = Invoke-RecordsFixtureGit $repo @('reset', '-q')
        foreach ($relativePath in $StagedFiles.Keys) {
            Write-RecordsFixtureFile $repo $relativePath ([string]$StagedFiles[$relativePath])
            $null = Invoke-RecordsFixtureGit $repo @('add', '--', $relativePath)
        }
        return Invoke-RecordsCheckCommit $context
    }

    $outcome = & $stageScenario @{ 'plans/complete/cycle-x/hub.plan.md' = "plan`n" }
    & $Assert 'archive: rejects an added archived plan with no staged DEVLOG.md' (
        $outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'cycle-x' -and ($outcome.Lines -join "`n") -cmatch 'not in the index') ($outcome.Lines -join ' | ')

    $outcome = & $stageScenario @{ 'plans/complete/cycle-x/hub.plan.md' = "plan`n"; 'DEVLOG.md' = "# Log`nNothing relevant here.`n" }
    & $Assert 'archive: rejects a DEVLOG.md that does not name the key' (
        $outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'does not name it') ($outcome.Lines -join ' | ')

    $outcome = & $stageScenario @{ 'plans/complete/cycle-x/hub.plan.md' = "plan`n"; 'DEVLOG.md' = "# Log`nClosed cycle-x today.`n" }
    & $Assert 'archive: accepts a folder key named in the staged DEVLOG.md' ($outcome.ExitCode -eq 0) ($outcome.Lines -join ' | ')

    $outcome = & $stageScenario @{ 'plans/complete/solo-plan-aa11bb22.plan.md' = "plan`n"; 'DEVLOG.md' = "# Log`nClosed solo-plan-aa11bb22.plan.md today.`n" }
    & $Assert 'archive: accepts a single-file key named in the staged DEVLOG.md' ($outcome.ExitCode -eq 0) ($outcome.Lines -join ' | ')

    $outcome = & $stageScenario @{ 'plans/complete/cycle-x/hub.plan.md' = "plan`n"; 'DEVLOG.md' = "# Log`nClosed cycle-x-2 today.`n" }
    & $Assert 'archive: rejects a key that is only the prefix of a longer key' (
        $outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'does not name it') ($outcome.Lines -join ' | ')

    $outcome = & $stageScenario @{ 'plans/superseded/cycle-old/hub.plan.md' = "plan`n" }
    & $Assert 'archive: ignores paths outside the archive root' ($outcome.ExitCode -eq 0) ($outcome.Lines -join ' | ')

    $disabled = New-RecordsContext $repo (New-RecordsFixtureConfig -Semver)
    $outcome = Invoke-RecordsCheckCommit $disabled
    & $Assert 'archive: passes when the archive rule is not configured' ($outcome.ExitCode -eq 0 -and ($outcome.Lines -join "`n") -cmatch 'not configured') ($outcome.Lines -join ' | ')
}

function Get-RecordsCheckFixtureFiles {
    $adrText = {
        param([string]$Number, [string]$Title, [string]$Status)
        return (@(
                "# ADR-${Number}: $Title", '',
                "- **Status:** $Status",
                '- **Component:** fixture',
                '- **Originating signal:** fixture',
                '- **Owner:** fixture',
                '- **Supersedes:** none',
                '- **Recorded:** 2026-01-02', '',
                '## Context', '', 'Fixture.', ''
            ) -join "`n")
    }
    $files = [ordered]@{}
    $files['docs/adr/README.md'] = (@(
            '# Architecture Decision Records', '', '## Conventions', '', '- Fixture.', '', '## Index', '',
            '| # | Title | Status |', '| ---- | ----- | ------ |',
            '| 0001 | [First decision](./0001-first-decision.md) | Accepted (2026-01-01) |',
            '| 0002 | [Second decision](./0002-second-decision.md) | Proposed |', ''
        ) -join "`n")
    $files['docs/adr/template.md'] = "# ADR-NNNN: Title`n"
    $files['docs/adr/0001-first-decision.md'] = & $adrText '0001' 'First decision' 'Accepted (2026-01-01)'
    $files['docs/adr/0002-second-decision.md'] = & $adrText '0002' 'Second decision' 'Proposed'
    $files['DEVLOG.md'] = (@(
            '# Dev Log', '', '## Conventions', '', '- Fixture.', '', '---', '',
            '## [2026-02-02] Second entry', '', '**Category:** `milestone`', '**Tags:** `fixture`', '',
            '### Summary', 'Closed the cycle.', '', '### Detail', '- Archived cycle-done.', '', '### Related', '- ADR-0002', '',
            '## [2026-01-02] First entry', '', '**Category:** `architecture`', '**Tags:** `retroactive`', '',
            '### Summary', 'Chose a thing.', '', '### Detail', '- Detail.', '', '### Related', '- ADR-0001', ''
        ) -join "`n")
    $files['CHANGELOG.md'] = (@(
            '# Changelog', '', '## [Unreleased]', '',
            '## [deploy/2026-01-02] - 2026-01-02', '', '### Added', '', '- Fixture change (abcd1234)', '',
            '[Unreleased]: https://example.test/compare/deploy/2026-01-02...staging',
            '[deploy/2026-01-02]: https://example.test/compare/seed...deploy/2026-01-02', ''
        ) -join "`n")
    return $files
}

function Invoke-RecordsSelfTestCheck {
    param([scriptblock]$Assert)
    $repo = New-RecordsFixtureRepo 'check'
    $context = New-RecordsContext $repo (New-RecordsFixtureConfig)
    $cleanFiles = Get-RecordsCheckFixtureFiles
    $null = Add-RecordsFixtureCommit $repo 'chore: base' @{ 'plans/complete/cycle-done/hub.plan.md' = "plan`n" }
    $null = Invoke-RecordsFixtureGit $repo @('tag', 'deploy/2026-01-02')

    $applyFiles = {
        param([hashtable]$Overrides = @{}, [string[]]$Deleted = @())
        $adrDirectory = Join-RecordsRepoPath $repo 'docs/adr'
        if (Test-Path -LiteralPath $adrDirectory) { Remove-Item -LiteralPath $adrDirectory -Recurse -Force }
        foreach ($relativePath in $cleanFiles.Keys) {
            $text = if ($Overrides.ContainsKey($relativePath)) { [string]$Overrides[$relativePath] } else { [string]$cleanFiles[$relativePath] }
            Write-RecordsFixtureFile $repo $relativePath $text
        }
        foreach ($extraPath in $Overrides.Keys) {
            if (-not $cleanFiles.Contains($extraPath)) { Write-RecordsFixtureFile $repo $extraPath ([string]$Overrides[$extraPath]) }
        }
        foreach ($deletedPath in $Deleted) { Remove-Item -LiteralPath (Join-RecordsRepoPath $repo $deletedPath) -Force }
    }
    $runCheck = {
        param([hashtable]$Overrides = @{}, [string[]]$Deleted = @())
        & $applyFiles $Overrides $Deleted
        return Invoke-RecordsCheck $context
    }
    $expectFailure = {
        param([string]$Name, $Outcome, [string]$Pattern)
        $joined = $Outcome.Lines -join "`n"
        & $Assert $Name ($Outcome.ExitCode -eq 1 -and $joined -match $Pattern) $joined
    }

    $readme = [string]$cleanFiles['docs/adr/README.md']
    $devlog = [string]$cleanFiles['DEVLOG.md']
    $changelog = [string]$cleanFiles['CHANGELOG.md']

    $outcome = & $runCheck @{ 'docs/adr/README.md' = $readme.Replace("| 0002 | [Second decision](./0002-second-decision.md) | Proposed |`n", '') }
    & $expectFailure 'check: fails on a missing ADR index row' $outcome 'ADR 0002: no index row'

    $gapReadme = $readme.Replace('0002-second-decision', '0003-third-decision').Replace('| 0002 |', '| 0003 |')
    $outcome = & $runCheck @{
        'docs/adr/README.md'              = $gapReadme
        'docs/adr/0003-third-decision.md' = ([string]$cleanFiles['docs/adr/0002-second-decision.md']).Replace('ADR-0002', 'ADR-0003')
    } @('docs/adr/0002-second-decision.md')
    & $expectFailure 'check: fails on an ADR number gap' $outcome 'numbering gap, 0002 is missing'

    $outcome = & $runCheck @{ 'docs/adr/0001-first-decision.md' = ([string]$cleanFiles['docs/adr/0001-first-decision.md']).Replace("- **Owner:** fixture`n", '') }
    & $expectFailure 'check: fails on a missing ADR header bullet' $outcome 'header bullet "Owner" is missing'

    $outcome = & $runCheck @{ 'docs/adr/README.md' = $readme.Replace('| Accepted (2026-01-01) |', '| Proposed |') }
    & $expectFailure 'check: fails on an ADR index status mismatch' $outcome 'ADR 0001: index status "Proposed" does not match'

    $swapped = $devlog.Replace('## [2026-02-02] Second entry', '## [2026-01-01] Second entry')
    $outcome = & $runCheck @{ 'DEVLOG.md' = $swapped.Replace('## [2026-01-02] First entry', '## [2026-02-03] First entry') }
    & $expectFailure 'check: fails on out-of-order DEVLOG dates' $outcome 'entries run newest first'

    $outcome = & $runCheck @{ 'DEVLOG.md' = $devlog.Replace('`milestone`', '`gossip`') }
    & $expectFailure 'check: fails on an unknown DEVLOG category' $outcome 'category "gossip"'

    $outcome = & $runCheck @{ 'DEVLOG.md' = $devlog.Replace('### Summary', '### Overview') }
    & $expectFailure 'check: fails on a DEVLOG entry missing ### Summary' $outcome '### Summary is missing'

    $outcome = & $runCheck @{ 'DEVLOG.md' = $devlog.Replace('- ADR-0002', '- ADR-0099') }
    & $expectFailure 'check: fails on a dangling ADR reference' $outcome 'ADR-0099 is referenced'

    & $applyFiles
    Write-RecordsFixtureFile $repo 'plans/complete/cycle-orphan/hub.plan.md' "plan`n"
    $null = Invoke-RecordsFixtureGit $repo @('add', '--', 'plans/complete/cycle-orphan/hub.plan.md')
    $outcome = Invoke-RecordsCheck $context
    & $expectFailure 'check: fails on an archived key the DEVLOG does not name' $outcome 'archived key "cycle-orphan"'
    $null = Invoke-RecordsFixtureGit $repo @('rm', '-q', '--cached', '--', 'plans/complete/cycle-orphan/hub.plan.md')
    Remove-Item -LiteralPath (Join-RecordsRepoPath $repo 'plans/complete/cycle-orphan') -Recurse -Force

    $outcome = & $runCheck @{ 'CHANGELOG.md' = $changelog.Replace("## [Unreleased]`n", "## [Unreleased]`n`n## [Unreleased]`n") }
    & $expectFailure 'check: fails on a second [Unreleased] heading' $outcome 'exactly one ## \[Unreleased\]'

    $outcome = & $runCheck @{ 'CHANGELOG.md' = $changelog.Replace("## [Unreleased]`n", "## [Unreleased]`n`n## [deploy/2026-03-03] - 2026-03-03`n`n### Fixed`n`n- Fixture (abcd1234)`n") }
    & $expectFailure 'check: fails on a stanza whose tag is absent' $outcome 'tag deploy/2026-03-03 does not exist'

    $outcome = & $runCheck @{ 'CHANGELOG.md' = $changelog.Replace('### Added', '### Novelties') }
    & $expectFailure 'check: fails on a section outside the configured order' $outcome 'section "Novelties" is not one of'

    $outcome = & $runCheck
    & $Assert 'check: passes on a clean fixture' ($outcome.ExitCode -eq 0) ($outcome.Lines -join ' | ')
}

function Invoke-RecordsSelfTestRange {
    param([scriptblock]$Assert)
    $hookFile = @{ '.githooks/commit-msg' = "#!/bin/sh`n" }
    $config = New-RecordsFixtureConfig

    $repo = New-RecordsFixtureRepo 'range-spanning'
    $context = New-RecordsContext $repo $config
    $c0 = Add-RecordsFixtureCommit $repo 'chore: root' @{ 'a.txt' = "0`n" }
    $c1 = Add-RecordsFixtureCommit $repo 'plans: pre-install bad subject' @{ 'a.txt' = "1`n" }
    $c2 = Add-RecordsFixtureCommit $repo 'chore: before install' @{ 'a.txt' = "2`n" }
    $null = Invoke-RecordsFixtureGit $repo @('checkout', '-q', '-b', 'side', $c2)
    $null = Add-RecordsFixtureCommit $repo 'plans: side branch before install' @{ 's.txt' = "s`n" }
    $null = Invoke-RecordsFixtureGit $repo @('checkout', '-q', 'main')
    $null = Add-RecordsFixtureCommit $repo 'chore: install the commit-msg hook' $hookFile
    $null = Add-RecordsFixtureCommit $repo 'feat: after install' @{ 'a.txt' = "4`n" }
    $c5 = Add-RecordsFixtureCommit $repo 'plans: post-install bad subject' @{ 'a.txt' = "5`n" }
    $null = Invoke-RecordsFixtureGit $repo @('merge', '--no-ff', '-q', 'side', '-m', "Merge branch 'side'")
    $mergeSha = (Invoke-RecordsFixtureGit $repo @('rev-parse', 'HEAD')).Lines[0].Trim()

    $outcome = Invoke-RecordsCheckRange $context $c5 $mergeSha
    & $Assert 'range: passes with 0 checked on a range wholly before the install commit' (
        $outcome.ExitCode -eq 0 -and ($outcome.Lines -join "`n") -cmatch '0 checked') ($outcome.Lines -join ' | ')

    $outcome = Invoke-RecordsCheckRange $context $c0 $c5
    $joined = $outcome.Lines -join "`n"
    & $Assert 'range: ignores a pre-install bad subject but fails a post-install one' (
        $outcome.ExitCode -eq 1 -and $joined.Contains((Get-RecordsShortSha $c5)) -and $joined.Contains('post-install bad subject') -and
        -not $joined.Contains('pre-install bad subject') -and -not $joined.Contains((Get-RecordsShortSha $c1)) -and $joined -cmatch '1 of 3 checked') $joined

    $installRepo = New-RecordsFixtureRepo 'range-install-bad'
    $installBase = Add-RecordsFixtureCommit $installRepo 'chore: root' @{ 'a.txt' = "0`n" }
    $installSha = Add-RecordsFixtureCommit $installRepo 'plans: install the hook' $hookFile
    $outcome = Invoke-RecordsCheckRange (New-RecordsContext $installRepo $config) $installBase $installSha
    $joined = $outcome.Lines -join "`n"
    & $Assert "range: fails the install commit's own bad subject" (
        $outcome.ExitCode -eq 1 -and $joined.Contains((Get-RecordsShortSha $installSha)) -and $joined.Contains('plans: install the hook')) $joined

    $plainRepo = New-RecordsFixtureRepo 'range-no-install'
    $plainBase = Add-RecordsFixtureCommit $plainRepo 'chore: root' @{ 'a.txt' = "0`n" }
    $plainHead = Add-RecordsFixtureCommit $plainRepo 'plans: never installed' @{ 'a.txt' = "1`n" }
    $outcome = Invoke-RecordsCheckRange (New-RecordsContext $plainRepo $config) $plainBase $plainHead
    & $Assert 'range: passes with 0 checked when no install commit exists' (
        $outcome.ExitCode -eq 0 -and ($outcome.Lines -join "`n") -cmatch '0 checked') ($outcome.Lines -join ' | ')

    $shallowPath = Join-Path $script:RecordsFixtureRoot 'range-shallow'
    $sourceUrl = 'file:///' + ($repo -replace '\\', '/').TrimStart('/')
    $null = Invoke-RecordsFixtureGit $script:RecordsFixtureRoot @('clone', '-q', '--depth', '1', $sourceUrl, $shallowPath)
    $outcome = Invoke-RecordsCheckRange (New-RecordsContext $shallowPath $config) 'HEAD' 'HEAD'
    & $Assert 'range: fails in a shallow clone' ($outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'shallow') ($outcome.Lines -join ' | ')

    $removedRepo = New-RecordsFixtureRepo 'range-hook-removed'
    $removedBase = Add-RecordsFixtureCommit $removedRepo 'chore: root' @{ 'a.txt' = "0`n" }
    $null = Add-RecordsFixtureCommit $removedRepo 'chore: install the hook' $hookFile
    $removedHead = Add-RecordsFixtureCommit $removedRepo 'chore: drop the hook' @{} @('.githooks/commit-msg')
    $outcome = Invoke-RecordsCheckRange (New-RecordsContext $removedRepo $config) $removedBase $removedHead
    & $Assert 'range: fails when Head lacks the hook file after an install commit' (
        $outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'absent at') ($outcome.Lines -join ' | ')

    $enforceRepo = New-RecordsFixtureRepo 'range-enforce-from'
    $enforceBase = Add-RecordsFixtureCommit $enforceRepo 'chore: root' @{ 'a.txt' = "0`n" }
    $null = Add-RecordsFixtureCommit $enforceRepo 'chore: install the hook' $hookFile
    $enforceEarly = Add-RecordsFixtureCommit $enforceRepo 'plans: bad subject before the pin' @{ 'a.txt' = "1`n" }
    $enforcePin = Add-RecordsFixtureCommit $enforceRepo 'chore: pin the enforcement start' @{ 'a.txt' = "2`n" }
    $enforceLate = Add-RecordsFixtureCommit $enforceRepo 'plans: bad subject after the pin' @{ 'a.txt' = "3`n" }
    $enforceHead = Add-RecordsFixtureCommit $enforceRepo 'feat: fine' @{ 'a.txt' = "4`n" }

    $outcome = Invoke-RecordsCheckRange (New-RecordsContext $enforceRepo $config) $enforceBase $enforceHead
    $joined = $outcome.Lines -join "`n"
    & $Assert 'range: without enforceFrom the install commit anchors the range and both bad subjects fail' (
        $outcome.ExitCode -eq 1 -and $joined.Contains((Get-RecordsShortSha $enforceEarly)) -and $joined.Contains((Get-RecordsShortSha $enforceLate)) -and
        $joined -cmatch '2 of 5 checked' -and $joined -cmatch 'install commit') $joined

    $pinned = New-RecordsContext $enforceRepo (New-RecordsFixtureConfig -Edit { param($d) $d.subject['enforceFrom'] = $enforcePin })
    $outcome = Invoke-RecordsCheckRange $pinned $enforceBase $enforceHead
    $joined = $outcome.Lines -join "`n"
    & $Assert 'range: enforceFrom replaces the install anchor, checking only that commit and its descendants' (
        $outcome.ExitCode -eq 1 -and $joined.Contains((Get-RecordsShortSha $enforceLate)) -and -not $joined.Contains((Get-RecordsShortSha $enforceEarly)) -and
        $joined -cmatch '1 of 3 checked' -and $joined -cmatch "enforced from $(Get-RecordsShortSha $enforcePin)") $joined

    $pinnedClean = New-RecordsContext $enforceRepo (New-RecordsFixtureConfig -Edit { param($d) $d.subject['enforceFrom'] = $enforceHead })
    $outcome = Invoke-RecordsCheckRange $pinnedClean $enforceBase $enforceHead
    & $Assert 'range: enforceFrom at Head checks only Head and passes when it conforms' (
        $outcome.ExitCode -eq 0 -and ($outcome.Lines -join "`n") -cmatch '1 checked \(enforced from') ($outcome.Lines -join ' | ')

    $unresolvable = New-RecordsContext $enforceRepo (New-RecordsFixtureConfig -Edit { param($d) $d.subject['enforceFrom'] = ('f' * 40) })
    $outcome = Invoke-RecordsCheckRange $unresolvable $enforceBase $enforceHead
    & $Assert 'range: fails when enforceFrom does not resolve to a commit' (
        $outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'subject\.enforceFrom .* does not resolve') ($outcome.Lines -join ' | ')

    $pinnedRemoved = Add-RecordsFixtureCommit $enforceRepo 'chore: drop the hook' @{} @('.githooks/commit-msg')
    $outcome = Invoke-RecordsCheckRange $pinned $enforceBase $pinnedRemoved
    & $Assert 'range: fails when Head lacks the hook file and enforceFrom is set' (
        $outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'absent at') ($outcome.Lines -join ' | ')
}

function Invoke-RecordsSelfTestRender {
    param([scriptblock]$Assert)
    $config = New-RecordsFixtureConfig
    $repo = New-RecordsFixtureRepo 'render'
    $context = New-RecordsContext $repo $config
    $appFile = 'src/app/f.txt'
    $appEdits = [pscustomobject]@{ Count = 0 }
    $nextApp = {
        $appEdits.Count++
        return @{ $appFile = "n=$($appEdits.Count)`n" }
    }

    $ledgerBefore = New-RecordsLedgerText @(
        (New-RecordsLedgerRow 'old.txt' 'Production' 'Removed 2026-01-01' 'first note'),
        (New-RecordsLedgerRow 'kept.txt' 'Production' 'Approved - pending' 'n')
    )
    $ledgerAfter = New-RecordsLedgerText @(
        (New-RecordsLedgerRow 'old.txt' 'Production' 'Removed 2026-01-01' 'second note, edited'),
        (New-RecordsLedgerRow 'gone.txt' 'Production' 'Removed 2026-09-30' 'n'),
        (New-RecordsLedgerRow 'stage.txt' 'Staging' 'Removed 2026-09-30' 'n'),
        (New-RecordsLedgerRow 'kept.txt' 'Production' 'Approved - pending (later)' 'n')
    )
    $baseFiles = (& $nextApp)
    $baseFiles['.gitattributes'] = Get-RecordsFixtureAttributes
    $baseFiles['docs/removal-ledger.md'] = $ledgerBefore
    $baseSha = Add-RecordsFixtureCommit $repo 'chore: base' $baseFiles

    $shaFeat = Add-RecordsFixtureCommit $repo 'feat(forms): add signup field' (& $nextApp)
    $shaFix = Add-RecordsFixtureCommit $repo 'fix: repair redirect' (& $nextApp)
    $shaPerf = Add-RecordsFixtureCommit $repo 'perf(db): cache lookup' (& $nextApp)
    $shaRefactor = Add-RecordsFixtureCommit $repo 'refactor(core): split loader' (& $nextApp)
    $shaRevert = Add-RecordsFixtureCommit $repo 'revert: back out banner' (& $nextApp)
    $shaLegal = Add-RecordsFixtureCommit $repo 'feat(legal)!: update privacy page' (& $nextApp)
    $shaSecurity = Add-RecordsFixtureCommit $repo 'fix(security): harden nonce' (& $nextApp)
    foreach ($excludedType in @('docs', 'plan', 'chore', 'ci', 'test', 'style')) {
        $null = Add-RecordsFixtureCommit $repo "${excludedType}: excluded type" (& $nextApp)
    }
    $null = Add-RecordsFixtureCommit $repo 'Update stuff' (& $nextApp)
    $null = Add-RecordsFixtureCommit $repo 'docs(removal-ledger): record production removals' @{ 'docs/removal-ledger.md' = $ledgerAfter }

    $short = { param([string]$Sha) Get-RecordsShortSha $Sha }
    $expected = @(
        '## [Unreleased]', '',
        '### Legal', '', "- **legal** update privacy page ($(& $short $shaLegal))", '',
        '### Security', '', "- **security** harden nonce ($(& $short $shaSecurity))", '',
        '### Added', '', "- **forms** add signup field ($(& $short $shaFeat))", '',
        '### Changed', '', "- back out banner ($(& $short $shaRevert))", "- **core** split loader ($(& $short $shaRefactor))", "- **db** cache lookup ($(& $short $shaPerf))", '',
        '### Fixed', '', "- repair redirect ($(& $short $shaFix))", '',
        '### Removed', '', '- `gone.txt` from production (see [removal ledger](docs/removal-ledger.md))', ''
    ) -join "`n"

    $model = Get-RecordsRenderModel $context $baseSha 'HEAD'
    $rendered = (Format-RecordsStanza $config '## [Unreleased]' $model) -join "`n"
    & $Assert 'render: produces the exact expected stanza from a history with every type, scope, and a Removed ledger row' (
        $rendered -ceq $expected -and $model.Warnings.Count -eq 1 -and $model.Warnings[0].Contains('Update stuff')) $rendered

    & $Assert 'render: a ledger row already Removed at From with an edited Notes cell does not re-appear' (
        -not $rendered.Contains('old.txt') -and -not $rendered.Contains('stage.txt') -and -not $rendered.Contains('kept.txt')) $rendered

    $scriptCopy = Join-RecordsRepoPath $repo 'scripts/project-records.ps1'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $scriptCopy) -Force
    Copy-Item -LiteralPath $script:RecordsScriptPath -Destination $scriptCopy -Force
    Write-RecordsFixtureFile $repo 'records.config.json' ((Get-RecordsFixtureConfigDocument) | ConvertTo-Json -Depth 8)
    $process = Invoke-RecordsProcess -FileName (Get-RecordsHostExecutable) -WorkingDirectory $repo `
        -Arguments @('-NoProfile', '-File', 'scripts/project-records.ps1', 'changelog-preview', '-From', $baseSha, '-To', $shaSecurity)
    $stdoutLines = @((ConvertFrom-RecordsBytes $process.StdoutBytes).TrimEnd([char]13, [char]10) -split '\r?\n')
    $prefixed = @($stdoutLines | Where-Object { $_.StartsWith($config.LogPrefix, [System.StringComparison]::Ordinal) })
    $subsetExpected = @(
        '## [Unreleased]', '',
        '### Legal', '', "- **legal** update privacy page ($(& $short $shaLegal))", '',
        '### Security', '', "- **security** harden nonce ($(& $short $shaSecurity))", '',
        '### Added', '', "- **forms** add signup field ($(& $short $shaFeat))", '',
        '### Changed', '', "- back out banner ($(& $short $shaRevert))", "- **core** split loader ($(& $short $shaRefactor))", "- **db** cache lookup ($(& $short $shaPerf))", '',
        '### Fixed', '', "- repair redirect ($(& $short $shaFix))"
    ) -join "`n"
    & $Assert 'render: changelog-preview stdout is raw markdown with no prefixed line' (
        $process.ExitCode -eq 0 -and $prefixed.Count -eq 0 -and (($stdoutLines -join "`n").TrimEnd() -ceq $subsetExpected)) "exit=$($process.ExitCode) stderr=$($process.Stderr) stdout=$($stdoutLines -join ' / ')"
    $cleanStderrLines = @($process.Stderr.TrimEnd([char]13, [char]10) -split '\r?\n')
    & $Assert 'render: a preview with no skipped subject ends stderr with the zero-skipped count line' (
        $cleanStderrLines.Count -eq 1 -and $cleanStderrLines[0] -ceq "$($config.LogPrefix) Preview rendered 7 commits, skipped 0") "stderr=$($process.Stderr)"

    $skipProcess = Invoke-RecordsProcess -FileName (Get-RecordsHostExecutable) -WorkingDirectory $repo `
        -Arguments @('-NoProfile', '-File', 'scripts/project-records.ps1', 'changelog-preview', '-From', $baseSha, '-To', 'HEAD')
    $skipStdout = ((ConvertFrom-RecordsBytes $skipProcess.StdoutBytes).TrimEnd([char]13, [char]10) -split '\r?\n') -join "`n"
    $skipStderrLines = @($skipProcess.Stderr.TrimEnd([char]13, [char]10) -split '\r?\n')
    & $Assert 'render: a skipped subject is a WARN line on stderr, the count line closes stderr, and stdout stays raw markdown' (
        $skipProcess.ExitCode -eq 0 -and $skipStderrLines.Count -eq 2 -and
        $skipStderrLines[0].StartsWith("$($config.LogPrefix) WARN skipped commit ", [System.StringComparison]::Ordinal) -and $skipStderrLines[0].Contains('Update stuff') -and
        $skipStderrLines[1] -ceq "$($config.LogPrefix) Preview rendered 7 commits, skipped 1" -and
        $skipStdout -ceq $expected.TrimEnd() -and -not $skipStdout.Contains('WARN')) "exit=$($skipProcess.ExitCode) stderr=$($skipProcess.Stderr) stdout=$skipStdout"

    $filterRepo = New-RecordsFixtureRepo 'render-filter'
    $filterContext = New-RecordsContext $filterRepo $config
    $filterBase = Add-RecordsFixtureCommit $filterRepo 'chore: base' @{ '.gitattributes' = (Get-RecordsFixtureAttributes); $appFile = "base`n" }
    $null = Add-RecordsFixtureCommit $filterRepo 'feat(agents): only the agents file' @{ 'AGENTS.md' = "a`n" }
    $null = Add-RecordsFixtureCommit $filterRepo 'feat(mixed): agents file and an app file' @{ 'AGENTS.md' = "b`n"; $appFile = "mixed`n" }
    $null = Add-RecordsFixtureCommit $filterRepo 'feat(tooling): only a bin tool' @{ 'bin/tool.ps1' = "tool`n" }
    $null = Add-RecordsFixtureCommit $filterRepo 'feat(guide): only a nested docs file' @{ 'src/plugins/example/docs/guide.md' = "guide`n" }
    $filterText = (Format-RecordsStanza $config '## [Unreleased]' (Get-RecordsRenderModel $filterContext $filterBase 'HEAD')) -join "`n"
    & $Assert 'render: a feat commit that changes only AGENTS.md (file pattern) is not rendered' (-not $filterText.Contains('only the agents file')) $filterText
    & $Assert 'render: a feat commit that changes AGENTS.md and an app file is rendered' ($filterText.Contains('agents file and an app file')) $filterText
    & $Assert 'render: a feat commit that changes only bin/tool.ps1 (directory pattern) is not rendered' (-not $filterText.Contains('only a bin tool')) $filterText
    & $Assert 'render: a feat commit that changes only a nested docs file is not rendered' (-not $filterText.Contains('nested docs file')) $filterText

    $noneContext = New-RecordsContext $filterRepo (New-RecordsFixtureConfig -Semver)
    $noneText = (Format-RecordsStanza $noneContext.Config '## [Unreleased]' (Get-RecordsRenderModel $noneContext $filterBase 'HEAD')) -join "`n"
    & $Assert 'render: releaseFilter none renders every included commit' ($noneText.Contains('only the agents file') -and $noneText.Contains('only a bin tool')) $noneText
}

function Invoke-RecordsSelfTestCut {
    param([scriptblock]$Assert)
    $repo = New-RecordsFixtureRepo 'cut'
    $context = New-RecordsContext $repo (New-RecordsFixtureConfig)
    $null = Invoke-RecordsFixtureGit $repo @('remote', 'add', 'origin', 'https://github.com/example/example-repo.git')
    $appFile = 'src/app/f.txt'
    $changelog = (@(
            '# Changelog', '', '## [Unreleased]', '',
            '## [deploy/2026-10-02] - 2026-10-02', '', '### Added', '', '- Seed change (abcd1234)', '',
            '[Unreleased]: https://github.com/example/example-repo/compare/deploy/2026-10-02...staging',
            '[deploy/2026-10-02]: https://github.com/example/example-repo/compare/seed...deploy/2026-10-02', ''
        ) -join "`r`n")
    $null = Add-RecordsFixtureCommit $repo 'chore: base' @{ '.gitattributes' = (Get-RecordsFixtureAttributes); $appFile = "base`n"; 'CHANGELOG.md' = $changelog }
    $null = Invoke-RecordsFixtureGit $repo @('tag', 'deploy/2026-10-02')
    $null = Add-RecordsFixtureCommit $repo 'feat(agents): export-ignored path only' @{ 'AGENTS.md' = "a`n" }
    $null = Invoke-RecordsFixtureGit $repo @('tag', 'deploy/2026-10-03')
    $ledger = New-RecordsLedgerText @((New-RecordsLedgerRow 'gone.txt' 'Production' 'Removed 2026-10-05' 'n'))
    $featSha = Add-RecordsFixtureCommit $repo 'feat(forms): release-bound change' @{ $appFile = "release`n"; 'docs/removal-ledger.md' = $ledger }
    $null = Invoke-RecordsFixtureGit $repo @('tag', 'deploy/2026-10-06')
    $changelogPath = Join-RecordsRepoPath $repo 'CHANGELOG.md'

    $outcome = Invoke-RecordsChangelogCut $context 'deploy/2026-10-02' 'deploy/2026-10-02'
    & $Assert 'cut: refuses a stanza that already exists' ($outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'already has a stanza') ($outcome.Lines -join ' | ')

    $outcome = Invoke-RecordsChangelogCut $context 'deploy/2026-10-02' ''
    & $Assert 'cut: refuses a first release without -From' ($outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'pass -From explicitly') ($outcome.Lines -join ' | ')

    $outcome = Invoke-RecordsChangelogCut $context 'release-1' ''
    & $Assert 'cut: refuses a tag outside the configured pattern' ($outcome.ExitCode -eq 1 -and ($outcome.Lines -join "`n") -cmatch 'configured tag pattern') ($outcome.Lines -join ' | ')

    $emptyByIgnore = Invoke-RecordsChangelogCut $context 'deploy/2026-10-03' ''
    $emptyRange = Invoke-RecordsChangelogCut $context 'deploy/2026-10-03' 'deploy/2026-10-03'
    & $Assert 'cut: refuses an empty range, including one whose only included commits touch export-ignored paths' (
        $emptyByIgnore.ExitCode -eq 1 -and ($emptyByIgnore.Lines -join "`n") -cmatch 'nothing to cut' -and
        $emptyRange.ExitCode -eq 1 -and ($emptyRange.Lines -join "`n") -cmatch 'nothing to cut') (($emptyByIgnore.Lines + $emptyRange.Lines) -join ' | ')

    $outcome = Invoke-RecordsChangelogCut $context 'deploy/2026-10-06' ''
    $bytes = [System.IO.File]::ReadAllBytes($changelogPath)
    $text = ConvertFrom-RecordsBytes $bytes
    $expectedStanza = (@(
            '## [Unreleased]', '',
            '## [deploy/2026-10-06] - 2026-10-06', '',
            '### Added', '', "- **forms** release-bound change ($(Get-RecordsShortSha $featSha))", '',
            '### Removed', '', '- `gone.txt` from production (see [removal ledger](docs/removal-ledger.md))', '',
            '## [deploy/2026-10-02] - 2026-10-02'
        ) -join "`r`n")
    $hasLoneLf = [regex]::IsMatch($text, '(?<!\r)\n')
    $footLinks = $text.Contains("[Unreleased]: https://github.com/example/example-repo/compare/deploy/2026-10-06...staging`r`n[deploy/2026-10-06]: https://github.com/example/example-repo/compare/deploy/2026-10-03...deploy/2026-10-06`r`n[deploy/2026-10-02]:")
    & $Assert 'cut: writes the stanza and foot links and preserves CRLF without a BOM' (
        $outcome.ExitCode -eq 0 -and -not $hasLoneLf -and -not (Test-RecordsBom $bytes) -and $text.Contains($expectedStanza) -and $footLinks) "exit=$($outcome.ExitCode) $($outcome.Lines -join ' | ') text=$text"

    $semverRepo = New-RecordsFixtureRepo 'cut-semver'
    $semverContext = New-RecordsContext $semverRepo (New-RecordsFixtureConfig -Semver)
    $null = Invoke-RecordsFixtureGit $semverRepo @('remote', 'add', 'origin', 'git@github.com:example/example-lib.git')
    $semverChangelog = (@('# Changelog', '', '## [Unreleased]', '', '[Unreleased]: https://github.com/example/example-lib/compare/v1.0.0...main', '') -join "`n")
    $null = Add-RecordsFixtureCommit $semverRepo 'chore: base' @{ 'CHANGELOG.md' = $semverChangelog; 'src/lib.txt' = "0`n" }
    $null = Invoke-RecordsFixtureGit $semverRepo @('tag', '-a', 'v1.0.0', '-m', 'v1.0.0')
    $semverFix = Add-RecordsFixtureCommit $semverRepo 'fix(parser): accept empty input' @{ 'src/lib.txt' = "1`n" }
    $null = Invoke-RecordsFixtureGit $semverRepo @('tag', '-a', 'v1.0.1', '-m', 'v1.0.1')
    $previewOutcome = Invoke-RecordsChangelogPreview $semverContext '' '' ''
    & $Assert 'cut: @latest-tag preview starts at the nearest semver tag' ($previewOutcome.ExitCode -eq 0 -and ($previewOutcome.Lines -join "`n") -cmatch 'No release-bound changes') ($previewOutcome.Lines -join ' | ')
    $outcome = Invoke-RecordsChangelogCut $semverContext 'v1.0.1' ''
    $semverText = Read-RecordsTextFile (Join-RecordsRepoPath $semverRepo 'CHANGELOG.md')
    $tagDate = Get-RecordsTagCreatorDate $semverRepo 'v1.0.1'
    $checkOutcome = Invoke-RecordsCheck $semverContext
    & $Assert 'cut: a semver tag takes its date from the tag and converts an scp-style remote for the compare links' (
        $outcome.ExitCode -eq 0 -and $semverText.Contains("## [v1.0.1] - $tagDate") -and $semverText.Contains("- **parser** accept empty input ($(Get-RecordsShortSha $semverFix))") -and
        $semverText.Contains('[v1.0.1]: https://github.com/example/example-lib/compare/v1.0.0...v1.0.1')) "exit=$($outcome.ExitCode) $($outcome.Lines -join ' | ') text=$semverText"
    $checkText = $checkOutcome.Lines -join "`n"
    & $Assert 'cut: check reports no CHANGELOG problem on the cut semver changelog' ($checkText -cnotmatch 'CHANGELOG') $checkText

    $firstRepo = New-RecordsFixtureRepo 'cut-first-release'
    $firstContext = New-RecordsContext $firstRepo (New-RecordsFixtureConfig -Semver)
    $null = Invoke-RecordsFixtureGit $firstRepo @('remote', 'add', 'origin', 'https://github.com/example/example-first.git')
    $firstBase = Add-RecordsFixtureCommit $firstRepo 'chore: base' @{ 'CHANGELOG.md' = ((@('# Changelog', '', '## [Unreleased]', '', '[Unreleased]: https://github.com/example/example-first/commits/main', '') -join "`n")) }
    $null = Add-RecordsFixtureCommit $firstRepo 'feat(core): first feature' @{ 'src/core.txt' = "1`n" }
    $null = Invoke-RecordsFixtureGit $firstRepo @('tag', '-a', 'v0.1.0', '-m', 'v0.1.0')
    $outcome = Invoke-RecordsChangelogCut $firstContext 'v0.1.0' 'HEAD~1'
    $firstText = Read-RecordsTextFile (Join-RecordsRepoPath $firstRepo 'CHANGELOG.md')
    & $Assert 'cut: a first release cut from a relative -From pins the compare link to the commit' (
        $outcome.ExitCode -eq 0 -and $firstText.Contains("[v0.1.0]: https://github.com/example/example-first/compare/$(Get-RecordsShortSha $firstBase)...v0.1.0") -and
        $firstText.Contains('[Unreleased]: https://github.com/example/example-first/compare/v0.1.0...main')) "exit=$($outcome.ExitCode) text=$firstText"
}

function Invoke-RecordsSelfTestEndToEnd {
    param([scriptblock]$Assert)
    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($null -eq $pwshCommand) { throw 'pwsh is not on PATH; the hooks run through pwsh' }

    $repo = New-RecordsFixtureRepo 'end-to-end'
    $config = New-RecordsFixtureConfig
    $null = Add-RecordsFixtureCommit $repo 'chore: base' @{ 'README.md' = "base`n" }
    $scriptCopy = Join-RecordsRepoPath $repo 'scripts/project-records.ps1'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $scriptCopy) -Force
    Copy-Item -LiteralPath $script:RecordsScriptPath -Destination $scriptCopy -Force
    Write-RecordsFixtureFile $repo 'records.config.json' ((Get-RecordsFixtureConfigDocument) | ConvertTo-Json -Depth 8)
    Write-RecordsFixtureFile $repo '.githooks/commit-msg' ($script:RecordsFixtureCommitMsgHook.Replace("`r`n", "`n") + "`n")
    Write-RecordsFixtureFile $repo '.githooks/pre-commit' ($script:RecordsFixturePreCommitHook.Replace("`r`n", "`n") + "`n")
    if ([System.IO.Path]::DirectorySeparatorChar -eq '/') {
        foreach ($hookName in @('pre-commit', 'commit-msg')) {
            $null = Invoke-RecordsProcess -FileName 'chmod' -Arguments @('+x', (Join-RecordsRepoPath $repo ".githooks/$hookName")) -WorkingDirectory $repo
        }
    }
    $null = Invoke-RecordsFixtureGit $repo @('config', 'core.hooksPath', '.githooks')

    $headOf = { (Invoke-RecordsFixtureGit $repo @('rev-parse', 'HEAD')).Lines[0].Trim() }
    $allText = { param($Result) ($Result.Stdout + "`n" + $Result.Stderr) }
    $prefixPattern = [regex]::Escape($config.LogPrefix) + ' FAIL'

    $before = & $headOf
    $result = Invoke-RecordsFixtureGit $repo @('commit', '--allow-empty', '-m', 'Update stuff') -AllowFailure
    & $Assert 'end-to-end: refuses a free-form subject and leaves HEAD unchanged' (
        $result.ExitCode -ne 0 -and (& $headOf) -ceq $before -and (& $allText $result) -cmatch $prefixPattern) (& $allText $result)

    $bomPath = Join-Path $script:RecordsFixtureRoot ('bom-message-' + [guid]::NewGuid().ToString('N') + '.txt')
    [System.IO.File]::WriteAllText($bomPath, 'chore: bom message', (New-Object System.Text.UTF8Encoding $true))
    $result = Invoke-RecordsFixtureGit $repo @('commit', '--allow-empty', '-F', $bomPath) -AllowFailure
    & $Assert 'end-to-end: refuses a BOM-prefixed message file' (
        $result.ExitCode -ne 0 -and (& $headOf) -ceq $before -and (& $allText $result) -cmatch ('(?s)' + $prefixPattern + '.*byte order mark')) (& $allText $result)

    $archivePath = 'plans/complete/cycle-e2e/hub.plan.md'
    Write-RecordsFixtureFile $repo $archivePath "plan`n"
    $null = Invoke-RecordsFixtureGit $repo @('add', '--', $archivePath)
    $result = Invoke-RecordsFixtureGit $repo @('commit', '-m', 'docs(records): close fixture cycle') -AllowFailure
    & $Assert 'end-to-end: refuses an archive commit without a DEVLOG entry' (
        $result.ExitCode -ne 0 -and (& $headOf) -ceq $before -and (& $allText $result) -cmatch ('(?s)' + $prefixPattern + '.*cycle-e2e')) (& $allText $result)

    Write-RecordsFixtureFile $repo 'DEVLOG.md' "# Log`nClosed cycle-e2e.`n"
    $null = Invoke-RecordsFixtureGit $repo @('add', '--', 'DEVLOG.md')
    $result = Invoke-RecordsFixtureGit $repo @('commit', '-m', 'docs(records): close fixture cycle') -AllowFailure
    & $Assert 'end-to-end: accepts a conventional archive commit that names the key' ($result.ExitCode -eq 0 -and (& $headOf) -cne $before) (& $allText $result)
}

function Invoke-RecordsSelfTest {
    $results = [System.Collections.Generic.List[pscustomobject]]::new()
    $assert = {
        param([string]$Name, [bool]$Condition, [string]$Detail = '')
        $results.Add([pscustomobject]@{ Name = $Name; Passed = $Condition; Detail = $Detail })
    }

    $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('project-records-selftest-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $fixtureRoot -Force
    $script:RecordsFixtureRoot = [System.IO.Path]::GetFullPath($fixtureRoot)
    $groups = @(
        @{ Name = 'config'; Run = { Invoke-RecordsSelfTestConfig $assert } },
        @{ Name = 'subject'; Run = { Invoke-RecordsSelfTestSubject $assert } },
        @{ Name = 'archive'; Run = { Invoke-RecordsSelfTestArchive $assert } },
        @{ Name = 'check'; Run = { Invoke-RecordsSelfTestCheck $assert } },
        @{ Name = 'range'; Run = { Invoke-RecordsSelfTestRange $assert } },
        @{ Name = 'render'; Run = { Invoke-RecordsSelfTestRender $assert } },
        @{ Name = 'cut'; Run = { Invoke-RecordsSelfTestCut $assert } },
        @{ Name = 'end-to-end'; Run = { Invoke-RecordsSelfTestEndToEnd $assert } }
    )
    try {
        foreach ($group in $groups) {
            try {
                & $group.Run
            } catch {
                & $assert "self-test group $($group.Name) aborted: $($_.Exception.Message)" $false
            }
        }
    } finally {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:RecordsFixtureRoot = $null
    }

    $stdoutLines = [System.Collections.Generic.List[string]]::new()
    $stderrLines = [System.Collections.Generic.List[string]]::new()
    foreach ($result in $results) {
        if ($result.Passed) {
            $stdoutLines.Add("PASS $($result.Name)")
            continue
        }
        $stderrLines.Add("FAIL $($result.Name)")
        if ($result.Detail) { $stderrLines.Add("      detail: $($result.Detail)") }
    }
    $failedCount = @($results | Where-Object { -not $_.Passed }).Count
    if ($failedCount -eq 0) {
        $stdoutLines.Add("SELF-TEST PASS $($results.Count) of $($results.Count) cases")
        return New-RecordsSplitOutcome 0 $stdoutLines.ToArray() @()
    }
    $stderrLines.Add("SELF-TEST FAIL $failedCount of $($results.Count) cases failed")
    return New-RecordsSplitOutcome 1 $stdoutLines.ToArray() $stderrLines.ToArray()
}

# ---------------------------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------------------------

function Get-RecordsArgumentError {
    param([string]$CommandName, [hashtable]$Supplied)
    if ([string]::IsNullOrWhiteSpace($CommandName)) {
        return "missing subcommand; expected one of: $($script:RecordsCommands -join ', ')"
    }
    if ($script:RecordsCommands -cnotcontains $CommandName) {
        return "unknown command `"$CommandName`"; expected one of: $($script:RecordsCommands -join ', ')"
    }
    $allowed = @{
        'check-msg'         = @('Path', 'Config')
        'check-commit'      = @('Config')
        'check-range'       = @('Base', 'Head', 'Config')
        'check'             = @('Config')
        'changelog-preview' = @('From', 'To', 'OutFile', 'Config')
        'changelog-cut'     = @('Tag', 'From', 'Config')
        'self-test'         = @('Config')
    }
    foreach ($name in @($Supplied.Keys | Sort-Object)) {
        if ($allowed[$CommandName] -notcontains $name) {
            $flag = if ($name -ceq 'Path') { 'a path argument' } else { "-$name" }
            return "$CommandName does not take $flag"
        }
    }
    $required = @{ 'check-msg' = @('Path'); 'check-range' = @('Base', 'Head'); 'changelog-cut' = @('Tag') }
    if ($required.ContainsKey($CommandName)) {
        foreach ($name in $required[$CommandName]) {
            if (-not $Supplied.ContainsKey($name)) {
                $flag = if ($name -ceq 'Path') { 'a message file path' } else { "-$name" }
                return "$CommandName requires $flag"
            }
        }
    }
    return $null
}

function Invoke-RecordsCli {
    param(
        [string]$CommandName,
        [string]$MessagePath,
        [string]$BaseRevision,
        [string]$HeadRevision,
        [string]$FromRevision,
        [string]$ToRevision,
        [string]$OutputPath,
        [string]$TagName,
        [string]$ConfigPath
    )
    $supplied = @{}
    if (-not [string]::IsNullOrEmpty($MessagePath)) { $supplied['Path'] = $MessagePath }
    if (-not [string]::IsNullOrEmpty($BaseRevision)) { $supplied['Base'] = $BaseRevision }
    if (-not [string]::IsNullOrEmpty($HeadRevision)) { $supplied['Head'] = $HeadRevision }
    if (-not [string]::IsNullOrEmpty($FromRevision)) { $supplied['From'] = $FromRevision }
    if (-not [string]::IsNullOrEmpty($ToRevision)) { $supplied['To'] = $ToRevision }
    if (-not [string]::IsNullOrEmpty($OutputPath)) { $supplied['OutFile'] = $OutputPath }
    if (-not [string]::IsNullOrEmpty($TagName)) { $supplied['Tag'] = $TagName }
    if (-not [string]::IsNullOrEmpty($ConfigPath)) { $supplied['Config'] = $ConfigPath }

    $session = [pscustomobject]@{ LogPrefix = $script:RecordsDefaultLogPrefix; Outcome = $null }
    $argumentError = Get-RecordsArgumentError $CommandName $supplied
    if ($null -ne $argumentError) {
        $session.Outcome = New-RecordsOutcome 1 @("FAIL $argumentError")
        return $session
    }

    $repoRoot = Get-RecordsRepoRoot (Get-Location).ProviderPath
    $resolvedConfigPath = $null
    if (-not [string]::IsNullOrEmpty($ConfigPath)) { $resolvedConfigPath = Resolve-RecordsPath $ConfigPath }
    elseif ($null -ne $repoRoot) { $resolvedConfigPath = Join-Path $repoRoot $script:RecordsConfigFileName }

    if ($CommandName -ceq 'self-test') {
        if ($null -ne $resolvedConfigPath -and (Test-Path -LiteralPath $resolvedConfigPath -PathType Leaf)) {
            try { $session.LogPrefix = (Read-RecordsConfig $resolvedConfigPath).LogPrefix } catch { }
        }
        try { $session.Outcome = Invoke-RecordsSelfTest } catch { $session.Outcome = New-RecordsOutcome 1 @("FAIL self-test stopped: $($_.Exception.Message)") }
        return $session
    }

    if ($null -eq $repoRoot) {
        $session.Outcome = New-RecordsOutcome 1 @('FAIL the current directory is not inside a git work tree')
        return $session
    }
    try {
        $config = Read-RecordsConfig $resolvedConfigPath
    } catch {
        $session.Outcome = New-RecordsOutcome 1 @("FAIL $($_.Exception.Message)")
        return $session
    }
    $session.LogPrefix = $config.LogPrefix
    $context = New-RecordsContext $repoRoot $config
    try {
        switch -CaseSensitive ($CommandName) {
            'check-msg' { $session.Outcome = Invoke-RecordsCheckMsg $context $MessagePath }
            'check-commit' { $session.Outcome = Invoke-RecordsCheckCommit $context }
            'check-range' { $session.Outcome = Invoke-RecordsCheckRange $context $BaseRevision $HeadRevision }
            'check' { $session.Outcome = Invoke-RecordsCheck $context }
            'changelog-preview' { $session.Outcome = Invoke-RecordsChangelogPreview $context $FromRevision $ToRevision $OutputPath }
            'changelog-cut' { $session.Outcome = Invoke-RecordsChangelogCut $context $TagName $FromRevision }
        }
    } catch {
        $session.Outcome = New-RecordsOutcome 1 @("FAIL $CommandName stopped: $($_.Exception.Message)")
    }
    return $session
}

if ($MyInvocation.InvocationName -ne '.') {
    $cliSession = Invoke-RecordsCli -CommandName $Command -MessagePath $Path -BaseRevision $Base -HeadRevision $Head `
        -FromRevision $From -ToRevision $To -OutputPath $OutFile -TagName $Tag -ConfigPath $Config
    $cliOutcome = $cliSession.Outcome
    $formatLine = { param([string]$Line) if ($cliOutcome.Raw) { $Line } else { "$($cliSession.LogPrefix) $Line" } }
    foreach ($warningText in $cliOutcome.Warnings) {
        [Console]::Error.WriteLine("$($cliSession.LogPrefix) WARN $warningText")
    }
    foreach ($outputLine in $cliOutcome.StdoutLines) {
        Write-Output (& $formatLine $outputLine)
    }
    foreach ($errorLine in $cliOutcome.StderrLines) {
        [Console]::Error.WriteLine((& $formatLine $errorLine))
    }
    if ($cliOutcome.Summary) {
        [Console]::Error.WriteLine("$($cliSession.LogPrefix) $($cliOutcome.Summary)")
    }
    exit $cliOutcome.ExitCode
}
