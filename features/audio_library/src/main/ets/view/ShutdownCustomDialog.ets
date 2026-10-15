import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { ShutdownOption } from './ShutdownDialog';


@CustomDialog
export struct ShutdownCustomDialog {
  @Link audioPlayerVM: AudioPlayerViewModel;
  private controller: CustomDialogController;
  private result?: TimePickerResult;

  build() {
    Column({ space: 12 }) {
      Row() {
        Button('取消')
          .padding(0)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.font_tertiary'))
          .onClick(() => {
            this.audioPlayerVM.shutdownOption = ShutdownOption.None;
            this.audioPlayerVM.clearShutdownDate();
            this.controller.close();
          });

        Button('确认')
          .padding(0)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.font_emphasize'))
          .onClick(() => {
            if (!this.result || (this.result.hour === 0 && this.result.minute === 0)) {
              this.audioPlayerVM.shutdownOption = ShutdownOption.None;
              this.audioPlayerVM.clearShutdownDate();
              this.controller.close();
              return;
            }
            this.audioPlayerVM.setShutdownDate(this.result.hour, this.result.minute);
            this.controller.close();
          });
      }
      .width('100%')
      .layoutWeight(0)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween);

      Row({ space: 12 }) {
        Text('小时')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_emphasize'));

        TimePicker({
          selected: new Date(0, 0, 0, 0, 0, 0),
          format: TimePickerFormat.HOUR_MINUTE,
        })
          .width('50%')
          .height('100%')
          .loop(false)
          .useMilitaryTime(true)
          .dateTimeOptions({ hour: 'numeric', minute: 'numeric' })
          .onEnterSelectedArea((result: TimePickerResult) => {
            this.result = result;
          });

        Text('分钟')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_emphasize'));
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center);
    }
    .padding({
      top: 8,
      left: 16,
      right: 16,
      bottom: 8,
    })
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}