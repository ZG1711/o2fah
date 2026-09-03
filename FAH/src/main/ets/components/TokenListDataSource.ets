import { TokenModel } from '../model/TokenModel';

export class TokenListDataSource implements IDataSource {
  private list: TokenModel[] = [];
  private listeners: DataChangeListener[] = [];
  private accessCallback: ((token: TokenModel) => void) | undefined = undefined;

  setAccessCallback(callback: (token: TokenModel) => void): void {
    this.accessCallback = callback;
  }

  setData(list: TokenModel[]): void {
    this.list = list;
    this.notifyDataReload();
  }

  totalCount(): number {
    return this.list.length;
  }

  getData(index: number): TokenModel {
    const t: TokenModel = this.list[index];
    if (t !== undefined && this.accessCallback !== undefined) {
      this.accessCallback(t);
    }
    return t;
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  private notifyDataReload(): void {
    for (let i: number = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }
}
