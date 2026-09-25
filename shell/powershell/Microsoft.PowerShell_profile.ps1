# Prompt -----------------------------------------------------------------------
$localBin = Join-Path $HOME '.local/bin'
if ((Test-Path -LiteralPath $localBin) -and
    -not (($env:PATH -split [IO.Path]::PathSeparator) -contains $localBin)) {
    $env:PATH = "$localBin$([IO.Path]::PathSeparator)$env:PATH"
}

$promptConfigPath = Join-Path $HOME '.config/oh-my-posh/lucas.omp.json'

if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git -ErrorAction SilentlyContinue
}

if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and
    (Test-Path -LiteralPath $promptConfigPath)) {
    oh-my-posh init pwsh --config $promptConfigPath | Invoke-Expression
}

# Linha de comando, historico e completions ------------------------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -Force

    Set-PSReadLineOption `
        -EditMode Emacs `
        -BellStyle None `
        -HistoryNoDuplicates `
        -HistorySearchCursorMovesToEnd `
        -MaximumHistoryCount 10000

    # Predictions geram erro quando a saida esta redirecionada (scripts/CI).
    if (-not [Console]::IsOutputRedirected) {
        try {
            Set-PSReadLineOption `
                -PredictionSource History `
                -PredictionViewStyle ListView `
                -ErrorAction Stop
        }
        catch {
            # Alguns hosts nao oferecem os recursos visuais exigidos pelo PSReadLine.
        }
    }

    # Tab abre uma lista selecionavel de comandos, parametros, arquivos e pastas.
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+c' -Function CopyOrCancelLine
    Set-PSReadLineKeyHandler -Chord 'Ctrl+v' -Function Paste
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardDeleteWord

    # Se a linha contiver somente uma pasta, Enter entra nela sem exigir `cd`.
    Set-PSReadLineKeyHandler `
        -Key Enter `
        -BriefDescription SmartEnter `
        -LongDescription 'Executa a linha ou entra diretamente em uma pasta' `
        -ScriptBlock {
            param($key, $arg)

            $line = $null
            $cursor = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
                [ref]$line,
                [ref]$cursor
            )

            $candidatePath = $line.Trim()
            if ($candidatePath -and
                (Test-Path -LiteralPath $candidatePath -PathType Container)) {
                $escapedPath = $candidatePath.Replace("'", "''")
                $replacement = "Set-Location -LiteralPath '$escapedPath'"
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                    0,
                    $line.Length,
                    $replacement
                )
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
}

# Busca fuzzy ------------------------------------------------------------------
if ((Get-Module -ListAvailable -Name PSFzf) -and
    (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Import-Module PSFzf

    if (-not $env:FZF_DEFAULT_OPTS) {
        $env:FZF_DEFAULT_OPTS = '--height=45% --layout=reverse --border=rounded --info=inline --cycle'
    }

    $fzfOptions = @{
        PSReadlineChordProvider       = 'Ctrl+f'
        PSReadlineChordReverseHistory = 'Ctrl+r'
        PSReadlineChordSetLocation    = 'Alt+c'
    }

    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $fzfOptions.EnableFd = $true
    }

    Set-PsFzfOption @fzfOptions

    function cdf {
        [CmdletBinding()]
        param([string]$Path = (Get-Location).Path)

        Invoke-FuzzySetLocation -Directory $Path
    }
}

# Atalhos ----------------------------------------------------------------------
if (Get-Command nvim -ErrorAction SilentlyContinue) { Set-Alias vim nvim }
if (Get-Command git -ErrorAction SilentlyContinue)  { Set-Alias g git }
if (Get-Command bat -ErrorAction SilentlyContinue)  { Set-Alias b bat }
elseif (Get-Command batcat -ErrorAction SilentlyContinue) { Set-Alias b batcat }

Set-Alias c Set-Location

# Listagem moderna com icones. `gci` continua sendo o Get-ChildItem nativo.
if (Get-Command eza -ErrorAction SilentlyContinue) {
    if (Test-Path Alias:ls) {
        Remove-Item Alias:ls -Force
    }

    function ls { eza --icons=always --group-directories-first @args }
    function ll { eza --long --all --header --git --icons=always --group-directories-first @args }
    function lt { eza --tree --level=3 --git-ignore --icons=always --group-directories-first @args }
}
else {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Import-Module Terminal-Icons
    }

    function ll { Get-ChildItem -Force @args }
}

# Navegacao inteligente: `z termo` salta e `zi` abre selecao interativa.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    $env:_ZO_FZF_OPTS = '--height=45% --layout=reverse --border=rounded --cycle'
    zoxide init powershell | Out-String | Invoke-Expression
}

# Versoes de runtimes, variaveis de ambiente e tarefas por projeto.
if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise activate pwsh | Out-String | Invoke-Expression
}

# Wrappers consistentes para os namespaces do Docker.
if (Get-Command docker -ErrorAction SilentlyContinue) {
    function dc  { docker container @args }
    function dco { docker compose @args }
    function di  { docker image @args }
    function dn  { docker network @args }
    function dv  { docker volume @args }
    function ds  { docker system @args }
}

function ..  { Set-Location .. }
function ... { Set-Location ../.. }

function mkcd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    $directory = New-Item -ItemType Directory -Path $Path -Force
    Set-Location -LiteralPath $directory.FullName
}

function which {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    Get-Command $Name -ErrorAction SilentlyContinue |
        Select-Object Name, CommandType, Source, Version
}

function Edit-Profile { nvim $PROFILE.CurrentUserCurrentHost }
function Reload-Profile { . $PROFILE.CurrentUserCurrentHost }

Set-Alias ep Edit-Profile
Set-Alias reload Reload-Profile

# No Debian, tig e less sao executaveis normais encontrados pelo PATH.
