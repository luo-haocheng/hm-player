import { display } from '@kit.ArkUI';
import { VideoPlayerViewModel } from '../viewmodel/VideoPlayerViewModel';
import { ShutdownCustomDialog } from './ShutdownCustomDialog';

export enum ShutdownOption {
  FIFTEEN_MIN = 'FifteenMin',
  THIRTY_MIN = 'ThirtyMin',
  SIXTY_MIN = 'SixtyMin',
  CUSTOM = 'Custom',
  None = 'None',
}

@CustomDialog
export struct ShutdownDialog {
  @State shutdownTimeMs: number = 0;
  @Link videoPlayerVM: VideoPlayerViewModel;
  private intervalId: number = 0;
  private optionWidth: number = 60;
  private controller: CustomDialogController;
  private shutdownOptionMap: Map<ShutdownOption, string> = new Map([
    [ShutdownOption.None, '不开启'],
    [ShutdownOption.FIFTEEN_MIN, '15分钟'],
    [ShutdownOption.THIRTY_MIN, '30分钟'],
    [ShutdownOption.SIXTY_MIN, '60分钟'],
    [ShutdownOption.CUSTOM, '自定义'],
  ]);

  private shutdownTimeStr() {
    const hours = (Math.floor(this.shutdownTimeMs / (60 * 60 * 1000))).toString().padStart(2, '0');
    const minutes = (Math.floor(this.shutdownTimeMs / (60 * 1000)) % 60).toString().padStart(2, '0');
    const seconds = (Math.floor(this.shutdownTimeMs / 1000) % 60).toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }

  @Builder
  optionBuilder(option: ShutdownOption, text: string) {
    Row() {
      Text(text)
        .fontSize(10)
        .fontColor(!this.videoPlayerVM.shutdownAfterComplete && this.videoPlayerVM.shutdownOption === option ?
          '#FF007DFF' : Color.Gray);
    }
    .height('100%')
    .width(this.optionWidth)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center);
  }

  aboutToAppear(): void {
    this.shutdownTimeMs = this.videoPlayerVM.getShutdownTimeMs();
    this.intervalId = setInterval(() => {
      this.shutdownTimeMs = this.videoPlayerVM.getShutdownTimeMs();
    }, 1000);

    try {
      const displayWidth = this.getUIContext().px2vp(display.getDefaultDisplaySync().width);
      this.optionWidth = (displayWidth - 32) / 5;
    } catch (error) {
      console.error(`Failed to calculate options width`);
    }
  }

  aboutToDisappear(): void {
    clearInterval(this.intervalId);
  }

  build() {
    Column() {
      Row() {
        Text(this.shutdownTimeMs <= 0 ? '定时关闭' : this.shutdownTimeStr())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'));

        Row({ space: 3 }) {
          Text('当前视频播放完后停止')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'));

          Toggle({ type: ToggleType.Switch, isOn: $$this.videoPlayerVM.shutdownAfterComplete })
            .width(30)
            .height(18)
            .selectedColor('#FF007DFF')
            .switchPointColor(Color.White)
            .onClick(() => {
              this.videoPlayerVM.shutdownOption = ShutdownOption.None;
              this.videoPlayerVM.clearShutdownDate();
            });
        };
      }
      .width('100%')
      .layoutWeight(0)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween);

      Row() {
        List() {
          ForEach(
            Array.from(this.shutdownOptionMap.entries()),
            (entry: [ShutdownOption, string]) => {
              ListItem() {
                this.optionBuilder(entry[0], entry[1]);
              }
              .onClick(() => {
                this.videoPlayerVM.shutdownAfterComplete = false;
                this.videoPlayerVM.shutdownOption = entry[0];

                switch (this.videoPlayerVM.shutdownOption) {
                  case ShutdownOption.FIFTEEN_MIN:
                    this.videoPlayerVM.setShutdownDate(0, 15);
                    break;
                  case ShutdownOption.THIRTY_MIN:
                    this.videoPlayerVM.setShutdownDate(0, 30);
                    break;
                  case ShutdownOption.SIXTY_MIN:
                    this.videoPlayerVM.setShutdownDate(0, 60);
                    break;
                  case ShutdownOption.CUSTOM:
                    this.controller = new CustomDialogController({
                      width: '100%',
                      height: '40%',
                      alignment: DialogAlignment.Bottom,
                      cornerRadius: { topLeft: 24, topRight: 24 },
                      builder: ShutdownCustomDialog({ videoPlayerVM: this.videoPlayerVM }),
                      onWillDisappear: () => {
                        this.shutdownTimeMs = this.videoPlayerVM.getShutdownTimeMs();
                      }
                    });
                    this.controller.open();
                    break;
                  case ShutdownOption.None:
                    this.videoPlayerVM.shutdownOption = ShutdownOption.None;
                    this.videoPlayerVM.clearShutdownDate();
                    break;
                }
                this.shutdownTimeMs = this.videoPlayerVM.getShutdownTimeMs();
              });
            },
            (entry: [ShutdownOption, string]) => entry[0],
          );
        }
        .height(40)
        .width('100%')
        .borderRadius(8)
        .scrollBar(BarState.Off)
        .listDirection(Axis.Horizontal)
        .divider({
          color: $r('sys.color.comp_divider'),
          strokeWidth: 0.5,
          startMargin: 8,
          endMargin: 8,
        });
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center);
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start);
  }
}