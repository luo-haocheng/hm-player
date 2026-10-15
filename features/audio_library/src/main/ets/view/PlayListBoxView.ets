import { LengthMetrics } from '@kit.ArkUI';
import { ViewOptionValue } from 'data_storage';
import { PlayListItemViewModel } from '../viewmodel/PlayListItemViewModel';

const AUDIO_VIEW_OPTION = 'AudioViewOption';

@Component
export struct PlayListBoxView {
  @ObjectLink playlistVM: PlayListItemViewModel;
  @Consume(AUDIO_VIEW_OPTION) audioViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;

  build() {
    if (this.audioViewOptions === ViewOptionValue.LIST_VIEW) {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center,
        space: { main: LengthMetrics.vp(12) }
      }) {
        Row() {
          if (this.playlistVM.albumCover) {
            Image(this.playlistVM.albumCover)
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
        .height('90%')
        .aspectRatio(1)
        .layoutWeight(0)
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center);

        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween,
        }) {
          Column() {
            Text(this.playlistVM.playListName)
              .maxLines(1)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Text(`${this.playlistVM.playListCount}个内容`)
              .fontSize(12)
              .fontColor($r('sys.color.font_tertiary'));
          }
          .height('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.SpaceAround);
        }
        .layoutWeight(1);
      }
      .padding(8)
      .height(80)
      .width('100%')
      .borderRadius(12)
      .backgroundColor($r('sys.color.comp_background_list_card'));
    } else {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center,
        space: { main: LengthMetrics.vp(12) }
      }) {
        Row() {
          if (this.playlistVM.albumCover) {
            Image(this.playlistVM.albumCover)
              .width('100%')
              .height('100%')
              .draggable(false)
              .objectFit(ImageFit.Cover)
              .borderRadius({ topLeft: 12, topRight: 12 });

          } else {
            Image($r('app.media.audio_default'))
              .width('100%')
              .height('100%')
              .draggable(false)
              .objectFit(ImageFit.Cover)
              .borderRadius({ topLeft: 12, topRight: 12 });

          }
        }
        .width('100%')
        .aspectRatio(1)
        .layoutWeight(0)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius({ topLeft: 12, topRight: 12 });


        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween,
        }) {
          Column() {
            Text(this.playlistVM.playListName)
              .maxLines(1)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Text(`${this.playlistVM.playListCount}个内容`)
              .fontSize(12)
              .fontColor($r('sys.color.font_tertiary'));
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.SpaceAround);
        }
        .layoutWeight(1);
      }
      .height(240)
      .width('100%')
      .borderRadius(12)
      .padding({ bottom: 8 })
      .backgroundColor($r('sys.color.comp_background_list_card'));
    }
  }
}