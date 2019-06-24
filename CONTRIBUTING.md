# Contributing to Dao Server

We only accept pull request that is assigned an accepted issue. By
participating in this project, you agree to abide by the [code of
conduct](./CODE_OF_CONDUCT.md "code of conduct").

## Submitting a Pull Request
1. Fork this repo.
2. Create a feature branch based of `develop` branch
3. Implement your feature or bug fix.
4. Add, commit, and push your changes.
5. Submit a pull request

### Considerations

- Add tests to cover the new feature to be accepted and make sure all
  test pass.
- If needed, update documentation or behaviors.
- If possible, avoid installing dependencies and if so use an exact
  version `x.y.z` instead of using semantic versioning.
- As much as possible, squash commits before filing a PR.
- Code should be formatted by [rubocop](https://github.com/rubocop-hq/rubocop "Rubocop")

# Development

## Dependency

Aside from setting up this server, remember to start this server before
[info-server](https://github.com/DigixGlobal/info-server "info-server")
and all its dependencies since itit starts syncing from the blockchain
and then making API calls to update this server.

## Models/Features
Majority of the business logic is written in the `/app/models`. So if
you need to explore, its good to start there.

### Authentication
The authentication used by `governance-ui` comes from this server.
However, users aren't created by this server instead synced from
`info-server` when it starts up. Although using standard JWT,
authentication is based on message signing instead of passwords. For the
`User` model, it is managing the profile features such as changing email
and username.

### Comments
The `Comment` model is primarily responsible for posting, liking,
banning and deleting comments from proposals.

### Proposals
Proposals are primarily created by the `info-server` and broadcasted for
this server to hold its key (`proposal.proposal_id`). So the `Proposal`
model is simply responsible for managing its likes.

### Transactions
User transactions status are recorded which is again synced from
`info-server` and display in the transaction history page. The updates
is mainly handled by the `TransactionsController`.

### KYC
This is straightforwardly encapsulated by the `Kyc` model with its submission,
approval and rejection operations.

## Style
Coming from Elixir, the coding style is based on tagged tuples or a raw
form of monads from [dry-rb](https://dry-rb.org/ "dry-rb"). Though not
perfect, the architectural style is based of a `service` so it is
preferable to add module functions instead of class functions to avoid
state.

For the coding style, like with [prettier](prettier "prettier"), we use
`rubocop` as an easy arbiter. As long as it is formatted and have no
warnings or errors, it is pretty much correct. Code reviews should
address the more technical aspect of design and structure.
