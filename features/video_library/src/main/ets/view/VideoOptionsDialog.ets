import { media } from '@kit.MediaKit';
import { VideoRepeatMode } from 'data_storage';
import { common } from '@kit.AbilityKit';
import { VideoPlayerViewModel } from '../viewmodel/VideoPlayerViewModel';
import { ShutdownDialog } from './ShutdownDialog';

const PLAYBACK_SPEED_MAP: Map<media.PlaybackSpeed, string> = new Map([
  [media.PlaybackSpeed.SPEED_FORWARD_0_50_X, '0.5'],
  [media.PlaybackSpeed.SPEED_FORWARD_0_75_X, '0.75'],
  [media.PlaybackSpeed.SPEED_FORWARD_1_00_X, '1'],
  [media.PlaybackSpeed.SPEED_FORWARD_1_25_X, '1.25'],
  [media.PlaybackSpeed.SPEED_FORWARD_1_50_X, '1.50'],
  [media.PlaybackSpeed.SPEED_FORWARD_2_00_X, '2'],
]);

const REPEAT_MODE_MAP: Map<VideoRepeatMode, string> = new Map([
  [VideoRepeatMode.SINGLE_NON_REPEAT, '播完暂停'],
  [VideoRepeatMode.LIST_NON_REPEAT, '自动连播'],
  [VideoRepeatMode.SINGLE_REPEAT, '单集循环'],
  [VideoRepeatMode.LIST_REPEAT, '列表循环'],
]);


@CustomDialog
export struct VideoOptionsDialog {
  @Link videoPlayerVM: VideoPlayerViewModel;
  private controller: CustomDialogController;
  private speedListScroller: Scroller = new Scroller();
  private repeatListScroller: Scroller = new Scroller();

  @Builder
  optionIconBuilder(icon: Resource, text: string) {
    Column() {
      Image(icon)
        .padding(8)
        .width('100%')
        .aspectRatio(1)
        .borderRadius(8)
        .layoutWeight(0)
        .fillColor(Color.Black)
        .backgroundColor(Color.White);

      Row() {
        Text(text)
          .fontSize(10)
          .fontColor(Color.Gray);
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Transparent);
  }

  @Builder
  optionListItemBuilder(icon: Resource, text: string) {
    Row({ space: 16 }) {
      Image(icon)
        .width(22)
        .aspectRatio(1)
        .fillColor($r('sys.color.font_primary'));

      Text(text)
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'));
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  speedOptionsBuilder() {
    List({ scroller: this.speedListScroller }) {
      ForEach(
        Array.from(PLAYBACK_SPEED_MAP.entries()),
        (entry: [media.PlaybackSpeed, string]) => {
          ListItem() {
            Text(entry[1])
              .fontSize(10)
              .textAlign(TextAlign.Center)
              .fontColor(
                this.videoPlayerVM.playbackSpeed === entry[0] ?
                  $r('sys.color.font_emphasize') :
                  $r('sys.color.font_tertiary')
              );
          }
          .width(40)
          .onClick(() => {
            this.videoPlayerVM.setSpeed(entry[0]);
            this.videoPlayerVM.playbackSpeed = entry[0];
          });
        },
      );
    }
    .width('50%')
    .scrollBar(BarState.Off)
    .listDirection(Axis.Horizontal)
    .divider({ strokeWidth: 0.5, color: Color.Gray })
    .onAppear(() => {
      const speedIdx = Array.from(PLAYBACK_SPEED_MAP.keys()).findIndex((playbackSpeed: media.PlaybackSpeed) => {
        return this.videoPlayerVM.playbackSpeed === playbackSpeed;
      });
      if (speedIdx !== -1) {
        this.speedListScroller.scrollToIndex(speedIdx, false, ScrollAlign.CENTER);
      }
    });
  }

  @Builder
  repeatOptionBuilder() {
    List({ scroller: this.repeatListScroller }) {
      ForEach(
        Array.from(REPEAT_MODE_MAP.entries()),
        (entry: [VideoRepeatMode, string]) => {
          ListItem() {
            Text(entry[1])
              .fontSize(10)
              .textAlign(TextAlign.Center)
              .fontColor(
                this.videoPlayerVM.videoRepeatMode === entry[0] ?
                  $r('sys.color.font_emphasize') :
                  $r('sys.color.font_tertiary')
              );
          }
          .width(60)
          .onClick(() => {
            this.videoPlayerVM.setRepeatMode(entry[0]);
          });
        },
      );
    }
    .width('50%')
    .scrollBar(BarState.Off)
    .listDirection(Axis.Horizontal)
    .divider({ strokeWidth: 0.5, color: Color.Gray })
    .onAppear(() => {
      const repeatIdx = Array.from(REPEAT_MODE_MAP.keys()).findIndex((repeatMode: VideoRepeatMode) => {
        return this.videoPlayerVM.videoRepeatMode === repeatMode;
      });
      if (repeatIdx !== -1) {
        this.repeatListScroller.scrollToIndex(repeatIdx, false, ScrollAlign.CENTER);
      }
    });
  }

  build() {
    Column({ space: 16 }) {
      // Row({ space: 16 }) {
      //   Column() {
      //     this.optionIconBuilder($r('app.media.arrow_right_up_and_square'), '小窗播放');
      //   }
      //   .width(40)
      //   .height(65)
      //   .onClick(async () => {
      //     const context = this.getUIContext().getHostContext() as Context;
      //     await this.videoPlayerVM.startPip(context);
      //     this.mainPageStack.pop();
      //     this.controller.close();
      //   });
      //
      //   Column() {
      //     this.optionIconBuilder($r('app.media.rectangle_and_arrowshape_turn_up_right'), '系统投播');
      //   }
      //   .width(40)
      //   .height(65)
      //   .onClick(() => {
      //     // todo
      //   });
      // }
      // .width('100%')
      // .justifyContent(FlexAlign.Start)
      // .alignItems(VerticalAlign.Center);

      List() {
        ListItem() {
          Row() {
            this.optionListItemBuilder($r('app.media.fast_forward'), '播放倍速');

            this.speedOptionsBuilder();
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .padding(12)
        .width('100%');

        ListItem() {
          Row() {
            this.optionListItemBuilder($r('app.media.repeat'), '播放模式');

            this.repeatOptionBuilder();
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .padding(12)
        .width('100%');

        ListItem() {
          Row() {
            this.optionListItemBuilder($r('app.media.share'), '系统分享');
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .padding(12)
        .width('100%')
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.videoPlayerVM.shareVideo(context);
          this.getDialogController().close();
        });

        ListItem() {
          Row() {
            this.optionListItemBuilder($r('app.media.timer'), '定时关闭');
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .padding(12)
        .width('100%')
        .onClick(() => {
          this.controller = new CustomDialogController({
            width: '100%',
            height: '15%',
            alignment: DialogAlignment.Bottom,
            cornerRadius: { topLeft: 24, topRight: 24 },
            builder: ShutdownDialog({ videoPlayerVM: this.videoPlayerVM }),
          });
          this.controller.open();
        });

        ListItem() {
          Row() {
            this.optionListItemBuilder($r('app.media.headphones_fill'), '后台听视频');

            Toggle({ type: ToggleType.Switch, isOn: $$this.videoPlayerVM.isListenVideoBackground })
              .selectedColor('#FF007DFF')
              .switchPointColor(Color.White)
              .onChange((isOn: boolean) => {
                this.videoPlayerVM.setListenVideoBG(isOn);
              });
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .padding(12)
        .width('100%');
      }
      .width('100%')
      .borderRadius(8)
      .scrollBar(BarState.Off)
      .divider({
        startMargin: 50,
        strokeWidth: 0.5,
        color: $r('sys.color.comp_divider'),
      });
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}