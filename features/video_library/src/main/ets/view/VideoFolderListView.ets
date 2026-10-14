import { FolderInfoModel } from 'data_storage/src/main/ets/rdbms/FolderInfoModel';
import { VideoInfoModel, ViewOptionValue } from 'data_storage';
import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';
import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { FolderItemViewModelList, VideoItemViewModelList, VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { FolderBoxView } from './FolderBoxView';
import { MovingToDialog } from './MovingToDialog';
import { RenameDialog } from './RenameDialog';
import { VideoBoxView } from './VideoBoxView';
import { VideoPlayerViewModel } from '../viewmodel/VideoPlayerViewModel';

const CHOICE_ALL = 'ChoiceAll';
const MULTI_CHOICE = 'MultiChoice';
const VIDEO_PLAYER_VM = 'VideoPlayerVM';
const MAIN_PAGE_STACK = 'MainPageStack';
const VIDEO_VIEW_OPTION = 'VideoViewOption';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct VideoFolderListView {
  @Consume(CHOICE_ALL) choiceAll: boolean = false;
  @Consume(MULTI_CHOICE) multiChoice: boolean = false;
  @Consume(MAIN_PAGE_STACK) mainPageStack: NavPathStack;
  @Consume(VIDEO_PLAYER_VM) videoPlayerVM: VideoPlayerViewModel;
  @Consume(VIDEO_VIEW_OPTION) videoViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @ObjectLink folderList: FolderItemViewModelList;
  @ObjectLink videoList: VideoItemViewModelList;
  @State invalidName: boolean = false;
  @Link videoListVM: VideoListViewModel;
  private moveDialogController?: CustomDialogController;
  private scroller: ListScroller = new ListScroller();
  private isAllChoice: Callback<void> = () => {
    const folderAllChoice = this.folderList.find((item: FolderItemViewModel) => {
      return !item.isChoice;
    });
    const videoAllChoice = this.videoList.find((item: VideoItemViewModel) => {
      return !item.isChoice;
    });
    this.choiceAll = (folderAllChoice !== undefined) || (videoAllChoice !== undefined);
  };

  @Builder
  folderSwipeEnd(info: FolderInfoModel) {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.rename'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Orange)
      .onClick(() => {
        this.moveDialogController = new CustomDialogController({
          width: '90%',
          alignment: DialogAlignment.Center,
          builder: RenameDialog({ videoListVM: this.videoListVM, info: info }),
          offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
        });
        this.moveDialogController.open();
        // Close swipe action
        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.arrow_right_folder_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Blue)
      .onClick(() => {
        this.moveDialogController = new CustomDialogController({
          width: '100%',
          height: '60%',
          alignment: DialogAlignment.Bottom,
          builder: MovingToDialog({ origFolder: this.videoListVM.folder, moveFolderList: [info] }),
          offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
        });
        this.moveDialogController.open();
        // Close swipe action
        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.trash_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.videoListVM.deleteFolder(info);
      });
    }
    .padding({ left: 8, right: 8 });
  }

  @Builder
  videoSwipeEnd(info: VideoInfoModel) {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.rename'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Orange)
      .onClick(() => {
        this.moveDialogController = new CustomDialogController({
          width: '90%',
          alignment: DialogAlignment.Center,
          builder: RenameDialog({ videoListVM: this.videoListVM, info: info }),
          offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
        });
        this.moveDialogController.open();
        // Close swipe action
        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.arrow_right_folder_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Blue)
      .onClick(() => {
        this.moveDialogController = new CustomDialogController({
          width: '100%',
          height: '60%',
          alignment: DialogAlignment.Bottom,
          builder: MovingToDialog({ origFolder: this.videoListVM.folder, moveVideoList: [info] }),
          offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
        });
        this.moveDialogController.open();
        // Close swipe action
        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.trash_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.videoListVM.deleteVideo(info);
      });
    }
    .padding({ left: 8, right: 8 });
  }

  build() {
    List({ scroller: this.scroller }) {
      ForEach(
        this.folderList,
        (item: FolderItemViewModel) => {
          ListItem() {
            FolderBoxView({
              folderItem: item,
              videoListVM: this.videoListVM,
              isAllChoice: () => {
                this.isAllChoice();
              }
            });
          }
          .swipeAction({
            end: {
              builder: () => {
                if (this.videoViewOptions === ViewOptionValue.LIST_VIEW) {
                  this.folderSwipeEnd(item.folderInfo);
                }
              }
            }
          });
        },
        (item: FolderItemViewModel, index: number) => {
          index;
          return item.folderInfo.id.toString();
        }
      );

      ForEach(
        this.videoList,
        (item: VideoItemViewModel) => {
          ListItem() {
            VideoBoxView({
              videoItem: item,
              videoListVM: this.videoListVM,
              isAllChoice: () => {
                this.isAllChoice();
              }
            });
          }
          .swipeAction({
            end: {
              builder: () => {
                if (this.videoViewOptions === ViewOptionValue.LIST_VIEW) {
                  this.videoSwipeEnd(item.videoInfo);
                }
              }
            }
          })
          .onClick(async () => {
            if (this.multiChoice) {
              item.isChoice = !item.isChoice;
            } else {
              await this.videoPlayerVM.stopPip();
              await this.videoPlayerVM.release();

              this.videoPlayerVM.currVideoItem = item;
              this.videoPlayerVM.videoList = this.videoList;

              setTimeout(() => {
                this.mainPageStack.pushPath({ name: 'VideoPlayer' });
              }, 300);
            }
          });
        },
        (item: VideoItemViewModel, index: number) => {
          index;
          return item.videoInfo.id.toString();
        }
      );
    }
    .width('100%')
    .height('100%')
    .contentEndOffset(8)
    .contentStartOffset(8)
    .scrollBar(BarState.Off)
    .divider({ strokeWidth: 8, color: $r('sys.color.background_secondary') })
    .lanes(this.videoViewOptions === ViewOptionValue.LIST_VIEW ? 1 : 2, 8);
  }
}