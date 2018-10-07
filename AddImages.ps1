param(
    [Parameter(<# Mandatory=$true #>)][string]
    $imageRepositoryPath = "E:\ISboxer\ISBoxerImages",
    [Parameter(<# Mandatory=$true #>)][string]
    $imageSetName = "Pro",
    [Parameter()][string]
    $isboxerInstallPath = "F:\Programs\ISBoxer"
)

Set-Location $PSScriptRoot
[Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath 

[xml]$doc = Get-Content $isboxerInstallPath\ISBoxerToolkitGlobalSettings.XML

# check if all files still exist
foreach($image in $doc.SelectNodes("//Image"))
{
    if($image.ImageSet -eq "Default") { continue; }
    if(!(Test-Path $image.Filename))
    {
        Write-Host "The file $($image.Filename) was not found, removing"
        $image.ParentNode.RemoveChild($image)
    }
}

# Insert Images
function ImageExists([xml]$doc, $imagePath)
{
    foreach($image in $doc.SelectNodes("//Image"))
    {
        if($image.ImageSet -ne $imageSetName) { continue; }
        if($image.Filename -eq $imagePath)
        {
            return $true
        }
    }
    return $false
}

function CreateXmlNodes($doc, $obj, $parent, $l = 1)
{
    foreach($key in $obj.Keys)
    {
        # Write-Host "$(' ' * $l)Node: $($key) ($l)"
        $subNode = $doc.CreateElement($key)
        $parent.AppendChild($subNode) | Out-Null
        $value = $obj[$key]
        switch($value.GetType().FullName)
        {
            "System.String" {
                $subNode.InnerText = $value
            }
            "System.Int32" {
                $subNode.InnerText = $value
            }
            "System.Collections.Hashtable" {
                CreateXmlNodes $doc $value $subNode ($l + 1)
            }
            Default {
                Write-Host "Unknown type: $($value.GetType().FullName)"
            }
        }
    }
}

foreach($file in Get-ChildItem -File -Recurse $imageRepositoryPath)
{
    $name = $file.FullName.Substring($imageRepositoryPath.Length + 1).Replace("\", "/")

    if((ImageExists $doc $file.FullName))
    {
        "Image already exists: $($file.FullName), skipping"
        continue
    }

    $data = @{
        "Name"=$name;
        "ImageSet"=$imageSetName;
        "Filename"=$file.FullName;
        "Crop"=@{
            "Location"=@{ "X"=0; "Y"=0 };
            "Size"=@{ "Width"=0; "Height"=0 };
            "X"=0;
            "Y"=0;
            "Width"=0;
            "Height"=0;
        };
        "ColorMask"=@{
            "Red"=51;
            "Green"=51;
            "Blue"=51;
        }
    }

    $imageNode = $doc.CreateElement("Image")
    CreateXmlNodes $doc $data $imageNode
    $lastNode = $doc.SelectNodes("//Image[last()]")[0]
    $doc.ISBoxerToolkitGlobalSettings.InsertAfter($imageNode, $lastNode) | Out-Null
}

$doc.Save("$isboxerInstallPath\ISBoxerToolkitGlobalSettings.XML")