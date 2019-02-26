
#Get template
$targetFile = 'C:\temp\environmentgeneral.json'
$templateLocation = 'C:\Users\JamieFellows\OneDrive - Applied Cloud Systems\Projects\accuweather\environmentgeneral_template.json'
$templateContents = get-content $templateLocation | convertfrom-json 
$instanceNameCount = 0
$instanceNameArray = @()


function new-instanceNames(){
    # Prompt for Instance names
    $instanceNameCount = [int](read-host "How many instance names?")

    # Get instance names
    while($instanceNameArray.count -lt $instanceNameCount){
        write-host $instanceNameCount
        $name = read-host "Please enter instance name: "
        $instanceNameArray =  $instanceNameArray + $name
    }

    get-instanceNames
}


function get-instanceNames(){
    # Validate we set up the instance names correctly
    Write-host "Please validate the names below"
    $tempCounter = 0
    foreach($name in $instanceNameArray){
        write-host $tempCounter ")" $name
        $tempCounter++
    }

    $response = read-host "Does this look correct?(Y/N)"

    if ($response -eq "Y" -or $response -eq "y") {
        # set the array to the instance names
        write-host "Setting instance names in config...."
        for($i = 0; $i -lt $templateContents.resources.Length; $i++){
          
            if ($templateContents.resources[$i].properties.instanceNames) {
                write-host "FOUND INSTANCE ITEM"
                $templateContents.resources[$i].properties.instanceNames = @()
                foreach ($tempItem in $instanceNameArray){
                    write-host "BLARG" $tempItem
                    $templateContents.resources[$i].properties.instanceNames = $templateContents.resources[$i].properties.instanceNames + $tempItem
                }
            }
        }
       
        $templateContents | ConvertTo-Json -depth 100 | Out-File $targetFile
        deploy-newresources
    } else {
        write-host "Which one is incorrect?"
        write-host "Type all to start again"
        $num = Read-Host 

        if($num -eq "all" -or $num -eq "ALL"){
            # We start again
            new-instanceNames
        } else {
            # We update the one
            set-instanceNames
        }
    }
}

function set-paramaters(){
    Write-Host "Would you like to change any of these?"
    $response = read-host "Type N to continue, enter the number to change the value"

    if($response -eq "N" -or $response -eq "n"){
        return
    } else {
        $newValue = read-host "What should the new default value be for "  $paramArray[$response]
        write-host $newValue
        $templateContents.parameters.($paramArray[$response]).defaultValue = $newValue
        get-paramaters


    }
}


$paramArray = @()
function get-paramaters(){
    Write-Host "Please verify the paramaters below"
    $paramCounter = 0
    $menuCounter  = 0
    foreach($param in $templateContents.parameters | Get-Member | Where-Object {$_.MemberType -ne "Method"}){
        $indexOfDefaultValue = $param.Definition.IndexOf("defaultValue=")
        $indexofEndofDefaultValue = $param.Definition.IndexOf(";", $indexOfDefaultValue)
        $defaultValue = $param.Definition.Substring($indexOfDefaultValue, $indexofEndofDefaultValue - $indexOfDefaultValue)
        $paramArray = $paramArray + $param.name
        write-host $paramCounter ")  Name: " $param.name 
        write-host "     Value:  " $defaultValue
        
    
        $paramCounter += 1
        $menuCounter += 1
        if($menuCounter -eq 9){
            set-paramaters 
            $menuCounter = 0
            
        }
        if($paramCounter -eq ($templateContents.parameters | Get-Member | Where-Object {$_.MemberType -ne "Method"}).count){
            set-paramaters 
            $menuCounter = 0
            
            break
            
        }
        
    }
    new-instanceNames
}

function set-instanceNames(){
    param(
        [int]$targetInstanceName
    )

    write-host "Current value is: " $instanceNameArray[$targetInstanceName]
    $newName = read-host "What is the new instance name"
    $instanceNameArray[$targetInstanceName] = $newName

    #Validate them again
    get-instanceNames

}

function deploy-newresources(){
    New-AzDeployment -templateFile 

}

#Start Script


function start-deploymentScript(){
    Connect-AzAccount
    $azureContext = Get-AzContext
    write-host "Current Azure Context: " $azureContext
    $response = read-host "Is this correct?(Y/N)"
    if($response -eq "N" -or $response -eq "n"){
        $subscriptions = Get-AzSubscription
        foreach($sub in $subscriptions){
            write-host $sub
        }

        $subChoice = read-host "Enter the Subscription you want to use:"
        Set-AzContext -Subscription $subChoice
    }

    get-paramaters
}




