# psruleexample

## Contains some sample data for verifying bicep / arm templates


### To Verify ARM you need to run
  Export-AzRuleTemplateData -TemplateFile .\resourcegroup.json -OutputPath .\
  
  ```powershell
  ResourceName   : .\resourcegroup.json
  name           : ps-rule-test-deployment
  properties     : @{template=; templateLink=; parameters=; mode=Incremental; provision
                   ingState=Accepted; templateHash=67010327; outputs=}
  location       : eastus
  type           : Microsoft.Resources/deployments
  metadata       : @{_generator=}
  rootDeployment : True
  _PSRule        : @{path=; source=System.Object[]}

  type     : Microsoft.Resources/resourceGroups
  name     : rg-testnortheurope
  location : northeurope
  tags     : @{env=kanin}
  id       : /subscriptions/ffffffff-ffff-ffff-ffff-ffffffffffff/resourceGroups/ps-rule 
             -test-rg/providers/Microsoft.Resources/resourceGroups/rg-testnortheurope   
  _PSRule  : @{path=resources[0]; source=System.Object[]}
```
