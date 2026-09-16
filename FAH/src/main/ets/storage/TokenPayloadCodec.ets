export interface EncryptedTokensPayload {
  v: number;
  alg: string;
  data: string;
}

export class TokenPayloadCodec {
  static readonly VERSION: number = 2;

  static build(cipherBase64: string): string {
    const payload: EncryptedTokensPayload = {
      v: TokenPayloadCodec.VERSION, alg: 'AES-GCM', data: cipherBase64
    };
    return JSON.stringify(payload);
  }

  static extractCipher(raw: string): string {
    const payload: EncryptedTokensPayload = JSON.parse(raw) as EncryptedTokensPayload;
    if (payload.v !== TokenPayloadCodec.VERSION) {
      throw new Error('unsupported payload version: ' + payload.v.toString());
    }
    if (payload.data === undefined || payload.data === '') {
      throw new Error('empty cipher data');
    }
    return payload.data;
  }
}
