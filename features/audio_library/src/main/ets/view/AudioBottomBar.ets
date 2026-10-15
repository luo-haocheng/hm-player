import { LengthMetrics } from '@kit.ArkUI';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { CurrentPlaylistView } from './CurrentPlaylistView';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const MAIN_PAGE_STACK = 'MainPageStack';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct AudioBottomBar {
  @Consume(MAIN_PAGE_STACK) mainPageStack: NavPathStack = new NavPathStack();
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private currPlaylistDialogController?: CustomDialogController;

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceAround,
      space: { main: LengthMetrics.vp(12) }
    }) {
      Row() {
        if (this.audioPlayerVM.currAudioItem && this.audioPlayerVM.currAudioItem.albumCover) {
          Image(this.audioPlayerVM.currAudioItem.albumCover)
            .width('100%')
            .height('100%')
            .borderRadius(12)
            .draggable(false)
            .objectFit(ImageFit.Cover);
        } else {
          Image($r('app.media.audio_default'))
            .width('100%')
            .height('100%')
            .borderRadius(12)
            .draggable(false)
            .objectFit(ImageFit.Cover);
        }
      }
      .height('100%')
      .aspectRatio(1)
      .layoutWeight(0)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center);

      Column() {
        if (this.audioPlayerVM.currAudioItem) {
          Text(this.audioPlayerVM.currAudioItem.title)
            .maxLines(1)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(this.audioPlayerVM.currAudioItem.artist)
            .fontSize(10)
            .fontColor($r('sys.color.font_primary'));
        } else {
          Text('未在播放')
            .maxLines(1)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'));
        }
      }
      .height('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.SpaceAround);

      Row() {
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image(this.audioPlayerVM.isPlaying ? $r('app.media.pause') : $r('app.media.play'))
            .width(24)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .height('100%')
        .aspectRatio(1)
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
          Image($r('app.media.music_note_list'))
            .width(24)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .height('100%')
        .aspectRatio(1)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.audioPlayerVM.currAudioItem) {
            this.currPlaylistDialogController = new CustomDialogController({
              width: '100%',
              height: '60%',
              builder: CurrentPlaylistView(),
              alignment: DialogAlignment.Bottom,
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.currPlaylistDialogController.open();
          }
        });
      }
      .layoutWeight(0)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center);
    }
    .padding(8)
    .width('100%')
    .height('100%')
    .borderRadius('50%')
    .backgroundColor($r('sys.color.arc_scroll_bar_background_color'))
    .onClick(() => {
      if (this.audioPlayerVM.currAudioItem) {
        this.mainPageStack.pushPath({ name: 'AudioImmersive' });
      }
    });
  }
}