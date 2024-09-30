#!/bin/bash


function az_location { 
  az account list-locations --output json | jq --arg displayName "$1" '.[] | select(.displayName == $displayName) | { "code": .name }'
}

# create array of all subs
subs=$(az account list --query '[].{id:id, name:name}' -o json)

# get the number of azure subscriptions
subnum=${#subs[@]}

# read in a valid password
complexpassword=-1
echo "Min 8 chars"
echo "at least one digit"
echo "at least one special char like #?!@$ %^&*-"
echo "at least one uppercase english letter"
while [ $complexpassword -le 0 ]
do
    read -p "Enter a password: " password
    echo "You entered $password"
    has_one_uppercase='[A-Z]'
    has_8='.{8}'
    has_digit='[[:digit:]]'
    has_special='[#?!@$ %^&*-]'  # or possibly '[[:punct:]]'

    if [[ $password =~ $has_8 ]] &&
    [[ $password =~ $has_digit ]] &&
    [[ $password =~ $has_special ]] &&
    [[ $password =~ $has_one_uppercase ]]
    then
        echo 'good'
        complexpassword=1
    else
        echo 'the password is weak. Please try again'
    fi
done

# generate a unique random suffix
suffix=$(shuf -er -n7  {A..Z} {a..z} {0..9} | tr -d '\n')
echo "Your randomly-generated suffix for Azure resources is $suffix"
resource_group_name="dp203-$suffix"

# Registers resource providers
provider_list="Microsoft.Synapse Microsoft.Sql Microsoft.Storage Microsoft.Compute"
for provider in $provider_list
do
#   az provider register --namespace $provider --wait
  status=$(az provider show --namespace $provider --query 'registrationState' -o tsv)
  echo "$provider: $status"
done


preferred_regions_a=(australiaeast centralus southcentralus eastus2 northeurope southeastasia uksouth westeurope westus westus2)
random_region=$(printf "%s\n" "${preferred_regions_a[@]}" | shuf -n 1)
echo "Creating resource group $resource_group_name in region $random_region"
group_create=$(az group create -l $random_region -n $resource_group_name --query 'properties.provisioningState' -o tsv)
