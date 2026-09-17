import { describe, it, expect } from '@ohos/hypium';
import { SecretNormalizer, NormalizeResult } from '../main/ets/utils/SecretNormalizer';

export default function secretNormalizerTest() {
  describe('SecretNormalizerTest', () => {
    it('stripsSpacesAndDashes', 0, () => {
      const r: NormalizeResult = SecretNormalizer.normalize('JBSW Y3DP-EHPK_3PXP');
      expect(r.secret).assertEqual('JBSWY3DPEHPK3PXP');
      expect(r.correctedCount).assertEqual(0);
    });

    it('uppercases', 0, () => {
      const r: NormalizeResult = SecretNormalizer.normalize('jbswy3dpehpk3pxp');
      expect(r.secret).assertEqual('JBSWY3DPEHPK3PXP');
    });

    it('stripsPaddingAndWhitespace', 0, () => {
      const r: NormalizeResult = SecretNormalizer.normalize('  JBSWY3DP====\n\t');
      expect(r.secret).assertEqual('JBSWY3DP');
    });

    it('mapsAmbiguousZeroOneEight', 0, () => {
      const r: NormalizeResult = SecretNormalizer.normalize('JBSWY3DP0E1PK8PXP');
      expect(r.secret).assertEqual('JBSWY3DPOEIPKBPXP');
      expect(r.correctedCount).assertEqual(3);
    });

    it('reportsNoCorrectionForCleanInput', 0, () => {
      const r: NormalizeResult = SecretNormalizer.normalize('JBSWY3DPEHPK3PXP');
      expect(r.correctedCount).assertEqual(0);
    });

    it('rejectsUnmappableCharacters', 0, () => {
      expect(SecretNormalizer.isValid('JBSWY3DP!')).assertFalse();
      expect(SecretNormalizer.isValid('JBSWY3DP')).assertTrue();
      expect(SecretNormalizer.isValid('')).assertFalse();
    });

    it('normalizedIsAlwaysValidWhenInputDecodable', 0, () => {
      const r: NormalizeResult = SecretNormalizer.normalize('jbsw-y3dp-ehpk-3pxp');
      expect(SecretNormalizer.isValid(r.secret)).assertTrue();
    });
  });
}
