function Join-ffmpegMp4 {
    param (
        [Parameter(
            ValueFromPipeline = $true
        )]
        [ValidateScript({
                $_.Name -match '\.mp4'
            })]
        [System.IO.FileInfo[]]$Files,
        [System.IO.DirectoryInfo]$TempFolder,
        [System.IO.FileInfo]$OutputFile
    )
    begin {
        [string[]]$outFiles = @()
    }
    process {
        foreach ($file in $Files) {
            $tmpFile = "$($TempFolder.FullName)$($file.BaseName).ts"
            & ffmpeg -y -i "$($file.FullName)" -c copy -bsf:v h264_mp4toannexb -f mpegts $tmpFile -v quiet
            [string[]]$outFiles += $tmpFile
        }
    }
    end {
        $concatString = "concat:" + ($outFiles -join '|')
        & ffmpeg -f mpegts -i $concatString -c copy -bsf:a aac_adtstoasc $OutputFile -v quiet
        foreach ($file in $outFiles) {
            Remove-Item $file -Force
        }
    }
}
