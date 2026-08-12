import { IconConstants } from '../common/IconConstants';

@Component
export struct ToastView {
  @State message: string = '';
  @State type: string = 'success';
  @State visible: boolean = false;

  show(msg: string, toastType: string): void {
    this.message = msg;
    this.type = toastType;
    this.visible = true;
    setTimeout(() => {
      this.visible = false;
    }, 2000);
  }

  build() {
    if (this.visible) {
      Row() {
        Row({ space: 8 }) {
          Image(this.type === 'success' ? IconConstants.IC_TOAST_SUCCESS :
            this.type === 'warning' ? IconConstants.IC_TOAST_WARNING :
              IconConstants.IC_TOAST_ERROR)
            .width(16)
            .height(16)

          Text(this.message)
            .fontSize(14)
            .fontWeight(500)
            .fontColor('#FFFFFF')
        }
        .padding({ top: 10, bottom: 10, left: 20, right: 20 })
        .backgroundColor('rgba(0,0,0,0.8)')
        .borderRadius(22)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .position({ top: 44 })
    }
  }
}
