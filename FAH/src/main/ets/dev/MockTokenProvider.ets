import { TokenModel } from '../model/TokenModel';

const B32_CHARS: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
const ISSUER_POOL: string[] = [
  'GitHub', 'Google', 'Microsoft', 'Apple', 'Amazon', 'AWS', 'Dropbox',
  'Slack', 'Discord', 'Telegram', 'Twitter', 'Facebook', 'Instagram',
  'LinkedIn', 'PayPal', 'Stripe', 'Shopify', 'Notion', 'Figma', 'Zoom',
  'Twitch', 'Reddit', 'Pinterest', 'Netflix', 'Spotify', 'Adobe', 'Oracle',
  'Salesforce', 'Samsung', 'Huawei', 'Xiaomi', 'Alibaba', 'Tencent', 'Baidu',
  'Meituan', 'DingTalk', 'Feishu', 'WeChat', 'QQ', 'Gitee', 'GitLab',
  'Bitbucket', 'Vercel', 'Cloudflare', 'Heroku', 'DigitalOcean', 'Linode',
  'Fastly', 'Kubernetes'
];
const COLOR_POOL: string[] = [
  '#4285F4', '#34A853', '#FBBC05', '#EA4335', '#7B1FA2', '#E91E63',
  '#009688', '#FF9800', '#795548', '#607D8B', '#3F51B5', '#00BCD4',
  '#8BC34A', '#FF5722', '#9C27B0', '#CDDC39'
];
const ALGO_POOL: string[] = ['SHA-1', 'SHA-256', 'SHA-512'];

export class MockTokenProvider {
  static readonly MOCK_COUNT: number = 1200;

  private static cache: TokenModel[] | undefined = undefined;

  static get(): TokenModel[] {
    if (MockTokenProvider.cache === undefined) {
      MockTokenProvider.regenerate();
    }
    return MockTokenProvider.cache as TokenModel[];
  }

  static invalidate(): void {
    MockTokenProvider.cache = undefined;
  }

  static regenerate(): TokenModel[] {
    const result: TokenModel[] = [];
    const now: number = Date.now();
    const seed: string = now.toString(36) + MockTokenProvider.randStr(4);
    for (let i: number = 0; i < MockTokenProvider.MOCK_COUNT; i++) {
      const t: TokenModel = new TokenModel();
      t.id = 'mock_' + seed + '_' + i.toString();
      const issuerIdx: number = i % ISSUER_POOL.length;
      t.issuer = ISSUER_POOL[issuerIdx] + ' #' + Math.floor(i / ISSUER_POOL.length).toString();
      t.account = MockTokenProvider.randAccount(i);
      t.secret = MockTokenProvider.randBase32Secret();
      t.type = 'TOTP';
      t.algorithm = ALGO_POOL[Math.floor(Math.random() * ALGO_POOL.length)];
      t.digits = Math.random() < 0.15 ? 8 : 6;
      t.period = Math.random() < 0.3 ? 60 : 30;
      t.counter = 0;
      t.tags = [];
      t.icon = '';
      t.iconColor = COLOR_POOL[Math.floor(Math.random() * COLOR_POOL.length)];
      t.createdAt = now - Math.floor(Math.random() * 365 * 24 * 3600 * 1000);
      t.lastUsedAt = 0;
      t.sortOrder = i;
      t.version = 0;
      result.push(t);
    }
    MockTokenProvider.cache = result;
    return result;
  }

  private static randBase32Secret(): string {
    let s: string = '';
    for (let i: number = 0; i < 32; i++) {
      s = s + B32_CHARS.charAt(Math.floor(Math.random() * B32_CHARS.length));
    }
    return s;
  }

  private static randAccount(idx: number): string {
    const r: number = Math.floor(Math.random() * 10000);
    const styles: number = idx % 4;
    if (styles === 0) {
      return 'user' + r.toString() + '@mail.com';
    }
    if (styles === 1) {
      return 'user' + r.toString() + '@example.org';
    }
    if (styles === 2) {
      return 'user_' + r.toString();
    }
    return 'u' + r.toString() + '.dev';
  }

  private static randStr(len: number): string {
    let s: string = '';
    for (let i: number = 0; i < len; i++) {
      s = s + Math.floor(Math.random() * 36).toString(36);
    }
    return s;
  }
}
