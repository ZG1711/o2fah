import { describe, it, expect } from '@ohos/hypium';
import { TokenMatcher } from '../main/ets/utils/TokenMatcher';
import { TokenModel } from '../main/ets/model/TokenModel';

function token(issuer: string, account: string): TokenModel {
  const t: TokenModel = new TokenModel();
  t.issuer = issuer;
  t.account = account;
  return t;
}

export default function tokenMatcherTest() {
  describe('TokenMatcherTest', () => {
    it('detectsExactDuplicate', 0, () => {
      const list: TokenModel[] = [token('GitHub', 'alice@example.com')];
      expect(TokenMatcher.isDuplicate(list, 'GitHub', 'alice@example.com')).assertTrue();
    });

    it('ignoresSurroundingWhitespace', 0, () => {
      const list: TokenModel[] = [token('GitHub', 'alice@example.com')];
      expect(TokenMatcher.isDuplicate(list, ' GitHub ', ' alice@example.com ')).assertTrue();
    });

    it('isCaseSensitiveLikeMergeImporter', 0, () => {
      const list: TokenModel[] = [token('GitHub', 'alice@example.com')];
      expect(TokenMatcher.isDuplicate(list, 'github', 'alice@example.com')).assertFalse();
    });

    it('doesNotMatchDifferentAccount', 0, () => {
      const list: TokenModel[] = [token('GitHub', 'alice@example.com')];
      expect(TokenMatcher.isDuplicate(list, 'GitHub', 'bob@example.com')).assertFalse();
    });

    it('doesNotMatchDifferentIssuerSameAccount', 0, () => {
      const list: TokenModel[] = [token('GitHub', 'shared@example.com')];
      expect(TokenMatcher.isDuplicate(list, 'GitLab', 'shared@example.com')).assertFalse();
    });

    it('emptyListIsNeverDuplicate', 0, () => {
      expect(TokenMatcher.isDuplicate([], 'GitHub', 'alice@example.com')).assertFalse();
    });

    it('findsMatchAmongMany', 0, () => {
      const list: TokenModel[] = [
        token('A', 'a'), token('B', 'b'), token('C', 'c'), token('D', 'd')
      ];
      expect(TokenMatcher.isDuplicate(list, 'C', 'c')).assertTrue();
      expect(TokenMatcher.isDuplicate(list, 'C', 'z')).assertFalse();
    });
  });
}
