import { preferences } from '@kit.ArkData';
import { TagModel } from '../model/TagModel';

const STORE_NAME: string = 'o2fah_tags';
const KEY_TAGS: string = 'tags';

export class TagStorage {
  private static storedContext: Context | undefined = undefined;

  static init(ctx: Context): void {
    TagStorage.storedContext = ctx;
  }

  static async getAll(): Promise<TagModel[]> {
    const ctx: Context = TagStorage.getContext();
    const prefs: preferences.Preferences = TagStorage.getPrefsSync(ctx);
    const jsonStr: string = prefs.getSync(KEY_TAGS, '[]') as string;
    return TagStorage.parseTags(jsonStr);
  }

  static async saveAll(tags: TagModel[]): Promise<void> {
    const ctx: Context = TagStorage.getContext();
    const prefs: preferences.Preferences = TagStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(tags);
    prefs.putSync(KEY_TAGS, jsonStr);
    await prefs.flush();
  }

  static async save(tag: TagModel): Promise<void> {
    const tags: TagModel[] = await TagStorage.getAll();
    tags.push(tag);
    const ctx: Context = TagStorage.getContext();
    const prefs: preferences.Preferences = TagStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(tags);
    prefs.putSync(KEY_TAGS, jsonStr);
    await prefs.flush();
  }

  static async update(tag: TagModel): Promise<void> {
    const tags: TagModel[] = await TagStorage.getAll();
    for (let i: number = 0; i < tags.length; i++) {
      if (tags[i].id === tag.id) {
        tags[i] = tag;
        break;
      }
    }
    const ctx: Context = TagStorage.getContext();
    const prefs: preferences.Preferences = TagStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(tags);
    prefs.putSync(KEY_TAGS, jsonStr);
    await prefs.flush();
  }

  static async delete(id: string): Promise<void> {
    const tags: TagModel[] = await TagStorage.getAll();
    const filtered: TagModel[] = [];
    for (let i: number = 0; i < tags.length; i++) {
      if (tags[i].id !== id) {
        filtered.push(tags[i]);
      }
    }
    const ctx: Context = TagStorage.getContext();
    const prefs: preferences.Preferences = TagStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(filtered);
    prefs.putSync(KEY_TAGS, jsonStr);
    await prefs.flush();
  }

  static async clear(): Promise<void> {
    const ctx: Context = TagStorage.getContext();
    const prefs: preferences.Preferences = TagStorage.getPrefsSync(ctx);
    prefs.deleteSync(KEY_TAGS);
    await prefs.flush();
  }

  private static getPrefsSync(ctx: Context): preferences.Preferences {
    const options: preferences.Options = { name: STORE_NAME };
    return preferences.getPreferencesSync(ctx, options);
  }

  private static getContext(): Context {
    if (TagStorage.storedContext === undefined) {
      throw new Error('TagStorage not initialized. Call TagStorage.init(context) first.');
    }
    return TagStorage.storedContext;
  }

  private static parseTags(jsonStr: string): TagModel[] {
    const rawArray: Object[] = JSON.parse(jsonStr) as Object[];
    const result: TagModel[] = [];
    for (let i: number = 0; i < rawArray.length; i++) {
      const raw: Record<string, Object> = rawArray[i] as Record<string, Object>;
      const tag: TagModel = new TagModel();
      tag.id = (raw['id'] ?? '') as string;
      tag.name = (raw['name'] ?? '') as string;
      tag.color = (raw['color'] ?? '#4285F4') as string;
      tag.sortOrder = (raw['sortOrder'] ?? 0) as number;
      tag.tokenCount = (raw['tokenCount'] ?? 0) as number;
      result.push(tag);
    }
    return result;
  }
}
