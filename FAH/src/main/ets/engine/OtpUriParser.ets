import { TokenModel } from '../model/TokenModel';

export class OtpUriParser {
  static parse(uri: string): TokenModel | null {
    if (!uri.startsWith('otpauth://')) {
      return null;
    }

    let pathAndQuery: string = uri.substring(10);

    let queryIndex: number = pathAndQuery.indexOf('?');
    if (queryIndex === -1) {
      return null;
    }

    let path: string = pathAndQuery.substring(0, queryIndex);
    let queryString: string = pathAndQuery.substring(queryIndex + 1);

    let slashIndex: number = path.indexOf('/');
    if (slashIndex === -1) {
      return null;
    }

    let type: string = path.substring(0, slashIndex).toUpperCase();
    if (type !== 'TOTP' && type !== 'HOTP') {
      return null;
    }

    let labelEncoded: string = path.substring(slashIndex + 1);
    let label: string = OtpUriParser.urlDecode(labelEncoded);

    let secret: string | undefined = OtpUriParser.extractParam(queryString, 'secret');
    if (secret === undefined || secret === '') {
      return null;
    }

    let issuer: string = '';
    let account: string = '';

    let colonIndex: number = label.indexOf(':');
    if (colonIndex !== -1) {
      issuer = label.substring(0, colonIndex);
      account = label.substring(colonIndex + 1);
    } else {
      account = label;
    }

    let queryIssuer: string | undefined = OtpUriParser.extractParam(queryString, 'issuer');
    if (queryIssuer !== undefined && queryIssuer !== '') {
      issuer = OtpUriParser.urlDecode(queryIssuer);
    }

    let algorithm: string = 'SHA-1';
    let algParam: string | undefined = OtpUriParser.extractParam(queryString, 'algorithm');
    if (algParam !== undefined) {
      algorithm = algParam.toUpperCase();
    }

    let digits: number = 6;
    let digitsParam: string | undefined = OtpUriParser.extractParam(queryString, 'digits');
    if (digitsParam !== undefined) {
      let parsed: number = parseInt(digitsParam);
      if (!isNaN(parsed)) {
        digits = parsed;
      }
    }

    let period: number = 30;
    let periodParam: string | undefined = OtpUriParser.extractParam(queryString, 'period');
    if (periodParam !== undefined) {
      let parsed: number = parseInt(periodParam);
      if (!isNaN(parsed)) {
        period = parsed;
      }
    }

    let counter: number = 0;
    let counterParam: string | undefined = OtpUriParser.extractParam(queryString, 'counter');
    if (counterParam !== undefined) {
      let parsed: number = parseInt(counterParam);
      if (!isNaN(parsed)) {
        counter = parsed;
      }
    }

    let token: TokenModel = TokenModel.create(issuer, account, secret);
    token.type = type;
    token.algorithm = algorithm;
    token.digits = digits;
    token.period = period;
    token.counter = counter;

    return token;
  }

  private static extractParam(queryString: string, name: string): string | undefined {
    let searchPrefix: string = name + '=';
    let startIndex: number = queryString.indexOf(searchPrefix);
    if (startIndex === -1) {
      return undefined;
    }
    if (startIndex > 0 && queryString.charAt(startIndex - 1) !== '&') {
      return undefined;
    }
    let valueStart: number = startIndex + searchPrefix.length;
    let valueEnd: number = queryString.indexOf('&', valueStart);
    if (valueEnd === -1) {
      valueEnd = queryString.length;
    }
    return queryString.substring(valueStart, valueEnd);
  }

  private static urlDecode(input: string): string {
    let result: string = '';
    let i: number = 0;
    while (i < input.length) {
      let ch: string = input.charAt(i);
      if (ch === '%' && i + 2 < input.length) {
        let hex: string = input.substring(i + 1, i + 3);
        let charCode: number = parseInt(hex, 16);
        if (!isNaN(charCode)) {
          result += String.fromCharCode(charCode);
          i += 3;
          continue;
        }
      }
      if (ch === '+') {
        result += ' ';
      } else {
        result += ch;
      }
      i++;
    }
    return result;
  }
}
