import { AudioEditViewModel } from '../viewmodel/AudioEditViewModel';
import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';

@CustomDialog
export struct AudioEditDialog {
  @State audioEditVM: AudioEditViewModel = new AudioEditViewModel();
  public audioItem: AudioItemViewModel = new AudioItemViewModel();
  public scroller: Scroller = new Scroller();
  public controller: CustomDialogController;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as Context;
    this.audioEditVM.init(context, this.audioItem.audioInfo);
  }

  @Builder
  albumCoverMenuBuilder() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Text('替换')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        this.audioEditVM.selectAlbumCover();
      });

      Divider()
        .vertical(false)
        .strokeWidth(0.5);

      Row() {
        Text('删除')
          .fontSize(14)
          .fontColor(Color.Red);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        this.audioEditVM.deleteAlbumCover();
      });
    }
    .width(100)
    .padding({ left: 16, right: 16 });
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.xmark'))
            .width(20)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .padding(8)
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .onClick(() => {
          this.controller.close();
        });

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.checkmark'))
            .width(20)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .padding(8)
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .onClick(async () => {
          this.controller.close();
          const context = this.getUIContext().getHostContext() as Context;
          this.audioEditVM.submitEdit(context, this.audioItem);
        });
      }
      .width('100%')
      .layoutWeight(0)
      .margin({ bottom: 16 })
      .justifyContent(FlexAlign.SpaceBetween);

      Scroll(this.scroller) {
        Column({ space: 24 }) {
          Column({ space: 8 }) {
            Text('封面')
              .fontSize(14)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Bold);

            if (this.audioEditVM.albumCover) {
              Image(this.audioEditVM.albumCover)
                .width('50%')
                .aspectRatio(1)
                .borderRadius(12)
                .draggable(false)
                .objectFit(ImageFit.Cover)
                .bindMenu(this.albumCoverMenuBuilder());
            } else {
              Row() {
                Image($r('app.media.plus'))
                  .width('50%')
                  .aspectRatio(1)
                  .draggable(false)
                  .objectFit(ImageFit.Contain)
                  .fillColor($r('sys.color.font_emphasize'));
              }
              .width('50%')
              .aspectRatio(1)
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('sys.color.background_primary'))
              .onClick(() => {
                this.audioEditVM.selectAlbumCover();
              });
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start);

          Column() {
            Text('标题')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'));
            TextInput({ text: $$this.audioEditVM.title })
              .fontSize(14)
              .maxLength(100)
              .showUnderline(true)
              .placeholderFont({ size: 14 })
              .padding({ top: 8, bottom: 8 })
              .backgroundColor(Color.Transparent)
              .underlineColor($r('sys.color.gray_04'));
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start);

          Column() {
            Text('专辑')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'));
            TextInput({ text: $$this.audioEditVM.album })
              .fontSize(14)
              .maxLength(100)
              .showUnderline(true)
              .placeholderFont({ size: 14 })
              .padding({ top: 8, bottom: 8 })
              .backgroundColor(Color.Transparent)
              .underlineColor($r('sys.color.gray_04'));
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start);

          Column() {
            Text('歌手')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'));
            TextInput({ text: $$this.audioEditVM.artist })
              .fontSize(14)
              .maxLength(100)
              .showUnderline(true)
              .placeholderFont({ size: 14 })
              .padding({ top: 8, bottom: 8 })
              .backgroundColor(Color.Transparent)
              .underlineColor($r('sys.color.gray_04'));
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start);

          Column({ space: 8 }) {
            Text('歌词')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'));

            Stack({ alignContent: Alignment.TopEnd }) {
              TextArea({ text: $$this.audioEditVM.lyrics })
                .height('100%')
                .fontSize(14)
                .borderWidth('1px')
                .placeholderFont({ size: 14 })
                .backgroundColor(Color.Transparent)
                .borderColor($r('sys.color.gray_04'));

              Button({ type: ButtonType.Circle, stateEffect: false }) {
                Image($r('app.media.plus'))
                  .width(18)
                  .aspectRatio(1)
                  .fillColor($r('sys.color.font_primary'));
              }
              .padding(6)
              .offset({ x: -8, y: 8 })
              .backgroundColor($r('sys.color.button_background_color_transparent'))
              .onClick(() => {
                this.audioEditVM.selectLyricsFile();
              });
            }
            .width('100%')
            .height(200);
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start);
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Vertical);
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}