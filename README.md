# Notifications API Gateway

This is a gateway service which allows project owners to send messages to the
frontend via Sugar.

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

## `POST /notifications`

This lets you send a message to a user, if they are currently online. The
message will be shown once they submit whatever classification they are
currently working on. If they never submit another classification after
you call this API, or if they reload or close their browser, the message will
not be shown.

```json
{
    "type": "notification",
    "project_id": "5733",
    "user_id": "6",
    "message": "All of your contributions really help.”
}
```

## `POST /subject_queues`

This lets you prepend subjects into the user's queue. This queue is only
maintained in the browser, so if the user reloads or closes their browser tab,
the subjects will disappear from their queue.

```json
{
    "type": "subject_queue",
    "project_id": "3434",
    "user_id": "23",
    "subject_ids": ["1", "2"],
    "workflow_id": "21"
}
```