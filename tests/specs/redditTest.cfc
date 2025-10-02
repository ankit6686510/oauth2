component extends='testbox.system.BaseSpec'{
	
	/*********************************** BDD SUITES ***********************************/
	
	function run(){

		describe( 'Reddit Component Suite', function(){
			
			variables.thisProvider = 'reddit';
			variables.sProviderData = {};

			include 'providerData.properties.cfm';

			if( structKeyExists( variables.providerInfo, variables.thisProvider ) ){
				variables.sProviderData = variables.providerInfo[ variables.thisProvider ];
			} else {
				variables.sProviderData = variables.providerInfo[ 'default' ];
			}

			var clientId     = variables.sProviderData[ 'clientId' ];
			var clientSecret = variables.sProviderData[ 'clientSecret' ];
			var redirect_uri = variables.sProviderData[ 'redirect_uri' ];

			var oReddit = new reddit(
				client_id           = clientId,
				client_secret       = clientSecret,
				redirect_uri        = redirect_uri
			);
			
			it( 'should return the correct object', function(){

				expect( oReddit ).toBeInstanceOf( 'reddit' );
				expect( oReddit ).toBeTypeOf( 'component' );

			});

			it( 'should have the correct properties', function() {

				var sMemento = oReddit.getMemento();

				expect( sMemento ).toBeStruct().toHaveLength( 5 );

				expect( sMemento ).toHaveKey( 'client_id' );
				expect( sMemento ).toHaveKey( 'client_secret' );
				expect( sMemento ).toHaveKey( 'authEndpoint' );
				expect( sMemento ).toHaveKey( 'accessTokenEndpoint' );
				expect( sMemento ).toHaveKey( 'redirect_uri' );

				expect( sMemento[ 'client_id' ] ).toBeString().toBe( clientId );
				expect( sMemento[ 'client_secret' ] ).toBeString().toBe( clientSecret );
				expect( sMemento[ 'redirect_uri' ] ).toBeString().toBe( redirect_uri );

			} );

			it( 'should have the correct methods', function() {

				expect( oReddit ).toHaveKey( 'init' );
				expect( oReddit ).toHaveKey( 'buildRedirectToAuthURL' );
				expect( oReddit ).toHaveKey( 'makeAccessTokenRequest' );
				expect( oReddit ).toHaveKey( 'refreshAccessTokenRequest' );
				expect( oReddit ).toHaveKey( 'revokeToken' );
				expect( oReddit ).toHaveKey( 'buildParamString' );
				expect( oReddit ).toHaveKey( 'getMemento' );

			} );

			it( 'should return a string when calling the `buildRedirectToAuthURL` method', function() {

				var strState = createUUID();
				var aScope = [
					'identity',
					'read',
					'mysubreddits'
				];
				var strURL = oReddit.buildRedirectToAuthURL(
					scope = aScope,
					state = strState
				);

				expect( strURL ).toBeString();

				var arrData = listToArray( strURL, '&?' );

				expect( arrData ).toHaveLength( 7 );
				expect( arrData[ 1 ] )
					.toBeString()
					.toBe( oReddit.getAuthEndpoint() );

				var stuParams = {};
				for( var i = 2; i <= arrayLen( arrData ); i++ ){
					structInsert( stuParams, listGetAt( arrData[ i ], 1, '=' ), listGetAt( arrData[ i ], 2, '=' ) );
				}

				expect( stuParams[ 'client_id' ] ).toBeString().toBe( clientId );
				expect( stuParams[ 'redirect_uri' ] ).toBeString().toBe( oReddit.getRedirect_URI() );
				expect( stuParams[ 'state' ] ).toBeString().toBe( strState );
				expect( stuParams[ 'scope' ] ).toBeString().toBe( 'identity read mysubreddits' );
				expect( stuParams[ 'response_type' ] ).toBeString().toBe( 'code' );
				expect( stuParams[ 'duration' ] ).toBeString().toBe( 'temporary' );

			} );

			it( 'should return a string with permanent duration when specified', function() {

				var strState = createUUID();
				var aScope = [
					'identity',
					'read'
				];
				var strURL = oReddit.buildRedirectToAuthURL(
					scope = aScope,
					state = strState,
					duration = 'permanent'
				);

				expect( strURL ).toBeString();

				var arrData = listToArray( strURL, '&?' );
				var stuParams = {};
				for( var i = 2; i <= arrayLen( arrData ); i++ ){
					structInsert( stuParams, listGetAt( arrData[ i ], 1, '=' ), listGetAt( arrData[ i ], 2, '=' ) );
				}

				expect( stuParams[ 'duration' ] ).toBeString().toBe( 'permanent' );

			} );

			it( 'should return a compact endpoint URL when compact is true', function() {

				var strState = createUUID();
				var aScope = [
					'identity'
				];
				var strURL = oReddit.buildRedirectToAuthURL(
					scope = aScope,
					state = strState,
					compact = true
				);

				expect( strURL ).toBeString();
				expect( strURL ).toInclude( 'authorize.compact' );

			} );

			it( 'should have the correct default endpoints', function() {

				expect( oReddit.getAuthEndpoint() )
					.toBeString()
					.toBe( 'https://www.reddit.com/api/v1/authorize' );

				expect( oReddit.getAccessTokenEndpoint() )
					.toBeString()
					.toBe( 'https://www.reddit.com/api/v1/access_token' );

			} );

		} );

	}
	
}
