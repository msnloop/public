function Get-NvidiaDownloadLink {
    param (
        [string]$url
    )
    Write-Verbose "Scraping URL: $url"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    $downloadLink = $null

    if ($response.Content -match 'https:\/\/us\.download\.nvidia\.com\/nvapp\/client\/[\d\.]+\/NVIDIA_app_v[\d\.]+\.exe') {
        $downloadLink = $matches[0]
    }
    elseif ($response.Content -match '<a[^>]*href="([^"]*nv[^"]*app[^"]*\.exe)"[^>]*>\s*<span[^>]*>Download Now<\/span>') {
        $downloadLink = $matches[1]
    }
    elseif ($response.Content -match 'href="([^"]*nv[^"]*app[^"]*\.exe)"') {
        $downloadLink = $matches[1]
    }

    return $downloadLink
}

$url = "https://www.nvidia.com/en-us/software/nvidia-app/"
$downloadLink = Get-NvidiaDownloadLink -url $url
$installParams = "-s -noreboot -noeula -nofinish -nosplash"

if ($downloadLink) {
    Write-Output "Downloading from: $downloadLink"
    $fileName = [System.IO.Path]::GetFileName($downloadLink)
    $nvapp = "$($env:TEMP)\$fileName"
    $client = new-object System.Net.WebClient
    $client.DownloadFile($downloadLink, $nvapp)
} else {
    Write-Output "Unable to get NVIDIA App download link"
}

if (Test-Path -Path "$nvapp") {
    Write-Output "Installing NVIDIA App from path: $nvapp with parameters: $installParams"
    $proc = (Start-Process -FilePath $nvapp -ArgumentList $installParams -Wait -PassThru)
    $proc.WaitForExit()
    Write-Output "NVIDIA App exit code: $($proc.ExitCode)"
}

function Get-InstalledNvidiaAppVersion {
    $appPath = Join-Path -Path ${env:ProgramFiles} -ChildPath "NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe"
    if (Test-Path $appPath) {
        $fileVersionInfo = Get-Item $appPath | Select-Object -ExpandProperty VersionInfo
        return $fileVersionInfo.ProductVersion
    }
    else {
        return $null
    }
}
