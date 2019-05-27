# This is just a PoC/demo Code to demonstrate how to create an application bundle group within ConfigMgr starting with TP1905.
# Some best practise patterns for robust code are missing.
# It also includes demo code on how to deserialize an SDMPackageXML to an Application Group Object for modifications


[System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.dll")) | Out-Null

function Create-CmApplicationGroup()
{
    # Basic Application Group Data
    $SiteServer = "CMTP.lab.local"
    $SiteCode = "LAB"
    $ApplicationTitle = "Test Application Bundle"
    $ApplicationVersion = 1 # Application Group Revision
    $ApplicationSoftwareVersion = "1.0.0"
    $ApplicationLanguage = (Get-Culture).Name # en-US
    $ApplicationDescription = "Application Bundle Test Description"
    $ApplicationPublisher = "Corporate Publisher Name"


    # Get ScopeID of ConfigMgr Site
    $GetIdentification = [WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Identification"
    $ScopeID = "ScopeId_" + $GetIdentification.GetSiteID().SiteID -replace "{","" -replace "}",""

    # Create ObjectId for Application Group an the ApplicationGroup Objects in memory
    $appGroupId = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectId($ScopeID,"ApplicationGroup_" + [GUID]::NewGuid().ToString())
    $appGroup = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ApplicationGroup($appGroupId)

    # Create the Localized Display Info
    $displayInfo = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.AppDisplayInfo
    $displayInfo.Language = $ApplicationLanguage
    $displayInfo.Title = $ApplicationTitle
    $displayInfo.Description = $ApplicationDescription
    
    # Set DisplayInfo and generic Information
    $appGroup.DisplayInfo.Add($ObjectDisplayInfo)
    $appGroup.DisplayInfo.DefaultLanguage = $ApplicationLanguage
    $appGroup.Title = $ApplicationTitle
    $appGroup.Version = $ApplicationVersion
    $appGroup.SoftwareVersion = $ApplicationSoftwareVersion
    $appGroup.Description = $ApplicationDescription
    $appGroup.Publisher = $ApplicationPublisher

    # Create first item in Application Group
    $grpItem1Ref = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectRef($scopeId, "Application_4908dfac-41a5-454b-bd55-c0e3d5dfd332")
    $grpItem1 = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.GroupItem
    $grpItem1.ObjectId = $grpItem1Ref
    $grpItem1.Order = 1

    # Create second item in Application Group
    $grpItem2Ref = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectRef($scopeId, "Application_1f11e8b2-ae6d-4a04-bbd7-3c216608d2ff")
    $grpItem2 = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.GroupItem
    $grpItem2.ObjectId = $grpItem2Ref
    $grpItem2.Order = 2

    # Add Items / Applications to Application Group
    $appGroup.GroupItems.Add($grpItem1)
    $appGroup.GroupItems.Add($grpItem2)

    # Serialize Object to XML
    $appGroupXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeObjectToString($appGroup, $true)

    # Create ConfigMgr Application Group Object
    $appGroupObject = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ApplicationGroup").CreateInstance()
    $appGroupObject = $appGroupXML
    $newAppGroup = $objAppGroup.Put()
}

function Modify-CmApplicationGroup([string]$appGroupModelName)
{
    # Basic Application Group Data
    $SiteServer = "CMTP.lab.local"
    $SiteCode = "LAB"

    # Create Deserializsation Method from generic .Net method for Type "Microsoft.ConfigurationManagement.ApplicationManagement.ApplicationGroup"
    $DeserialzeAppGrpMethod = ([Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer].GetMethods() | where {$_.Name -eq "DeserializeObjectFromString" -and $_.IsGenericMethod})[0].MakeGenericMethod([Microsoft.ConfigurationManagement.ApplicationManagement.ApplicationGroup])

    $wmiObj = Get-WmiObject -Namespace "\\$($SiteServer)\root\SMS\Site_$($SiteCode)" -Class SMS_ApplicationGroup -Filter "ModelName='$appGroupModelName' AND IsLatest=1"
    $wmiObj.Get()

    $appGroup = $DeserialzeAppGrpMethod.Invoke($null,@($wmiObj.SDMPackageXML, $true))

    # Create second item in Application Group
    $grpItemRef = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectRef($scopeId, "Application_1f11e8b2-ae6d-4a04-bbd7-3c216608d2ff")
    $grpItem = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.GroupItem
    $grpItem.ObjectId = $grpItemRef
    $grpItem.Order = $appGroup.GroupItems.Count + 1

    $appGroup.GroupItems.Add($grpItem)
    $appGroup.Publisher = "New Publisher"
    $appGroup.DisplayInfo[0].Publisher = "New Publisher"
    
    # Serialize Object to XML
    $appGroupXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeObjectToString($appGroup, $true)

    # Update ConfigMgr Application Group Object
    $wmiObj.SDMPackageXML = $appGroupXML
    $updatedAppGroup = $wmiObj.Put()
}
