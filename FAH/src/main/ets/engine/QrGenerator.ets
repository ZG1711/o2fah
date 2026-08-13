import { generateBarcode, scanCore } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';

export class QrGenerator {
  static generateQr(content: string): Promise<image.PixelMap> {
    const options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      width: 600,
      height: 600,
      level: generateBarcode.ErrorCorrectionLevel.LEVEL_M
    };
    return generateBarcode.createBarcode(content, options);
  }
}
