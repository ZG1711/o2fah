export class Base32Decoder {
  private static readonly ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static decode(input: string): Uint8Array {
    let cleaned: string = input.toUpperCase();
    let filtered: string = '';
    for (let i: number = 0; i < cleaned.length; i++) {
      let ch: string = cleaned.charAt(i);
      if (ch !== ' ' && ch !== '-' && ch !== '=' && ch !== '\t' && ch !== '\n' && ch !== '\r') {
        filtered += ch;
      }
    }

    if (filtered.length === 0) {
      return new Uint8Array(0);
    }

    let outputSize: number = Math.floor((filtered.length * 5) / 8);
    let output: Uint8Array = new Uint8Array(outputSize);

    let bitCount: number = 0;
    let bitBuffer: number = 0;
    let byteIndex: number = 0;

    for (let i: number = 0; i < filtered.length; i++) {
      let ch: string = filtered.charAt(i);
      let value: number = Base32Decoder.ALPHABET.indexOf(ch);
      if (value === -1) {
        throw new Error('Invalid Base32 character: ' + ch);
      }

      bitBuffer = (bitBuffer << 5) | value;
      bitCount += 5;

      if (bitCount >= 8) {
        bitCount -= 8;
        output[byteIndex] = (bitBuffer >> bitCount) & 0xFF;
        byteIndex++;
      }
    }

    return output;
  }

  static encode(data: Uint8Array): string {
    if (data.length === 0) {
      return '';
    }

    let bitCount: number = 0;
    let bitBuffer: number = 0;
    let result: string = '';

    for (let i: number = 0; i < data.length; i++) {
      bitBuffer = (bitBuffer << 8) | data[i];
      bitCount += 8;

      while (bitCount >= 5) {
        bitCount -= 5;
        let index: number = (bitBuffer >> bitCount) & 0x1F;
        result += Base32Decoder.ALPHABET.charAt(index);
      }
    }

    if (bitCount > 0) {
      let index: number = (bitBuffer << (5 - bitCount)) & 0x1F;
      result += Base32Decoder.ALPHABET.charAt(index);
    }

    while (result.length % 8 !== 0) {
      result += '=';
    }

    return result;
  }
}
