# DAO Server

Within the governance project, this humble Ruby on Rails server handles
the centralized aspects of the site such as:

- Authorization and authentication
- Proposal comments
- Proposal and comment likes
- KYC
- Transaction history

Along with [info-server](https://github.com/DigixGlobal/info-server
"info-server"), they provide the data for the frontend. When running as
a whole, this must run before
[info-server](https://github.com/DigixGlobal/info-server "info-server")` 
since that will broadcast changes that this server must sync.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

This is a standard [Ruby on Rails](https://rubyonrails.org/ "Ruby on
Rails") API only server with a [MySQL](https://www.mysql.com/ "MySQL")
database.

The databases `dao_dev` and `dao_test` are used for development and test
respectively. Both have a user called `dao_user` with a password
`digixtest`. To create them, run this snippet within your `mysql`
client as `root`:

```sql
create database dao_dev;
create database dao_test;
create user 'dao_user'@'localhost' identified by 'digixtest';
grant all privileges on dao_dev.* to 'dao_user'@'localhost';
grant all privileges on dao_test.* to 'dao_user'@'localhost';
```

Also, this uses `ruby` `2.6.0`. Use [rvm](https://rvm.io/rvm/install
"rvm") or [asdf](https://github.com/asdf-vm/asdf "asdf") for version
management.

### Installing

Since this is a standard Rails server, we can get started by running
this snippet:

```bash
bundle
bin/rake db:create db:migrate db:seed
```

To start the server, run the default rails serve command:

```bash
bin/rails serve
```

Visit the [landing page](http://localhost:3005/apipie "landing page") to
check if the server works. Now if you want to read more about the API,
you can checkout the following:

- [Apipie Documentation](http://localhost:3005/apipie "apipie
  Documentation")
- [GraphQL Endpoint](http://localhost:3005/api "GraphQL Endpoint")
  -  [GraphiQL Playground](http://localhost:3005/graphiql "GraphiQL Playground")

## Running the tests

We use the [default Rails testing](https://guides.rubyonrails.org/testing.html "default Rails
testing") framework, to run the test:

```bash
bin/rake test
```

It goes without saying that all test should pass.

## Contributing

Consult [CONTRIBUTING.md](./CONTRIBUTING.md "CONTRIBUTING.md") for the
process for submitting pull requests to us.

## License

Copyright DIGIXGLOBAL PRIVATE LIMITED

The code in this repository is licensed under the [BSD-3 Clause](https://opensource.org/licenses/BSD-3-Clause)
BSD-3-clause, 2017
