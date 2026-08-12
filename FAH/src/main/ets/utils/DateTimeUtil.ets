export class DateTimeUtil {
  static getRemainingSeconds(period: number): number {
    return period - (Math.floor(Date.now() / 1000) % period);
  }

  static formatDate(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const date: Date = new Date(timestamp);
    const year: number = date.getFullYear();
    const month: number = date.getMonth() + 1;
    const day: number = date.getDate();
    return year.toString() + '-' +
      (month < 10 ? '0' + month.toString() : month.toString()) + '-' +
      (day < 10 ? '0' + day.toString() : day.toString());
  }

  static daysSince(timestamp: number): number {
    if (timestamp <= 0) {
      return -1;
    }
    const now: number = Date.now();
    return Math.floor((now - timestamp) / (1000 * 60 * 60 * 24));
  }
}
