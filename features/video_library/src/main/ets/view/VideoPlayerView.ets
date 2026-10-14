import { VideoPlayerViewModel } from '../viewmodel/VideoPlayerViewModel';
import { common, Context } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { media } from '@kit.MediaKit';
import { AVVolumePanel } from '@kit.AudioKit';
import { VideoOptionsDialog } from './VideoOptionsDialog';
import { AVCastPicker } from '@kit.AVSessionKit';

@Builder
export function VideoPlayerBuilder() {
  VideoPlayerView();
}

const MAX_VOLUME_LEVEL = 15;
const MAX_WINDOW_BRIGHTNESS = 1.0;
const VIDEO_PLAYER_VM = 'VideoPlayerVM';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct VideoPlayerView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Consume(VIDEO_PLAYER_VM) videoPlayerVM: VideoPlayerViewModel;
  private mainPathStack: NavPathStack = new NavPathStack();
  private videoOptionsDialogCtrl?: CustomDialogController;

  private timeStr(timeMs: number): string {
    let helper = (num: number): string => {
      return num >= 10 ? `${num}` : `0${num}`;
    };
    let timeSS = Math.floor(timeMs / 1000);
    let seconds = timeSS % 60;
    let minutes = Math.floor(timeSS / 60) % 60;
    let hours = Math.floor(timeSS / 3600);
    if (hours > 0) {
      return `${hours}:${helper(minutes)}:${helper(seconds)}`;
    } else {
      return `${helper(minutes)}:${helper(seconds)}`;
    }
  }

  build() {
    NavDestination() {
      Stack() {
        XComponent({
          type: XComponentType.SURFACE,
          controller: this.videoPlayerVM.xComponentCtrl,
        })
          .width('100%')
          .height('100%')
          .renderFit(RenderFit.RESIZE_CONTAIN)
          .onLoad(async () => {
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const surfaceId = this.videoPlayerVM.xComponentCtrl.getXComponentSurfaceId();
            await this.videoPlayerVM.initPlayer(surfaceId, context);
            await this.videoPlayerVM.setVideoAsset(context);
          });

        AVVolumePanel({
          volumeLevel: this.videoPlayerVM.volumeLevel,
          volumeParameter: {
            position: { x: -100, y: 0 }
          }
        });

        Column() {
          if (this.videoPlayerVM.isSeeking) {
            Row() {
              Text(`${this.timeStr(this.videoPlayerVM.currTime)} / ${this.timeStr(this.videoPlayerVM.duration)}`)
                .fontSize(12)
                .fontColor(Color.White);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#66000000')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center);
          } else if (this.videoPlayerVM.isControlVolume) {
            Row({ space: 6 }) {
              Image(this.videoPlayerVM.volumeLevel === 0 ? $r('app.media.speaker_wave_slash') :
                $r('app.media.speaker_wave'))
                .width(20)
                .aspectRatio(1)
                .fillColor(Color.White);

              Slider({
                min: 0,
                max: MAX_VOLUME_LEVEL,
                value: this.videoPlayerVM.volumeLevel,
                style: SliderStyle.NONE,
              })
                .width(100)
                .height(24)
                .trackThickness(2)
                .selectedColor(Color.White);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#66000000')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center);
          } else if (this.videoPlayerVM.isControlBrightness) {
            Row({ space: 6 }) {
              Image($r('app.media.sun_max'))
                .width(20)
                .aspectRatio(1)
                .fillColor(Color.White);

              Slider({
                min: 0,
                max: MAX_WINDOW_BRIGHTNESS,
                value: this.videoPlayerVM.brightness,
                style: SliderStyle.NONE,
              })
                .width(100)
                .height(24)
                .trackThickness(2)
                .selectedColor(Color.White);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#66000000')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center);
          } else if (this.videoPlayerVM.isPlaying && this.videoPlayerVM.isSpeeding) {
            Row({ space: 2 }) {
              Image($r('app.media.fast_forward'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.White);
              Text('倍速播放中')
                .fontSize(12)
                .fontColor(Color.White);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#66000000')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .margin({ top: this.videoPlayerVM.isLandscape ? 16 : this.getUIContext().px2vp(this.topRectHeight) });
          }
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(this.videoPlayerVM.isSpeeding ? FlexAlign.Start : FlexAlign.Center);

        Column() {
          Row() {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.back'))
                .width(20)
                .aspectRatio(1)
                .fillColor(Color.White);
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.mainPathStack.pop();
              this.videoPlayerVM.release();
            });

            Row({ space: 16 }) {
              AVCastPicker({
                normalColor: Color.White,
                sessionType: 'video'
              })
                .width(24)
                .aspectRatio(1);

              Button({ type: ButtonType.Circle, stateEffect: false }) {
                Image($r('app.media.arrow_right_up_and_square'))
                  .width(24)
                  .aspectRatio(1)
                  .fillColor(Color.White);
              }
              .backgroundColor(Color.Transparent)
              .onClick(async () => {
                const context = this.getUIContext().getHostContext() as Context;
                await this.videoPlayerVM.startPip(context);
                this.mainPathStack.pop();
              });

              Button({ type: ButtonType.Circle, stateEffect: false }) {
                Image($r('app.media.dot_grid_2x2'))
                  .width(28)
                  .aspectRatio(1)
                  .fillColor(Color.White);
              }
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                if (this.videoPlayerVM.isLandscape) {
                  this.videoOptionsDialogCtrl = new CustomDialogController({
                    width: '45%',
                    height: '100%',
                    alignment: DialogAlignment.TopEnd,
                    cornerRadius: { topLeft: 24, bottomLeft: 24 },
                    builder: VideoOptionsDialog({ videoPlayerVM: this.videoPlayerVM }),
                  });
                } else {
                  this.videoOptionsDialogCtrl = new CustomDialogController({
                    width: '100%',
                    height: '35%',
                    alignment: DialogAlignment.Bottom,
                    cornerRadius: { topLeft: 24, topRight: 24 },
                    builder: VideoOptionsDialog({ videoPlayerVM: this.videoPlayerVM }),
                  });
                }
                this.videoOptionsDialogCtrl.open();
              });
            };
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)
          .visibility(this.videoPlayerVM.isLocking ? Visibility.Hidden : Visibility.Visible);

          Column() {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image(this.videoPlayerVM.isLocking ? $r('app.media.lock') : $r('app.media.lock_open'))
                .width(20)
                .aspectRatio(1)
                .fillColor(Color.White);
            }
            .padding(8)
            .backgroundColor($r('sys.color.button_background_color_transparent'))
            .onClick(() => {
              this.videoPlayerVM.isLocking = !this.videoPlayerVM.isLocking;
            });
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.End)
          .justifyContent(FlexAlign.Center);

          Column({ space: 12 }) {
            Column({ space: 3 }) {
              Row() {
                Text(`${this.timeStr(this.videoPlayerVM.currTime)} / ${this.timeStr(this.videoPlayerVM.duration)}`)
                  .fontSize(10)
                  .fontColor(Color.White);
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
              .padding({ left: 6, right: 6 });

              Slider({
                min: 0,
                max: this.videoPlayerVM.duration,
                value: this.videoPlayerVM.currTime,
                style: SliderStyle.OutSet,
              })
                .height(8)
                .width('100%')
                .trackColor('#33FFFFFF')
                .blockSize({ width: 12, height: 12 })
                .trackThickness(this.videoPlayerVM.isSeeking ? 8 : 5)
                .selectedColor(this.videoPlayerVM.isSeeking ? Color.White : Color.Gray)
                .onChange((value: number, mode: SliderChangeMode) => {
                  if (mode === SliderChangeMode.Begin) {
                    this.videoPlayerVM.isSeeking = true;
                  } else if (mode === SliderChangeMode.Moving) {
                    this.videoPlayerVM.currTime = value;
                  } else {
                    this.videoPlayerVM.seek(value);
                  }
                });
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start);

            Row() {
              Row({ space: 12 }) {
                Button({ type: ButtonType.Circle, stateEffect: false }) {
                  Image(this.videoPlayerVM.isPlaying ? $r('app.media.pause') : $r('app.media.play'))
                    .width(30)
                    .aspectRatio(1)
                    .fillColor(Color.White);
                }
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  if (this.videoPlayerVM.isPlaying) {
                    await this.videoPlayerVM.pause();
                  } else {
                    const context = this.getUIContext().getHostContext() as Context;
                    await this.videoPlayerVM.play(context);
                  }
                });

                if (this.videoPlayerVM.videoList && this.videoPlayerVM.videoList.length > 1) {
                  Button({ type: ButtonType.Circle, stateEffect: false }) {
                    Image($r('app.media.forward_end_fill'))
                      .width(30)
                      .aspectRatio(1)
                      .fillColor(Color.White);
                  }
                  .backgroundColor(Color.Transparent)
                  .onClick(async () => {
                    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                    this.videoPlayerVM.switchNext(context);
                  });
                }
              };

              Button({ type: ButtonType.Circle, stateEffect: false }) {
                Image(
                  this.videoPlayerVM.isLandscape ?
                    $r('app.media.rectangle_rotate') :
                    $r('app.media.rectangle_portrait_rotate')
                )
                  .width(24)
                  .aspectRatio(1)
                  .fillColor(Color.White);
              }
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                if (this.videoPlayerVM.isLandscape) {
                  this.videoPlayerVM.setWindowOrientation(context, window.Orientation.PORTRAIT);
                } else {
                  this.videoPlayerVM.setWindowOrientation(context, window.Orientation.LANDSCAPE);
                }
              });
            }
            .width('100%')
            .padding({ left: 6, right: 6 })
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween);

          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .padding({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)
          .visibility(this.videoPlayerVM.isLocking ? Visibility.Hidden : Visibility.Visible);
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceBetween)
        .visibility(this.videoPlayerVM.isCtrlPanelShow ? Visibility.Visible : Visibility.Hidden)
        .padding({
          top: this.videoPlayerVM.isLandscape ? 16 : this.getUIContext().px2vp(this.topRectHeight),
          bottom: this.videoPlayerVM.isLandscape ? 16 : this.getUIContext().px2vp(this.bottomRectHeight),
        });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .onClick(() => {
        this.videoPlayerVM.setControlPanelShow();
      })
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          LongPressGesture({ repeat: false })
            .onAction(() => {
              this.videoPlayerVM.isSpeeding = true;
              this.videoPlayerVM.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_3_00_X);
            })
            .onActionEnd(() => {
              this.videoPlayerVM.isSpeeding = false;
              this.videoPlayerVM.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
            })
            .onActionCancel(() => {
              this.videoPlayerVM.isSpeeding = false;
              this.videoPlayerVM.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
            }),
          PanGesture({ direction: PanDirection.Horizontal, distance: 50 })
            .onActionStart(() => {
              if (!this.videoPlayerVM.isLocking) {
                this.videoPlayerVM.isSeeking = true;
                this.videoPlayerVM.startHorizontalSlide();
              }
            })
            .onActionUpdate((event: GestureEvent) => {
              if (event.offsetX > -50 && event.offsetX < 50) {
                console.error(`Error offsetX value when horizontal pan gesture: ${event.offsetX}`);
                return;
              }
              if (!this.videoPlayerVM.isLocking) {
                const offsetX = event.offsetX > 0 ? event.offsetX - 50 : event.offsetX + 50;
                this.videoPlayerVM.updateHorizontalSlide(offsetX);
              }
            })
            .onActionEnd(() => {
              if (!this.videoPlayerVM.isLocking) {
                this.videoPlayerVM.isSeeking = false;
                this.videoPlayerVM.endHorizontalSlide();
              }
            })
            .onActionCancel(() => {
              if (!this.videoPlayerVM.isLocking) {
                this.videoPlayerVM.isSeeking = false;
                this.videoPlayerVM.endHorizontalSlide();
              }
            }),
          PanGesture({ direction: PanDirection.Vertical, distance: 100 })
            .onActionStart((event: GestureEvent) => {
              if (event.fingerInfos && event.fingerInfos.length > 0) {
                const uiContext = this.getUIContext() as UIContext;
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                this.videoPlayerVM.startVerticalSlide(context, uiContext, event.fingerInfos[0].globalX);
              }
            })
            .onActionUpdate((event: GestureEvent) => {
              if (event.offsetY > -100 && event.offsetY < 100) {
                console.error(`Error offsetY value when vertical pan gesture: ${event.offsetY}`);
                return;
              }
              const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
              const offsetY = event.offsetY > 0 ? event.offsetY - 100 : event.offsetY + 100;
              this.videoPlayerVM.updateVerticalSlide(context, offsetY);
            })
            .onActionEnd(() => {
              this.videoPlayerVM.isControlVolume = false;
              this.videoPlayerVM.isControlBrightness = false;
            })
            .onActionCancel(() => {
              this.videoPlayerVM.isControlVolume = false;
              this.videoPlayerVM.isControlBrightness = false;
            })
        )
      );
    }
    .hideBackButton(true)
    .onBackPressed(() => {
      this.videoPlayerVM.release();
      return false;
    })
    .onWillAppear(() => {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.videoPlayerVM.setSystemBarEnable(context, false);
    })
    .onWillDisappear(() => {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.videoPlayerVM.setDefaultBrightness(context);
      this.videoPlayerVM.setSystemBarEnable(context, true);
      this.videoPlayerVM.setWindowOrientation(context, window.Orientation.PORTRAIT);
    })
    .onReady((navContext: NavDestinationContext) => {
      this.mainPathStack = navContext.pathStack;
    });
  }
}