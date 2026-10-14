import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { LengthMetrics } from '@kit.ArkUI';
import { ViewOptionValue } from 'data_storage';
import { VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { MovingToDialog } from './MovingToDialog';
import { RenameDialog } from './RenameDialog';

const MULTI_CHOICE = 'MultiChoice';
const CHOICE_COUNT = 'ChoiceCount';
const VIDEO_VIEW_OPTION = 'VideoViewOption';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct VideoBoxView {
  @Link videoListVM: VideoListViewModel;
  @ObjectLink videoItem: VideoItemViewModel;
  @Consume(CHOICE_COUNT) choiceCount: number = 0;
  @Consume(MULTI_CHOICE) multiChoice: boolean = false;
  @Consume(VIDEO_VIEW_OPTION) videoViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;
  public isAllChoice: Callback<void> = () => {
  };
  private moveDialogController?: CustomDialogController;
  private optionsMenu: MenuElement[] = [
    {
      value: '重命名',
      action: () => {
        this.moveDialogController = new CustomDialogController({
          width: '90%',
          alignment: DialogAlignment.Center,
          offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) },
          builder: RenameDialog({ videoListVM: this.videoListVM, info: this.videoItem.videoInfo }),
        });
        this.moveDialogController.open();
      }
    },
    {
      value: '移动',
      action: () => {
        this.moveDialogController = new CustomDialogController({
          width: '100%',
          height: '60%',
          alignment: DialogAlignment.Bottom,
          offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) },
          builder: MovingToDialog({ origFolder: this.videoListVM.folder, moveVideoList: [this.videoItem.videoInfo] }),
        });
        this.moveDialogController.open();
      }
    },
    {
      value: '删除',
      action: () => {
        this.videoListVM.deleteVideo(this.videoItem.videoInfo);
      }
    }
  ];

  build() {
    if (this.videoViewOptions === ViewOptionValue.LIST_VIEW) {
      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Start,
        space: { main: LengthMetrics.vp(12) }
      }) {
        Image(this.videoItem.previewImg)
          .height('90%')
          .layoutWeight(0)
          .borderRadius(12)
          .draggable(false)
          .aspectRatio(16 / 9)
          .objectFit(ImageFit.Cover);

        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween,
        }) {
          Column() {
            Text(this.videoItem.videoName)
              .maxLines(2)
              .fontSize(14)
              .fontColor($r('sys.color.font_primary'))
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Row({ space: 12 }) {
              Row({ space: 3 }) {
                Image($r('app.media.clock'))
                  .width(14)
                  .aspectRatio(1)
                  .draggable(false)
                  .fillColor($r('sys.color.font_tertiary'));

                Text(this.videoItem.duration)
                  .fontSize(12)
                  .fontColor($r('sys.color.font_tertiary'));
              };

              Row({ space: 3 }) {
                Image($r('app.media.save'))
                  .width(14)
                  .aspectRatio(1)
                  .draggable(false)
                  .fillColor($r('sys.color.font_tertiary'));

                Text(this.videoItem.videoSize)
                  .fontSize(12)
                  .fontColor($r('sys.color.font_tertiary'));
              };
            }
            .justifyContent(FlexAlign.Start);
          }
          .height('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.SpaceAround);

          if (this.multiChoice) {
            Column() {
              Checkbox()
                .width(18)
                .aspectRatio(1)
                .select($$this.videoItem.isChoice)
                .onDisAppear(() => {
                  // delay some time for getting choice item
                  setTimeout(() => {
                    this.videoItem.isChoice = false;
                  }, 200);
                })
                .onChange((value: boolean) => {
                  this.choiceCount += value ? 1 : -1;
                  this.isAllChoice();
                });
            }
            .height('100%')
            .layoutWeight(0)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
          }
        }
        .layoutWeight(1);
      }
      .padding(8)
      .height(100)
      .width('100%')
      .borderRadius(12)
      .backgroundColor($r('sys.color.comp_background_list_card'));
    } else {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Start,
      }) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Image(this.videoItem.previewImg)
            .width('100%')
            .layoutWeight(0)
            .draggable(false)
            .aspectRatio(16 / 9)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: 12, topRight: 12 });

          if (this.multiChoice) {
            Checkbox()
              .width(18)
              .aspectRatio(1)
              .select($$this.videoItem.isChoice)
              .onDisAppear(() => {
                // delay some time for getting choice item
                setTimeout(() => {
                  this.videoItem.isChoice = false;
                }, 200);
              })
              .onChange((value: boolean) => {
                this.choiceCount += value ? 1 : -1;
                this.isAllChoice();
              });
          }
        };

        Column() {
          Row() {
            Text(this.videoItem.videoName)
              .maxLines(2)
              .fontSize(12)
              .fontColor($r('sys.color.font_primary'))
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .width('100%')
          .justifyContent(FlexAlign.Start);

          Row({ space: 12 }) {
            Text(this.videoItem.duration)
              .fontSize(10)
              .fontColor($r('sys.color.font_tertiary'));

            Text(this.videoItem.videoSize)
              .fontSize(10)
              .fontColor($r('sys.color.font_tertiary'));

            Blank();

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.dot_grid_1x2'))
                .width(12)
                .aspectRatio(1)
                .draggable(false)
                .fillColor($r('sys.color.font_tertiary'));
            }
            .width(16)
            .aspectRatio(1)
            .bindMenu(this.optionsMenu)
            .backgroundColor(Color.Transparent);
          }
          .width('100%')
          .justifyContent(FlexAlign.Start);
        }
        .padding(8)
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceBetween);
      }
      .height(160)
      .width('100%')
      .borderRadius(12)
      .backgroundColor($r('sys.color.comp_background_list_card'));
    }
  }
}