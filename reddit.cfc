component extends="oauth2" accessors="true" {

	property name="client_id" type="string";
	property name="client_secret" type="string";
	property name="authEndpoint" type="string";
	property name="accessTokenEndpoint" type="string";
	property name="redirect_uri" type="string";
	
	/**
	* I return an initialized reddit object instance.
	* @client_id The client ID for your application.
	* @client_secret The client secret for your application.
	* @authEndpoint The URL endpoint that handles the authorisation.
	* @accessTokenEndpoint The URL endpoint that handles retrieving the access token.
	* @redirect_uri The URL to redirect the user back to following authentication.
	**/
	public reddit function init(
		required string client_id, 
		required string client_secret, 
		required string authEndpoint = 'https://www.reddit.com/api/v1/authorize', 
		required string accessTokenEndpoint = 'https://www.reddit.com/api/v1/access_token',
		required string redirect_uri
	)
	{
		super.init(
			client_id           = arguments.client_id, 
			client_secret       = arguments.client_secret, 
			authEndpoint        = arguments.authEndpoint, 
			accessTokenEndpoint = arguments.accessTokenEndpoint, 
			redirect_uri        = arguments.redirect_uri
		);
		return this;
	}

	/**
	* I return the URL as a string which we use to redirect the user for authentication.
	* @scope A required array of values to pass through for scope access. Available scopes: identity, edit, flair, history, modconfig, modflair, modlog, modposts, modwiki, mysubreddits, privatemessages, read, report, save, submit, subscribe, vote, wikiedit, wikiread.
	* @state A unique string value of your choice that is hard to guess. Used to prevent CSRF attacks.
	* @duration Either 'temporary' or 'permanent'. Indicates whether or not your app needs a permanent token. Choose 'temporary' for one-time requests; choose 'permanent' for ongoing tasks. Defaults to 'temporary'.
	* @compact Boolean value. If true, uses the compact authorization page that's friendlier to small screens. Defaults to false.
	**/
	public string function buildRedirectToAuthURL(
		required array scope,
		required string state,
		string duration = 'temporary',
		boolean compact = false
	){
		var sParams = {
			'response_type' = 'code',
			'scope'         = arrayToList( arguments.scope, ' ' ),
			'state'         = arguments.state,
			'duration'      = arguments.duration
		};
		
		// Use compact endpoint if requested
		if( arguments.compact ){
			var compactEndpoint = replace( getAuthEndpoint(), '/api/v1/authorize', '/api/v1/authorize.compact' );
			var objAuthBuilder = new utils.authStringBuilder(
				authEndpoint = compactEndpoint,
				client_id = getClient_id(),
				redirect_uri = getRedirect_uri()
			);
			return objAuthBuilder.withParams( sParams ).get();
		}
		
		return super.buildRedirectToAuthURL( sParams );
	}

	/**
	* I make the HTTP request to obtain the access token.
	* @code The code returned from the authentication request.
	**/
	public struct function makeAccessTokenRequest(
		required string code
	){
		var aFormFields = [];
		var aHeaders = [];
		
		// Reddit requires HTTP Basic Auth with client_id as username and client_secret as password
		var credentials = toBase64( getClient_id() & ':' & getClient_secret() );
		arrayAppend( aHeaders, {
			'name': 'Authorization',
			'value': 'Basic ' & credentials
		} );
		
		return super.makeAccessTokenRequest(
			code       = arguments.code,
			formfields = aFormFields,
			headers    = aHeaders
		);
	}

	/**
	* I make the HTTP request to refresh the access token.
	* @refresh_token The refresh_token returned from the accessTokenRequest request.
	**/
	public struct function refreshAccessTokenRequest(
		required string refresh_token
	){
		var aFormFields = [];
		var aHeaders = [];
		
		// Reddit requires HTTP Basic Auth for refresh token requests
		var credentials = toBase64( getClient_id() & ':' & getClient_secret() );
		arrayAppend( aHeaders, {
			'name': 'Authorization',
			'value': 'Basic ' & credentials
		} );
		
		return super.refreshAccessTokenRequest(
			refresh_token = arguments.refresh_token,
			formfields    = aFormFields,
			headers       = aHeaders
		);
	}

	/**
	* I make the HTTP request to revoke the access token.
	* @token The access token or refresh token to revoke.
	* @token_type_hint Optional hint about the token type ('access_token' or 'refresh_token'). Defaults to 'access_token'.
	**/
	public struct function revokeToken(
		required string token,
		string token_type_hint = 'access_token'
	){
		var stuResponse = {};
		var httpService = new http();
		httpService.setMethod( "post" ); 
		httpService.setCharset( "utf-8" );
		httpService.setUrl( 'https://www.reddit.com/api/v1/revoke_token' );
		
		// Reddit requires HTTP Basic Auth for token revocation
		var credentials = toBase64( getClient_id() & ':' & getClient_secret() );
		httpService.addParam( type="header", name="Authorization", value="Basic " & credentials );
		httpService.addParam( type="header", name="Content-Type", value="application/x-www-form-urlencoded" );
		
		httpService.addParam( type="formfield", name="token", value=arguments.token );
		httpService.addParam( type="formfield", name="token_type_hint", value=arguments.token_type_hint );
		
		var result = httpService.send().getPrefix();
		if( '204' == result.ResponseHeader[ 'Status_Code' ] ) {
			stuResponse.success = true;
			stuResponse.content = 'Token revoked successfully';
		} else {
			stuResponse.success = false;
			stuResponse.content = result.Statuscode;
		}
		return stuResponse;
	}

}
