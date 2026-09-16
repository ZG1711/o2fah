import { describe, it, expect } from '@ohos/hypium';
import { TokenSchema } from '../main/ets/storage/TokenSchema';

export default function tokenSchemaTest() {
  describe('TokenSchemaTest', () => {
    it('emptyIsCurrent', 0, () => {
      expect(TokenSchema.detectVersion('')).assertEqual(TokenSchema.CURRENT);
    });

    it('arrayIsV1', 0, () => {
      expect(TokenSchema.detectVersion('[{"id":"a"}]')).assertEqual(TokenSchema.V1_PLAINTEXT);
      expect(TokenSchema.detectVersion('  [ ]  ')).assertEqual(TokenSchema.V1_PLAINTEXT);
    });

    it('objectWithVersionIsV2', 0, () => {
      expect(TokenSchema.detectVersion('{"v":2,"alg":"AES-GCM","data":"QUJD"}'))
        .assertEqual(TokenSchema.V2_ENCRYPTED);
    });

    it('rejectsUnknownShape', 0, () => {
      let thrown: boolean = false;
      try {
        TokenSchema.detectVersion('"just a string"');
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('rejectsMissingVersion', 0, () => {
      let thrown: boolean = false;
      try {
        TokenSchema.detectVersion('{"alg":"AES-GCM"}');
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });
  });
}
