# Fork this repository to your own GitHub organization

Add a Humanitec API token as a [GitHub Secret](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository) called `HUMANITEC_TOKEN`.

You can create a Humanitec API token via [Organization Settings](https://docs.humanitec.com/reference/user-interface/organization-settings) -> API Tokens

# Setup the webhook in Humanitec:

Webhook settings can be found in the "Webhooks" tab in [App Settings](https://docs.humanitec.com/reference/user-interface/app-settings-screen).

- **ID**: `github-automation`
- **URL**: `https://api.github.com/repos/chrishumanitec/actions-automation/actions/workflows/autodeploy.yaml/dispatches`
- **Headers**: `Accept: application/vnd.github.v3+json` and `Authorization: token {GITHUB_PAC}` (replace `{GITHUB_PAC}` with your [GitHub Personal Access Token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token))
- **Payload**:

````
{
  "ref": "main",
  "inputs": {
    "org_id": "${org_id}",
    "app_id": "${app_id}",
    "env_id": "${env_id}",
    "deploy_id": "${deploy_id}",
    "delta_id": "${delta_id}",
    "set_id": "${set_id}",
    "status": "${status}",
    "env_filter": "development",
    "clone_to_env_id": "staging"
  }
}
````
The `env_filter` property limits the environment this automation will be applied to.
You can change the `clone_to_env` to the ID of the environment you want to clone the successful deployment to.

- **Triggers**: Deployment => Finished

# Testing

There is a test.sh file which will perform the same action as the webhook without having to trigger a deployment.
