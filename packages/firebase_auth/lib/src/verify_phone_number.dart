part of firebase_auth_ui;

/// Used to set the type of verification request on [VerifyPhoneNumberOptions].
enum VerifyPhoneNumberType {
  /// Once verified, the user signed in.
  ///
  /// The user must be logged out otherwise an error will be thrown.
  signIn,

  /// Once verified, the phone number is linked to the currently signed in user.
  ///
  /// The user must be signed in otherwise an error will be thrown.
  link,
}

/// Custom error callback handler.
typedef String VerifyPhoneNumberError(Object exception);

/// Options which can be passed to the [verifyPhoneNumber] method to control
/// the sign-in flow.
///
/// ```dart
/// verifyPhoneNumber(context, VerifyPhoneNumberOptions(
///   title: 'Phone number verification',
/// ));
/// ```
class VerifyPhoneNumberOptions {
  const VerifyPhoneNumberOptions(
      {this.auth,
      this.type = VerifyPhoneNumberType.signIn,
      this.onError,
      this.title = "Verify your phone number",
      this.description =
          "Enter your phone number below. Once validated, a SMS code will be sent to your device. Enter the code in the box below to verify your phone number and sign-in to the application.",
      this.phoneNumberLabel = "Enter your phone number (+44)",
      this.send = "Send SMS Code",
      this.cancel = "Cancel"});

  /// The [FirebaseAuth] instance to authentication with.
  ///
  /// The default [FirebaseAuth] instance will be used if not provided.
  final FirebaseAuth auth;

  /// The type of authentication to carry out once verified.
  final VerifyPhoneNumberType type;

  /// A custom error handler function.
  ///
  /// By default, errors will be strigified and displayed to users. Use this
  /// argument to return your own custom error messages.
  final VerifyPhoneNumberError onError;

  /// The title of the dialog.
  ///
  /// Defaults to "Verify your phone number".
  final String title;

  /// The description shown below the [title].
  final String description;

  /// The label shown for the phone number text field.
  final String phoneNumberLabel;

  /// The text used for the send button.
  final String send;

  /// The text used for the cancel button.
  final String cancel;
}

/// The entry point for triggering the phone number verification UI.
///
/// Resolves with the result of the flow. If the user successfully verifies the
/// phone number, they will be signed in and the [UserCredential] will be returned.
/// Otherwise, `null` will be returned (e.g. if they cancel the flow).
Future<UserCredential> verifyPhoneNumber(BuildContext context,
    [VerifyPhoneNumberOptions options = const VerifyPhoneNumberOptions()]) {
  assert(context != null);

  return showDialog<UserCredential>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          insetPadding: EdgeInsets.all(16),
          child: _VerifyPhoneNumber(
            context: context,
            options: options,
          ),
        );
      });
}

class _VerifyPhoneNumber extends StatefulWidget {
  _VerifyPhoneNumber({
    @required this.context,
    @required this.options,
    Key key,
  })  : auth = options.auth ?? FirebaseAuth.instance,
        super(key: key);

  final BuildContext context;

  final VerifyPhoneNumberOptions options;

  final FirebaseAuth auth;

  @override
  State<StatefulWidget> createState() {
    return _VerifyPhoneNumberState();
  }
}

class _VerifyPhoneNumberState extends State<_VerifyPhoneNumber> {
  String _error;
  String _phoneNumber;
  String _verificationId;
  int _resendToken;
  bool _verifying = false;
  bool _enterSmsCode = false;
  TextEditingController codeInputController = TextEditingController();

  void setVerifying(bool value) {
    setState(() {
      _verifying = value;
    });
  }

  void setEnterSmsCode(bool value) {
    setState(() {
      _error = null;
      _enterSmsCode = value;
    });
  }

  Widget get title {
    return Container(
        margin: EdgeInsets.only(bottom: 24),
        child: Text(
          widget.options.title,
          style: TextStyle(fontSize: 24),
        ));
  }

  Widget get description {
    return Text(widget.options.description,
        style: TextStyle(fontSize: 14, color: Colors.grey));
  }

  Widget get error {
    return Container(
      margin: EdgeInsets.only(top: 12),
      child: Text(_error, style: TextStyle(color: Colors.red)),
    );
  }

  Widget get input {
    return Container(
        margin: EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              onChanged: (value) => _phoneNumber = value,
              decoration: InputDecoration(
                  labelText: widget.options.phoneNumberLabel,
                  prefixIcon: Icon(Icons.phone),
                  suffix: _verifying
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : null),
            ),
          ],
        ));
  }

  Widget get footer {
    return Container(
      margin: EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FlatButton(
            onPressed: () => Navigator.pop(context, null),
            padding: EdgeInsets.all(16),
            child: Text("Cancel", style: TextStyle(fontSize: 16)),
          ),
          if (!_enterSmsCode)
            FlatButton(
              onPressed: () => triggerVerification(),
              padding: EdgeInsets.all(16),
              child: Text(
                widget.options.send,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          if (_enterSmsCode)
            FlatButton(
              onPressed: () => triggerVerification(),
              padding: EdgeInsets.all(16),
              child: Text(
                widget.options.send,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void performAuthAction(PhoneAuthCredential phoneAuthCredential) async {
    UserCredential userCredential;
    Future<UserCredential> action;

    if (widget.options.type == VerifyPhoneNumberType.signIn) {
      assert(widget.auth.currentUser == null);
      action = widget.auth.signInWithCredential(phoneAuthCredential);
    } else {
      assert(widget.auth.currentUser != null);
      action = widget.auth.currentUser.linkWithCredential(phoneAuthCredential);
    }

    try {
      userCredential = await action;
    } on FirebaseException catch (e) {
      if (e.code == 'invalid-verification-code') {
        // TODO show invalid error code
      } else {
        handleError(e);  
      }
    } catch (e) {
      handleError(e);
    }

    Navigator.pop(context, userCredential);
  }

  void handleError(Object e) {
    if (widget.options.onError != null) {
      setState(() {
        _error = widget.options.onError(e);
      });
    } else {
      String message;

      if (e is FirebaseException) {
        message = e.message;
      } else {
        message = e.toString();
      }
      print(message);
      setState(() {
        _error = message;
      });
    }
  }

  void verificationCompleted(PhoneAuthCredential credential) {
    try {
      codeInputController.text = credential.smsCode;
      Timer(Duration(seconds: 1), () {
        performAuthAction(credential);
      });
    } catch (e) {
      handleError(e);
    }
  }

  void codeSent(String verificationId, int resendToken) {
    _resendToken = resendToken;
    _verificationId = verificationId;
    setEnterSmsCode(true);
  }

  void codeAutoRetrievalTimeout(String verificationId) {
    print('codeAutoRetrievalTimeout');
  }

  void onCodeEntered(String code) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: code);
    performAuthAction(credential);
  }

  Future<void> triggerVerification() async {
    if (_verifying || (_phoneNumber == null || _phoneNumber.isEmpty)) {
      return;
    }

    try {
      setVerifying(true);
      await widget.auth.verifyPhoneNumber(
          phoneNumber: _phoneNumber ?? '',
          verificationCompleted: verificationCompleted,
          verificationFailed: handleError,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    } catch (e) {
      handleError(e);
    } finally {
      setVerifying(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          width: 500,
          child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  description,
                  if (!_enterSmsCode) input,
                  if (_enterSmsCode) _SMSCodeInput(onCodeEntered),
                  if (_error != null) _Error(_error),
                  footer,
                ],
              )),
        ));
  }
}

class _Error extends StatelessWidget {
  const _Error(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      child: Text(text, style: TextStyle(color: Colors.red)),
    );
  }
}

class _SMSCodeInput extends StatelessWidget {
  _SMSCodeInput(this.onEntered);

  final void Function(String code) onEntered;

  final int total = 6;

  final List<String> codeArray = [];

  final List<FocusNode> focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  Widget input(BuildContext context, int index) {
    return Expanded(
        child: Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        child: TextField(
          focusNode: focusNodes[index],
          onChanged: (value) {
            codeArray.insert(index, value);
            if (index + 1 == focusNodes.length) {
              onEntered(codeArray.join());
            } else {
              FocusScope.of(context).requestFocus(focusNodes[index + 1]);
            }
          },
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontSize: 22,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.only(
              bottom: 8,
            ),
            border: UnderlineInputBorder(),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> inputs = [];

    for (var i = 0; i < total; i++) {
      inputs.add(input(context, i));
    }

    return Container(
      margin: EdgeInsets.only(top: 24),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: inputs),
    );
  }
}
