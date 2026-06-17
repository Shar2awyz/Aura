sealed class Signupstate {}
class SignUpInitial extends Signupstate{}
class SignUpLoading extends Signupstate{}
class SignUpSuccess extends Signupstate{}
class SignUpFailure extends Signupstate{
  String error;
  SignUpFailure( this.error);

}
