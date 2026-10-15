import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioItemViewModelList } from '../viewmodel/AudioListViewModel';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { LengthMetrics } from '@kit.ArkUI';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';

@CustomDialog
export struct CurrentPlaylistView {
  public controller: CustomDialogController;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Text('当前播放列表')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'));

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.xmark'))
            .width(20)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .padding(6)
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .onClick(() => {
          this.controller.close();
        });
      }
      .width('100%')
      .layoutWeight(0)
      .margin({ bottom: 16 })
      .justifyContent(FlexAlign.SpaceBetween);

      ListView({ audioList: this.audioPlayerVM.audioList })
        .layoutWeight(1);
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}

@Component
struct ListView {
  @ObjectLink audioList: AudioItemViewModelList;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  @Builder
  audioItemBuilder(audioItem: AudioItemViewModel, index: number) {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
      space: { main: LengthMetrics.vp(16) }
    }) {
      Stack() {
        Text(this.audioList.length.toString())
          .fontSize(16)
          .fontColor(Color.Transparent);

        Text(index.toString())
          .fontSize(16)
          .fontColor(
            this.audioPlayerVM.currAudioItem === audioItem ?
              $r('sys.color.font_emphasize') :
              $r('sys.color.font_tertiary')
          );
      }
      .layoutWeight(0);

      Row() {
        Text(audioItem.title)
          .fontSize(14)
          .fontColor(
            this.audioPlayerVM.currAudioItem === audioItem ?
              $r('sys.color.font_emphasize') :
              $r('sys.color.font_primary')
          );
        Text(' · ')
          .fontSize(14)
          .fontColor(
            this.audioPlayerVM.currAudioItem === audioItem ?
              $r('sys.color.font_emphasize') :
              $r('sys.color.font_primary')
          );
        Text(audioItem.artist)
          .fontSize(14)
          .fontColor(
            this.audioPlayerVM.currAudioItem === audioItem ?
              $r('sys.color.font_emphasize') :
              $r('sys.color.font_primary')
          );
      }
      .height('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .borderColor($r('sys.color.comp_divider'))
      .borderWidth({ bottom: this.audioList.length === index ? 0 : 1 });
    }
    .height(50)
    .width('100%')
    .padding({ left: 8, right: 8 });
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        ForEach(
          this.audioList,
          (audioItem: AudioItemViewModel, index: number) => {
            ListItem() {
              this.audioItemBuilder(audioItem, index + 1);
            }
            .onClick(() => {
              const context = this.getUIContext().getHostContext() as Context;
              this.audioPlayerVM.setAudioAsset(audioItem.audioInfo, context);
              this.audioPlayerVM.currAudioItem = audioItem;
            });
          }
        );
      }
      .width('100%')
      .borderRadius(12)
      .contentEndOffset(8)
      .contentStartOffset(8)
      .scrollBar(BarState.Off);
    }
    .width('100%');
  }
}