import { FolderBrowserViewModel } from '../viewmodel/FolderBrowserViewModel';
import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';
import { FolderItemViewModelList } from '../viewmodel/VideoListViewModel';
import { Context } from '@kit.AbilityKit';
import { FolderInfoModel } from 'data_storage/src/main/ets/rdbms/FolderInfoModel';
import { VideoInfoModel } from 'data_storage';

const ROOT_PATH = '/';
const SECRET_FOLDER = '/*/';

@Builder
export function FolderBrowserBuilder() {
  FolderBrowserView();
}

@Component
struct FolderBrowserView {
  @State folderList: FolderItemViewModelList = new FolderItemViewModelList();
  @Consume('MoveToFolder') moveToFolder: string = ROOT_PATH;
  @Consume('MoveNavPath') moveNavPath: NavPathStack = new NavPathStack();
  @Consume('FolderBrowserViewModel') folderBrowserVM: FolderBrowserViewModel = new FolderBrowserViewModel();
  private origFolder: string = ROOT_PATH;

  @Builder
  folderItemBuilder(folderItem: FolderItemViewModel) {
    Row({ space: 12 }) {
      Image($r('app.media.folder_fill'))
        .padding(8)
        .height('90%')
        .aspectRatio(1)
        .borderRadius(12)
        .draggable(false)
        .fillColor(Color.Orange)
        .objectFit(ImageFit.Contain)
        .backgroundColor($r('sys.color.background_tertiary'));

      Column() {
        Text(folderItem.folderName)
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'));

        Row({ space: 3 }) {
          Text('创建于 ')
            .fontSize(12)
            .fontColor($r('sys.color.font_tertiary'));

          Text(folderItem.dateAdd)
            .fontSize(12)
            .fontColor($r('sys.color.font_tertiary'));
        };
      }
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceAround);
    }
    .padding(8)
    .height(80)
    .width('100%')
    .borderRadius(12)
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center);
  }

  build() {
    NavDestination() {
      Column() {
        List() {
          ForEach(
            this.folderList,
            (item: FolderItemViewModel) => {
              ListItem() {
                this.folderItemBuilder(item);
              }
              .onClick(() => {
                this.moveNavPath.pushPath({ name: 'FolderBrowser', param: item.folderInfo.path }, false);
              });
            },
            (item: FolderItemViewModel, index: number) => {
              index;
              return item.folderInfo.id.toString();
            }
          );
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .divider({
          endMargin: 8,
          startMargin: 8,
          strokeWidth: 0.5,
          color: $r('sys.color.comp_divider')
        });
      };
    }
    .hideBackButton(true)
    .backgroundColor(Color.Transparent)
    .onReady(async (ctx: NavDestinationContext) => {
      if (ctx.pathInfo.param !== undefined) {
        this.origFolder = ctx.pathInfo.param as string;
      }
      let context = this.getUIContext().getHostContext() as Context;
      this.folderList = await this.folderBrowserVM.initFolderList(this.origFolder, context);
    })
    .onActive(() => {
      this.moveToFolder = this.origFolder;
    });
  }
}

@CustomDialog
export struct MovingToDialog {
  origFolder: string = ROOT_PATH;
  moveVideoList: VideoInfoModel[] = [];
  moveFolderList: FolderInfoModel[] = [];
  controller: CustomDialogController;
  @Provide('MoveToFolder') moveToFolder: string = ROOT_PATH;
  @Provide('MoveNavPath') moveNavPath: NavPathStack = new NavPathStack();
  @Provide('FolderBrowserViewModel') folderBrowserVM: FolderBrowserViewModel = new FolderBrowserViewModel();

  aboutToAppear(): void {
    this.moveToFolder = this.origFolder;
    this.folderBrowserVM.moveFolderList = this.moveFolderList;
    // this.moveNavPath.pushPath({ name: 'FolderBrowser', param: this.origFolder });
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.arrow_left'))
            .width(20)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .padding(8)
        .enabled(![ROOT_PATH, SECRET_FOLDER].includes(this.moveToFolder))
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .onClick(() => {
          if ([ROOT_PATH, SECRET_FOLDER].includes(this.moveToFolder)) {
            return;
          }
          if (this.moveNavPath.size() > 1) {
            this.moveNavPath.pop();
          } else {
            // Get Parent Path
            const lastSecondSlashIdx = this.moveToFolder.lastIndexOf('/', this.moveToFolder.length - 2);
            const parentPath = this.moveToFolder.slice(0, lastSecondSlashIdx + 1);
            // Replace nav stack to parent path
            this.moveNavPath.replacePath({ name: 'FolderBrowser', param: parentPath });
          }
        });

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.checkmark'))
            .width(20)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .padding(8)
        .enabled(this.moveToFolder !== this.origFolder)
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .onClick(async () => {
          if (this.moveToFolder === this.origFolder) {
            return;
          }
          for (let i = 0; i < this.moveVideoList.length; ++i) {
            await this.folderBrowserVM.moveVideo(this.moveVideoList[i], this.moveToFolder);
          }
          for (let i = 0; i < this.moveFolderList.length; ++i) {
            await this.folderBrowserVM.moveFolder(this.moveFolderList[i], this.moveToFolder);
          }
          this.controller.close();
        });
      }
      .width('100%')
      .layoutWeight(0)
      .justifyContent(FlexAlign.SpaceBetween);

      Navigation(this.moveNavPath, { name: 'FolderBrowser', param: this.origFolder })
        .layoutWeight(1)
        .hideTitleBar(true)
        .margin({ top: 16 });
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}

