import { userAuth } from '@kit.UserAuthenticationKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class BiometricUtil {
  private static storedContext: Context | undefined = undefined;

  static init(ctx: Context): void {
    BiometricUtil.storedContext = ctx;
  }

  static checkAvailability(): boolean {
    const authTypes: userAuth.UserAuthType[] = [
      userAuth.UserAuthType.FINGERPRINT,
      userAuth.UserAuthType.FACE,
      userAuth.UserAuthType.PIN
    ];
    for (let i: number = 0; i < authTypes.length; i++) {
      try {
        userAuth.getAvailableStatus(authTypes[i], userAuth.AuthTrustLevel.ATL3);
        return true;
      } catch (_error) {
        continue;
      }
    }
    return false;
  }

  static async authenticate(): Promise<boolean> {
    return new Promise<boolean>((resolve: (value: boolean) => void): void => {
      try {
        const rand: cryptoFramework.Random = cryptoFramework.createRandom();
        const randData: Uint8Array = rand.generateRandomSync(16).data;

        const authParam: userAuth.AuthParam = {
          challenge: randData,
          authType: [
            userAuth.UserAuthType.PIN,
            userAuth.UserAuthType.FINGERPRINT,
            userAuth.UserAuthType.FACE
          ],
          authTrustLevel: userAuth.AuthTrustLevel.ATL3
        };

        const widgetParam: userAuth.WidgetParam = {
          title: BiometricUtil.getAuthTitle()
        };

        const userAuthInstance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(
          authParam,
          widgetParam
        );

        userAuthInstance.on('result', {
          onResult: (result: userAuth.UserAuthResult): void => {
            userAuthInstance.off('result');
            if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
              resolve(true);
            } else {
              resolve(false);
            }
          }
        });

        userAuthInstance.start();
      } catch (error) {
        resolve(false);
      }
    });
  }

  private static getAuthTitle(): string {
    if (BiometricUtil.storedContext !== undefined) {
      return BiometricUtil.storedContext.resourceManager.getStringSync($r('app.string.biometric_auth_title').id);
    }
    return 'Identity verification';
  }
}
