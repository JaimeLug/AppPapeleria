$ErrorActionPreference = "Stop"

$projectRoot = Get-Location
$buildDir = "$projectRoot\build\windows"
$runnerDir = "$buildDir\runner\Debug"

# Ensure the runner directory exists
if (-not (Test-Path $runnerDir)) {
    Write-Host "Error: Runner directory not found at $runnerDir. Please build the project first." -ForegroundColor Red
    exit 1
}

# Define source paths for DLLs
$dlls = @(
    @{
        Source = "$projectRoot\windows\flutter\ephemeral\flutter_windows.dll"
        Name = "flutter_windows.dll"
    },
    @{
        Source = "$buildDir\plugins\connectivity_plus\Debug\connectivity_plus_plugin.dll"
        Name = "connectivity_plus_plugin.dll"
    },
    @{
        Source = "$buildDir\plugins\printing\Debug\printing_plugin.dll"
        Name = "printing_plugin.dll"
    },
    @{
        Source = "$buildDir\pdfium-src\bin\pdfium.dll"
        Name = "pdfium.dll"
    }
)

Write-Host "Copying missing DLLs..." -ForegroundColor Cyan

foreach ($dll in $dlls) {
    if (Test-Path $dll.Source) {
        Copy-Item -Path $dll.Source -Destination $runnerDir -Force
        Write-Host "Copied $($dll.Name)" -ForegroundColor Green
    } else {
        Write-Host "Warning: Could not find $($dll.Name) at $($dll.Source)" -ForegroundColor Yellow
    }
}

Write-Host "Launching application..." -ForegroundColor Cyan
& "$runnerDir\app_papeleria.exe"
