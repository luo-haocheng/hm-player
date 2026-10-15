import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioItemViewModelList } from '../viewmodel/AudioListViewModel';
import { LengthMetrics } from '@kit.ArkUI';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { AudioLibraryStore } from 'data_storage';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';

@CustomDialog
export struct AlbumDialog {
  @Require album: string | null;
  @State audioList: AudioItemViewModelList = new AudioItemViewModelList();
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private controller: CustomDialogController;
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.audioStore.initStore(context);

    const audioInfoList = await this.audioStore.selectAudioByAlbum(this.album);
    for (let i = 0; i < audioInfoList.length; ++i) {
      let audioItem = new AudioItemViewModel();
      audioItem.updateAudioItem(audioInfoList[i]);
      this.audioList.push(audioItem);
    }
  }

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
            this.audioPlayerVM.currAudioItem?.id === audioItem.id ?
              $r('sys.color.font_emphasize') :
              $r('sys.color.font_tertiary')
          );
      }
      .layoutWeight(0);

      Row() {
        Text(audioItem.title)
          .fontSize(14)
          .fontColor(
            this.audioPlayerVM.currAudioItem?.id === audioItem.id ?
              $r('sys.color.font_emphasize') :
              $r('sys.color.font_primary')
          );
        Text(' · ')
          .fontSize(14)
          .fontColor(
            this.audioPlayerVM.currAudioItem?.id === audioItem.id ?
              $r('sys.color.font_emphasize') :
              $r('sys.color.font_primary')
          );
        Text(audioItem.artist)
          .fontSize(14)
          .fontColor(
            this.audioPlayerVM.currAudioItem?.id === audioItem.id ?
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
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Text(this.album ?? '未知专辑')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'));
      }
      .width('100%')
      .layoutWeight(0)
      .margin({ bottom: 16 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center);

      Column() {
        List() {
          ForEach(
            this.audioList,
            (audioItem: AudioItemViewModel, index: number) => {
              ListItem() {
                this.audioItemBuilder(audioItem, index + 1);
              }
              .onClick(async () => {
                const context = this.getUIContext().getHostContext() as Context;
                await this.audioPlayerVM.init(context);
                this.audioPlayerVM.updatePlaylist(this.audioList, audioItem);
                await this.audioPlayerVM.setAudioAsset(audioItem.audioInfo, context);
              });
            }
          );
        }
        .width('100%')
        .borderRadius(8)
        .contentEndOffset(8)
        .contentStartOffset(8)
        .scrollBar(BarState.Off);
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center);
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}