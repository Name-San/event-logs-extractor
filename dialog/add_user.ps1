# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework

# Load the XAML file
$xamlPath = "C:\App\dialog\dialog.xaml"
[xml]$xaml = Get-Content $xamlPath
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get UI elements
$DeviceIDTextBox = $window.FindName("DeviceIDTextBox")
$AddButton = $window.FindName("AddButton")

# Define Start Scan Button Click Event
$AddButton.Add_Click({
    # Retrieve the entered Device ID
    $deviceID = $DeviceIDTextBox.Text

    if ([string]::IsNullOrWhiteSpace($deviceID)) {
        # Notify user if Device ID is empty
        [System.Windows.MessageBox]::Show("Please enter a valid Device ID.", "Error")
        return
    } else {
        echo "device: $deviceID" > C:\App\config\user.prof
        [System.Windows.MessageBox]::Show("Device registration complete.")
    }

exit 0

})

# Show the window
$window.ShowDialog()

