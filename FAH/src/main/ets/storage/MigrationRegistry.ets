/**
 * 单条迁移步骤。ArkTS 不支持「带方法的对象字面量」，故用抽象类而非 interface。
 */
export abstract class MigrationStep {
  readonly fromVersion: number;
  readonly toVersion: number;

  constructor(fromVersion: number, toVersion: number) {
    this.fromVersion = fromVersion;
    this.toVersion = toVersion;
  }

  abstract run(raw: string): Promise<string>;
}

/** 迁移链执行器：逐级升级，缺环即抛错（绝不写回半成品数据） */
export class MigrationRegistry {
  private static readonly MAX_STEPS: number = 32;

  static async runChain(raw: string, fromVersion: number, targetVersion: number,
    steps: MigrationStep[]): Promise<string> {
    if (fromVersion >= targetVersion) {
      return raw;
    }
    let current: string = raw;
    let version: number = fromVersion;
    let guard: number = 0;
    while (version < targetVersion) {
      const next: MigrationStep | undefined = MigrationRegistry.findStep(steps, version);
      if (next === undefined) {
        throw new Error('missing migration step from version ' + version.toString()
          + ' to ' + targetVersion.toString());
      }
      if (next.toVersion <= version) {
        throw new Error('invalid migration step: ' + version.toString()
          + ' -> ' + next.toVersion.toString());
      }
      current = await next.run(current);
      version = next.toVersion;
      guard = guard + 1;
      if (guard > MigrationRegistry.MAX_STEPS) {
        throw new Error('migration chain exceeded max steps');
      }
    }
    return current;
  }

  private static findStep(steps: MigrationStep[], fromVersion: number): MigrationStep | undefined {
    for (let i: number = 0; i < steps.length; i++) {
      if (steps[i].fromVersion === fromVersion) {
        return steps[i];
      }
    }
    return undefined;
  }
}
