#######################################################################################################
# 
# Autor: Bernardo Lankheet
# Simple powershell script to extract information from agents registered in Tacticalrmm in csv
# Version: 1.0
# change the parameters $TRMM_API_Base_Endpoint, $TRMM_API_Key and $CSVFilePath.
# $TRMM_API_Base_Endpoint - TacticalRmm api
# $TRMM_API_Key - Settings > Global Settings > API Keys
# $CSVFilePath - path where the csv file will be stored.
#
#######################################################################################################

# Variables
$TRMM_API_Base_Endpoint = "https://api.domaintactical.com"
$TRMM_API_Key = "APIKEY" # Settings > Global Settings > API Keys
$CSVFilePath = "C:\rmm.csv" # Replace with the path you want to save the csv file

# API endpoint for querying agents and the headers for the request
$Agents_Endpoint = "$TRMM_API_Base_Endpoint/agents"
$TRMM_Request_Headers = @{
    "X-API-KEY" = $TRMM_API_Key
}

# Consult the list of all agents
$Agents = Invoke-RestMethod $Agents_Endpoint -Headers $TRMM_Request_Headers -ContentType "application/json" -Method "Get"
$AgentInfoList = @()

# Collect information from agents
$Agents | ForEach-Object -Begin {
    $TotalAgents = $Agents.Count
    $Counter = 0
} -Process {
    $Counter++
    $PercentComplete = ($Counter / $TotalAgents) * 100

    $Agent_ID = $_.agent_id
    $Agent_Info_Endpoint = "$TRMM_API_Base_Endpoint/agents/$Agent_ID"
    $Agent_Info = Invoke-RestMethod $Agent_Info_Endpoint -Headers $TRMM_Request_Headers -ContentType "application/json" -Method "Get"
    
    # Extract hostname from response
    $Hostname = $Agent_Info.hostname

    # Filtering all desired properties from the json output with the inventory information.
    $Filtered_Info = $Agent_Info | Select-Object -Property @{Name='Hostname';Expression={$Hostname}}, client, site_name, @{Name='CPU_Model';Expression={$_.cpu_model -join '; '}}, 
      @{Name='Disks';Expression={($_.disks | ForEach-Object { "Unidade $($_.device), Total: $($_.total), Percent: $($_.percent)%" }) -join '; ' }}, 
      operating_system, goarch, total_ram

    # create a list
    $AgentInfoList += $Filtered_Info

    # Creating a Progress Bar for Tracking
    Write-Progress -Activity "Generating report" -Status "Processing Agent $Counter of $TotalAgents" -PercentComplete $PercentComplete
} -End {
    # Export information to CSV file
    $AgentInfoList | Export-Csv -Path $CSVFilePath -NoTypeInformation

    # Completing report generation
    Write-Progress -Activity "Generating report" -Status "Concluded" -PercentComplete 100
    Write-Host "File saved in $CSVFilePath."
}
