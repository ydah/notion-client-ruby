# OAuth

```ruby
oauth = Notion::OAuth::Client.new(client_id:, client_secret:, redirect_uri:)
redirect_to oauth.authorize_url(state: session[:oauth_state])
token = oauth.exchange(code: params[:code])
```

Validate `state` in the callback before exchanging the code. Store access and refresh tokens encrypted at rest.
