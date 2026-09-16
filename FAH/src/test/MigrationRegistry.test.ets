import { describe, it, expect } from '@ohos/hypium';
import { MigrationRegistry, MigrationStep } from '../main/ets/storage/MigrationRegistry';

class SuffixStep extends MigrationStep {
  private suffix: string;

  constructor(from: number, to: number, suffix: string) {
    super(from, to);
    this.suffix = suffix;
  }

  run(raw: string): Promise<string> {
    return Promise.resolve(raw + this.suffix);
  }
}

export default function migrationRegistryTest() {
  describe('MigrationRegistryTest', () => {
    it('noopWhenAlreadyCurrent', 0, async () => {
      const steps: MigrationStep[] = [new SuffixStep(1, 2, '-v2')];
      const out: string = await MigrationRegistry.runChain('raw', 2, 2, steps);
      expect(out).assertEqual('raw');
    });

    it('runsSingleStep', 0, async () => {
      const steps: MigrationStep[] = [new SuffixStep(1, 2, '-v2')];
      const out: string = await MigrationRegistry.runChain('raw', 1, 2, steps);
      expect(out).assertEqual('raw-v2');
    });

    it('runsChainInOrder', 0, async () => {
      const steps: MigrationStep[] = [new SuffixStep(1, 2, '-v2'), new SuffixStep(2, 3, '-v3')];
      const out: string = await MigrationRegistry.runChain('raw', 1, 3, steps);
      expect(out).assertEqual('raw-v2-v3');
    });

    it('throwsWhenStepMissing', 0, async () => {
      const steps: MigrationStep[] = [new SuffixStep(2, 3, '-v3')];
      let thrown: boolean = false;
      try {
        await MigrationRegistry.runChain('raw', 1, 3, steps);
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('throwsOnCycle', 0, async () => {
      const steps: MigrationStep[] = [new SuffixStep(1, 1, ''), new SuffixStep(1, 1, '')];
      let thrown: boolean = false;
      try {
        await MigrationRegistry.runChain('raw', 1, 3, steps);
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });
  });
}
