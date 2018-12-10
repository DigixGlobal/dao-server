source scripts/variables.env

pm2 del info-server:dev

if [[ $SKIP_DAO_CONTRACTS != "true" ]]
then
  cd ../dao-contracts
  $NPM run dao:dev
  node_modules/.bin/truffle exec scripts/send-dummy-tnxs.js > /dev/null &
fi

if [[ $SKIP_DAO_SERVER != "true" ]]
then
  cd ../dao-server
  killall ruby
  export RAILS_ENV=development
  bin/rails db:drop
  bin/rails db:create
  bin/rails db:migrate
  bin/rails db:seed
  bin/rails s > /dev/null &
fi

if [[ $SKIP_INFO_SERVER != "true" ]]
then
  cd ../info-server
  service mongod restart
  $NPM run dev
fi

if [[ $SKIP_UI != "true" ]]
then
  cd ../governance-ui
  $NPM start
fi
