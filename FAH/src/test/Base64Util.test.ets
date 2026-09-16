import { describe, it, expect } from '@ohos/hypium';
import { Base64Util } from '../main/ets/storage/Base64Util';

export default function base64UtilTest() {
  describe('Base64UtilTest', () => {
    it('roundTripEmpty', 0, () => {
      const out: Uint8Array = Base64Util.decode('');
      expect(out.length).assertEqual(0);
    });

    it('roundTripAscii', 0, () => {
      const src: Uint8Array = new Uint8Array([72, 101, 108, 108, 111]);
      const encoded: string = Base64Util.encode(src);
      expect(encoded).assertEqual('SGVsbG8=');
      const decoded: Uint8Array = Base64Util.decode(encoded);
      expect(decoded.length).assertEqual(5);
      expect(decoded[0]).assertEqual(72);
      expect(decoded[4]).assertEqual(111);
    });

    it('roundTripAllByteValues', 0, () => {
      const src: Uint8Array = new Uint8Array(256);
      for (let i: number = 0; i < 256; i++) {
        src[i] = i;
      }
      const decoded: Uint8Array = Base64Util.decode(Base64Util.encode(src));
      expect(decoded.length).assertEqual(256);
      let same: boolean = true;
      for (let i: number = 0; i < 256; i++) {
        if (decoded[i] !== src[i]) {
          same = false;
          break;
        }
      }
      expect(same).assertTrue();
    });

    it('roundTripNoPaddingLengths', 0, () => {
      for (let len: number = 1; len <= 8; len++) {
        const src: Uint8Array = new Uint8Array(len);
        for (let i: number = 0; i < len; i++) {
          src[i] = (i * 37) % 256;
        }
        const decoded: Uint8Array = Base64Util.decode(Base64Util.encode(src));
        expect(decoded.length).assertEqual(len);
      }
    });
  });
}
