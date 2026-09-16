import { describe, it, expect } from '@ohos/hypium';
import { TokenPayloadCodec } from '../main/ets/storage/TokenPayloadCodec';

export default function tokenPayloadTest() {
  describe('TokenPayloadTest', () => {
    it('buildThenExtract', 0, () => {
      const raw: string = TokenPayloadCodec.build('QUJD');
      expect(TokenPayloadCodec.extractCipher(raw)).assertEqual('QUJD');
    });

    it('rejectsOldVersion', 0, () => {
      let thrown: boolean = false;
      try {
        TokenPayloadCodec.extractCipher('{"v":1,"alg":"none","data":"QUJD"}');
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('rejectsEmptyData', 0, () => {
      let thrown: boolean = false;
      try {
        TokenPayloadCodec.extractCipher('{"v":2,"alg":"AES-GCM","data":""}');
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });
  });
}
