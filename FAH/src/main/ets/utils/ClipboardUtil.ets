import { pasteboard } from '@kit.BasicServicesKit';

export class ClipboardUtil {
  static copy(text: string): void {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    const sysBoard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    sysBoard.setData(data);
  }

  static async paste(): Promise<string> {
    const sysBoard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    const data: pasteboard.PasteData = await sysBoard.getData();
    return data.getPrimaryText();
  }
}
