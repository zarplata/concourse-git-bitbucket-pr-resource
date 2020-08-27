# concourse-git-bitbucket-pr-resource

Tracks changes for all *git* branches for pull requests.

**This resource is meant to be used with [`version:
every`](https://concourse.ci/get-step.html#get-version).**

Inspirited by [git-branch-heads-resourse](https://github.com/vito/git-branch-heads-resource)

## Installation

Add the following `resource_types` entry to your pipeline:

```yaml
---
resource_types:
- name: git-bitbucket-pr
  type: docker-image
  source:
    repository: zarplata/concourse-git-bitbucket-pr-resource
```

## Source Configuration

* `base_url`: *Required*. base URL of the bitbucket server, without a trailing slash. 
For example: `http://bitbucket.local`
* `project`: *Required*. project for tracking
* `repository`: *Required*. repository for tracking
* `limit`: *Optional*. limit of tracked pull requests `default: 100`.
* `git`: *Required*. configuration is based on the [Git
resource](https://github.com/concourse/git-resource). The `branch` configuration
from the original resource is ignored.
* `bitbucket_type`: *Optional*. `cloud` for BitBucket Cloud or `server` for a self-hosted BitBucket Server. `default: server`
* `dir`: *Deprecated*. set to name of the resource if resource name is different than repository name. Is deprecated in favor to `params.repository` in `out`.
* `branch`: *Optional*. if given, only pull requests against this branch will be checked
* `paths`: *Optional*. if specified (as a list of glob patterns), only changes to the specified files will yield new versions from check
* `changes_limit`: *Optional*. the maximum number of changed `paths` loaded for each pull-request. `default: 100`. It works only with the `paths` parameter.
* `direction`: *Optional*. the direction relative to the specified repository, either `incoming` (destination, e.g. to master) or `outgoing` (source, e.g. from feature).
Either:
* `username`: *Required*. username of the user which have access to repository.
* `password`: *Required*. password of that user
Or:
* `oauth_id`: *Required*. Oauth id of an OAuth consumer configured as private and with permission to write to PRs.
* `oauth_secret`: *Required*. Oauth secret of the same consumer.


### Example

``` yaml
resources:
- name: my-repo-with-pull-requests
  type: git-bitbucket-pr
  source:
    base_url: http://bitbucket.local
    username: some-username
    password: some-password
    project: zarplata
    repository: concourse-git-bitbucket-pr-resource
    git:
      uri: https://github.com/zarplata/concourse-git-bitbucket-pr-resource
      private_key: {{git-repo-key}}

jobs:
  - name: my build
    plan:    
      - get: my-repo-with-pull-requests
        trigger: true
        version: every
      - task: unit test
          ...
          inputs:          
            - name: my-repo-with-pull-requests
          run:
          ...
        on_failure:
          put: my-repo-with-pull-requests
          params:
            action: change-build-status
            state: FAILED
            name: "unit test"
            url: "http://acme.com/teams/$BUILD_TEAM_NAME/pipelines/$BUILD_PIPELINE_NAME/jobs/$BUILD_JOB_NAME/builds/$BUILD_NAME"
        on_success:
          put: my-repo-with-pull-requests
          params:
            action: change-build-status
            state: SUCCESSFUL
            name: "unit test"
            url: "http://acme.com/teams/$BUILD_TEAM_NAME/pipelines/$BUILD_PIPELINE_NAME/jobs/$BUILD_JOB_NAME/builds/$BUILD_NAME"
```

## Behavior

### `check`: Check for changes to all pull requests.

The current open pull requests fetched from Bitbucket server for given 
project and repository. Update time are compared to the last fetched pull request.

If any pull request are new or updated or removed, a new version is emitted.

### `in`: Fetch the commit that changed the pull request.

This resource delegates entirely to the `in` of the original Git resource, by
passing through `source.git` to `source` of the original `git-resource`, then
specifying `source.branch` as the branch that changed, and `version.ref` as the
commit on the branch.

#### Parameters

All `params`, except the ones listed below, will be passed through to `params` of the original `git-resource`.

* `skip_download`: `Optional`. Skip `git pull`. Artifacts based on the git will not be present.
* `fetch_upstream`: `Optional`. Also fetch the pull requests' upstream ref. This will overwrite the `fetch` param.

### `out`: Update the PR.
 
Behavior depends on the value of parameter `action`, where is the values are:

* `change-build-status`: Change the commit build status.

    * `action`: `Required`. For this behavior should be `change-build-status`.
    * Parameters except the `name` will be respected the [Bitbucket documentation](https://developer.atlassian.com/server/bitbucket/how-tos/updating-build-status-for-commits/).
    * `name`: `Deprecated`. Parameter is deprecated and has been left only for backward compatibility.
    * `repository`: `Optional`. The path of the source repository for changing build status.

* `push`: Push the commit to pull request branch.

    * `action`: `Required`. For this behavior should be `push`.
    * `repository`: `Optional`. The path of the source repository for pushing.

## Troubleshooting

* [Mark PR with "build started" creates a new version of a PR](https://github.com/zarplata/concourse-git-bitbucket-pr-resource/issues/15).

    The Concourse is not available to skipping versions but have the workaround. 
    You should add the _resource with the same settings_ as `pull-request` for changing the build status only.

    ```
    - name: test-pull-requests
      plan:
      - get: pull-request
        trigger: true
        version: every
      - get: node
      - put: pull-request-status
        params:
          action: change-build-status
          state: INPROGRESS
          key: concourse-build
          description: Building on Concourse
    ```
