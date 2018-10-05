Set-Location $PSScriptRoot
[Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath 

$doc = [xml](Get-Content pro-v2.xml)
foreach($character in $doc.SelectNodes("//Character"))
{
    foreach($vft in $character.VirtualFileTargets.ChildNodes)
    {
        switch ($vft.VirtualFileString) {
            "AddOns.txt" {
                $vft.Filename = "../../../AddOns-ISBoxer.txt"
            }
            "Config.WTF" {
                $vft.Filename = "Config-$($character.SubAccountName).WTF"
            }
            Default {
            }
        }
    }
}

$doc.Save("out.xml")