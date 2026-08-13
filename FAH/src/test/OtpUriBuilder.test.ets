import { describe, it, expect } from '@ohos/hypium';
import { TokenModel } from '../main/ets/model/TokenModel';
import { OtpUriBuilder } from '../main/ets/engine/OtpUriBuilder';
import { OtpUriParser } from '../main/ets/engine/OtpUriParser';

function buildToken(issuer: string, account: string, secret: string, type: string,
  algorithm: string, digits: number, period: number, counter: number): TokenModel {
  const t: TokenModel = TokenModel.create(issuer, account, secret);
  t.type = type;
  t.algorithm = algorithm;
  t.digits = digits;
  t.period = period;
  t.counter = counter;
  return t;
}

export default function otpUriBuilderTest() {
  describe('OtpUriBuilderTest', () => {
    it('totpDefaultOmitsDefaults', 0, () => {
      const token: TokenModel = buildToken('Google', 'user@example.com', 'JBSWY3DPEHPK3PXP', 'TOTP', 'SHA-1', 6, 30, 0);
      const uri: string = OtpUriBuilder.buildUri(token);
      expect(uri.indexOf('otpauth://totp/') === 0).assertTrue();
      expect(uri.indexOf('secret=JBSWY3DPEHPK3PXP') !== -1).assertTrue();
      expect(uri.indexOf('algorithm=') === -1).assertTrue();
      expect(uri.indexOf('digits=') === -1).assertTrue();
      expect(uri.indexOf('period=') === -1).assertTrue();
    });

    it('totpNonDefaultParams', 0, () => {
      const token: TokenModel = buildToken('Google', 'user@example.com', 'JBSWY3DPEHPK3PXP', 'TOTP', 'SHA-256', 8, 45, 0);
      const uri: string = OtpUriBuilder.buildUri(token);
      expect(uri.indexOf('algorithm=SHA256') !== -1).assertTrue();
      expect(uri.indexOf('algorithm=SHA-256') === -1).assertTrue();
      expect(uri.indexOf('digits=8') !== -1).assertTrue();
      expect(uri.indexOf('period=45') !== -1).assertTrue();
    });

    it('hotpIncludesCounter', 0, () => {
      const token: TokenModel = buildToken('GitHub', 'octocat', 'JBSWY3DPEHPK3PXP', 'HOTP', 'SHA-1', 6, 30, 42);
      const uri: string = OtpUriBuilder.buildUri(token);
      expect(uri.indexOf('otpauth://hotp/') === 0).assertTrue();
      expect(uri.indexOf('counter=42') !== -1).assertTrue();
    });

    it('specialCharsEncoded', 0, () => {
      const token: TokenModel = buildToken('My Issuer: Sub', 'user name', 'JBSWY3DPEHPK3PXP', 'TOTP', 'SHA-1', 6, 30, 0);
      const uri: string = OtpUriBuilder.buildUri(token);
      expect(uri.indexOf('otpauth://totp/') === 0).assertTrue();
      expect(uri.indexOf(' ') === -1).assertTrue();
      expect(uri.indexOf('issuer=') !== -1).assertTrue();
    });

    it('roundTrip', 0, () => {
      const token: TokenModel = buildToken('Google', 'user@example.com', 'JBSWY3DPEHPK3PXP', 'TOTP', 'SHA-1', 6, 30, 0);
      const uri: string = OtpUriBuilder.buildUri(token);
      const parsed: TokenModel | null = OtpUriParser.parse(uri);
      expect(parsed !== null).assertTrue();
      if (parsed !== null) {
        expect(parsed.issuer).assertEqual(token.issuer);
        expect(parsed.account).assertEqual(token.account);
        expect(parsed.secret).assertEqual(token.secret);
        expect(parsed.type).assertEqual(token.type);
        expect(parsed.algorithm).assertEqual(token.algorithm);
        expect(parsed.digits).assertEqual(token.digits);
        expect(parsed.period).assertEqual(token.period);
        expect(parsed.counter).assertEqual(token.counter);
      }
    });
  });
}
