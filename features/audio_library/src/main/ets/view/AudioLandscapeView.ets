import { common } from '@kit.AbilityKit';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { window } from '@kit.ArkUI';
import { AudioLyricsView } from './AudioLyricsView';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Builder
export function AudioLandscapeBuilder() {
  AudioLandscapeView();
}

@Component
struct AudioLandscapeView {
  @State isTopBarShow: boolean = false;
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private mainPathStack: NavPathStack = new NavPathStack();

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
      Stack({ alignContent: Alignment.TopStart }) {
        Row() {
          Column() {
            Row() {
              if (this.audioPlayerVM.currAudioItem && this.audioPlayerVM.currAudioItem.albumCover) {
                Image(this.audioPlayerVM.currAudioItem.albumCover)
                  .width('90%')
                  .aspectRatio(1)
                  .borderRadius(8)
                  .draggable(false)
                  .objectFit(ImageFit.Cover);
              } else {
                Image($r('app.media.audio_default'))
                  .width('90%')
                  .aspectRatio(1)
                  .borderRadius(12)
                  .draggable(false)
                  .objectFit(ImageFit.Cover);
              }
            }
            .aspectRatio(1)
            .layoutWeight(1)
            .borderRadius(8)
            .alignItems(VerticalAlign.Top)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Color.Transparent);

            Row() {
              Slider({
                min: 0,
                max: this.audioPlayerVM.duration,
                value: this.audioPlayerVM.currTime,
                style: SliderStyle.NONE,
              })
                .height(24)
                .width('100%')
                .selectedColor($r('sys.color.font_primary'))
                .trackColor($r('sys.color.progress_track_color'))
                .trackThickness(this.audioPlayerVM.isSeeking ? 6 : 3)
                .onChange(async (value: number, mode: SliderChangeMode) => {
                  if (mode === SliderChangeMode.Begin) {
                    this.audioPlayerVM.isSeeking = true;
                  } else if (mode === SliderChangeMode.Moving) {
                    this.audioPlayerVM.currTime = value;
                  } else if (mode === SliderChangeMode.End) {
                    this.audioPlayerVM.seek(value);
                  }
                });
            }
            .width('100%')
            .height('20%')
            .layoutWeight(0)
            .justifyContent(FlexAlign.Start)
            .alignItems(VerticalAlign.Center);
          }
          .width('50%')
          .height('100%')
          .padding({ left: 32, right: 32 })
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);

          Column() {
            Row() {
              AudioLyricsView();
            }
            .width('100%')
            .layoutWeight(1)
            .alignItems(VerticalAlign.Top)
            .justifyContent(FlexAlign.Start);


            Row() {
              Text(this.timeStr(this.audioPlayerVM.currTime) + '/' + this.timeStr(this.audioPlayerVM.duration))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.font_tertiary'));

              Row() {
                Button({ type: ButtonType.Circle, stateEffect: false }) {
                  Image($r('app.media.backward_end_fill'))
                    .width(36)
                    .aspectRatio(1)
                    .fillColor($r('sys.color.font_primary'));
                }
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  const context = this.getUIContext().getHostContext() as Context;
                  this.audioPlayerVM.switchPrev(context);
                });

                Button({ type: ButtonType.Circle, stateEffect: false }) {
                  Image(this.audioPlayerVM.isPlaying ? $r('app.media.pause') : $r('app.media.play'))
                    .width(36)
                    .aspectRatio(1)
                    .fillColor($r('sys.color.font_primary'));
                }
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  if (this.audioPlayerVM.isPlaying) {
                    await this.audioPlayerVM.pause();
                  } else {
                    const context = this.getUIContext().getHostContext() as Context;
                    await this.audioPlayerVM.play(context);
                  }
                });

                Button({ type: ButtonType.Circle, stateEffect: false }) {
                  Image($r('app.media.forward_end_fill'))
                    .width(36)
                    .aspectRatio(1)
                    .fillColor($r('sys.color.font_primary'));
                }
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  const context = this.getUIContext().getHostContext() as Context;
                  this.audioPlayerVM.switchNext(context);
                });
              }
              .width('50%')
              .height('100%')
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.SpaceAround);

              Button({ type: ButtonType.Circle, stateEffect: false }) {
                Image(this.audioPlayerVM.isFavorite ? $r('app.media.heart_fill') : $r('app.media.heart'))
                  .width(28)
                  .aspectRatio(1)
                  .fillColor(
                    this.audioPlayerVM.isFavorite ?
                      $r('sys.color.font_primary') :
                      $r('sys.color.font_tertiary')
                  );
              }
              .backgroundColor(Color.Transparent)
              .onClick(async () => {
                await this.audioPlayerVM.toggleFavorite();
              });
            }
            .width('100%')
            .height('20%')
            .layoutWeight(0)
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween);
          }
          .width('50%')
          .height('100%')
          .padding({ right: 32 })
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start);
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Top)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          top: this.getUIContext().px2vp(this.topRectHeight),
          bottom: this.getUIContext().px2vp(this.bottomRectHeight)
        });

        Row() {
          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.back'))
              .width(20)
              .aspectRatio(1)
              .fillColor($r('sys.color.font_primary'));
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.mainPathStack.pop();
          });
        }
        .padding({
          top: 16,
          left: 32,
          right: 32,
          bottom: 16,
        })
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .visibility(this.isTopBarShow ? Visibility.Visible : Visibility.Hidden)
        .backgroundColor($r('sys.color.segment_button_v2_tab_button_background'));
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.isTopBarShow = !this.isTopBarShow;
      });
    }
    .hideBackButton(true)
    .onReady((navContext: NavDestinationContext) => {
      this.mainPathStack = navContext.pathStack;
    })
    .onWillDisappear(() => {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.audioPlayerVM.setWindowOrientation(context, window.Orientation.PORTRAIT);
    });
  }
}