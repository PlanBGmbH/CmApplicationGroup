# Demo Code for ConfigMgr ApplicationGroup handling
This repository includes PowerShell demo code for creating and updating ConfigMgr Application Groups (Bundles) via the ConfigMgr SDK.

It is not a complete E2E solution. It just demonstrates the basic parts how to do it.

The sample code was tested and verified with the ConfigMgr TP1905.

# Basic Steps
1. Load the dependend AdminUI Libraries for managing ApplicationGroups
2. Create the in memory Application Group Object
3. Set the Localization information
4. Create and add the applications that should belong to this group
5. Serialize the object to SDMPackageXml
6. Create the ConfigMgr **SMS_ApplicationGroup** Object
7. Save the ConfigMgr Object
