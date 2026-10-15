import { AddToPlaylistDialog } from './AddToPlaylistDialog';
import { AlbumDialog } from './AlbumDialog';
import { ArtistDialog } from './ArtistDialog';
import { common } from '@kit.AbilityKit';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { media } from '@kit.MediaKit';
import { ShutdownDialog } from './ShutdownDialog';
import { window } from '@kit.ArkUI';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const MAIN_PAGE_STACK = 'MainPageStack';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

const PLAYBACK_SPEED_MAP: Map<media.PlaybackSpeed, string> = new Map([
  [media.PlaybackSpeed.SPEED_FORWARD_0_50_X, '0.5'],
  [media.PlaybackSpeed.SPEED_FORWARD_0_75_X, '0.75'],
  [media.PlaybackSpeed.SPEED_FORWARD_1_00_X, '1'],
  [media.PlaybackSpeed.SPEED_FORWARD_1_25_X, '1.25'],
  [media.PlaybackSpeed.SPEED_FORWARD_1_50_X, '1.50'],
  [media.PlaybackSpeed.SPEED_FORWARD_2_00_X, '2'],
]);

@CustomDialog
export struct AudioOptionsDialog {
  @Consume(MAIN_PAGE_STACK) mainPageStack: NavPathStack = new NavPathStack();
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private controller: CustomDialogController;
  private speedListScroller: Scroller = new Scroller();

  @Builder
  optionItemBuilder(icon: Resource, text: string) {
    Row({ space: 12 }) {
      Image(icon)
        .width(24)
        .aspectRatio(1)
        .fillColor($r('sys.color.font_primary'));

      Text(text)
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'));
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
    .padding({
      top: 12,
      left: 8,
      right: 8,
      bottom: 12
    });
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
                this.audioPlayerVM.playbackSpeed === entry[0] ?
                  $r('sys.color.font_emphasize') :
                  $r('sys.color.font_tertiary')
              );
          }
          .width(40)
          .onClick(() => {
            this.audioPlayerVM.setSpeed(entry[0]);
            this.audioPlayerVM.playbackSpeed = entry[0];
          });
        },
      );
    }
    .width('50%')
    .scrollBar(BarState.Off)
    .listDirection(Axis.Horizontal)
    .divider({ strokeWidth: 0.5, color: $r('sys.color.comp_divider') })
    .onAppear(() => {
      const speedIdx = Array.from(PLAYBACK_SPEED_MAP.keys()).findIndex((playbackSpeed: media.PlaybackSpeed) => {
        return this.audioPlayerVM.playbackSpeed === playbackSpeed;
      });
      if (speedIdx !== -1) {
        this.speedListScroller.scrollToIndex(speedIdx, false, ScrollAlign.CENTER);
      }
    });
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        if (this.audioPlayerVM.currAudioItem && this.audioPlayerVM.currAudioItem.albumCover) {
          Image(this.audioPlayerVM.currAudioItem.albumCover)
            .width(48)
            .aspectRatio(1)
            .borderRadius(8);
        } else {
          Image($r('app.media.audio_default'))
            .width(48)
            .aspectRatio(1)
            .borderRadius(8);
        }

        Text(this.audioPlayerVM.currAudioItem?.title)
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));
      }
      .width('100%')
      .layoutWeight(0)
      .margin({ bottom: 16 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center);

      List() {
        ListItem() {
          Row() {
            this.optionItemBuilder($r('app.media.portrait'), `歌手:  ${this.audioPlayerVM.currAudioItem?.artist}`);
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%')
        .onClick(() => {
          this.controller.close();

          if (this.audioPlayerVM.currAudioItem) {
            this.controller = new CustomDialogController({
              width: '100%',
              height: '60%',
              alignment: DialogAlignment.Bottom,
              builder: ArtistDialog({ artist: this.audioPlayerVM.currAudioItem.audioInfo.artist }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.controller.open();
          }
        });

        ListItem() {
          Row() {
            this.optionItemBuilder($r('app.media.record_circle'), `专辑:  ${this.audioPlayerVM.currAudioItem?.album}`);
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%')
        .onClick(() => {
          this.controller.close();

          if (this.audioPlayerVM.currAudioItem) {
            this.controller = new CustomDialogController({
              width: '100%',
              height: '60%',
              alignment: DialogAlignment.Bottom,
              builder: AlbumDialog({ album: this.audioPlayerVM.currAudioItem.audioInfo.album }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.controller.open();
          }
        });

        ListItem() {
          Row() {
            this.optionItemBuilder($r('app.media.plus_square'), '添加到歌单');
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%')
        .onClick(() => {
          this.controller.close();

          if (this.audioPlayerVM.currAudioItem) {
            this.controller = new CustomDialogController({
              width: '100%',
              height: '60%',
              alignment: DialogAlignment.Bottom,
              builder: AddToPlaylistDialog({ audioInfoList: [this.audioPlayerVM.currAudioItem.audioInfo] }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.controller.open();
          }
        });

        ListItem() {
          Row() {
            this.optionItemBuilder($r('app.media.rectangle_rotate'), '横屏模式');
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%')
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.audioPlayerVM.setWindowOrientation(context, window.Orientation.LANDSCAPE);
          this.mainPageStack.pushPath({ name: 'AudioLandscape' });
          this.controller.close();
        });

        ListItem() {
          Row() {
            this.optionItemBuilder($r('app.media.share'), '系统分享');
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%')
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.audioPlayerVM.shareAudio(context);
          this.controller.close();
        });

        ListItem() {
          Row() {
            this.optionItemBuilder($r('app.media.timer'), '定时关闭');
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%')
        .onClick(() => {
          this.controller = new CustomDialogController({
            width: '100%',
            height: '15%',
            alignment: DialogAlignment.Bottom,
            cornerRadius: { topLeft: 24, topRight: 24 },
            offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) },
            builder: ShutdownDialog({ audioPlayerVM: this.audioPlayerVM }),
          });
          this.controller.open();
        });

        ListItem() {
          Row() {
            this.optionItemBuilder($r('app.media.fast_forward'), '播放倍速');

            this.speedOptionsBuilder();
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%');
      }
      .width('100%')
      .layoutWeight(1)
      .contentEndOffset(8)
      .contentStartOffset(8)
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, startMargin: 46, color: $r('sys.color.comp_divider') });

    }
    .padding(16)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}