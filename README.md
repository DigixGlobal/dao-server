### SETUP INSTRUCTIONS
Please refer [HERE](https://gist.github.com/roynalnaruto/52f2be795f256ed7b0f156666108f8fc). The DAO-server runs together with [DigixDAO contracts](https://github.com/DigixGlobal/dao-contracts/tree/dev-info-server) and [Info-server](https://github.com/DigixGlobal/info-server/tree/dev)

# Endpoints:
* `/get_challenge?address=<address>`: Get a challenge for logging into Dao Server
```
{
  "challenge": {
    "id": 4,
    "challenge": "322",
    "user_id": 1,
    "created_at": "2018-10-24T14:44:15.000+08:00",
    "updated_at": "2018-10-24T14:44:15.000+08:00"
  }
}
```

* `/prove?address=<address>&challenge_id=2&message=<message>&signature=<signature>`: Prove the address and login, getting back the access tokens
```
{
    "access-token": "aXi_r1LkjihLH9UIZpVKVw",
    "token-type": "Bearer",
    "client": "5JVvXO45a65YyS8VsNb3_w",
    "expiry": "1541573249",
    "uid": "12"
}
```
These info should be put into the headers for subsequent APIs to Dao Server

* `/user/details`: [authenticated] get a user details after login, to test if token authentication works
```
{
    "id": 1,
    "provider": "address",
    "uid": "12",
    "address": "0x6d07b3f29a305294bde6dc4976d923cc9f5ee4de",
    "created_at": "2018-10-24T10:27:45.000+08:00",
    "updated_at": "2018-10-24T15:07:33.000+08:00"
}
```

* `/transactions/new?txhash=<>&title=<>`: [authenticated] tell the dao server that we have just executed a tnx
```
{
    "success": true,
    "tx": {
        "id": 1,
        "title": "123123123",
        "txhash": "0x0123",
        "user_id": 1,
        "created_at": "2018-11-01T11:56:53.000+08:00",
        "updated_at": "2018-11-01T11:56:53.000+08:00"
    }
}
```

* `/transactions/list`: [authenticated] get the status of all transactions of current user
```
{
    "transactions": [
        {
            "id": 1,
            "title": "123123123",
            "txhash": "0x0123",
            "status": "pending",
            "user_id": 1,
            "created_at": "2018-11-01T12:00:02.000+08:00",
            "updated_at": "2018-11-01T12:00:02.000+08:00"
        }
    ]
}
```

* `/transactions/status?txhash=<>`: get status of a particular tnx
```
{
    "id": 1,
    "title": "123123123",
    "txhash": "0x0123",
    "status": "pending",
    "user_id": 1,
    "created_at": "2018-11-01T12:00:02.000+08:00",
    "updated_at": "2018-11-01T12:00:02.000+08:00"
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
