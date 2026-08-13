import { TokenModel } from '../model/TokenModel';

export class OtpUriBuilder {
  static buildUri(token: TokenModel): string {
    const type: string = token.type === 'HOTP' ? 'hotp' : 'totp';
    const label: string = encodeURIComponent(token.issuer + ':' + token.account);

    let uri: string = 'otpauth://' + type + '/' + label + '?secret=' + token.secret;
    uri = uri + '&issuer=' + encodeURIComponent(token.issuer);

    const algorithm: string = OtpUriBuilder.toUriAlgorithm(token.algorithm);
    if (algorithm !== 'SHA1') {
      uri = uri + '&algorithm=' + algorithm;
    }

    if (token.digits !== 6) {
      uri = uri + '&digits=' + token.digits.toString();
    }

    if (type === 'hotp') {
      uri = uri + '&counter=' + token.counter.toString();
    } else if (token.period !== 30) {
      uri = uri + '&period=' + token.period.toString();
    }

    return uri;
  }

  private static toUriAlgorithm(algorithm: string): string {
    if (algorithm === 'SHA-256') {
      return 'SHA256';
    }
    if (algorithm === 'SHA-512') {
      return 'SHA512';
    }
    return 'SHA1';
  }
}
