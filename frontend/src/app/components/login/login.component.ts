import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, AbstractControl } from '@angular/forms';
import { AppConfig } from '../../../conf/app.config';
import { AuthService } from '../auth/auth.service';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  enable_sign_up: boolean = false;
  enable_user_management: boolean = false;
  public casLogin: boolean;

  identifiant: FormGroup;
  password: FormGroup;
  form: FormGroup;
  login_or_pass_recovery: boolean = false;

  constructor(
    private _authService: AuthService,
    private fb: FormBuilder,
    private _toasterService: ToastrService
  ) {
    this.casLogin = AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION;
    this.enable_sign_up = AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false;
    this.enable_user_management =
      AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false;
  }

  ngOnInit() {
    if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      // if token not here here, redirection to CAS login page
      const url_redirection_cas = `${AppConfig.CAS_PUBLIC.CAS_URL_LOGIN}?service=${
        AppConfig.API_ENDPOINT
      }/gn_auth/login_cas`;
      document.location.href = url_redirection_cas;
    }
  }

  register(user) {
    this._authService.signinUser(user);
  }

  loginOrPwdRecovery(data) {
    this._authService.loginOrPwdRecovery(data).subscribe(
      res => {
        this._toasterService.info(res.msg, '', {
          positionClass: 'toast-top-center',
          tapToDismiss: true,
          timeOut: 10000
        });
      },
      error => {
        this._toasterService.error(error.error.msg, '', {
          positionClass: 'toast-top-center',
          tapToDismiss: true,
          timeOut: 5000
        });
      }
    );
  }
}
