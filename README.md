# Interventions API Gateway

This is a gateway service which allows project owners to send messages to the
frontend via Sugar.

## Operations

This service automatically deploys the `master` branch to https://interventions-gateway-staging.zooniverse.org

The production branch gets deployed to https://interventions-gateway.zooniverse.org

## Usage

All requests need to be authenticated. Authentication is done with an OAuth
bearer token which can be gotten from Panoptes. You will probably want to create
an OAuth application at https://panoptes.zooniverse.org/oauth/applications

This will give you an application ID and secret, and you can use this to
authenticate with Panoptes, which will give you an OAuth bearer token in
return.

Send in the bearer token in the Authorization header like so:

```
Authorization: Bearer <TOKEN>
```

All of the APIs exposed by this gateway service require you to pass in a
project ID.  If the project ID given does not match a project that you are an
owner or collaborator on, you will get an HTTP 403 error status.

This service exposes the following API endpoints:

### `POST /messages`

This lets you send a message to a user, if they are currently online.

A message will be shown to the user once they submit the classification they are currently working on.

A message will not be shown after posting to this message API if the user never submits another classification or they reload / close their browser.

```json
{
    "project_id": "5733",
    "user_id": "6",
    "message": "All of your contributions really help."
}
```

**Please note: the behaviour of how the interventions events are presented to the user is out of the control of this repo.** Please refer to  https://github.com/zooniverse/Panoptes-Front-End/ for specific details on intervention message handling.

### `POST /subject_queues`

This lets you prepend subjects into the user's queue. This queue is only maintained in the browser, so if the user reloads or closes their browser tab, the subjects will disappear from their queue.

```json
{
    "project_id": "3434",
    "user_id": "23",
    "subject_ids": ["1", "2"],
    "workflow_id": "21"
}
```

#### On projects you do not run

To be able to post intervention messages to users on a project, you need to be an owner or have collaborator rights on a project.

Approved third parties can use Zooniverse controlled OAuth credentials to gain access to projects they don't run. Please get in touch via [contact@zooniverse.org](mailto:contact@zooniverse.org) for more information.

Once approved, you can use the credentials in OAuth flows described above to get bearer tokens.

#### On projects you do run

Good news - as a project owner you can already send intervention messages to a project. You can also send messages to any project you have collaborator rights on.

## Development
Install specified ruby version (see Dockerfile)
1. `bundle install`
0. `bundle exec rspec` or `rspec`

To add new features

1. Add specs and make them pass
0. Commit the code with good commit messages
0. Issue a pull request to start a discussion around the changes being included in the codebase

Testing with docker-compose
1. `docker-compose build`
0. `docker-compose up`

Manually running the webserver
1. `bundle exec puma -C docker/puma.rb`
