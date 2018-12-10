source scripts/variables.env

# if [[ $SKIP_UI_COMPONENTS != "true" ]]
# then
#   echo Setting up node modules in governance-ui-components
#   cd ../governance-ui-components
#   rm -rf node_modules
#   rm package-lock.json
#   $NPM i
# fi
#
# if [[ $SKIP_UI != "true" ]]
# then
#   echo Setting up node modules in governance-ui
#   cd ../governance-ui
#   rm -rf node_modules
#   rm package-lock.json
#   $NPM i
# fi

# if [[ $SKIP_INFO_SERVER != "true" ]]
# then
#   echo Setting up node modules in info-server
#   cd ../info-server
#   rm -rf node_modules
#   rm package-lock.json
#   $NPM i
# fi

if [[ $SKIP_DAO_CONTRACTS != "true" ]]
then
  echo Setting up node modules in dao-contracts
  cd ../dao-contracts
  rm -rf node_modules
  rm package-lock.json
  $NPM i
  echo recompiling contracts
  rm -rf build
  cd node_modules/truffle && $NPM i solc@0.4.25 && cd ../..
  node_modules/.bin/truffle compile
fi

# if [[ $SKIP_DAO_SERVER != "true" ]]
# then
#   echo installing gems in dao-server
#   cd ../dao-server
#   bin/bundle install
# fi
