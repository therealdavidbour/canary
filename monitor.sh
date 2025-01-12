#!/bin/bash

# ##################################################
# Sends traffic to the canary and calculates
# the distribution of traffic. The percentages
# may not equal 100 because of integer division
# ###################################################

TOTAL=1000  # Number of requests to make
counter=0
blue=0
green=0

while [ $counter -lt $TOTAL ]; do
  response=$(curl -s http://canary.localhost)
  
  if [[ $response == *"Blue Deployment"* ]]; then
    ((blue++))
  elif [[ $response == *"Green Deployment"* ]]; then
    ((green++))
  fi
  
  ((counter++))
  
  # Print progress
  echo -ne "Blue: $blue ($(( blue * 100 / counter ))%), Green: $green ($(( green * 100 / counter ))%), Total: $counter\r"
  
  sleep 0.1
done

echo -e "\nFinal split:"
echo "Blue: $blue ($(( blue * 100 / TOTAL ))%)"
echo "Green: $green ($(( green * 100 / TOTAL ))%)"
