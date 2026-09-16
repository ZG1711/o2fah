import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const PRIVACY_MODE_KEY: string = 'privacyMode';

/**
 * 窗口隐私模式（防截屏 / 防录屏）统一入口。
 *
 * 隐私模式是**窗口级**设置，设置一次后对整个应用窗口生效。官方 FAQ
 * `faqs-arkui-1283` 提示：频繁切换页面时反复开关可能导致设置失效，
 * 因此只在「窗口创建完成」与「设置项变更」时调用，不做页面级反复开关。
 */
export class PrivacyModeManager {
  private static mainWindow: window.Window | undefined = undefined;

  /** 由 FAHAbility 在 onWindowStageCreate 中注入主窗口 */
  static attach(win: window.Window): void {
    PrivacyModeManager.mainWindow = win;
  }

  /** 设置项变更入口：同步 AppStorage 运行期状态 + 应用到窗口 */
  static apply(enabled: boolean): void {
    AppStorage.setOrCreate(PRIVACY_MODE_KEY, enabled);
    PrivacyModeManager.applyWindow(enabled);
  }

  /** 窗口创建完成后按当前状态恢复一次 */
  static applyCurrent(): void {
    PrivacyModeManager.applyWindow(AppStorage.get<boolean>(PRIVACY_MODE_KEY) ?? true);
  }

  /**
   * 仅作用于窗口，**不修改**用户设置。
   * 供导出二维码页临时强制开启/恢复：避免污染 AppStorage `privacyMode`
   * 导致设置页开关状态被带偏。
   */
  static applyWindow(enabled: boolean): void {
    const win: window.Window | undefined = PrivacyModeManager.mainWindow;
    if (win === undefined) {
      return;
    }
    win.setWindowPrivacyMode(enabled).catch((err: BusinessError): void => {
      hilog.error(DOMAIN, 'testTag', 'setWindowPrivacyMode failed: %{public}s', JSON.stringify(err));
    });
  }
}
