function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle = "PowerShell",
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText = "PowerShell Notification"
    )

    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue

    $toastManagerType = [type]::GetType('Windows.UI.Notifications.ToastNotificationManager, Windows, ContentType=WindowsRuntime', $false)
    $xmlDocumentType = [type]::GetType('Windows.Data.Xml.Dom.XmlDocument, Windows, ContentType=WindowsRuntime', $false)
    $toastType = [type]::GetType('Windows.UI.Notifications.ToastNotification, Windows, ContentType=WindowsRuntime', $false)
    $toastTemplateType = [type]::GetType('Windows.UI.Notifications.ToastTemplateType, Windows, ContentType=WindowsRuntime', $false)

    if ($toastManagerType -and $xmlDocumentType -and $toastType -and $toastTemplateType) {
        $template = $toastManagerType::GetTemplateContent($toastTemplateType::ToastText02)
        $rawXml = [xml]$template.GetXml()
        ($rawXml.toast.visual.binding.text | Where-Object { $_.id -eq '1' }).AppendChild($rawXml.CreateTextNode($ToastTitle)) > $null
        ($rawXml.toast.visual.binding.text | Where-Object { $_.id -eq '2' }).AppendChild($rawXml.CreateTextNode($ToastText)) > $null

        $serializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $serializedXml.LoadXml($rawXml.OuterXml)

        $toast = $toastType::new($serializedXml)
        $toast.Tag = 'PowerShell'
        $toast.Group = 'PowerShell'
        $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)
        $toast.Priority = $toastType::High
        $toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(1)
        $toast.ExpiresOnReboot = $true

        $notifier = $toastManagerType::CreateToastNotifier('PowerShell')
        $notifier.Show($toast)
        return
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notifyIcon.BalloonTipTitle = $ToastTitle
    $notifyIcon.BalloonTipText = $ToastText
    $notifyIcon.Visible = $true
    $notifyIcon.ShowBalloonTip(5000)
}
