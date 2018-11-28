### SETUP INSTRUCTIONS
Please refer [HERE](https://gist.github.com/roynalnaruto/52f2be795f256ed7b0f156666108f8fc). The DAO-server runs together with [DigixDAO contracts](https://github.com/DigixGlobal/dao-contracts/tree/dev-info-server) and [Info-server](https://github.com/DigixGlobal/info-server/tree/dev)

### Proposals
[link](PROPOSALS.md)

### Endpoints:
* `/get_challenge?address=<address>`(**GET**): To get an authentication token, first get a challenge which you must prove

``` json
{
  "result": {
    "id": 2,
    "challenge": "239",
    "proven": false,
    "user_id": 1,
    "created_at": "2018-11-28T14:26:39.000+08:00",
    "updated_at": "2018-11-28T14:26:39.000+08:00"
  }
}
```
* `/prove?address=<address>&challenge_id=<challenge_id>&message=<message>&signature=<signature>`(**POST**):
    Using your ethereum account, sign the `challenge` with your signature to get the tokens

``` json
{
  "result": {
    "access-token": "ld7LvGgwNfPWYWb8FjojHQ",
    "token-type": "Bearer",
    "client": "7vZsAGdmbrD8aPMQRiwZjw",
    "expiry": "1544596721",
    "uid": "96949"
  }
}
```

These info should be put into the headers for subsequent APIs to Dao Server. As an example:

``` shell
curl -i -H UID\:\ 96949 -H CLIENT\:\ 7vZsAGdmbrD8aPMQRiwZjw -H ACCESS-TOKEN\:\ ld7LvGgwNfPWYWb8FjojHQ -XGET http\://127.0.0.1\:3005/user/details
```

* `/user/details`(**GET**): [authenticated] Get current user details. Use this to test if token authentication works

``` json
{
  "result": {
    "id": 1,
    "provider": "address",
    "uid": "96949",
    "address": "0x22e8422744054e07f15a4d634747e5bed53b043d",
    "created_at": "2018-11-28T14:25:12.000+08:00",
    "updated_at": "2018-11-28T14:38:41.000+08:00"
  }
}
```

* `/transactions/new?txhash=<>&title=<>`(**POST**): [authenticated] Notify the server that a transaction is executed

``` json
{
  "result": {
    "id": 3,
    "title": "Lock DGD",
    "txhash": "0x510c47f843bdcc21891b10def3f12a575b2b2e73889228f0ac75a45e22eab5cd",
    "status": "pending",
    "blockNumber": null,
    "user_id": 1,
    "created_at": "2018-11-28T15:07:50.000+08:00",
    "updated_at": "2018-11-28T15:07:50.000+08:00"
  }
}
```

* `/transactions/list`(**POST**): [authenticated] Get all transaction details of the current user

```json
{
  "result": [
    {
      "id": 1,
      "title": "Lock DGD",
      "txhash": "0x500c47f843bdcc21891b10def3f12a575b2b2e73889228f0ac75a45e22eab5cd",
      "status": "pending",
      "blockNumber": null,
      "user_id": 1,
      "created_at": "2018-11-28T14:47:35.000+08:00",
      "updated_at": "2018-11-28T14:47:35.000+08:00"
    }
  ]
}
```

* `/transactions/status?txhash=<txhash>`(**POST**): [authenticated] Get a specific transaction detail given an hash

``` json
{
  "result": {
    "id": 4,
    "title": "Lock DGD",
    "txhash": "0x520c47f843bdcc21891b10def3f12a575b2b2e73889228f0ac75a45e22eab5cd",
    "status": "pending",
    "blockNumber": null,
    "user_id": 1,
    "created_at": "2018-11-28T15:09:39.000+08:00",
    "updated_at": "2018-11-28T15:09:39.000+08:00"
  }
}
```

# Setup
* Install mysql2, set the password for root user to be `digixtest` https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-16-04
* Add these lines to `/etc/mysql/my.cnf`:
```
[mysqld]
socket          = /tmp/mysql.sock
```
* Install rvm, following instructions at https://rvm.io/rvm/install
* `bash --login`
* `gem install bundler`
* `bundle install`
* `rails db:create`
* `rails db:migrate`
* `rails db:seed`
* `rails server`
