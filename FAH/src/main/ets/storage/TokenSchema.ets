import { MigrationStep } from './MigrationRegistry';
import { HuksStore } from './HuksStore';
import { TokenPayloadCodec } from './TokenPayloadCodec';

interface VersionProbe {
  v: number;
}

/** 数据由更高版本应用写入（降级安装）：不得解析，提示用户升级 */
export class TokenVersionTooNewError extends Error {
  readonly found: number;

  constructor(found: number) {
    super('token data was created by a newer app version: v' + found.toString());
    this.found = found;
  }
}

export class TokenSchema {
  static readonly V1_PLAINTEXT: number = 1;
  static readonly V2_ENCRYPTED: number = 2;
  static readonly CURRENT: number = TokenSchema.V2_ENCRYPTED;

  /**
   * 检测已归档数据的版本。
   * - 空串 → 当前版本（空态，无数据）
   * - 明文数组 JSON（忽略前导空白）→ v1
   * - 含 v 字段的 payload 对象 → 该 v
   * - 其他 → 抛错（不猜测）
   */
  static detectVersion(raw: string): number {
    const trimmed: string = raw.trim();
    if (trimmed === '') {
      return TokenSchema.CURRENT;
    }
    if (trimmed.charAt(0) === '[') {
      return TokenSchema.V1_PLAINTEXT;
    }
    if (trimmed.charAt(0) === '{') {
      const probe: VersionProbe = JSON.parse(trimmed) as VersionProbe;
      if (probe.v === undefined) {
        throw new Error('token payload missing version field');
      }
      return probe.v;
    }
    throw new Error('unrecognized token payload format');
  }

  /** 版本过高时抛 TokenVersionTooNewError，调用方据此提示升级 */
  static assertNotFromFuture(version: number): void {
    if (version > TokenSchema.CURRENT) {
      throw new TokenVersionTooNewError(version);
    }
  }

  static steps(): MigrationStep[] {
    return [new PlaintextToEncryptedStep()];
  }
}

/** v1 明文数组 JSON → v2 HUKS 加密 payload */
class PlaintextToEncryptedStep extends MigrationStep {
  constructor() {
    super(TokenSchema.V1_PLAINTEXT, TokenSchema.V2_ENCRYPTED);
  }

  run(raw: string): Promise<string> {
    return HuksStore.encrypt(raw).then((cipher: string): string => {
      return TokenPayloadCodec.build(cipher);
    });
  }
}
