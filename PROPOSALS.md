## Proposals
* A `proposal` will have at least one `thread`, which contains multiple `comment`
* When a `proposal` is created, a default `thread` is created, which is of type IDEA_THREAD
* A `proposal` is created when `info-server` sends a POST request to `/proposals/create` with `proposer`, `proposalId` as parameters. If no proposal with the same `proposalId` has been created, create the proposal.
* `/proposals/details/:proposalId` will return the details of the proposal:
  * `proposer`
  * `proposalId`
  * array of threads, including its comments

## Threads
* Has a type (IDEA_THREAD=1, DRAFT_THREAD=2, ...)
* Has multiple comments
