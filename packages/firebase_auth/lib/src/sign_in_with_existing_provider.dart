part of firebase_auth_ui;

class ExistingProviderOptions {
  const ExistingProviderOptions({
    this.auth,
    this.title = "Fetch Sign In Providers",
    this.providerSelectTitle = "Available Providers",
    this.description = "Please enter your email",
    this.providerSelectDescription = "Please select a provider to login with",
  });

  /// The [FirebaseAuth] instance to authentication with.
  ///
  /// The default [FirebaseAuth] instance will be used if not provided.
  final FirebaseAuth auth;

  /// The title of the dialog.
  ///
  /// Defaults to "Fetch Sign In Providers".
  final String title;

  /// The title of the provider select page.
  final String providerSelectTitle;

  /// The description shown below the [title].
  final String description;

  /// The description shown below the [providerSelectTitle].
  final String providerSelectDescription;
}

class _FetchProviders extends StatefulWidget {
  _FetchProviders({
    @required this.context,
    @required this.options,
    this.gitHubConfig,
    this.twitterConfig,
    this.facebookConfig,
    Key key
  }) : auth = options.auth ?? FirebaseAuth.instance, super(key: key);

  final BuildContext context;
  final ExistingProviderOptions options;
  final FirebaseAuth auth;
  final GitHubConfig gitHubConfig;
  final TwitterConfig twitterConfig;
  final FacebookConfig facebookConfig;

  @override
  State<StatefulWidget> createState() {
    return _FetchProvidersState();
  }
}

class _FetchProvidersState extends State<_FetchProviders> {
  String _email;
  bool _fetching = false;
  bool _selectProvider = false;
  List<String> _providers = [];

  Widget get title {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Center(
        child: Text( _selectProvider ? widget.options.providerSelectTitle : widget.options.title,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget get description {
    return Center(
      child: Text( _selectProvider ? widget.options.providerSelectDescription : widget.options.description,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.5
          )
      ),
    );
  }

  Widget get emailInput {
    return Container(
      child: TextField(
          onChanged: (value) => {
            setState(() {
              _email = value;
            })
          }),
    );
  }

  Widget get providerList {
    return Container(
        padding: EdgeInsets.only(top: 10),
        child: Center(
          child: Column(
            children: <Widget>[
              for(var item in _providers)
                ProviderButton(item: item)
            ],
          ),
        )
    );
  }

  Widget get footer {
    return Container(
      margin: EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FlatButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.black))),
          FlatButton(
              onPressed: () => fetchUsersProviders(),
              child: Text("Fetch", style: TextStyle(fontSize: 16, color: Colors.black)))
        ],
      ),
    );
  }

  void setFetching(bool value) {
    setState(() {
      _fetching = value;
    });
  }

  void setProviders(List<String> providers) {
    setState(() {
      _providers = providers;
    });
  }

  void setSelectProvider(bool value) {
    setState(() {
      _selectProvider = value;
    });
  }

  Future<void> fetchUsersProviders() async {
    try {
      setFetching(true);
      final List<String> providers = await widget.auth.fetchSignInMethodsForEmail(_email);
      setProviders(providers);
      setSelectProvider(true);
    } catch (e) {
      print(e);
    } finally {
      setFetching(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
            width: 500,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize:  MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  description,
                  if(!_selectProvider) emailInput,
                  if(_selectProvider) providerList,
                  footer
                ],
              ),
            )
        )
    );
  }
}

class ProviderButton extends StatefulWidget {
  ProviderButton({
    Key key,
    this.item
  }) : super(key:key);

  final String item;

  @override
  _ProviderButtonState createState() => _ProviderButtonState();
}

class _ProviderButtonState extends State<ProviderButton> {
  String _providerName;

  void initState() {
    switch(widget.item) {
      case 'password':
        break;
      case 'phone':
        break;
      case 'facebook.com':
        setState(() =>  _providerName = "Facebook");
        break;
      case 'twitter.com':
        setState(() =>  _providerName = "Twitter");
        break;
      case 'github.com':
        setState(() =>  _providerName = "GitHub");
        break;
      case 'apple.com':
        setState(() =>  _providerName = "Apple");
        break;
      case 'yahoo.com':
        setState(() =>  _providerName = "Yahoo");
        break;
      case 'hotmail.com':
        setState(() =>  _providerName = "Hotmail");
        break;
      case 'google.com':
        setState(() =>  _providerName = "Google");
        break;
      default:
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text(_providerName),
      onPressed: () {},
    );
  }
}

Future<UserCredential> signInWithExistingProvider(BuildContext context,
    [
      GitHubConfig gitHubConfig = const GitHubConfig(),
      TwitterConfig twitterConfig = const TwitterConfig(),
      FacebookConfig facebookConfig = const FacebookConfig(),
      ExistingProviderOptions options = const ExistingProviderOptions()
    ]
    ){

  return showDialog<UserCredential>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          insetPadding: EdgeInsets.all(16),
          child: _FetchProviders(
            context: context,
            options: options,
            gitHubConfig: gitHubConfig,
            twitterConfig: twitterConfig,
            facebookConfig: facebookConfig,
          ),
        );
      }
  );
}