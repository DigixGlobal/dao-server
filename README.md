# Endpoints:

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
* `rails db:migrate`
* `rails server`
