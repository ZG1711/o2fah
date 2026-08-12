import { ThemeManager, ThemeColors } from '../common/ThemeManager';

@Component
export struct CountdownRing {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop totalSeconds: number = 30;
  @Prop @Watch('onRemainingChange') remainingSeconds: number = 18;
  @Prop color: string = '#4285F4';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private drawTimer: number = -1;

  getRingTrackColor(): string {
    if (this.isDarkMode) {
      return '#3A3A3C';
    }
    return '#E5E5E5';
  }

  private onRemainingChange(): void {
    if (this.drawTimer >= 0) {
      clearTimeout(this.drawTimer);
    }
    this.drawTimer = setTimeout(() => {
      this.drawRing();
    }, 0);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.canvasCtx)
        .width(36)
        .height(36)
        .onReady(() => {
          this.drawRing();
        })
      Text(this.remainingSeconds.toString() + 's')
        .fontSize(10)
        .fontWeight(700)
        .fontColor(this.color)
    }
    .width(36)
    .height(36)
  }

  aboutToDisappear(): void {
    if (this.drawTimer >= 0) {
      clearTimeout(this.drawTimer);
      this.drawTimer = -1;
    }
  }

  private drawRing(): void {
    this.canvasCtx.clearRect(0, 0, 36, 36);
    // Background ring
    this.canvasCtx.strokeStyle = this.getRingTrackColor();
    this.canvasCtx.lineWidth = 3;
    this.canvasCtx.beginPath();
    this.canvasCtx.arc(18, 18, 15, 0, 2 * Math.PI);
    this.canvasCtx.stroke();

    // Progress arc
    const ratio: number = this.totalSeconds > 0 ? this.remainingSeconds / this.totalSeconds : 0;
    const endAngle: number = -Math.PI / 2 + ratio * 2 * Math.PI;
    this.canvasCtx.strokeStyle = this.color;
    this.canvasCtx.lineWidth = 3;
    this.canvasCtx.lineCap = 'round';
    this.canvasCtx.beginPath();
    this.canvasCtx.arc(18, 18, 15, -Math.PI / 2, endAngle);
    this.canvasCtx.stroke();
  }
}
